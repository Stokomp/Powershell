<#
.SYNOPSIS
    Configura ou rotaciona a senha de administrador da BIOS em dispositivos Dell.
.DESCRIPTION
    Este script verifica a presença do Dell Command | Configure e aplica a senha corporativa
    gerenciada de forma segura através de parâmetros do Intune.

    Intune install command: powershell.exe -ExecutionPolicy Bypass -File .\Set-DellBiosPassword.ps1 -NewPassword "Pass!Secure" -OldPassword "Pass@2025!"
.EXAMPLE
    .\Set-DellBiosPassword.ps1 -NewPassword "Password" -OldPassword "Password"
#>
[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$NewPassword,

    [Parameter(Mandatory = $false)]
    [string]$OldPassword
)

$ErrorActionPreference = "Stop"

try {
    # 1. Determinar o caminho do CCTK baseado na arquitetura do sistema
    $CctkFolder = "C:\Program Files (x86)\Dell\Command Configure\X86_64"
    if (-not (Test-Path $CctkFolder)) {
        throw "Dell Command | Configure nao esta instalado no caminho padrao de 64-bit."
    }

    Set-Location -Path $CctkFolder
    $CctkExe = ".\cctk.exe"

    Write-Output "LOG: Iniciando analise do status atual da BIOS..."

    # 2. Executar validação para checar se já existe senha definida (WMI)
    # Usamos o namespace nativo da Dell provisionado pelo CCTK
    $BiosAttributes = Get-CimInstance -Namespace "root\dcim\sysman" -ClassName "DCIM_BIOSService" -ErrorAction SilentlyContinue
    
    # 3. Execução do comando CCTK conforme cenários
    if ([string]::IsNullOrEmpty($OldPassword)) {
        Write-Output "LOG: Tentando definir a primeira senha de BIOS (Fábrica)..."
        $Process = Start-Process -FilePath $CctkExe -ArgumentList "--SetupPwd=$NewPassword" -Wait -NoNewWindow -PassThru
    } else {
        Write-Output "LOG: Rotação detectada. Tentando atualizar senha existente..."
        $Process = Start-Process -FilePath $CctkExe -ArgumentList "--SetupPwd=$NewPassword --ValSetupPwd=$OldPassword" -Wait -NoNewWindow -PassThru
    }

    # 4. Tratamento do código de retorno (ExitCode 0 indica sucesso)
    if ($Process.ExitCode -eq 0) {
        Write-Output "SUCCESS: Senha de BIOS configurada com sucesso."
        Exit 0
    } else {
        Write-Error "ERROR: Falha ao aplicar configuracao. Codigo de saida do CCTK: $($Process.ExitCode)"
        Exit $Process.ExitCode
    }

} catch {
    Write-Error "CRITICAL: Erro inesperado durante a execucao: $_"
    Exit 1
}
