<#
Criado por: Marcos Paulo
Objetivo: Consultar GroupTag (Tag) de dispositivos Windows Autopilot no Intune via Graph API, sem popup de login.
#>

$clientId = "<SEU_CLIENT_ID>"
$clientSecret = "<SEU_CLIENT_SECRET>"
$tenantId = "<SEU_TENANT_ID>"

# Endpoint do Microsoft Graph
$graphApiVersion = "Beta"
$resource = "https://graph.microsoft.com/"
$uri = "https://graph.microsoft.com/$graphApiVersion/deviceManagement/windowsAutopilotDeviceIdentities"

# ========================
# 🔐 Obter Token (sem login)
# ========================

$body = @{
    Grant_Type    = "client_credentials"
    Scope         = "https://graph.microsoft.com/.default"
    Client_Id     = $clientId
    Client_Secret = $clientSecret
}
$tokenResponse = Invoke-RestMethod -Uri "https://login.microsoftonline.com/$tenantId/oauth2/v2.0/token" -Method POST -Body $body
$headers = @{ Authorization = "Bearer $($tokenResponse.access_token)" }

# ==========================
# 📋 Ler os números de série
# ==========================

$SerialNumbers = Get-Content -Path ".\SerialNumber.txt"
$results = @()

foreach ($Serial in $SerialNumbers) {

    # Filtra dispositivo pelo número de série
    $filter = "?`$filter=contains(serialNumber,'$Serial')"
    $response = Invoke-RestMethod -Uri "$uri$filter" -Headers $headers -Method GET

    if ($response.value.Count -gt 0) {
        foreach ($device in $response.value) {
            Write-Host "--------------------------------------"
            Write-Host "Serial Number : $($device.serialNumber)"
            Write-Host "Group Tag     : $($device.groupTag)"
            Write-Host "Display Name  : $($device.displayName)"
            Write-Host "ID (Graph)    : $($device.id)"
            Write-Host "--------------------------------------"

            $results += [PSCustomObject]@{
                SerialNumber = $device.serialNumber
                GroupTag     = $device.groupTag
                DisplayName  = $device.displayName
                Id           = $device.id
            }
        }
    } else {
        Write-Host "⚠️ Nenhum dispositivo encontrado com o serial $Serial."
    }
}

# ==========================
# 💾 Exportar resultados CSV
# ==========================

if ($results.Count -gt 0) {
    $results | Export-Csv -Path ".\AutopilotGroupTags.csv" -NoTypeInformation -Encoding UTF8
    Write-Host "✅ Relatório exportado para AutopilotGroupTags.csv"
} else {
    Write-Host "❌ Nenhum dispositivo encontrado."
}
