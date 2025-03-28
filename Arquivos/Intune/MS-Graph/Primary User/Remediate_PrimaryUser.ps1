<#
.DESCRIÇÃO
Este script utiliza a API do Microsoft Graph para atualizar o usuário primário de um dispositivo gerenciado pelo Intune.

.FUNCIONAMENTO
1. Obtém um token de autenticação do Azure AD usando as credenciais do aplicativo.
2. Busca o Object ID do novo usuário primário no Azure AD.
3. Obtém o ID do dispositivo gerenciado no Intune com base no nome do host da máquina.
4. Atualiza o usuário primário do dispositivo no Intune utilizando a API do Microsoft Graph.

.PRÉ-REQUISITOS
- O aplicativo deve estar registrado no Azure AD com permissões adequadas para acessar e modificar objetos do Intune.
- As credenciais do aplicativo (TenantId, ClientId, ClientSecret) devem ser configuradas corretamente.
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
- O script oculta mensagens de erro utilizando `-ErrorAction SilentlyContinue` para evitar ruídos desnecessários.
- Caso qualquer etapa falhe (token não gerado, usuário não encontrado, etc.), o script simplesmente finaliza sem alertas.

.NOTAS
- A API utilizada está na versão **Beta**, o que significa que pode sofrer alterações futuras.
- A atualização do usuário primário pode levar alguns minutos para ser refletida no portal do Intune.
#>



# Defina as informações de autenticação
$TenantId = ""
$ClientId = ""
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

# Obtém usuário logado e constrói UPN
$loggedInUser = (Get-WmiObject -Class Win32_ComputerSystem).UserName
$loggedInUserName = $loggedInUser.Split('\')[1]
$domain = "@omeusobrinhosabe.com"
$userPrincipalName = "$loggedInUserName$domain"

# Consulta Object ID do usuário
$userUrl = "https://graph.microsoft.com/v1.0/users?`$filter=userPrincipalName eq '$userPrincipalName'"
$userResponse = Invoke-RestMethod -Uri $userUrl -Headers $headers

if ($userResponse.value.Count -gt 0) {
    $newUserObjectId = $userResponse.value[0].id
    Write-Output "Novo usuário encontrado: $newUserObjectId"
} else {
    Write-Output "Usuário não encontrado no Azure AD."
    exit
}

# Lista dispositivos no Intune
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

# Atualizar usuário primário do dispositivo
$updateUrl = "https://graph.microsoft.com/beta/deviceManagement/managedDevices('$deviceId')/users/`$ref"
$body = @{
    "@odata.id" = "https://graph.microsoft.com/beta/users/$newUserObjectId"
} | ConvertTo-Json -Depth 1

try {
    Invoke-RestMethod -Method POST -Uri $updateUrl -Headers $headers -Body $body -ContentType "application/json"
    Write-Output "Usuário primário atualizado com sucesso!"
    Exit 0
} catch {
    Write-Output "Erro ao atualizar usuário primário: $_"
    Exit 1
}