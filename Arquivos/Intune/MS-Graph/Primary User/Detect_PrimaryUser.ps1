<#
.DESCRIÇÃO
Este script utiliza a API do Microsoft Graph para verificar se o usuário atualmente logado no Windows é o usuário primário do dispositivo gerenciado no Microsoft Intune.

.FUNCIONAMENTO
1. Obtém um token de autenticação no Azure AD utilizando as credenciais do aplicativo.
2. Captura o SAM Account Name do usuário logado no Windows.
3. Consulta o usuário no Microsoft Graph para obter o On-Premises User Principal Name (UPN).
4. Busca o dispositivo no Intune com base no hostname do computador.
5. Verifica se o UPN do usuário logado corresponde ao usuário primário registrado no dispositivo.
6. Exibe uma mensagem informando se o usuário logado é ou não o usuário primário do dispositivo.

.PRÉ-REQUISITOS
- O dispositivo deve estar registrado no Intune.
- O usuário deve existir no Azure AD com um On-Premises SAM Account Name registrado.
- O aplicativo no Azure AD deve ter as seguintes permissões concedidas na Microsoft Graph API:
  1. `Device.Read.All` - Permite leitura de dispositivos gerenciados.
  2. `User.Read.All` - Permite leitura de informações dos usuários.
  3. `DeviceManagementManagedDevices.Read.All` - Permite consultar dispositivos no Intune.

.EXECUÇÃO
- O script retorna `Exit 0` se o usuário logado for o usuário primário do dispositivo.
- Caso contrário, retorna `Exit 1`.

.NOTAS
- O tempo para refletir mudanças no Intune pode variar.
- Erros de autenticação podem ocorrer caso as credenciais estejam incorretas ou sem permissões adequadas.
#>

# Defina as informações de autenticação
$TenantId     = ""
$ClientId     = ""
$ClientSecret = ""

# Obter token de acesso
$body = @{
    grant_type    = "client_credentials"
    scope         = "https://graph.microsoft.com/.default"
    client_id     = $ClientId
    client_secret = $ClientSecret
}
$response = Invoke-RestMethod -Method Post -Uri "https://login.microsoftonline.com/$TenantId/oauth2/v2.0/token" `
                              -ContentType "application/x-www-form-urlencoded" -Body $body
$token = $response.access_token

$headers = @{
    Authorization = "Bearer $token"
    "Content-Type" = "application/json"
}

# Obtém usuário logado e extrai o SAM Account Name
$loggedInUser = (Get-CimInstance -ClassName Win32_ComputerSystem).UserName
$loggedInUserName = $loggedInUser.Split('\')[1]

# Buscar usuário no Microsoft Graph pelo SAM Account Name
$userUrl = "https://graph.microsoft.com/v1.0/users?`$select=id,displayName,userPrincipalName,onPremisesSamAccountName,onPremisesUserPrincipalName"
$userResponse = Invoke-RestMethod -Uri $userUrl -Headers $headers

$user = $userResponse.value | Where-Object { $_.onPremisesSamAccountName -eq $loggedInUserName }

if ($user) {
    $newUserObjectId = $user.id
    $newUserUPN = $user.onPremisesUserPrincipalName
    Write-Output "Usuário encontrado: $newUserObjectId, UPN: $newUserUPN"
} else {
    Write-Output "Usuário não encontrado no Azure AD."
    exit
}

# Buscar dispositivo no Intune pelo hostname
$deviceUrl = "https://graph.microsoft.com/v1.0/deviceManagement/managedDevices"
$deviceResponse = Invoke-RestMethod -Uri $deviceUrl -Headers $headers
$device = $deviceResponse.value | Where-Object { $_.deviceName -eq $(hostname) }

if ($device) {
    $deviceId = $device.id
    Write-Output "Dispositivo encontrado: $deviceId"
} else {
    Write-Output "Dispositivo não encontrado no Intune."
    
}

# Verificar se o usuário logado é o usuário primário do dispositivo
$primaryUserUrl = "https://graph.microsoft.com/v1.0/deviceManagement/managedDevices('$deviceId')/users"
$primaryUserResponse = Invoke-RestMethod -Uri $primaryUserUrl -Headers $headers

$primaryUser = $primaryUserResponse.value | Where-Object { $_.userPrincipalName -eq $newUserUPN }

if ($primaryUser) {
    Write-Output "Usuário logado é o usuário primário do dispositivo."
    Exit 0
} else {
    Write-Output "Usuário logado não é o usuário primário do dispositivo."
    Exit 1
    }
