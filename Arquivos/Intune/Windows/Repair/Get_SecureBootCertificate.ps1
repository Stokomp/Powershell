# 1. Monta a partição de sistema EFI (que normalmente fica oculta) na letra S:
Mount-DiskImage -ImagePath "S:" -ErrorAction SilentlyContinue | Out-Null
mountvol S: /S

# 2. Caminho do gerenciador de boot oficial da Microsoft
$bootMgrPath = "S:\EFI\Microsoft\Boot\bootmgfw.efi"

if (Test-Path $bootMgrPath) {
    # 3. Extrai o certificado digital usado para assinar o arquivo
    $cert = Get-PfxCertificate -FilePath $bootMgrPath
    
    # 4. Exibe as informações cruciais
    Write-Host "`n=== INFORMAÇÕES DO CERTIFICADO SECURE BOOT ATUAL ===" -ForegroundColor Cyan
    Write-Host "Emissor (Issuer): " $cert.Issuer
    Write-Host "Assunto (Subject): " $cert.Subject
    Write-Host "----------------------------------------------------"
    Write-Host "VÁLIDO ATÉ: " $cert.NotAfter -ForegroundColor Yellow
    Write-Host "----------------------------------------------------"
    
    # Verifica se é o certificado de 2011 (o que vai expirar)
    if ($cert.Issuer -like "*2011*") {
        Write-Host "ATENÇÃO: Este dispositivo está usando o certificado de 2011." -ForegroundColor Red
        Write-Host "Ele precisará ser atualizado antes de Junho/2026." -ForegroundColor Gray
    } elseif ($cert.Issuer -like "*2023*") {
        Write-Host "SUCESSO: Este dispositivo já está assinado com a nova CA de 2023." -ForegroundColor Green
    }
} else {
    Write-Host "Não foi possível encontrar o arquivo de boot na unidade S:." -ForegroundColor Red
}

# 5. Desmonta a unidade S: para deixar tudo limpo
mountvol S: /D