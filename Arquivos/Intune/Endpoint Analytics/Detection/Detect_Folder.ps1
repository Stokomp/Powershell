#Validacao de pasta

$Folder = "C:\EndpointAnalytics"

if (test-path -Path $Folder) {
Write-Output "A pasta existe."
Exit 0
}

else {
Write-Output "A pasta não existe. Criando a pasta"
exit 1
}