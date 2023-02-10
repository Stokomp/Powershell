#Script de remocao - Mozilla Firefox x64

#Variaveis
$Caminho = "C:\Program Files\Mozilla Firefox\uninstall"
#$Caminho2 = "C:\Program Files\Mozilla Firefox\crashreporter.exe"
$parametro = "-ms"


#Inicio do script

Set-Location $Caminho
start-process "helper.exe" -ArgumentList $parametro

Get-Item HKLM:\SOFTWARE\Mozilla | Remove-Item -Force -recurse
Get-Item HKLM:\SOFTWARE\mozilla.org | Remove-Item -Force -recurse
Get-Item HKLM:\SOFTWARE\MozillaPlugins | Remove-Item -Force -recurse
Get-Item HKCU:\SOFTWARE\Mozilla | Remove-Item -Force -recurse