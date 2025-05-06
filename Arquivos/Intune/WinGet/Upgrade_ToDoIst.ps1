<#

Winget Path: "$env:ProgramW6432\WindowsApps\Microsoft.DesktopAppInstaller_*_x64__8wekyb3d8bbwe\winget.exe")

#>



# Variaveis
$ID = "XP99K37G9CWBDC"
$WingetPath = "$env:ProgramW6432\WindowsApps\Microsoft.DesktopAppInstaller_*_x64__8wekyb3d8bbwe"

$ArgumentList = "upgrade --id $ID --silent --accept-package-agreements --accept-source-agreements"

# Execucao do script
Set-location -path $WingetPath
Start-Process -FilePath .\winget.exe -ArgumentList $ArgumentList