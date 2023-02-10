#Remocao do Backup and Sync from Google via WMIObject

Get-WmiObject -Class Win32_Product | Where-Object {$_.Name -match "Backup and Sync from Google"}

gwmi Win32_Product -filter "name like 'Backup and Sync from Google'"  | % { $_.Uninstall() }

$Data = Get-Date
write-output "O Backup and Sync from Google foi excluído em $Data." | out-file C:\Windows\Temp\RemoveBackupandSyncfromGoogle.txt -force