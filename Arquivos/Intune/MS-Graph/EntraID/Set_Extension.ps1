<##
.DESCRIPTION
    Este script PowerShell automatiza a atualização de um atributo personalizado em um dispositivo no Microsoft Entra ID.
    Ele obtém um token de acesso usando as credenciais fornecidas, e utiliza esse token para enviar uma requisição PATCH ao Microsoft Graph API, atualizando o atributo especificado.

.PARAMETER TenantId
    O ID do locatário (tenant) do Azure AD.

.PARAMETER ClientId
    O ID do cliente (client) registrado no Azure AD.

.PARAMETER ClientSecret
    O segredo do cliente (client secret) registrado no Azure AD.

.PARAMETER CustomExtensionValue
    O valor do atributo personalizado que será aplicado ao dispositivo. Na linha 52 temos o "extensionAttribute1" e o
    extensionAttribute vai de 1 ate 15, personalize de acordo com a necessidade.

.PARAMETER Device ObjectId
    O ID do objeto do dispositivo no Azure AD.

.EXAMPLE
    PS> .\SeuScript.ps1 -TenantId "KK723420-7a5a-46f2-a44L-ab98d49bd815" -ClientId "2c6d525e-5513-5uk1-00a8-c46bf5f3cd80" -ClientSecret "AS08asdscfeudud01abpSTpB9eilMV66SOqwoapxmbc7Y" -CustomExtensionValue "ABC" -DeviceObjectId "b09bd58f-4W4a-45e7-8fb1-f030985w3121"

.NOTES
    Este script requer permissões adequadas no Azure AD e no Microsoft Graph API.
    Autor: Marcos Paulo Stoko
    Data: 17.04.2025
#>

# Configurações
$TenantId = ""
$ClientId = ""
$ClientSecret = ""
$CustomExtensionValue = "FABRICA"
$DeviceObjectId = "b06bd58a-4b4a-45e7-8fb1-e0379854e121"

# Obter Token de Acesso para o Microsoft Graph
$Body = @{
    grant_type    = "client_credentials"
    client_id     = $ClientId
    client_secret = $ClientSecret
    scope         = "https://graph.microsoft.com/.default"
} 

$TokenResponse = Invoke-RestMethod -Uri "https://login.microsoftonline.com/$TenantId/oauth2/v2.0/token" -Method Post -Body $Body
$AccessToken = $TokenResponse.access_token
$Headers = @{ Authorization = "Bearer $AccessToken"; "Content-Type" = "application/json" }

# Define o corpo da requisição para atualizar o atributo
$UpdateBody = @{
    extensionAttributes = @{
        extensionAttribute1 = $CustomExtensionValue
    }
} | ConvertTo-Json -Depth 3

# Atualiza o atributo no Entra ID
$PatchUrl = "https://graph.microsoft.com/v1.0/devices/$DeviceObjectId"
Invoke-RestMethod -Uri $PatchUrl -Headers $Headers -Method Patch -Body $UpdateBody

Write-Host "Atributo personalizado aplicado para o dispositivo com ObjectId '$DeviceObjectId'!" -ForegroundColor Green
