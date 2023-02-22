#Script para remover o Mozilla Firefox

#Variaveis
$LocalPath = "C:\Program Files\Mozilla Firefox\uninstall"
$MozillaFirefox = 'C:\Program Files\Mozilla Firefox\uninstall\helper.exe'

#Inicia do script
Start-Process -FilePath $MozillaFirefox -ArgumentList "/S"
Exit 0