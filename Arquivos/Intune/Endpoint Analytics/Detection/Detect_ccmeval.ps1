#Check SCCM Eval

if (Get-ScheduledTask | where {$_.TaskName -eq "Configuration Manager Health Evaluation"} | where state -EQ 'Ready' )
{
    Write-Output "A tarefa esta habilitada."
    exit 0
}
else {
   Write-Output "A tarefa nao esta em execucao."
    exit 1
}