<#
.SYNOPSIS
    GB Deployment Script V4 - Otimizado para Windows 11 24H2+.
.DESCRIPTION
    Arquitetura de diretórios via variáveis nativas, chamadas NoProfile 
    e blindagem contra restrições de Smart App Control.
#>
[CmdletBinding()]
param()

process {
    try {
        Write-Host "--- Iniciando Setup de Identidade GB (V4 - 24H2 Ready) ---" -ForegroundColor Cyan

        # 1. Definição de Caminhos à Prova de Falhas
        $BaseFolder = "C:\ProgramData\GB"
        $ScriptPath = "$BaseFolder\IntuneJoin.ps1"
        $ConfigPath = "$BaseFolder\Booster.xml"
        
        # Variável de ambiente direta (nunca falha no 24H2)
        $PublicDesktop = "$env:PUBLIC\Desktop"
        $ShortcutPath  = "$PublicDesktop\Finalizar Configuracao GB.lnk"

        # 2. Garante a existência da pasta de sistema
        if (!(Test-Path $BaseFolder)) { 
            New-Item -Path $BaseFolder -ItemType Directory -Force | Out-Null
        }

        # 3. Escrita do Script de Lógica (Cérebro do Booster)
        $LogicContent = @"
# Script de Logica GB - Otimizado para 24H2
`$ConfigPath = "$ConfigPath"
`$Shortcut   = "$ShortcutPath"

try {
    # Controle de Execuções
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

    # Ação Principal: Invoca a Janela de Autenticação NATIVA do Windows 11
    Start-Process "ms-settings:workplace-repairtoken"
    
    # Sincronismo Silencioso via Enroller
    Start-Process "C:\Windows\system32\deviceenroller.exe" -ArgumentList "/mobilepolicysync" -WindowStyle Hidden

    # Limpeza Automática no 3º login (apenas se invocado pela tarefa agendada)
    if (`$count -ge 3 -and !`$args.Contains("-ManualClick")) {
        Unregister-ScheduledTask -TaskName "GB_Identity_Booster" -Confirm:`$false -ErrorAction SilentlyContinue
        if (Test-Path `$Shortcut) { Remove-Item `$Shortcut -Force }
    }
} catch {
    # Fail silent mode para não poluir a tela do usuário
}
"@
        # O 24H2 prefere UTF8 com BOM para leitura de scripts sem assinatura
        $LogicContent | Out-File -FilePath $ScriptPath -Encoding utf8 -Force
        Write-Host "[OK] Script de logica criado com sucesso." -ForegroundColor Green

        # 4. Registro da Tarefa Agendada (Contexto Multi-Idioma Seguro)
        # S-1-5-32-545 = Grupo Built-In 'Usuários'
        $Action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$ScriptPath`""
        $Trigger = New-ScheduledTaskTrigger -AtLogon
        $Principal = New-ScheduledTaskPrincipal -GroupId "S-1-5-32-545"
        $Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries

        Register-ScheduledTask -TaskName "GB_Identity_Booster" -Action $Action -Trigger $Trigger -Principal $Principal -Settings $Settings -Force | Out-Null
        Write-Host "[OK] Tarefa Agendada registrada (AtLogon, NoProfile)." -ForegroundColor Green

        # 5. Criação do Atalho via COM Object (Padrão ouro de UI)
        $WshShell = New-Object -ComObject WScript.Shell
        $Shortcut = $WshShell.CreateShortcut($ShortcutPath)
        $Shortcut.TargetPath = "powershell.exe"
        $Shortcut.Arguments = "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$ScriptPath`" -ManualClick"
        $Shortcut.IconLocation = "shell32.dll,238" # Ícone da Chave
        $Shortcut.Description = "Sincronizar Identidade Corporativa GB"
        $Shortcut.Save()
        Write-Host "[OK] Atalho criado no Desktop Publico." -ForegroundColor Green

        Write-Host "--- SETUP 24H2 CONCLUIDO COM EXCELENCIA ---" -ForegroundColor Cyan
    }
    catch {
        Write-Host "ERRO: $($_.Exception.Message)" -ForegroundColor Red
    }
}
