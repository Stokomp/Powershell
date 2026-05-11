<#
.SYNOPSIS
    GB Identity Booster V5 - WAM Bridge (Edge App Mode).
.DESCRIPTION
    Desenvolvido para Windows 11 24H2+. Força MFA via Broker nativo (Edge),
    injetando o PRT e sincronizando o Intune. Limpeza automática após 3 usos.
#>
[CmdletBinding()]
param()

process {
    try {
        Write-Host "--- Iniciando Setup GB Identity Booster V5 ---" -ForegroundColor Cyan

        # 1. Caminhos Literais (Blindagem 24H2)
        $BaseFolder = "C:\ProgramData\GB"
        $ScriptPath = "$BaseFolder\IntuneJoin.ps1"
        $ConfigPath = "$BaseFolder\Booster.xml"
        $PublicDesktop = "$env:PUBLIC\Desktop"
        $ShortcutPath  = "$PublicDesktop\Finalizar Configuracao GB.lnk"

        if (!(Test-Path $BaseFolder)) { New-Item $BaseFolder -ItemType Directory -Force | Out-Null }

        # 2. O Script de Lógica (Cérebro do Booster)
        $LogicContent = @"
# GB Identity Booster - WAM Bridge Logic
`$ConfigPath = "$ConfigPath"
`$Shortcut   = "$ShortcutPath"

try {
    # Contador de Execuções
    if (Test-Path `$ConfigPath) {
        [xml]`$xml = Get-Content `$ConfigPath
        `$count = [int]`$xml.Settings.ExecutionCount
    } else {
        `$count = 0
        `$xml = [xml]"<Settings><ExecutionCount>0</ExecutionCount></Settings>"
    }

    `$count++
    `$xml.Settings.ExecutionCount = [string]`$count
    `$xml.Save(`$ConfigPath)

    # --- AÇÃO: PONTE WAM (SIMULAÇÃO VPN F5) ---
    # Abrimos o portal de conta no modo App (Mini-Navegador) para forçar o MFA
    Start-Process "msedge.exe" -ArgumentList "--app=https://myaccount.microsoft.com", "--window-size=500,700"
    
    # Popup de Orientação (Bom Tom GB)
    `$wshell = New-Object -ComObject WScript.Shell
    `$wshell.Popup("Grupo Boticário: Por favor, valide sua identidade na janela segura para liberar seus aplicativos.", 15, "Segurança e Identidade", 64) | Out-Null

    # Aguarda o login e injeta o sincronismo
    Start-Sleep -Seconds 45
    Start-Process "C:\Windows\system32\deviceenroller.exe" -ArgumentList "/mobilepolicysync" -WindowStyle Hidden

    # --- LIMPEZA AUTOMÁTICA ---
    if (`$count -ge 3 -and !`$args.Contains("-ManualClick")) {
        Unregister-ScheduledTask -TaskName "GB_Identity_Booster" -Confirm:`$false -ErrorAction SilentlyContinue
        if (Test-Path `$Shortcut) { Remove-Item `$Shortcut -Force }
    }
} catch {}
"@
        $LogicContent | Out-File -FilePath $ScriptPath -Encoding utf8 -Force

        # 3. Tarefa Agendada (SID S-1-5-32-545 = Usuários)
        $Action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$ScriptPath`""
        $Trigger = New-ScheduledTaskTrigger -AtLogon
        $Principal = New-ScheduledTaskPrincipal -GroupId "S-1-5-32-545"
        $Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries

        Register-ScheduledTask -TaskName "GB_Identity_Booster" -Action $Action -Trigger $Trigger -Principal $Principal -Settings $Settings -Force | Out-Null

        # 4. Atalho (Chave Dourada)
        $WshShell = New-Object -ComObject WScript.Shell
        $Shortcut = $WshShell.CreateShortcut($ShortcutPath)
        $Shortcut.TargetPath = "powershell.exe"
        $Shortcut.Arguments = "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$ScriptPath`" -ManualClick"
        $Shortcut.IconLocation = "shell32.dll,238"
        $Shortcut.Description = "Sincronizar Identidade Corporativa GB"
        $Shortcut.Save()

        Write-Host "[OK] Estrutura V5 (24H2 Ready) implantada com sucesso." -ForegroundColor Green
    }
    catch {
        Write-Error "Falha no setup: $($_.Exception.Message)"
    }
}
