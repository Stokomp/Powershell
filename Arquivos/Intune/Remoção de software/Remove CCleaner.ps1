<#
.SYNOPSIS
    GB Deployment Script V2 - Identity Booster Manual Setup.
.DESCRIPTION
    Correção de caminhos e mapeamento de pastas especiais para Windows 11.
#>
[CmdletBinding()]
param()

process {
    try {
        Write-Host "--- Iniciando Setup de Identidade GB (Versão Corrigida) ---" -ForegroundColor Cyan

        # 1. Definição de Caminhos Robustos
        $Folder = "C:\ProgramData\GB"
        $ScriptPath = "$Folder\IntuneJoin.ps1"
        $ConfigPath = "$Folder\Booster.xml"
        $ShortcutName = "Finalizar Configuracao GB.lnk"
        
        # Forma segura de pegar o Desktop Público sem depender de Enums sensíveis
        $PublicDesktop = Join-Path $env:PUBLIC "Desktop"

        # 2. Criação da Estrutura de Pastas
        if (!(Test-Path $Folder)) { 
            New-Item -Path $Folder -ItemType Directory -Force | Out-Null
        }

        # 3. Criação do Script de Lógica (Cérebro do Booster)
        # Usaremos aspas simples no Here-String para evitar expansão precoce de variáveis
        $LogicContent = @'
[CmdletBinding()]
param([switch]$ManualClick)

$Folder = "C:\ProgramData\GB"
$ConfigPath = "$Folder\Booster.xml"
$LogPath = "$Folder\Booster.log"
$PublicDesktop = Join-Path $env:PUBLIC "Desktop"
$ShortcutName = "Finalizar Configuracao GB.lnk"

# Gerenciamento do Contador
if (Test-Path $ConfigPath) {
    [xml]$xml = Get-Content $ConfigPath
    $count = [int]$xml.Settings.ExecutionCount
} else {
    $count = 0
    $xml = [xml]"<Settings><ExecutionCount>0</ExecutionCount></Settings>"
}

$count++
$xml.Settings.ExecutionCount = [string]$count
$xml.Save($ConfigPath)
"$(Get-Date): Execucao n $count" | Out-File $LogPath -Append

# --- EXECUÇÃO TÉCNICA ---
# Força a janela de reparo do Windows (WAM/MFA)
Start-Process "ms-settings:workplace-repairtoken"
# Força o sincronismo silencioso
Start-Process "C:\Windows\system32\deviceenroller.exe" -ArgumentList "/mobilepolicysync" -WindowStyle Hidden

# --- LIMPEZA APÓS 3 LOGINS ---
if ($count -ge 3 -and -not $ManualClick) {
    # Remove a tarefa sem pedir confirmação
    Unregister-ScheduledTask -TaskName "GB_Identity_Booster" -Confirm:$false -ErrorAction SilentlyContinue
    # Remove o atalho
    $FullShortcutPath = Join-Path $PublicDesktop $ShortcutName
    if (Test-Path $FullShortcutPath) { Remove-Item $FullShortcutPath -Force }
}
'@
        $LogicContent | Out-File -FilePath $ScriptPath -Encoding utf8 -Force
        Write-Host "[OK] Script de logica implantado em $ScriptPath" -ForegroundColor Green

        # 4. Criação da Tarefa Agendada
        $Action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -WindowStyle Hidden -File `"$ScriptPath`""
        $Trigger = New-ScheduledTaskTrigger -AtLogon
        
        # Registra para rodar no contexto do usuário que logar (Users)
        $Principal = New-ScheduledTaskPrincipal -GroupId "S-1-5-32-545" -Id "Author" # S-1-5-32-545 é o SID fixo para 'Usuários'

        Register-ScheduledTask -TaskName "GB_Identity_Booster" -Action $Action -Trigger $Trigger -Principal $Principal -Force | Out-Null
        Write-Host "[OK] Tarefa Agendada registrada." -ForegroundColor Green

        # 5. Criação do Atalho
        $WshShell = New-Object -ComObject WScript.Shell
        $Shortcut = $WshShell.CreateShortcut(Join-Path $PublicDesktop $ShortcutName)
        $Shortcut.TargetPath = "powershell.exe"
        $Shortcut.Arguments = "-ExecutionPolicy Bypass -WindowStyle Hidden -File `"$ScriptPath`" -ManualClick"
        $Shortcut.IconLocation = "shell32.dll,238"
        $Shortcut.Description = "Sincronizar Identidade Corporativa GB"
        $Shortcut.Save()
        Write-Host "[OK] Atalho criado no Desktop Publico: $PublicDesktop" -ForegroundColor Green

        Write-Host "--- SETUP CONCLUIDO ---" -ForegroundColor Cyan
    }
    catch {
        Write-Error "Falha ao configurar a estrutura: $($_.Exception.Message)"
    }
}
