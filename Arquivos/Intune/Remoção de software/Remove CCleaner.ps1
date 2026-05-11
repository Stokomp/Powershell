<#
.SYNOPSIS
    Reparo de Identidade e Sincronismo MDM (Contexto de Usuário).
    
.DESCRIPTION
    Ativa notificações globais para erros de conta, verifica a presença do Azure PRT
    e força o sincronismo de políticas MDM/Intune sem exigir privilégios de Admin.

.EXAMPLE
    .\Repair-IdentityContext.ps1
#>
[CmdletBinding()]
param()

process {
    try {
        # 1. Configuração de Notificações (UX para erros de conta)
        Write-Host "1. Ativando notificações de sistema para o usuário..." -ForegroundColor Cyan
        $RegPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Notifications\Settings"
        
        if (!(Test-Path $RegPath)) { 
            New-Item -Path $RegPath -Force | Out-Null 
        }

        # NOC_GLOBAL_SETTING_TOASTS_ENABLED garante que alertas de conta não sejam silenciados
        Set-ItemProperty -Path $RegPath -Name "NOC_GLOBAL_SETTING_TOASTS_ENABLED" -Value 1 -Force
        Write-Host "[OK] Notificações configuradas." -ForegroundColor Green

        # 2. Verificação de Identidade (PRT)
        Write-Host "2. Validando Token de Identidade (Azure PRT)..." -ForegroundColor Cyan
        $dsreg = dsregcmd /status
        $hasPrt = $dsreg | Select-String "AzureAdPrt : YES"

        if ($hasPrt) {
            Write-Host "[OK] Token PRT validado com sucesso." -ForegroundColor Green
        } else {
            Write-Host "[!] PRT Ausente. Invocando janela de autenticação..." -ForegroundColor Yellow
            
            # Execução assíncrona para não travar o script enquanto o usuário loga
            Start-Process -FilePath "C:\Windows\System32\DeviceEnroller.exe" -ArgumentList "/c /u /d" -WindowStyle Hidden
        }

        # 3. Forçar sincronismo de políticas (MobilePolicySync)
        Write-Host "3. Sincronizando políticas de dispositivo (Intune)..." -ForegroundColor Cyan
        
        # O parâmetro /mobilepolicysync é o padrão ouro para 'Sync' via linha de comando no Win10/11
        Start-Process -FilePath "C:\Windows\System32\DeviceEnroller.exe" -ArgumentList "/mobilepolicysync" -Wait
        
        Write-Host "[OK] Sincronismo disparado com sucesso." -ForegroundColor Green
        Write-Host "--- PROCESSO CONCLUÍDO ---" -ForegroundColor Cyan

    }
    catch {
        Write-Error "Falha crítica durante o reparo de identidade: $($_.Exception.Message)"
    }
}
