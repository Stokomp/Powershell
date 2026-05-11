<#
.SYNOPSIS
    GB Deployment Script - Identity Booster Manual Setup.
.DESCRIPTION
    Este script prepara o ambiente local, criando a estrutura de arquivos, 
    atalho e a tarefa agendada autolimpante.
#>
[CmdletBinding()]
param()

process {
    try {
        Write-Host "--- Iniciando Setup de Identidade GB ---" -ForegroundColor Cyan

        # 1. Definição de Caminhos e Variáveis
        $Folder = "C:\ProgramData\GB"
        $ScriptPath = "$Folder\IntuneJoin.ps1"
        $ConfigPath = "$Folder\Booster.xml"
        $ShortcutName = "Finalizar Configuração GB.lnk"
        $PublicDesktop = [Environment]::GetFolderPath("PublicDesktop")

        # 2. Criação da Estrutura de Pastas
        if (!(Test-Path $Folder)) { 
            New-Item -Path $Folder -ItemType Directory -Force | Out-Null
            Write-Host "[OK] Pasta de sistema criada em $Folder" -ForegroundColor Green
        }

        # 3. Criação do Script de Lógica (O "Cérebro" do Booster)
        $LogicContent = @"
[CmdletBinding()]
param([switch]`ManualClick)

`$ConfigPath = "$ConfigPath"
`$LogPath = "$Folder\Booster.log"

# Gerenciamento do Contador
if (Test-Path `$ConfigPath) {
    [xml]`$xml = Get-Content `$ConfigPath
    `$count = [int]`$xml.Settings.ExecutionCount
} else {
    `$count = 0
    "<Settings><ExecutionCount>0</ExecutionCount></Settings>" | Out-File `$ConfigPath
}

`$count++
`$xml.Settings.ExecutionCount = [string]`$count
`$xml.Save(`$ConfigPath)
Get-Date | Out-File `$LogPath -Append

# --- EXECUÇÃO TÉCNICA ---
# Força a janela de reparo do Windows (WAM/MFA)
Start-Process "ms-settings:workplace-repairtoken"
# Força o sincronismo de políticas silencioso
Start-Process "C:\Windows\system32\deviceenroller.exe" -ArgumentList "/mobilepolicysync" -WindowStyle Hidden

# --- LIMPEZA APÓS 3 LOGINS ---
if (`$count -ge 3 -and -not `$ManualClick) {
    Unregister-ScheduledTask -TaskName "GB_Identity_Booster" -Confirm:`$false
    if (Test-Path "$PublicDesktop\$ShortcutName") { Remove-Item "$PublicDesktop\$ShortcutName" -Force }
}
"@
        $LogicContent | Out-File -FilePath $ScriptPath -Encoding utf8 -Force
        Write-Host "[OK] Script de lógica implantado." -ForegroundColor Green

        # 4. Criação da Tarefa Agendada (Contexto de Usuário)
        $Action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -WindowStyle Hidden -File $ScriptPath"
        $Trigger = New-ScheduledTaskTrigger -AtLogon
        $Principal = New-ScheduledTaskPrincipal -GroupId "Users" -Id "Author" # Roda para quem logar

        Register-ScheduledTask -TaskName "GB_Identity_Booster" -Action $Action -Trigger $Trigger -Principal $Principal -Force | Out-Null
        Write-Host "[OK] Tarefa Agendada registrada (Trigger: Logon)." -ForegroundColor Green

        # 5. Criação do Atalho na Área de Trabalho Pública
        $WshShell = New-Object -ComObject WScript.Shell
        $Shortcut = $WshShell.CreateShortcut("$PublicDesktop\$ShortcutName")
        $Shortcut.TargetPath = "powershell.exe"
        $Shortcut.Arguments = "-ExecutionPolicy Bypass -WindowStyle Hidden -File $ScriptPath -ManualClick"
        $Shortcut.IconLocation = "shell32.dll,238" # Ícone de chave
        $Shortcut.Description = "Sincronizar Identidade Corporativa GB"
        $Shortcut.Save()
        Write-Host "[OK] Atalho criado na Área de Trabalho Pública." -ForegroundColor Green

        Write-Host "--- SETUP CONCLUÍDO COM EXCELÊNCIA ---" -ForegroundColor Cyan
    }
    catch {
        Write-Error "Falha ao configurar a estrutura: $($_.Exception.Message)"
    }
}
