<#

Titulo: Uptime Days
Descricao: Este script verifica quantos dias o Windows está ligado sem ser reiniciado. Ele usa a variável $Uptime.OSUptime.Days para identificar o número de dias,
e verifica se é maior ou igual a 1 (-ge 1). O número 1 representa pelo menos um dia sem reinicialização, fique a vontade para alterar de acordo
com o seu ambiente.

.Autor: Marcos Paulo Stoko

#>


$Uptime= get-computerinfo | Select-Object OSUptime 
if ($Uptime.OsUptime.Days -ge 1){
    Write-Output "Device has not rebootet on $($Uptime.OsUptime.Days) days, notify user to reboot"
    Exit 1
}else {
    Write-Output "Device has rebootet $($Uptime.OsUptime.Days) days ago, all good"
    Exit 0
}