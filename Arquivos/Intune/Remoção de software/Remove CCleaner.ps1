#Script de remoção do CCleaner

#Variaveis
$CCleaner = "C:\Program Files\CCleaner"

#Inicio do script
Set-Location $CCleaner
.\uninst.exe /S