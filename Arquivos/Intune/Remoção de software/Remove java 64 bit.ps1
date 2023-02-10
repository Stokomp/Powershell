Get-WmiObject -Class Win32_Product | Where-Object {$_.Name -match "GlobalProtect"}

gwmi Win32_Product -filter "name like 'GlobalProtect'" | % { $_.Uninstall() }

[System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms')
[System.Windows.Forms.MessageBox]::Show('Su computadora se reiniciará en 5 minutos. Después de reiniciar, se instalará un nuevo software.','Gracias')

shutdown /r /t 300