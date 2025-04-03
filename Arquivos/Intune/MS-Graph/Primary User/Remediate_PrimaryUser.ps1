<#
.DESCRIÇÃO
Este script utiliza a API do Microsoft Graph para verificar e atualizar o usuário primário de um dispositivo gerenciado pelo Intune, garantindo que o usuário logado no Windows seja corretamente refletido no Azure AD.

.FUNCIONAMENTO
1. Obtém um token de autenticação do Azure AD usando as credenciais do aplicativo.
2. Captura o SAM Account Name do usuário logado no Windows.
3. Consulta o Azure AD para obter o onPremisesUserPrincipalName correspondente.
4. Obtém o ID do dispositivo gerenciado no Intune com base no nome do host da máquina.
5. Verifica se o usuário logado é o usuário primário do dispositivo no Intune.
6. Caso necessário, atualiza o usuário primário do dispositivo no Intune.

.PRÉ-REQUISITOS
- O aplicativo deve estar registrado no Azure AD com permissões adequadas para acessar e modificar objetos do Intune.
- As credenciais do aplicativo (TenantId, ClientId, ClientSecret) devem estar configuradas corretamente.
- O dispositivo deve estar registrado no Intune.
- O usuário que será definido como primário deve existir no Azure AD.

.PERMISSÕES NECESSÁRIAS (Microsoft Graph API)
O aplicativo no Azure AD precisa ter as seguintes permissões concedidas:
1. `Device.ReadWrite.All` - Permite leitura e modificação de dispositivos gerenciados.
2. `User.Read.All` - Permite a leitura das informações dos usuários no Azure AD.
3. `Directory.ReadWrite.All` - Necessário para modificar propriedades no diretório.
4. `DeviceManagementManagedDevices.PrivilegedOperations.All` - Permissão específica para operações privilegiadas no Intune.

Todas as permissões acima devem ser concedidas como **Application Permissions** e consentidas pelo administrador.

.EXECUÇÃO
- Execute este script em um ambiente PowerShell com acesso à internet.
- Caso qualquer etapa falhe (token não gerado, usuário não encontrado, etc.), o script encerrará a execução com uma mensagem de erro.
- A atualização do usuário primário pode levar alguns minutos para ser refletida no portal do Intune.

.NOTAS
- A API utilizada pode sofrer alterações futuras.
- O script oculta mensagens de erro desnecessárias utilizando `-ErrorAction SilentlyContinue` para melhor legibilidade.
- Após a execução, recomenda-se validar a alteração diretamente no portal do Intune.

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
    exit
}

# Verificar se o usuário logado é o usuário primário do dispositivo
$primaryUserUrl = "https://graph.microsoft.com/v1.0/deviceManagement/managedDevices('$deviceId')/users"
$primaryUserResponse = Invoke-RestMethod -Uri $primaryUserUrl -Headers $headers

$primaryUser = $primaryUserResponse.value | Where-Object { $_.userPrincipalName -eq $newUserUPN }

if ($primaryUser) {
    Write-Output "Usuário logado é o usuário primário do dispositivo."
    Exit 0
} else {
    Write-Output "Usuário logado NÃO é o usuário primário do dispositivo. Atualizando..."
    
    # Atualizar usuário primário do dispositivo
    $updateUrl = "https://graph.microsoft.com/beta/deviceManagement/managedDevices('$deviceId')/users/`$ref"
    $body = @{ "@odata.id" = "https://graph.microsoft.com/beta/users/$newUserObjectId" } | ConvertTo-Json -Depth 1

    try {
        Invoke-RestMethod -Method POST -Uri $updateUrl -Headers $headers -Body $body -ContentType "application/json"
        Write-Output "Usuário primário atualizado com sucesso!"
        Exit 0
    } catch {
        Write-Output "Erro ao atualizar usuário primário: $_"
        Exit 1
    }
}
