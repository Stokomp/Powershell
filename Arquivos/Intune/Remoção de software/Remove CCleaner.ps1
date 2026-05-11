<#
.SYNOPSIS
    GB Enrollment Booster V5.0 - O Guardião da Identidade.
    Foco: Superar a latência do HAADJ e forçar PRT/Windows Hello.
.DESCRIPTION
    Monitora o dsregcmd até que o registro Hybrid apareça e força a interação do usuário.
#>
[CmdletBinding()]
param()

# --- CONFIGURAÇÕES DE IDENTIDADE VISUAL GB ---
$GB_Blue = "#011E38"
$GB_OffWhite = "#F5F1EB"

function Show-GBNotification {
    param([string]$Message)
    # Aqui poderíamos disparar um Toast via BurntToast ou um simples popup estilizado
    # Para máxima compatibilidade sem módulos extras, usaremos o shell de sistema
    $wshell = New-Object -ComObject WScript.Shell
    $wshell.Popup($Message, 10, "Grupo Boticário - Finalizando Configuração", 64)
}

process {
    try {
        Write-Host "[1/4] Ativando Notificações de Sistema..." -ForegroundColor Cyan
        $RegPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Notifications\Settings"
        if (!(Test-Path $RegPath)) { New-Item -Path $RegPath -Force | Out-Null }
        Set-ItemProperty -Path $RegPath -Name "NOC_GLOBAL_SETTING_TOASTS_ENABLED" -Value 1 -Force

        Write-Host "[2/4] Iniciando Monitoramento de Identidade (Loop de 5 min)..." -ForegroundColor Cyan
        $ready = $false
        $timer = [System.Diagnostics.Stopwatch]::StartNew()

        while ($timer.Elapsed.TotalMinutes -lt 5 -and !$ready) {
            $dsreg = dsregcmd /status
            $isHybrid = $dsreg | Select-String "AzureAdJoined : YES"
            $hasPrt = $dsreg | Select-String "AzureAdPrt : YES"

            if ($isHybrid -and !$hasPrt) {
                Write-Host "[!] Dispositivo detectado no Entra ID, mas PRT ausente. Forçando Login..." -ForegroundColor Yellow
                
                # Interface GB para o usuário
                Show-GBNotification -Message "Olá! Estamos finalizando a configuração do seu ambiente para Épocas Especiais. Uma janela de login poderá aparecer, por favor, autentique-se."

                # O segredo: Invocação da URI que força o Broker de Autenticação (WAM)
                # Esta URI é mais eficaz que o DeviceEnroller para "acordar" o PRT
                Start-Process "ms-settings:workplace-repairtoken"
                
                # Aguarda o usuário interagir e tenta o sync de apps
                Start-Sleep -Seconds 30
                & "C:\Windows\system32\deviceenroller.exe" /mobilepolicysync
                $ready = $true
            }
            elseif ($isHybrid -and $hasPrt) {
                Write-Host "[OK] Identidade íntegra. Sincronizando políticas..." -ForegroundColor Green
                & "C:\Windows\system32\deviceenroller.exe" /mobilepolicysync
                $ready = $true
            }
            else {
                Write-Host "...Aguardando sincronismo do AD Connect (60s)..."
                Start-Sleep -Seconds 60
            }
        }

        if (!$ready) {
            Write-Host "[!] Tempo limite atingido. O dispositivo ainda não foi sincronizado pelo AD Connect." -ForegroundColor Red
        }

    }
    catch {
        Write-Error "Erro no processo Guardião: $($_.Exception.Message)"
    }
}
