<#
.SYNOPSIS
    Ativa e habilita o chip TPM em notebooks Dell de forma automatizada para conformidade com o Intune.

.DESCRIPTION
    Este script de remediação foi projetado para ser executado via Microsoft Intune Proactive Remediations.
    O processo executado é o seguinte:
    1. Inicia um log detalhado.
    2. Faz o download da ferramenta Dell Command | Configure.
    3. Instala a ferramenta de forma totalmente silenciosa.
    4. Usa a ferramenta para enviar os comandos de ativação do TPM para a BIOS.
    5. SUSPENDE O BITLOCKER por 1 reinicialização para garantir uma ativação sem interrupções.
    6. Desinstala a ferramenta de forma eficiente e 100% silenciosa.
    7. Retorna 'exit 0' em caso de sucesso e 'exit 1' em caso de falha.

.NOTES
    Versão: 4.0 (Adicionada suspensão inteligente do BitLocker)
    Data: 15 de setembro de 2025
    IMPORTANTE: A ativação do TPM só será efetivada após a REINICIALIZAÇÃO do dispositivo.
    AVISO: Se uma senha de administrador da BIOS estiver definida, este script falhará.
#>

# --- INÍCIO DO LOG DETALHADO ---
$logFile = "C:\Temp\DellTPMRemediation.log"
if (!(Test-Path (Split-Path $logFile))) { New-Item -ItemType Directory -Path (Split-Path $logFile) -Force }
Start-Transcript -Path $logFile -Force

$remediationFailed = $false

try {
    Write-Host "Iniciando script de remediação do TPM - Versão 4.0"
    
    # --- CONFIGURAÇÃO ---
    $downloadUrl = "https://dl.dell.com/FOLDER12902766M/1/Dell-Command-Configure-Application_MD8CJ_WIN64_5.2.0.9_A00.EXE"
    $destinationPath = "C:\Users\Public\Documents\DellTempTPM"
    $installerPath = Join-Path $destinationPath "Dell-Command-Configure.exe"
    # CORREÇÃO: A versão 64-bit do DCC instala em "Program Files"
    $cctkPath = "C:\Program Files (x86)\Dell\Command Configure\X86_64\cctk.exe"

    # Verifica se está executando como Administrador/SYSTEM
    if (-Not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        throw "O script precisa ser executado com privilégios de Administrador/SYSTEM."
    }

    # Verifica se a ferramenta já está instalada
    if (Test-Path $cctkPath) {
        Write-Host "O 'Dell Command | Configure' já está instalado. Prosseguindo para a configuração."
    }
    else {
        Write-Host "Iniciando o processo de download e instalação..."
        if (!(Test-Path $destinationPath)) { New-Item -ItemType Directory -Path $destinationPath -Force }

        Write-Host "Baixando o instalador de '$downloadUrl'..."
        $webClient = New-Object System.Net.WebClient
        $webClient.Headers.Add("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36")
        $webClient.DownloadFile($downloadUrl, $installerPath)
        
        if (!(Test-Path $installerPath)) { throw "Falha no download do arquivo." }
        Write-Host "Download concluído."

        Write-Host "Executando a instalação silenciosa..."
        Start-Process -FilePath $installerPath -ArgumentList '/s' -Wait
        
        Write-Host "Aguardando 60 segundos para garantir a finalização da instalação..."
        Start-Sleep -Seconds 60
        
        if (-not (Test-Path $cctkPath)) {
            throw "A instalação parece ter falhado, pois o arquivo cctk.exe não foi encontrado em '$cctkPath'."
        }
        Write-Host "Instalação verificada com sucesso."
    }

    # --- LÓGICA DE REMEDIAÇÃO DO TPM ---
    Write-Host "Usando a ferramenta CCTK para configurar o TPM..."
    
    Write-Host "Passo 1: Habilitando o TPM (--tpm=on)..."
    $resultadoTpmOn = & $cctkPath --tpm=on 2>&1 | Out-String
    if ($LASTEXITCODE -ne 0) {
        if ($resultadoTpmOn -like "*password*") {
            throw "Falha ao habilitar o TPM. Uma senha de administrador da BIOS está definida e é necessária."
        }
        throw "Falha ao executar o comando --tpm=on. Código de saída: $LASTEXITCODE. Saída: $resultadoTpmOn"
    }
    Write-Host "TPM habilitado com sucesso na BIOS."

    Write-Host "Passo 2: Ativando o TPM (--tpmactivation=activate)..."
    $resultadoActivate = & $cctkPath --tpmactivation=activate 2>&1 | Out-String
    if ($LASTEXITCODE -ne 0) {
        throw "Falha ao executar o comando --tpmactivation=activate. Código de saída: $LASTEXITCODE. Saída: $resultadoActivate"
    }
    Write-Host "SUCESSO! O TPM foi agendado para ser ATIVADO na próxima reinicialização."

    # --- MELHORIA ADICIONADA ---
    # Suspende o BitLocker para garantir que a ativação do TPM não dispare o modo de recuperação.
    try {
        if ((Get-BitLockerVolume -MountPoint "C:").ProtectionStatus -eq 'On') {
            Write-Host "BitLocker está ativo. Suspendendo a proteção por 1 reinicialização para uma ativação de TPM segura..."
            Suspend-BitLocker -MountPoint "C:" -RebootCount 1
            Write-Host "Proteção do BitLocker suspensa com sucesso para a próxima reinicialização."
        } else {
            Write-Host "BitLocker não está ativo na unidade C:. A suspensão não é necessária."
        }
    } catch {
        # Adiciona um aviso ao log, mas não falha o script, pois a remediação principal (TPM) foi bem-sucedida.
        Write-Warning "Não foi possível verificar ou suspender o BitLocker. Se ele estiver ativo, a chave de recuperação pode ser necessária após reiniciar."
    }
    # --- FIM DA MELHORIA ---
}
catch {
    $remediationFailed = $true
    Write-Error "Ocorreu um erro crítico durante a remediação: $($_.Exception.Message)"
    Write-Error "Detalhes do Erro: $_"
}
finally {
    Write-Host "Iniciando a limpeza final..."
    
    # Usa a chave do registro para desinstalação silenciosa e confiável
    $uninstallKey = "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
    $app = Get-ChildItem -Path $uninstallKey | Get-ItemProperty | Where-Object { $_.DisplayName -eq "Dell Command | Configure" }

    if ($app) {
        Write-Host "Desinstalando 'Dell Command | Configure' de forma 100% silenciosa..."
        $productCode = $app.PSChildName
        $uninstallArgs = "/X $productCode /qn /norestart"
        $process = Start-Process -FilePath "msiexec.exe" -ArgumentList $uninstallArgs -Wait -PassThru
        
        if ($process.ExitCode -eq 0) {
            Write-Host "Ferramenta desinstalada com sucesso."
        } else {
            Write-Warning "A desinstalação retornou o código de erro: $($process.ExitCode)."
        }
    } else {
        Write-Host "'Dell Command | Configure' não foi encontrado para desinstalação."
    }

    if (Test-Path $destinationPath) {
        Write-Host "Removendo diretório temporário '$destinationPath'..."
        Remove-Item -Path $destinationPath -Recurse -Force
        Write-Host "Arquivos temporários removidos."
    }
}

# --- LÓGICA DE SAÍDA PARA O INTUNE ---
if ($remediationFailed) {
    Write-Host "Status da Remediação: Com Problema."
    Stop-Transcript
    exit 1
} else {
    Write-Host "Status da Remediação: Resolvido."
    Stop-Transcript
    exit 0
}