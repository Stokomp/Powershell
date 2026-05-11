# 1. Forçar notificações ON (Contexto do Usuário)
$RegistryPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Notifications\Settings"
if (!(Test-Path $RegistryPath)) { New-Item -Path $RegistryPath -Force }
Set-ItemProperty -Path $RegistryPath -Name "NOC_GLOBAL_SETTING_TOASTS_ENABLED" -Value 1

# 2. Loop de verificação de Identidade (PRT)
$Timeout = 10 # Tentará por 10 minutos
$Counter = 0

Write-Host "Configurando sua conta corporativa. Por favor, aguarde..." -ForegroundColor Cyan

while ($Counter -lt $Timeout) {
    $dsreg = dsregcmd /status
    $hasPrt = ($dsreg | Select-String "AzureAdPrt : YES")

    if ($hasPrt) {
        Write-Host "Identidade confirmada! O Windows Hello iniciará em breve." -ForegroundColor Green
        break
    } else {
        Write-Host "Identidade pendente. Tentando validar credenciais..." -ForegroundColor Yellow
        
        # O PULO DO GATO: Abre a janela de correção e a traz para frente
        Start-Process "ms-settings:workplace-repairtoken"
        
        # Força o motor de registro a procurar o usuário agora
        Start-Process "C:\Windows\system32\DeviceEnroller.exe" -ArgumentList "/c /u /d" -Wait
    }

    Start-Sleep -Seconds 60
    $Counter++
}

# 3. Disparo final para o Intune
Get-ScheduledTask | Where-Object {$_.TaskName -eq "PushLaunch"} | Start-ScheduledTask
