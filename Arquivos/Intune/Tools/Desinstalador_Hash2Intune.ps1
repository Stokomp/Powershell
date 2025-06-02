param(
    [Switch]$Quiet # Parâmetro para execução silenciosa
)

# Verifica se está sendo executado como administrador
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    if (-not $Quiet) {
        Write-Error "Este script precisa ser executado como administrador."
        Write-Host "Por favor, clique com o botão direito no script e selecione 'Executar como administrador'."
        if ($Host.UI.RawUI.ReadKey) {} 
    }
    Exit 1
}

try {
    $AppName = "Hash2Intune"
    $CompanyName = "UEM"
    
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
        if (-not $Quiet) { Write-Error "ERRO FATAL: Não foi possível determinar o diretório Program Files apropriado." }
        Exit 1
    }

    $InstallBasePath = Join-Path $InstallBaseParentDir $CompanyName
    $InstallDir = Join-Path $InstallBasePath $AppName

    # Atalho para todos os usuários
    $ProgramsPath = Join-Path $env:ProgramData "Microsoft\Windows\Start Menu\Programs\$CompanyName"
    $ShortcutName = "$AppName.lnk"
    $ShortcutFilePath = Join-Path $ProgramsPath $ShortcutName

    # Chave de registro da aplicação (para informações adicionais, se criada)
    $RegistryAppPath = "HKLM:\Software\$CompanyName\$AppName"
    # Chave de desinstalação em "Programas e Recursos"
    $UninstallRegistryKeyPath = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\$AppName"


    if (-not $Quiet) { Write-Host "Iniciando desinstalação do $AppName..." }

    # 1. Remove a chave de registro de "Programas e Recursos"
    if (Test-Path $UninstallRegistryKeyPath) {
        Remove-Item -Path $UninstallRegistryKeyPath -Recurse -Force -ErrorAction SilentlyContinue
        if (-not $Quiet) { Write-Host "Chave de registro de desinstalação removida: $UninstallRegistryKeyPath" }
    } else {
        if (-not $Quiet) { Write-Host "Chave de registro de desinstalação não encontrada: $UninstallRegistryKeyPath" }
    }
    
    # 2. Remove a chave de registro adicional da aplicação (se existir)
    if (Test-Path $RegistryAppPath) {
        Remove-Item -Path $RegistryAppPath -Recurse -Force -ErrorAction SilentlyContinue
        if (-not $Quiet) { Write-Host "Chave de registro da aplicação removida: $RegistryAppPath" }
    } else {
        if (-not $Quiet) { Write-Host "Chave de registro da aplicação não encontrada: $RegistryAppPath" }
    }

    # 3. Remove o atalho
    if (Test-Path $ShortcutFilePath) {
        Remove-Item -Path $ShortcutFilePath -Force -ErrorAction SilentlyContinue
        if (-not $Quiet) { Write-Host "Atalho removido: $ShortcutFilePath" }
    } else {
        if (-not $Quiet) { Write-Host "Atalho não encontrado: $ShortcutFilePath" }
    }
    # Tenta remover a pasta da empresa no Menu Iniciar se estiver vazia
    if (Test-Path $ProgramsPath) {
        if ((Get-ChildItem -Path $ProgramsPath -Force -ErrorAction SilentlyContinue).Count -eq 0) {
            Remove-Item -Path $ProgramsPath -Recurse -Force -ErrorAction SilentlyContinue
            if (-not $Quiet) { Write-Host "Pasta de atalhos da empresa '$CompanyName' removida do Menu Iniciar." }
        }
    }

    # 4. Remove o diretório de instalação
    if (Test-Path $InstallDir) {
        Remove-Item -Path $InstallDir -Recurse -Force -ErrorAction SilentlyContinue
        if (-not $Quiet) { Write-Host "Diretório de instalação removido: $InstallDir" }
    } else {
        if (-not $Quiet) { Write-Host "Diretório de instalação não encontrado: $InstallDir" }
    }

    # 5. Remove o diretório base da empresa se estiver vazio
    if (Test-Path $InstallBasePath) {
        if ((Get-ChildItem -Path $InstallBasePath -Force -ErrorAction SilentlyContinue).Count -eq 0) {
            Remove-Item -Path $InstallBasePath -Recurse -Force -ErrorAction SilentlyContinue
            if (-not $Quiet) { Write-Host "Diretório base da empresa removido: $InstallBasePath" }
        } else {
            if (-not $Quiet) { Write-Host "Diretório base da empresa '$CompanyName' não está vazio (outras aplicações podem existir)." }
        }
    }

    if (-not $Quiet) { Write-Host "$AppName desinstalado com sucesso!" }
    Exit 0
} catch {
    if (-not $Quiet) { 
        Write-Error "ERRO DURANTE A DESINSTALAÇÃO: $($_.Exception.Message)"
        Write-Error "Detalhes: $($_.ScriptStackTrace)"
        if ($Host.UI.RawUI.ReadKey) {}
    }
    Exit 1
}
