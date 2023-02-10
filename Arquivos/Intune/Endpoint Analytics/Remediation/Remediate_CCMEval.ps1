#Remediate CCMEval
Enable-ScheduledTask -TaskName "\Microsoft\Configuration Manager\Configuration Manager Health Evaluation"
#Log
$Data = get-date
write-output "O forcepoint foi removido em $Data." | out-file C:\Temp\Remediate_CCMEval.log
exit 0