param()

# Verifica se está sendo executado como administrador
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Error "Este script precisa ser executado como administrador."
    Write-Host "Por favor, clique com o botão direito no script e selecione 'Executar como administrador'."
    if ($Host.UI.RawUI.ReadKey) {} # Pausa para o usuário ler a mensagem se executado diretamente
    Exit 1
}

try {
    $AppName = "Hash2Intune"
    $AppVersion = "1.0" # Defina a versão da sua aplicação
    $CompanyName = "UEM"
    $MainAppScriptName = "Hash2Intune.ps1" # Nome do arquivo .ps1 da sua aplicação GUI
    $IconName = "favicon.ico" 
    $ShortcutName = "$AppName.lnk" # Nome do atalho

    # Determina o caminho base para Program Files (x86) em sistemas 64-bit, ou Program Files em 32-bit
    if ([Environment]::Is64BitOperatingSystem) {
        $InstallBaseParentDir = [Environment]::GetFolderPath([System.Environment+SpecialFolder]::ProgramFilesX86)
        if (-not $InstallBaseParentDir) { # Fallback raro
            $InstallBaseParentDir = [Environment]::GetFolderPath([System.Environment+SpecialFolder]::ProgramFiles)
        }
    } else {
        $InstallBaseParentDir = [Environment]::GetFolderPath([System.Environment+SpecialFolder]::ProgramFiles)
    }

    if ([string]::IsNullOrWhiteSpace($InstallBaseParentDir)) {
        Write-Error "ERRO FATAL: Não foi possível determinar o diretório Program Files apropriado."
        if ($Host.UI.RawUI.ReadKey) {}
        Exit 1
    }

    $InstallBasePath = Join-Path $InstallBaseParentDir $CompanyName
    $InstallDir = Join-Path $InstallBasePath $AppName

    $SourceDir = $PSScriptRoot # Diretório onde o Instalador.ps1 está localizado

    # Atalho para todos os usuários
    $ProgramsPath = Join-Path $env:ProgramData "Microsoft\Windows\Start Menu\Programs\$CompanyName"
    $ShortcutFilePath = Join-Path $ProgramsPath $ShortcutName

    # Chave de registro para desinstalação e detecção (HKLM)
    $RegistryAppPath = "HKLM:\Software\$CompanyName\$AppName" # Chave para informações da aplicação
    # Chave específica para "Programas e Recursos"
    $UninstallRegistryKeyPath = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\$AppName"


    Write-Host "Iniciando instalação do $AppName v$AppVersion..."
    Write-Host "Diretório de origem dos arquivos da aplicação: $SourceDir"
    Write-Host "Diretório de instalação: $InstallDir"

    # 1. Criar diretórios de instalação
    if (-not (Test-Path -Path $InstallBasePath)) {
        New-Item -Path $InstallBasePath -ItemType Directory -Force -ErrorAction Stop | Out-Null
        Write-Host "Pasta da empresa '$InstallBasePath' criada com sucesso."
    }
    if (-not (Test-Path -Path $InstallDir)) {
        New-Item -Path $InstallDir -ItemType Directory -Force -ErrorAction Stop | Out-Null
        Write-Host "Pasta da aplicação '$InstallDir' criada com sucesso."
    } else {
        Write-Host "Pasta da aplicação '$InstallDir' já existe."
    }

    # 2. Copiar arquivos da aplicação (script principal, ícone e desinstalador)
    $MainAppScriptSourcePath = Join-Path $SourceDir $MainAppScriptName
    $IconSourcePath = Join-Path $SourceDir $IconName
    $DesinstaladorNomeBaseNoSource = "Desinstalador.ps1" # Nome do script desinstalador na pasta de origem
    $DesinstaladorSourcePath = Join-Path $SourceDir $DesinstaladorNomeBaseNoSource
    $DesinstaladorNomeApp = "Desinstalador_$AppName.ps1" # Nome do desinstalador como será salvo na pasta da app
    $DesinstaladorAppPath = Join-Path $InstallDir $DesinstaladorNomeApp

    if (-not (Test-Path $MainAppScriptSourcePath -PathType Leaf)) {
        Write-Error "ERRO: Script principal '$MainAppScriptSourcePath' não encontrado."
        if ($Host.UI.RawUI.ReadKey) {}; Exit 1
    }
    Copy-Item -Path $MainAppScriptSourcePath -Destination $InstallDir -Force -ErrorAction Stop
    Write-Host "Script principal '$MainAppScriptName' copiado para '$InstallDir'."

    $InstalledIconPathForShortcut = Join-Path $InstallDir $IconName
    if (Test-Path $IconSourcePath -PathType Leaf) {
        Copy-Item -Path $IconSourcePath -Destination $InstallDir -Force -ErrorAction Stop
        Write-Host "Ícone '$IconName' copiado para '$InstallDir'."
    } else {
        Write-Warning "Ícone '$IconSourcePath' não encontrado. O atalho usará um ícone padrão."
        $InstalledIconPathForShortcut = "powershell.exe,0" 
    }

    if (Test-Path $DesinstaladorSourcePath -PathType Leaf) {
        Copy-Item -Path $DesinstaladorSourcePath -Destination $DesinstaladorAppPath -Force -ErrorAction Stop
        Write-Host "Script desinstalador copiado para '$DesinstaladorAppPath'."
    } else {
        Write-Warning "AVISO: Script desinstalador '$DesinstaladorSourcePath' não encontrado na pasta de origem."
    }

    # 3. Criar atalho no Menu Iniciar
    if (-not (Test-Path -Path $ProgramsPath)) {
        New-Item -Path $ProgramsPath -ItemType Directory -Force -ErrorAction Stop | Out-Null
        Write-Host "Pasta de atalhos '$ProgramsPath' criada."
    }
    
    $InstalledAppScriptFullPath = Join-Path $InstallDir $MainAppScriptName
    try {
        $WshShell = New-Object -ComObject WScript.Shell
        $Shortcut = $WshShell.CreateShortcut($ShortcutFilePath)
        $Shortcut.TargetPath = "powershell.exe"
        $Shortcut.Arguments = "-WindowStyle Hidden -NoProfile -ExecutionPolicy Bypass -File `"$InstalledAppScriptFullPath`""
        $Shortcut.IconLocation = $InstalledIconPathForShortcut
        $Shortcut.Description = "Abre a aplicação $AppName"
        $Shortcut.WorkingDirectory = $InstallDir 
        $Shortcut.Save()
        Write-Host "Atalho criado em: $ShortcutFilePath"
    } catch {
        Write-Warning "Falha ao criar atalho: $($_.Exception.Message)"
    }

    # 4. Criar chaves de registro para "Programas e Recursos"
    if (-not (Test-Path $UninstallRegistryKeyPath)) {
        New-Item -Path $UninstallRegistryKeyPath -Force -ErrorAction Stop | Out-Null
        Write-Host "Chave de registro para desinstalação criada: $UninstallRegistryKeyPath"
    }

    Set-ItemProperty -Path $UninstallRegistryKeyPath -Name "DisplayName" -Value $AppName -Type String -Force
    Set-ItemProperty -Path $UninstallRegistryKeyPath -Name "DisplayVersion" -Value $AppVersion -Type String -Force
    Set-ItemProperty -Path $UninstallRegistryKeyPath -Name "InstallLocation" -Value $InstallDir -Type String -Force
    Set-ItemProperty -Path $UninstallRegistryKeyPath -Name "Publisher" -Value $CompanyName -Type String -Force
    $UninstallString = "powershell.exe -ExecutionPolicy Bypass -File `"$DesinstaladorAppPath`""
    Set-ItemProperty -Path $UninstallRegistryKeyPath -Name "UninstallString" -Value $UninstallString -Type String -Force
    Set-ItemProperty -Path $UninstallRegistryKeyPath -Name "QuietUninstallString" -Value "$UninstallString -Quiet" -Type String -Force 
    Set-ItemProperty -Path $UninstallRegistryKeyPath -Name "DisplayIcon" -Value $InstalledIconPathForShortcut -Type String -Force
    Set-ItemProperty -Path $UninstallRegistryKeyPath -Name "EstimatedSize" -Value 1024 -Type DWord -Force # Tamanho em KB (aprox.)
    Set-ItemProperty -Path $UninstallRegistryKeyPath -Name "NoModify" -Value 1 -Type DWord -Force
    Set-ItemProperty -Path $UninstallRegistryKeyPath -Name "NoRepair" -Value 1 -Type DWord -Force
    
    # Opcional: Chave de registro adicional para informações da aplicação (se necessário para outros fins)
    if (-not (Test-Path $RegistryAppPath)) {
        New-Item -Path $RegistryAppPath -Force -ErrorAction SilentlyContinue | Out-Null
    }
    Set-ItemProperty -Path $RegistryAppPath -Name "Version" -Value $AppVersion -Type String -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $RegistryAppPath -Name "InstallPath" -Value $InstallDir -Type String -Force -ErrorAction SilentlyContinue


    Write-Host "$AppName v$AppVersion instalado com sucesso!"
    Write-Host "Você pode encontrá-lo no Menu Iniciar em '$CompanyName'."
    Exit 0
} catch {
    Write-Error "ERRO DURANTE A INSTALAÇÃO: $($_.Exception.Message)"
    Write-Error "Detalhes: $($_.ScriptStackTrace)"
    if ($Host.UI.RawUI.ReadKey) {}
    Exit 1
}
