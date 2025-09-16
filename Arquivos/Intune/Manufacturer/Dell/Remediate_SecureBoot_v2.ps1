# SCRIPT FINAL E CORRIGIDO PARA ATIVAR O SECURE BOOT
#
# FLUXO DE EXECUÇÃO:
# 1. Verifica privilégios de Administrador.
# 2. Faz o download do 'Dell Command | Configure'.
# 3. Instala a ferramenta silenciosamente.
# 4. Usa a ferramenta para agendar a ativação do Secure Boot.
# 5. SUSPENDE O BITLOCKER por 1 reinicialização para evitar a tela de recuperação.
# 6. Desinstala a ferramenta e limpa os arquivos temporários.
#
# --- DEVE SER EXECUTADO COMO ADMINISTRADOR ---

# --- CONFIGURAÇÃO ---
$downloadUrl = "https://dl.dell.com/FOLDER12902766M/1/Dell-Command-Configure-Application_MD8CJ_WIN64_5.2.0.9_A00.EXE"
$destinationPath = Join-Path $env:TEMP "DellTemp"
$installerPath = Join-Path $destinationPath "Dell-Command-Configure.exe"
$cctkPath = "C:\Program Files (x86)\Dell\Command Configure\X86_64\cctk.exe"

# --- INÍCIO DO SCRIPT ---
Clear-Host

# 1. Verificar privilégios de Administrador
if (-Not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "Este script precisa ser executado com privilégios de Administrador."
    if ($Host.UI.RawUI.KeyAvailable -and ("Enter" -eq $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyUp").VirtualKeyCode)) { }
    exit
}

try {
    # 2. Instalar o Dell Command | Configure (se necessário)
    if (Test-Path $cctkPath) {
        Write-Host "O 'Dell Command | Configure' já está instalado. Pulando para a configuração." -ForegroundColor Green
    }
    else {
        Write-Host "Iniciando o processo de download e instalação do 'Dell Command | Configure'..." -ForegroundColor Yellow

        # Criar diretório
        if (!(Test-Path $destinationPath)) {
            New-Item -ItemType Directory -Path $destinationPath -Force
        }

        # Download
        Write-Host "Baixando o instalador da URL fornecida..." -ForegroundColor Cyan
        $webClient = New-Object System.Net.WebClient
        $webClient.Headers.Add("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36")
        $webClient.DownloadFile($downloadUrl, $installerPath)

        if (!(Test-Path $installerPath)) {
            throw "Falha no download do arquivo. Verifique a URL ou sua conexão."
        }
        Write-Host "Download concluído com sucesso!" -ForegroundColor Green

        # Instalação silenciosa com o parâmetro correto
        Write-Host "Instalando silenciosamente... Esta etapa levará um tempo." -ForegroundColor Cyan
        Start-Process -FilePath $installerPath -ArgumentList '/s' -Wait
        
        # Pausa para garantir que a instalação em segundo plano termine
        Write-Host "Aguardando 60 segundos para garantir a finalização da instalação..."
        Start-Sleep -Seconds 60
        
        if (-not (Test-Path $cctkPath)) {
            throw "A instalação parece ter falhado, pois o arquivo cctk.exe não foi encontrado em '$cctkPath'."
        }
        Write-Host "Instalação concluída com sucesso." -ForegroundColor Green
    }

    # 3. Usar a ferramenta para Ativar o Secure Boot
    Write-Host "------------------------------------------------------------"
    Write-Host "Usando a ferramenta da Dell para configurar o Secure Boot..." -ForegroundColor Cyan
    
    $statusAtual = & $cctkPath --secureboot
    if ($statusAtual -match "Enabled") {
        Write-Host "O Secure Boot já está ATIVADO. Nenhuma ação necessária." -ForegroundColor Green
    } else {
        $resultado = & $cctkPath --secureboot=enable
        if ($LASTEXITCODE -eq 0) {
            Write-Host "SUCESSO! O Secure Boot foi agendado para ser ATIVADO na próxima reinicialização." -ForegroundColor Green
            
            # --- MELHORIA ADICIONADA ---
            # Verifica se o BitLocker está ativo e o suspende para a próxima reinicialização
            try {
                if ((Get-BitLockerVolume -MountPoint "C:").ProtectionStatus -eq 'On') {
                    Write-Host "BitLocker está ativo. Suspendendo a proteção por 1 reinicialização para evitar o modo de recuperação..." -ForegroundColor Cyan
                    Suspend-BitLocker -MountPoint "C:" -RebootCount 1
                    Write-Host "Proteção do BitLocker suspensa com sucesso para a próxima reinicialização." -ForegroundColor Green
                }
            } catch {
                Write-Warning "Não foi possível verificar ou suspender o BitLocker. Se ele estiver ativo, você poderá precisar da chave de recuperação após reiniciar."
            }
            # --- FIM DA MELHORIA ---

            Write-Host "Para completar o processo, você PRECISA REINICIAR o seu computador." -ForegroundColor Yellow
        } else {
            throw "Falha ao executar o comando CCTK. Verifique se há senha na BIOS ou se o modo é UEFI."
        }
    }
}
catch {
    Write-Error "Ocorreu um erro crítico durante a execução:"
    Write-Error $_.Exception.Message
}
finally {
    # 4. Desinstalar e Limpar
    Write-Host "------------------------------------------------------------"
    Write-Host "Iniciando a limpeza e desinstalação da ferramenta..." -ForegroundColor Cyan
    
    $app = Get-WmiObject -Class Win32_Product | Where-Object { $_.Name -like "Dell Command | Configure" }
    if ($app) {
        Write-Host "Desinstalando 'Dell Command | Configure' silenciosamente..."
        $app.Uninstall() | Out-Null
        Write-Host "Ferramenta desinstalada com sucesso." -ForegroundColor Green
    }

    # Limpar a pasta de download
    if (Test-Path $destinationPath) {
        Remove-Item -Path $destinationPath -Recurse -Force
        Write-Host "Pasta de trabalho e arquivos temporários removidos."
    }
}