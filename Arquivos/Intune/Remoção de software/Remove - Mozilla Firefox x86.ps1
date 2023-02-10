#Script de remocao - Mozilla Firefox x86

#Variaveis
$Caminho = "C:\Program Files (x86)\Mozilla Firefox\uninstall"
$parametro = "-ms"
$Caminho2 = "C:\Program Files (x86)"
$ApagarDiretorio = "C:\Program Files (x86)\Mozilla Firefox"
$ApagarDiretorio2 = "C:\Program Files (x86)\Mozilla Maintenance Service"
$RegUninstallPaths = "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall"

#Inicio do script

Set-Location $Caminho

start-process "helper.exe" -ArgumentList $parametro

Set-location $Caminho2 
remove-item $ApagarDiretorio -recurse -force
remove-item $ApagarDiretorio2 -recurse -force

New-PSDrive -Name HKCR -PSProvider Registry -Root HKEY_CLASSES_ROOT | Out-Null $ClassesRootPath = "HKCR:\SOFTWARE\Mozilla"
Get-ChildItem $ClassesRootPath | Where-Object { ($_.GetValue('ProductName') -like '*Mozilla*')} | Foreach {Remove-Item $_.PsPath -Force -Recurse}