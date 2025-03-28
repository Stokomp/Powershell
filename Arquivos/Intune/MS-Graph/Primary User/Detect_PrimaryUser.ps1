# Define as informações de autenticação do aplicativo no Azure AD
$TenantId     = ""
$ClientId     = ""
$ClientSecret = ""

# URL de autenticação
$authUrl = "https://login.microsoftonline.com/$TenantId/oauth2/v2.0/token"

# Corpo da solicitação de autenticação
$body = @{
    grant_type    = "client_credentials"
    client_id     = $ClientId
    client_secret = $ClientSecret
    scope         = "https://graph.microsoft.com/.default"
}

# Obtém o token de acesso
$tokenResponse = Invoke-RestMethod -Method Post -Uri $authUrl -Body $body
$accessToken = $tokenResponse.access_token

# Define o cabeçalho de autorização
$headers = @{
    "Authorization" = "Bearer $accessToken"
}

# Obtém o nome do usuário conectado
$loggedInUser = (Get-WmiObject -Class Win32_ComputerSystem).UserName

# Remove o prefixo do domínio para obter o nome de usuário
$loggedInUserName = $loggedInUser.Split('\')[1]

# URL para listar dispositivos gerenciados
$deviceUrl = "https://graph.microsoft.com/v1.0/deviceManagement/managedDevices"

# Obtém a lista de dispositivos
$deviceResponse = Invoke-RestMethod -Uri $deviceUrl -Headers $headers

# Filtra o dispositivo específico pelo nome do host
$device = $deviceResponse.value | Where-Object { $_.deviceName -eq $(hostname) }

# Verifica se o userDisplayName do usuário conectado é o usuário primário no Intune
if ($device.userDisplayName -eq $loggedInUserName) {
    Write-Output "O usuário conectado é o usuário primário no Intune."
    Exit 0
    Disconnect-MgGraph -ErrorAction SilentlyContinue
} else {
    Write-Output "O usuário conectado não é o usuário primário no Intune."
    Exit 1
    Disconnect-MgGraph -ErrorAction SilentlyContinue
}