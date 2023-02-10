#Variaveis
$search = "wireshark" #Coloque o nome do programa
$Regedit1 = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*"
$Regedit2 = "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
$Regedit3 = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*"
$software =  $(Get-ItemProperty $Regedit1, $Regedit2, $Regedit3 | Where-Object {$_.DisplayName -Match $search} | select DisplayName)

#$software

if ($software -match $installed) {
    Write-Host "Nenhum software contendo '$search' foi encontrado"
    Exit 0
} else {
    Write-Host "Os seguintes softwares com '$search' foram encontrados:"
    $software.DisplayName
    Exit 1
}