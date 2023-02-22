#Script para detectar instalacao do Mozilla Firefox

#Variaveis
$MozillaFirefox = 'C:\Program Files\Mozilla Firefox\uninstall\helper.exe'
$Folder = 'C:\Program Files\Mozilla Firefox\uninstall'

#Inicio do script
if (Test-Path -Path $Folder) {
    Write-Output "O mozilla esta instalado. Iniciando remocao."
    Exit 1
    } else {
    Write-Output "O mozilla nao esta instalado."
    exit 0
    }