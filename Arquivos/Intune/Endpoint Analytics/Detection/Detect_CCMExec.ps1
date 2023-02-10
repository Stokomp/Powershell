#Check CCMExec

if (get-service -name ccm* | where status -eq running )
{
    Write-Output "O servico esta em execucao. "
    exit 0
}
else {
   Write-Output "A tarefa nao esta em execucao."
    exit 1
}