#Check zscaler ZSATunnel Service

if (get-service -name ZSATrayManager | where status -eq running )
{
    Write-Output "O servico esta em execucao. "
    exit 0
}
else {
   Write-Output "O servico nao esta em execucao."
    exit 1
}