<#
.SYNOPSIS
    Script de detecção do Intune para verificar se a senha de BIOS da Dell está ativa.
.DESCRIPTION
    Consulta a classe nativa WMI da Dell instalada pelo Command Configure para verificar
    se o atributo 'AdminSetupLockout' ou a senha do sistema está populada.
.EXAMPLE
    .\Test-DellBiosPassword.ps1
#>
[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

try {
    # Caminho do utilitário Dell para dupla checagem caso necessário
    $CctkPath = "C:\Program Files (x86)\Dell\Command Configure\X86_64\cctk.exe"
    if (-not (Test-Path $CctkPath)) {
        # Se o CCTK não existir, o app não está instalado/detectado corretamente
        Exit 1
    }

    # Query WMI robusta no ecossistema Dell para checar se AdminPwd está configurado
    # Evita rodar o exe desnecessariamente e expor logs
    $AdminPwdAttr = Get-CimInstance -Namespace "root\dcim\sysman" -ClassName "DCIM_StringAttribute" | 
                    Where-Object { $_.AttributeName -eq "AdminPwd" }

    if ($null -ne $AdminPwdAttr -and $AdminPwdAttr.IsSet -eq $true) {
        # O Intune reconhece qualquer saída de texto no STDOUT + Exit 0 como "Detected"
        Write-Output "Detected: Dell BIOS Admin Password is set and compliant."
        Exit 0
    } else {
        # Não detectado (Incompatível / Sem senha definida)
        Exit 1
    }

} catch {
    # Erro na consulta WMI ou permissão
    Exit 1
}
