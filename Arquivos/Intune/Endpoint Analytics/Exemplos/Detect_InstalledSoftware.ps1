#-------------------------------------------------------------------------------------
#                               Variaveis
#   $Software = Corresponde à aplicação que você quer localizar
#       $Installed = Propriedade que fará a busca do software nos caminhos do REGEDIT.
#-------------------------------------------------------------------------------------

#Variaveis
$Regedit1 = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*"
$Regedit2 = "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
$Regedit3 = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*"
$Regedit4 = "HKCU:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
$software = "WinRAR 6.20 (64-bit)"
$installed = (Get-ItemProperty $Regedit1,$Regedit2 | Where { $_.DisplayName -eq $software })

#Ínicio do script 

If(-Not $installed) {
	Write-Host "$software nao esta instalado."
   
#log
$Data = get-date
write-output "O software não está instalado em $Data." | out-file C:\Windows\Temp\Winrar_naoinstalado.txt -force
Exit 0
} else {
	Write-Host "$software esta instalado."
    
#log
$Data = get-date
write-output "O software foi localizado em $Data." | out-file C:\Windows\Temp\Winrar_instalado.txt -force
Exit 1
}