#Limpeza 7ZIP v2
$7ZipFolder = "C:\Program Files\7-Zip"
$Validar = "C:\Program Files\7-Zip\7-zip.chm"
$Arquivo = "7-zip.chm"


#Inicio do script
test-path -path $Validar 
Set-location $7ZipFolder
Remove-item $Arquivo -force

#log
$Data = get-date
write-output "O arquivo help foi excluído em $Data." | out-file C:\Windows\Temp\7zipExclude.txt -force