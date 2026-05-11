<#
.SYNOPSIS
    GB Identity Booster V7 - Literal String Architecture.
.DESCRIPTION
    Resolve erros de parsing (caracteres inesperados) usando aspas literais.
    Implementa monitoramento de PRT e finalização de Join para Windows 11 24H2.
#>
[CmdletBinding()]
param()

process {
    try {
        Write-Host "--- Implantando GB Identity Booster V7 (Reestruturado) ---" -ForegroundColor Cyan

        # 1. Definição do Ambiente
        $BaseFolder = "C:\ProgramData\GB"
        $ScriptPath = "$BaseFolder\IntuneJoin.ps1"
        $PublicDesktop = "$env:PUBLIC\Desktop"
        $ShortcutName  = "Finalizar Configuracao GB.lnk"

        if (!(Test-Path $BaseFolder)) { New-Item $BaseFolder -ItemType Directory -Force | Out-Null }

        # =====================================================================
        # 2. CÉREBRO DO BOOSTER (Literal Here-String: Sem expansão acidental)
        # =====================================================================
        $LogicContent = @'
param([switch]$ManualClick)

$Folder = "C:\ProgramData\GB"
$CounterFile = "$Folder\BoosterCount.txt"
$ShortcutPath = "$env:PUBLIC\Desktop\Finalizar Configuracao GB.lnk"

# --- 1. CONTADOR SIMPLIFICADO ---
$count = 0
if (Test-Path $CounterFile) {
    $count = [int](Get-Content $CounterFile -ErrorAction SilentlyContinue)
}
$count++
$count | Out-File $CounterFile -Force

# --- 2. PONTE MFA (SIMULAÇÃO VPN) ---
Start-Process "msedge.exe" -ArgumentList "--app=https://myaccount.microsoft.com", "--window-size=500,700"

# --- 3. LOOP DE VIGILÂNCIA DO PRT ---
$timeout = 300 # 5 minutos
$timer = [System.Diagnostics.Stopwatch]::StartNew()
$prtReady = $false

while ($timer.Elapsed.TotalSeconds -lt $timeout) {
    $status = dsregcmd /status
    if ($status -match "AzureAdPrt : YES") {
        $prtReady = $true
        break
    }
    Start-Sleep -Seconds 5
}

# --- 4. FINALIZAÇÃO DO JOIN E SYNC ---
if ($prtReady) {
    # Comando de Matrícula do Intune
    Start-Process "C:\Windows\system32\deviceenroller.exe" -ArgumentList "/c /u /d" -WindowStyle Hidden
    
    Start-Sleep -Seconds 10
    
    # Comando de Download de Apps
    Start-Process "C:\Windows\system32\deviceenroller.exe" -ArgumentList "/mobilepolicysync" -WindowStyle Hidden

    # Feedback Visual GB
    $ws = New-Object -ComObject WScript.Shell
    $ws.Popup("Configuração concluída com sucesso! Seus aplicativos começarão a aparecer.", 10, "Grupo Boticário", 64) | Out-Null
}

# --- 5. AUTOLIMPEZA ---
if ($count -ge 3 -and !$ManualClick) {
    Unregister-ScheduledTask -TaskName "GB_Identity_Booster" -Confirm:$false -ErrorAction SilentlyContinue
    if (Test-Path $ShortcutPath) { Remove-Item $ShortcutPath -Force }
}
'@
        # Salva o script em UTF-8 com BOM (Padrão ouro do 24H2)
        $LogicContent | Out-File -FilePath $ScriptPath -Encoding utf8 -Force

        # =====================================================================
        # 3. REGISTRO DE TAREFA E ATALHO (Concatenação Segura)
        # =====================================================================
        
        # Concatenação evita o erro do caractere 46 na linha 87
        $TaskArgs = '-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "' + $ScriptPath + '"'
        $ShortcutArgs = '-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "' + $ScriptPath + '" -ManualClick'

        $Action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument $TaskArgs
        $Trigger = New-ScheduledTaskTrigger -AtLogon
        $Principal = New-ScheduledTaskPrincipal -GroupId "S-1-5-32-545" # Grupo Usuários Local
        
        Register-ScheduledTask -TaskName "GB_Identity_Booster" -Action $Action -Trigger $Trigger -Principal $Principal -Force | Out-Null

        $WshShell = New-Object -ComObject WScript.Shell
        $Shortcut = $WshShell.CreateShortcut("$PublicDesktop\$ShortcutName")
        $Shortcut.TargetPath = "powershell.exe"
        $Shortcut.Arguments = $ShortcutArgs
        $Shortcut.IconLocation = "shell32.dll,238"
        $Shortcut.Save()

        Write-Host "[OK] Booster V7 implantado e livre de erros de parsing." -ForegroundColor Green
    }
    catch {
        Write-Error "Erro no Setup: $($_.Exception.Message)"
    }
}
