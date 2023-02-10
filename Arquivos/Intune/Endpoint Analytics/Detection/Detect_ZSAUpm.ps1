#Check zscaler ZSAUpm Service

if (get-service -name ZSAUpm | where status -eq running )
{
    Write-Output "O servico esta em execucao. "
    exit 0
}
else {
   Write-Output "O servico nao esta em execucao."
    exit 1
}