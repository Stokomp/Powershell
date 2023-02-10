#Script de remoção do Winrar

#Variaveis
$CaminhoWinrar = "C:\Program Files\WinRAR"
#$Apagardiretorio = "C:\Program Files\WinRAR"

#Inicio do script
Set-Location $CaminhoWinrar
.\Uninstall.exe -s