Add-Type -AssemblyName System.Windows.Forms 
$global:balloon = New-Object System.Windows.Forms.NotifyIcon
$path = (Get-Process -id $pid).Path
$balloon.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon($path) 
$balloon.BalloonTipIcon = [System.Windows.Forms.ToolTipIcon]::Warning 
$balloon.BalloonTipText = 'Identificamos que seu computador não foi reiniciado nesses últimos 7 dias. Para melhor desempenho, por favor reinicie.'
$balloon.BalloonTipTitle = "Atenção $Env:USERNAME" 
$balloon.Visible = $true 
$balloon.ShowBalloonTip(8000)
exit 0