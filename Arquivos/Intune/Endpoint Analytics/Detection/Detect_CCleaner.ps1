#Remocao CCleaner

#-------------------------------------------------------------------------------------
#                               Variaveis
#   $Software = Corresponde Ã  aplicaÃ§Ã£o que vocÃª quer localizar
#       $Installed = Propriedade que farÃ¡ a busca do software nos caminhos do REGEDIT.
#-------------------------------------------------------------------------------------

#Variaveis
$Regedit1 = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*"
$Regedit2 = "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
$Regedit3 = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*"
$Regedit4 = "HKCU:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
$software = "CCleaner" #Colocar exatamente o nome que aparece no painel de controle do Windows.
$installed = (Get-ItemProperty $Regedit1,$Regedit2 | Where { $_.DisplayName -match $software }) -ne $null

#Inicio do script 

If(-NOT $installed) {
	Write-Host "$software nao esta instalado.";
    Exit 0
} else {
	Write-Host "$software esta instalado. Iniciando remocao"
    Exit 1
}