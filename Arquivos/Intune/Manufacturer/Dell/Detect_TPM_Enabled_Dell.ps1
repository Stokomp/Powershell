<#
.SYNOPSIS
    Verifica se o chip TPM (Trusted Platform Module) está presente e pronto para uso no sistema operacional.

.DESCRIPTION
    Este script de detecção para o Intune utiliza o cmdlet nativo Get-Tpm para checar o status do TPM.
    - Se o TPM estiver pronto (TpmReady = True), o script sai com código 0 (sem problemas/em conformidade).
    - Se o TPM não estiver pronto ou ausente, o script sai com código 1 (problema encontrado/não conforme).

.NOTES
    Data: 02 de setembro de 2025
    Este script não requer ferramentas externas e é executado de forma rápida.
#>

try {
    Write-Host "Verificando o status do TPM..."
    $tpmStatus = Get-Tpm

    # A propriedade 'TpmReady' é a verificação mais completa. 
    # Ela só é 'True' se o TPM estiver presente, ativado na BIOS e com o driver funcionando.
    if ($tpmStatus.TpmReady -eq $true) {
        Write-Host "Detecção: TPM está presente, ativado e pronto para uso. (TpmReady = True)"
        exit 0 # Conformidade, sem problemas.
    }
    else {
        Write-Host "Detecção: TPM não está pronto. (TpmReady = False)"
        exit 1 # Não conformidade, precisa de remediação.
    }
}
catch {
    $errorMessage = $_.Exception.Message
    Write-Warning "Não foi possível obter o status do TPM. Detalhes: $errorMessage"
    # Se não for possível verificar, consideramos como não conforme para acionar a remediação.
    exit 1 # Não conformidade, precisa de remediação.
}