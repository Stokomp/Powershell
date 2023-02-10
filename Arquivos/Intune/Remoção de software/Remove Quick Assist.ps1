#Script de remoção do Assistência Rápida (QuickAssist) do Windows 10
powershell.exe -ExecutionPolicy Bypass -NoLogo -NonInteractive -NoProfile -WindowStyle Hidden -command "Remove-WindowsCapability -Online -Name App.Support.QuickAssist~~~~0.0.1.0"

#Commandline para instalar o QuickAssist
#Add-WindowsCapability -Online -Name App.Support.QuickAssist~~~~0.0.1.0