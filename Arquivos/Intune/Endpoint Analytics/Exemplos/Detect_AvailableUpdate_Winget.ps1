#Detectar update disponivel via WINGET

#Variaveis
$SoftwareID = "Anki.Anki"
$List_software = winget.exe list -e --id $SoftwareID --accept-source-agreements
$Update = (-split $List_software[-3])[-2]
#Write-host $Update -> Linha criada para consultar se existe atualizacao de software

#Inicio do script
if ($List_software -Match 'Available')
{
Write-Output "Foi encontrado uma atualizacao, iniciando upgrade na versao de software."
Exit 1
} 
if ($List_software -eq 'Version')
{
write-host "O software esta atualizado ou nao existe, nenhuma acao sera necessaria."
Exit 1
}
else 
{
Write-Output "O software esta atualizado, nenhuma acao sera necessaria."
Exit 0
}