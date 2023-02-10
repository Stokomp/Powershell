#Limpeza 7zip
$Validar = "C:\Program Files\7-Zip\7-zip.chm"
$Arquivo = "7-zip.chm"
$Data = Get-Date

#Inicio do script
if (Test-path -path $Validar)
{Remove-item $Arquivo 
Write-host "O arquivo foi excluído"
}
else {
    write-host "Não existe este arquivo"
}

#log
$Data = get-date
write-output "O arquivo help foi excluído em $Data." | out-file C:\Windows\Temp\7zipExclude.txt -force