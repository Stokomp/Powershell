# ==============================================================================
# SCRIPT DE REPARO - VERSÃO USUÁRIO COMUM (SEM ERRO DE TAREFA)
# ==============================================================================

Write-Host "1. Forçando ativação de notificações..." -ForegroundColor Cyan
$RegPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Notifications\Settings"
if (!(Test-Path $RegPath)) { New-Item -Path $RegPath -Force | Out-Null }
Set-ItemProperty -Path $RegPath -Name "NOC_GLOBAL_SETTING_TOASTS_ENABLED" -Value 1 -Force

Write-Host "2. Verificando Identidade..." -ForegroundColor Cyan
$dsreg = dsregcmd /status
$prt = ($dsreg | Select-String "AzureAdPrt : YES")

if ($prt) {
    Write-Host "[OK] AzureAdPrt já está ativo!" -ForegroundColor Green
} else {
    Write-Host "[!] AzureAdPrt em falta. Chamando janela de login..." -ForegroundColor Yellow
    # Este comando abre a página de reparo
    Start-Process "ms-settings:workplace-repairtoken"
    
    # Este é o comando que substitui a tarefa agendada para o usuário comum
    # Ele força o 'entrar' da conta
    Start-Process "C:\Windows\system32\DeviceEnroller.exe" -ArgumentList "/c /u /d"
}

Write-Host "3. Forçando Sincronismo do Intune (Modo Usuário)..." -ForegroundColor Cyan
# Este comando substitui o Start-ScheduledTask e não pede Admin
& "C:\Windows\system32\deviceenroller.exe" /mobilepolicysync

Write-Host "--- FIM ---" -ForegroundColor Cyan
Write-Host "Se o seu PC já estiver como 'Hybrid' no servidor, a janela de login deve aparecer agora."
