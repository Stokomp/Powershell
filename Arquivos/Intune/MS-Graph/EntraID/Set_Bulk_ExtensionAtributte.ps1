<#
Criado por: Marcos Paulo Stoko
Descrição: Utilize este script powershell para aplicar um atributo espeficico em dispositivos via ObjectID.
Versão: 1.0
#>


# Configurações
$TenantId = ""
$ClientId = ""
$ClientSecret = ""
$DeviceListFile = "C:\Scripts\PSscripts\Microsoft Graph\Devices\Endpoints.txt"
$CustomExtensionValue = "FBC3"

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

# Lê o arquivo com os ObjectIds
$DeviceObjectIds = Get-Content -Path $DeviceListFile

# Para cada ObjectId no arquivo, realiza a atualização
foreach ($DeviceObjectId in $DeviceObjectIds) {
    $PatchUrl = "https://graph.microsoft.com/v1.0/devices/$DeviceObjectId"
    try {
        # Atualiza o atributo no Entra ID
        Invoke-RestMethod -Uri $PatchUrl -Headers $Headers -Method Patch -Body $UpdateBody
        Write-Host "Atributo personalizado aplicado para o dispositivo com ObjectId '$DeviceObjectId'!" -ForegroundColor Green
    } catch {
        Write-Host "Erro ao aplicar o atributo para o dispositivo com ObjectId '$DeviceObjectId'. Erro: $_" -ForegroundColor Red
    }
}
