# Definir variáveis
$downloadUrl = "https://dl.dell.com/FOLDER12177776M/1/Dell-ControlVault3-Driver-and-Firmware_98DKH_WIN_5.14.15.22_A28.EXE"
$destinationPath = "C:\temp\Dell"
$installerPath = "$destinationPath\Dell-ControlVault3.exe"

# Criar diretório se não existir
if (!(Test-Path $destinationPath)) {
    New-Item -ItemType Directory -Path $destinationPath -Force
}

# Configurar User-Agent para simular um navegador
$webClient = New-Object System.Net.WebClient
$webClient.Headers.Add("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36")

# Baixar o arquivo
$webClient.DownloadFile($downloadUrl, $installerPath)

# Verificar se o download foi bem-sucedido
if (Test-Path $installerPath) {
    # Extrair os arquivos (parâmetro /s /e para extração silenciosa)
    Start-Process -FilePath $installerPath -ArgumentList "/s /e=$destinationPath" -NoNewWindow -Wait

    # Opcional: Remover o instalador após a extração
    Remove-Item $installerPath -Force
} else {
    Write-Host "Falha no download do arquivo. Verifique a URL."
}
