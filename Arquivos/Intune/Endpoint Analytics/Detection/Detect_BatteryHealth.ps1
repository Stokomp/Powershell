# Executa o comando powercfg para gerar o relatório da bateria
$Bateria = "$env:TEMP\battery_report.html"
Remove-Item $Bateria
start-sleep 10
Invoke-Expression -Command "powercfg /batteryreport /output `"$env:TEMP\battery_report.html`""

# Caminho para o arquivo HTML do relatório da bateria
$arquivoHTML = "$env:TEMP\battery_report.html"

# Verifica se o arquivo HTML existe
if (Test-Path $arquivoHTML) {
    # Lê o conteúdo do arquivo HTML
    $conteudoHTML = Get-Content $arquivoHTML -Raw
    
    # Encontra os valores de FULL CHARGE CAPACITY e DESIGN CAPACITY no HTML
    $fullChargeCapacity = [regex]::Match($conteudoHTML, 'FULL CHARGE CAPACITY.*?(\d+\.\d+)').Groups[1].Value
    $designCapacity = [regex]::Match($conteudoHTML, 'DESIGN CAPACITY.*?(\d+\.\d+)').Groups[1].Value
    
    # Converte os valores extraídos para números
    $fullChargeCapacity = [decimal]::Parse($fullChargeCapacity)
    $designCapacity = [decimal]::Parse($designCapacity)
    
    # Calcula a saúde da bateria
    $saudeBateria = [math]::Round(($fullChargeCapacity / $designCapacity) * 100)
    
    # Exibe a saúde da bateria
    Write-Host "Saúde da Bateria: $saudeBateria%"
    Exit 0
} else {
    Write-Host "O arquivo HTML do relatório da bateria não foi encontrado."
    Exit 1
}