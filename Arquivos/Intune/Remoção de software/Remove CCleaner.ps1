<#
.SYNOPSIS
    GB Identity Booster V6 - Inteligência Pós-MFA.
.DESCRIPTION
    Monitora o PRT em tempo real e dispara a finalização do Join/Sync 
    imediatamente após a validação do usuário.
#>
[CmdletBinding()]
param()

process {
    try {
        Write-Host "--- Implantando GB Identity Booster V6 (Inteligente) ---" -ForegroundColor Cyan

        $BaseFolder = "C:\ProgramData\GB"
        $ScriptPath = "$BaseFolder\IntuneJoin.ps1"
        $ConfigPath = "$BaseFolder\Booster.xml"
        $PublicDesktop = "$env:PUBLIC\Desktop"
        $ShortcutName  = "Finalizar Configuracao GB.lnk"

        if (!(Test-Path $BaseFolder)) { New-Item $BaseFolder -ItemType Directory -Force | Out-Null }

        # --- CÉREBRO DO BOOSTER V6 ---
        $LogicContent = @"
# Lógica de Monitoramento GB
`$ConfigPath = "$ConfigPath"
`$Shortcut   = "$PublicDesktop\$ShortcutName"

# 1. Incrementa Contador
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

# 2. Inicia a Ponte MFA (Mini-Navegador)
Start-Process "msedge.exe" -ArgumentList "--app=https://myaccount.microsoft.com", "--window-size=500,700"

# 3. Loop de Vigilância (Espera o MFA virar PRT)
`$timeout = 300 # 5 minutos de tolerância
`$timer = [System.Diagnostics.Stopwatch]::StartNew()
`$prtReady = `$false

while (`$timer.Elapsed.TotalSeconds -lt `$timeout) {
    `$status = dsregcmd /status
    if (`$status | Select-String "AzureAdPrt : YES") {
        `$prtReady = `$true
        break
    }
    Start-Sleep -Seconds 5
}

# 4. FINALIZAÇÃO DO JOIN (Apenas se o PRT estiver OK)
if (`$prtReady) {
    # Comando de Registro (O 'empurrão' que faltava)
    Start-Process "C:\Windows\system32\deviceenroller.exe" -ArgumentList "/c /u /d" -WindowStyle Hidden
    
    # Aguarda o registro processar e força o Sync de Apps
    Start-Sleep -Seconds 10
    Start-Process "C:\Windows\system32\deviceenroller.exe" -ArgumentList "/mobilepolicysync" -WindowStyle Hidden

    # Feedback de Sucesso (Excelência GB)
    `$ws = New-Object -ComObject WScript.Shell
    `$ws.Popup("Configuração concluída com sucesso! Seus aplicativos começarão a aparecer em breve.", 10, "Grupo Boticário", 64) | Out-Null
}

# 5. Limpeza Automática
if (`$count -ge 3 -and !`$args.Contains("-ManualClick")) {
    Unregister-ScheduledTask -TaskName "GB_Identity_Booster" -Confirm:`$false -ErrorAction SilentlyContinue
    if (Test-Path `$Shortcut) { Remove-Item `$Shortcut -Force }
}
"@
        $LogicContent | Out-File -FilePath $ScriptPath -Encoding utf8 -Force

        # Registro da Tarefa e Atalho (Mantendo a compatibilidade 24H2)
        $Action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$ScriptPath`""
        $Trigger = New-ScheduledTaskTrigger -AtLogon
        $Principal = New-ScheduledTaskPrincipal -GroupId "S-1-5-32-545"
        Register-ScheduledTask -TaskName "GB_Identity_Booster" -Action $Action -Trigger $Trigger -Principal $Principal -Force | Out-Null

        $WshShell = New-Object -ComObject WScript.Shell
        $Shortcut = $WshShell.CreateShortcut(Join-Path $PublicDesktop $ShortcutName)
        $Shortcut.TargetPath = "powershell.exe"
        $Shortcut.Arguments = "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$ScriptPath`" -ManualClick"
        $Shortcut.IconLocation = "shell32.dll,238"
        $Shortcut.Save()

        Write-Host "[OK] Booster V6 Inteligente implantado com sucesso." -ForegroundColor Green
    }
    catch {
        Write-Error "Erro no Setup: $($_.Exception.Message)"
    }
}
