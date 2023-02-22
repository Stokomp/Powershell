#Como identificar aplicacao Google Chrome baseada em versao menor que a versao atual 110.0.5481.104
#Como funciona o script?
#O parametro -lt (less than) significa "menor que", então, voce vai colocar a versao desejada que queira monitorar.



#Variaveis
$GoogleChrome = "C:\Program Files\Google\Chrome\Application\chrome.exe"
$LocalPath = "C:\Program Files\Google\Chrome\Application\110.0.5481.104"
$Versao = "110.0.5481.104"

#Inicio do script 
if (test-path -path $LocalPath) {
    #Vamos validar se o Git esta instalado e em qual versao
    if ((get-item -path $GoogleChrome).versioninfo.fileversion -lt $Versao) {
        Write-Output "A versao do Google Chrome nao esta atualizada. Iniciando atualizacao."
        Exit 1
    } else {
        Write-Output "A versao do Google Chrome esta atualizada. Nenhuma acao necessaria."
        Exit 0
    }
} else { Write-Output "O Google Chrome nao esta instalado."
Exit 0 
}
