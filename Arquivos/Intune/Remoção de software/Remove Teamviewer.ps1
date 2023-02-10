#Script de remoção do Teamviewer

#Variaveis
$CaminhoTeamviewer = "C:\Program Files\TeamViewer"

#Inicio do script
Set-Location $CaminhoTeamviewer
.\Uninstall.exe /S