<#
.SYNOPSIS
    Verifica o status do Secure Boot (UEFI) de forma robusta.

.DESCRIPTION
    Este script utiliza o cmdlet Confirm-SecureBootUEFI dentro de um bloco try/catch.
    - Se o comando for bem-sucedido, informa se o Secure Boot está ativado ou não.
    - Se o comando falhar (ex: sistema em modo Legacy BIOS), ele captura o erro
      e informa ao usuário a causa provável.

.NOTES
    Requer execução como Administrador para funcionar corretamente.
#>

# É uma boa prática verificar se o script está sendo executado como Administrador
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "Para garantir um resultado preciso, por favor, execute este script no PowerShell como Administrador."
    # Pausa a execução para que o usuário possa ler a mensagem
    Read-Host "Pressione Enter para tentar continuar..."
}

try {
    # Tenta executar o comando que pode falhar
    $isSecureBootEnabled = Confirm-SecureBootUEFI

    if ($isSecureBootEnabled) {
        Write-Host "O Secure Boot está ATIVADO."
        exit 0 # Sucesso, estado desejado
    }
    else {
        Write-Host "O Secure Boot está DESATIVADO."
        exit 1 # Sucesso na execução, mas estado indesejado
    }
}
catch {
    # Este bloco só é executado se o comando em 'try' gerar um erro
    Write-Host "Não foi possível verificar o status do Secure Boot." -ForegroundColor Red
    Write-Host "       Causa provável: O sistema não está inicializado em modo UEFI ou o cmdlet não é suportado." -ForegroundColor Red
    exit 2 # Código de saída para erro na execução do script
}