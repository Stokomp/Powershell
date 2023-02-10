#Script de remoção do Teamviewer

#Variaveis
$LinuxLiveUsb = "C:\Program Files (x86)\LinuxLive USB Creator"

#Inicio do script
Set-Location $LinuxLiveUsb
.\Uninstall.exe /S
cd c:\
Exit 0