<#
Criado por: Marcos Paulo
#>

$clientId = ""
$clientSecret = ""
$ourTenantId = ""

$Resource = "deviceManagement/windowsAutopilotDeviceIdentities"
$Resource = "deviceManagement/managedDevices"
$graphApiVersion = "Beta"
$uri = "https://graph.microsoft.com/$graphApiVersion/$($resource)"
$authority = "https://login.microsoftonline.com/$ourTenantId"
#Update-MSGraphEnvironment -AppId $clientId -Quiet
#Update-MSGraphEnvironment -AuthUrl $authority -Quiet
Connect-MSGraph #-ClientSecret $clientSecret

$Grouptag = "BR2" #Specify the GroupTag Here
$SerialNumbers = Get-Content -Path ".\SerialNumber.txt"
foreach ($Serial in $SerialNumbers) {
    $AutopilotDevice = Get-AutopilotDevice -serial $Serial
    
    # Verifique se $AutopilotDevice tem a propriedade SerialNumber para determinar o tipo
    if ($AutopilotDevice.SerialNumber) {
        # Se a propriedade SerialNumber existir, então considere o objeto como do tipo esperado
        Set-AutopilotDevice -Id $AutopilotDevice.Id -groupTag $Grouptag
        Write-Host "Tag adicionada com sucesso para o dispositivo com o serial $Serial."
    } else {
        Write-Host "O objeto retornado para o serial $Serial não é do tipo esperado."
        # Você pode adicionar manipulação adicional aqui, se necessário
    }
}
