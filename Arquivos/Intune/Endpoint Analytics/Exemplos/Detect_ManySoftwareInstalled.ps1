#Remocao CCleaner

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
$software = "Wireshark 4.0.0 64-bit"; #Colocar exatamente o nome que aparece no painel de controle do Windows.
$software2 = "CCleaner"; #Colocar exatamente o nome que aparece no painel de controle do Windows.
$software3 = "Dell SupportAssist"; #Colocar exatamente o nome que aparece no painel de controle do Windows.
$software4 = "WinRar"; #Colocar exatamente o nome que aparece no painel de controle do Windows.
$software5 = "Teste 1"; #Colocar exatamente o nome que aparece no painel de controle do Windows.
$software6 = "Teste 2"; #Colocar exatamente o nome que aparece no painel de controle do Windows.
$software7 = "Teste 3"; #Colocar exatamente o nome que aparece no painel de controle do Windows.
$software8 = "Teste 4"; #Colocar exatamente o nome que aparece no painel de controle do Windows.
$software9 = "Teste 5"; #Colocar exatamente o nome que aparece no painel de controle do Windows.
$software10 = "Teste 6"; #Colocar exatamente o nome que aparece no painel de controle do Windows.
$software11 = "Teste 7"; #Colocar exatamente o nome que aparece no painel de controle do Windows.
$software12 = "Teste 8"; #Colocar exatamente o nome que aparece no painel de controle do Windows.
$software13 = "Teste 9"; #Colocar exatamente o nome que aparece no painel de controle do Windows.
$software14 = "Teste 10"; #Colocar exatamente o nome que aparece no painel de controle do Windows.
$software15 = "Teste 11"; #Colocar exatamente o nome que aparece no painel de controle do Windows.
$software16 = "Teste 12"; #Colocar exatamente o nome que aparece no painel de controle do Windows.
$software17 = "Teste 13"; #Colocar exatamente o nome que aparece no painel de controle do Windows.
$software18 = "Teste 14"; #Colocar exatamente o nome que aparece no painel de controle do Windows.
$installed = (Get-ItemProperty $Regedit1,$Regedit2 | Where { $_.DisplayName -eq $software }) -ne $null
$installed2 = (Get-ItemProperty $Regedit1,$Regedit2 | Where { $_.DisplayName -eq $software2 }) -ne $null
$installed3 = (Get-ItemProperty $Regedit1,$Regedit2 | Where { $_.DisplayName -eq $software3 }) -ne $null
$installed4 = (Get-ItemProperty $Regedit1,$Regedit2 | Where { $_.DisplayName -Match $software4 }) -ne $null
$installed5 = (Get-ItemProperty $Regedit1,$Regedit2 | Where { $_.DisplayName -eq $software5 }) -ne $null
$installed6 = (Get-ItemProperty $Regedit1,$Regedit2 | Where { $_.DisplayName -eq $software6 }) -ne $null
$installed7 = (Get-ItemProperty $Regedit1,$Regedit2 | Where { $_.DisplayName -eq $software7 }) -ne $null
$installed8 = (Get-ItemProperty $Regedit1,$Regedit2 | Where { $_.DisplayName -eq $software8 }) -ne $null
$installed9 = (Get-ItemProperty $Regedit1,$Regedit2 | Where { $_.DisplayName -eq $software9 }) -ne $null
$installed10 = (Get-ItemProperty $Regedit1,$Regedit2 | Where { $_.DisplayName -eq $software10 }) -ne $null
$installed11 = (Get-ItemProperty $Regedit1,$Regedit2 | Where { $_.DisplayName -eq $software11 }) -ne $null
$installed12 = (Get-ItemProperty $Regedit1,$Regedit2 | Where { $_.DisplayName -eq $software12 }) -ne $null
$installed13 = (Get-ItemProperty $Regedit1,$Regedit2 | Where { $_.DisplayName -eq $software13 }) -ne $null
$installed14 = (Get-ItemProperty $Regedit1,$Regedit2 | Where { $_.DisplayName -eq $software14 }) -ne $null
$installed15 = (Get-ItemProperty $Regedit1,$Regedit2 | Where { $_.DisplayName -eq $software15 }) -ne $null
$installed16 = (Get-ItemProperty $Regedit1,$Regedit2 | Where { $_.DisplayName -eq $software16 }) -ne $null
$installed17 = (Get-ItemProperty $Regedit1,$Regedit2 | Where { $_.DisplayName -eq $software17 }) -ne $null
$installed18 = (Get-ItemProperty $Regedit1,$Regedit2 | Where { $_.DisplayName -eq $software18 }) -ne $null

#Ínicio do script 

If(-Not $installed) {
	Write-Host "$software nao esta instalado."
   #Exit 0
} 

If(-Not $installed2) {
	Write-Host "$software2 nao esta instalado."
    #Exit 0
}

If(-Not $installed3) {
	Write-Host "$software3 nao esta instalado."
    #Exit 0
}

If(-Not $installed4) {
	Write-Host "$software4 nao esta instalado."
    #Exit 0
}

If(-Not $installed5) {
	Write-Host "$software5 nao esta instalado."
    #Exit 0
}

If(-Not $installed6) {
	Write-Host "$software6 nao esta instalado."
    #Exit 0
}

If(-Not $installed7) {
	Write-Host "$software7 nao esta instalado."
    #Exit 0
}

If(-Not $installed8) {
	Write-Host "$software8 nao esta instalado."
    #Exit 0
}

If(-Not $installed9) {
	Write-Host "$software9 nao esta instalado."
    #Exit 0
}

If(-Not $installed10) {
	Write-Host "$software10 nao esta instalado."
    #Exit 0
}

If(-Not $installed11) {
	Write-Host "$software11 nao esta instalado."
    #Exit 0
}

If(-Not $installed12) {
	Write-Host "$software12 nao esta instalado."
    #Exit 0
}

If(-Not $installed13) {
	Write-Host "$software13 nao esta instalado."
    #Exit 0
}

If(-Not $installed14) {
	Write-Host "$software14 nao esta instalado."
    #Exit 0
}

If(-Not $installed15) {
	Write-Host "$software15 nao esta instalado."
    #Exit 0
}

If(-Not $installed16) {
	Write-Host "$software16 nao esta instalado."
    #Exit 0
}

If(-Not $installed17) {
	Write-Host "$software17 nao esta instalado."
    #Exit 0
}

If(-Not $installed18) {
	Write-Host "$software18 nao esta instalado."
    #Exit 0
} else {
Write-Host "$software esta instalado."
Write-host "$software2  esta instalado"
Write-host "$software3  esta instalado"
Write-host "$software4  esta instalado"
Write-host "$software5  esta instalado"
Write-host "$software6  esta instalado"
Write-host "$software7  esta instalado"
Write-host "$software8  esta instalado"
Write-host "$software9  esta instalado"
Write-host "$software10  esta instalado"
Write-host "$software11  esta instalado"
Write-host "$software12  esta instalado"
Write-host "$software13  esta instalado"
Write-host "$software14  esta instalado"
Write-host "$software15  esta instalado"
Write-host "$software16  esta instalado"
Write-host "$software17  esta instalado"
Write-host "$software18  esta instalado"
Exit 1 
    
}