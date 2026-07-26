<#
.SYNOPSIS
    Detection Script - Verifica se o dispositivo foi reiniciado nos últimos 7 dias.

.DESCRIPTION
    Script utilizado em Microsoft Intune Remediations.

    Critério:

    • Última inicialização <= 7 dias
        Exit 0 (Compliant)

    • Última inicialização > 7 dias
        Exit 1 (Needs Remediation)

.NOTES
    Engenharia.............: Invoke Management
    Framework..............: Invoke Detection Framework
    Plataforma.............: Microsoft Intune
    Contexto...............: Usuário ou Sistema
    Exit Codes.............: 0 (Compliant) | 1 (Needs Remediation)
#>

[CmdletBinding()]
param()

try {

    # Número de dias permitido
    $MaximumUptimeDays = 7

    # Última inicialização do Windows
    $LastBoot = (Get-CimInstance Win32_OperatingSystem).LastBootUpTime

    # Calcula o uptime
    $Uptime = (Get-Date) - $LastBoot

    if ($Uptime.TotalDays -le $MaximumUptimeDays) {

        Write-Output "Compliant"
        Write-Output ("Last Boot : {0}" -f $LastBoot)
        Write-Output ("Uptime    : {0:N1} dias" -f $Uptime.TotalDays)

        exit 0

    }
    else {

        Write-Output "Needs Remediation"
        Write-Output ("Last Boot : {0}" -f $LastBoot)
        Write-Output ("Uptime    : {0:N1} dias" -f $Uptime.TotalDays)

        exit 1

    }

}
catch {

    Write-Error $_.Exception.Message
    exit 1

}