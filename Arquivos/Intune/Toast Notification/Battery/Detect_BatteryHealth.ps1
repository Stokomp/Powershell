<#
.SYNOPSIS
Obtém o percentual de saúde da bateria do dispositivo.

.DESCRIPTION
Este script foi desenhado para ser executado via Intune (Endpoint Analytics / Proactive Remediations).
Ele utiliza a ferramenta nativa 'powercfg' do Windows para gerar um relatório de bateria temporário em formato HTML.
Em seguida, faz a leitura do arquivo, extrai os valores de 'FULL CHARGE CAPACITY' e 'DESIGN CAPACITY' via Regex, 
calcula a porcentagem de vida útil restante da bateria e retorna o valor na saída padrão (stdout) para captura no portal.

.AUTHOR
Marcos Paulo Stoko

.NOTES
Nome do Arquivo: Detect_BatteryHealth.ps1
Contexto de Execução: Sistema (System)
#>

# Caminho para o arquivo HTML do relatório da bateria
$Bateria = "$env:TEMP\battery_report.html"

# Remove o arquivo anterior de forma silenciosa, se ele existir
Remove-Item -Path $Bateria -Force -ErrorAction SilentlyContinue

# Pausa opcional para garantir a deleção antes da nova criação
Start-Sleep -Seconds 2

# Executa o comando powercfg para gerar o relatório da bateria diretamente, suprimindo o texto de sucesso do comando
& powercfg /batteryreport /output $Bateria | Out-Null

# Pausa para garantir que o arquivo terminou de ser gravado no disco
Start-Sleep -Seconds 2

# Verifica se o arquivo HTML existe
if (Test-Path $Bateria) {
    # Lê o conteúdo do arquivo HTML
    $conteudoHTML = Get-Content $Bateria -Raw
    
    # Encontra os valores de FULL CHARGE CAPACITY e DESIGN CAPACITY no HTML
    $fullChargeCapacity = [regex]::Match($conteudoHTML, 'FULL CHARGE CAPACITY.*?(\d+\.\d+|\d+)').Groups[1].Value
    $designCapacity = [regex]::Match($conteudoHTML, 'DESIGN CAPACITY.*?(\d+\.\d+|\d+)').Groups[1].Value
    
    # Converte os valores extraídos para números
    $fullChargeCapacity = [decimal]::Parse($fullChargeCapacity)
    $designCapacity = [decimal]::Parse($designCapacity)
    
    # Calcula a saúde da bateria
    $saudeBateria = [math]::Round(($fullChargeCapacity / $designCapacity) * 100)
    
    # Exibe a saúde da bateria (Usando Write-Output para melhor captura no Intune)
    Write-Output "Saúde da Bateria: $saudeBateria%"
    Exit 0
} else {
    Write-Output "O arquivo HTML do relatório da bateria não foi encontrado."
    Exit 1
}

# Caminho para o arquivo HTML do relatório da bateria
$Bateria = "$env:TEMP\battery_report.html"

# Remove o arquivo anterior de forma silenciosa, se ele existir
Remove-Item -Path $Bateria -Force -ErrorAction SilentlyContinue

# Pausa opcional (ajustada para 2 segundos apenas para garantir a deleção antes da nova criação)
Start-Sleep -Seconds 2

# Executa o comando powercfg para gerar o relatório da bateria diretamente, suprimindo o texto de sucesso do comando
& powercfg /batteryreport /output $Bateria | Out-Null

# Pausa para garantir que o arquivo terminou de ser gravado no disco
Start-Sleep -Seconds 2

# Verifica se o arquivo HTML existe
if (Test-Path $Bateria) {
    # Lê o conteúdo do arquivo HTML
    $conteudoHTML = Get-Content $Bateria -Raw
    
    # Encontra os valores de FULL CHARGE CAPACITY e DESIGN CAPACITY no HTML
    $fullChargeCapacity = [regex]::Match($conteudoHTML, 'FULL CHARGE CAPACITY.*?(\d+\.\d+|\d+)').Groups[1].Value
    $designCapacity = [regex]::Match($conteudoHTML, 'DESIGN CAPACITY.*?(\d+\.\d+|\d+)').Groups[1].Value
    
    # Converte os valores extraídos para números
    $fullChargeCapacity = [decimal]::Parse($fullChargeCapacity)
    $designCapacity = [decimal]::Parse($designCapacity)
    
    # Calcula a saúde da bateria
    $saudeBateria = [math]::Round(($fullChargeCapacity / $designCapacity) * 100)
    
    # Exibe a saúde da bateria (Usando Write-Output para melhor captura no Intune)
    Write-Output "Saúde da Bateria: $saudeBateria%"
    Exit 0
} else {
    Write-Output "O arquivo HTML do relatório da bateria não foi encontrado."
    Exit 1
}