#Script de remocao - Mozilla Firefox

#Variaveis
$Caminho = "C:\Program Files\Mozilla Firefox\uninstall"
$parametro = "-ms"
$Caminho2 = "C:\Program Files\Mozilla Firefox"

#Inicio do script
Set-Location $Caminho
start-process "helper.exe" -ArgumentList $parametro

#Excluir chave de registro
Get-Item HKLM:\SOFTWARE\Mozilla | Remove-Item -Force -recurse
Get-Item HKLM:\SOFTWARE\mozilla.org | Remove-Item -Force -recurse
Get-Item HKLM:\SOFTWARE\MozillaPlugins | Remove-Item -Force -recurse
Get-Item HKCU:\SOFTWARE\Mozilla | Remove-Item -Force -recurse

cd 'C:\Program Files'

#Excluir diretorio
Remove-Item -Path $Caminho2 -Force -Recurse

#log
$Data = get-date
write-output "O firefox foi removido em $Data." | out-file C:\Windows\Temp\Removefirefox.log