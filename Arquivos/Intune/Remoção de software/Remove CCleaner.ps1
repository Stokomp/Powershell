<#
.SYNOPSIS
    Executa manualmente o booster de enrollment e sincronismo do Intune (v4.2).

.DESCRIPTION
    Este script verifica o status do AzureAdPrt e força o gatilho de enrollment 
    e sincronização de políticas. Ideal para troubleshooting presencial ou remoto.

.EXAMPLE
    PS C:\> .\Invoke-GBEnrollmentBooster.ps1
#>
[CmdletBinding()]
param()

process {
    Write-Host "--- GB Enrollment Booster (Manual Mode) ---" -ForegroundColor Cyan
    
    try {
        # 1. Diagnóstico de Identidade (dsregcmd)
        Write-Verbose "Checando status do dispositivo e PRT..."
        $dsreg = dsregcmd /status
        
        $isJoined = $dsreg | Select-String "AzureAdJoined : YES"
        $hasPrt   = $dsreg | Select-String "AzureAdPrt : YES"

        if ($isJoined) {
            Write-Host "[OK] Dispositivo está AzureAdJoined." -ForegroundColor Green
        } else {
            Write-Warning "[ALERTA] Dispositivo NÃO está AzureAdJoined. O enrollment pode falhar."
        }

        if (-not $hasPrt) {
            Write-Host "[!] AzureAdPrt não detectado. Iniciando DeviceEnroller..." -ForegroundColor Yellow
            # Dispara a UI de autenticação (Cloud Kerberos / Modern Auth)
            Start-Process "C:\Windows\system32\DeviceEnroller.exe" -ArgumentList "/c /u /s" -Wait
            Write-Host "[+] Fluxo de autenticação disparado." -ForegroundColor Green
        } else {
            Write-Host "[OK] AzureAdPrt (Token de Identidade) está ativo." -ForegroundColor Green
        }

        # 2. Gatilhos de Sincronismo (Intune/MDM)
        Write-Host "--- Iniciando Sincronismo de Políticas ---" -ForegroundColor Cyan
        
        $MdmTasks = Get-ScheduledTask -TaskPath "\Microsoft\Windows\EnterpriseMgmt\*" -ErrorAction SilentlyContinue
        
        if ($null -eq $MdmTasks) {
            Write-Error "Nenhuma tarefa de EnterpriseMgmt encontrada. O dispositivo pode não estar matriculado no MDM."
        } else {
            foreach ($Task in $MdmTasks) {
                Write-Host "  > Disparando: $($Task.TaskName)" -ForegroundColor Gray
                $Task | Start-ScheduledTask -ErrorAction SilentlyContinue
            }
        }

        # Gatilho de Check-in Adicional
        Write-Host "  > Disparando: PushLaunch" -ForegroundColor Gray
        Start-ScheduledTask -TaskName "PushLaunch" -ErrorAction SilentlyContinue

        # 3. Log de Sucesso Local
        Write-Host "--- Processo Concluído com Sucesso ---" -ForegroundColor Cyan
        Write-EventLog -LogName Application -Source "Application" -EventID 9020 -EntryType Information `
            -Message "PowerForge: Enrollment Booster executado manualmente com sucesso."

    }
    catch {
        Write-Error "Falha crítica durante a execução: $($_.Exception.Message)"
        exit 1
    }
}
