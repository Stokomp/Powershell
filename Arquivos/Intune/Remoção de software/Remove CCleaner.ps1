# ==============================================================================
# REPARO DE IDENTIDADE - VERSÃO "SEM ADMIN"
# FOCO: LIGAR NOTIFICAÇÕES E FORÇAR JANELA DE LOGIN
# ==============================================================================

Write-Host "1. Ligando notificações (Toast) para o usuário..." -ForegroundColor Cyan
$RegPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Notifications\Settings"
if (!(Test-Path $RegPath)) { New-Item -Path $RegPath -Force | Out-Null }

# Garante que o 'Não Perturbe' não abafe o erro da conta
Set-ItemProperty -Path $RegPath -Name "NOC_GLOBAL_SETTING_TOASTS_ENABLED" -Value 1 -Force
Write-Host "[OK] Notificações ativadas no Registro." -ForegroundColor Green

Write-Host "2. Verificando se o token de identidade (PRT) existe..." -ForegroundColor Cyan
$dsreg = dsregcmd /status
$hasPrt = ($dsreg | Select-String "AzureAdPrt : YES")

if ($hasPrt) {
    Write-Host "[OK] Você já tem um token válido. Sincronizando apenas políticas..." -ForegroundColor Green
} else {
    Write-Host "[!] Token ausente. FORÇANDO JANELA DE LOGIN..." -ForegroundColor Yellow
    
    # Este é o comando que substitui o 'Sync' manual e NÃO pede admin
    # Ele vai tentar registrar o usuário e, se precisar de MFA, DEVE abrir a janela azul
    Start-Process "C:\Windows\system32\DeviceEnroller.exe" -ArgumentList "/c /u /d"
}

Write-Host "3. Forçando sincronismo de apps (Modo Usuário)..." -ForegroundColor Cyan
# Este comando faz o 'Sync' do Intune sem precisar de tarefa agendada
& "C:\Windows\system32\deviceenroller.exe" /mobilepolicysync

Write-Host "--- PROCESSO CONCLUÍDO ---" -ForegroundColor Cyan
Write-Host "Fique atento a qualquer janela de login que aparecer nos próximos segundos."
