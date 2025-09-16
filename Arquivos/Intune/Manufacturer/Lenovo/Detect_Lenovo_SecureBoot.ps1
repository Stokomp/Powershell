<#
.SYNOPSIS
    Verifica o status do Secure Boot em dispositivos Lenovo para o Intune Proactive Remediations.

.DESCRIPTION
    Este script de detecção foi projetado para verificar se o Secure Boot está funcionalmente ativo em um dispositivo, com foco em sistemas Lenovo. A lógica de verificação ocorre em duas etapas principais:
    
    1.  Verificação no Nível do SO: Primeiramente, utiliza o cmdlet 'Confirm-SecureBootUEFI' para uma checagem rápida e confiável do status funcional do Secure Boot. Se o retorno for verdadeiro, o dispositivo é considerado compatível.
    2.  Verificação no Nível do BIOS (para Lenovo): Se a primeira verificação falhar, o script confirma se o fabricante é 'Lenovo'. Em caso afirmativo, ele consulta a interface WMI específica da Lenovo (root\wmi) para determinar se a configuração do BIOS para 'SecureBoot' está explicitamente definida como 'Disable'.

    O script retornará um código de saída '1' (indicando a necessidade de remediação) apenas se o Secure Boot estiver desativado no BIOS e puder ser corrigido pelo script de remediação correspondente. Em todos os outros casos (compatível, não-Lenovo, erro ou problema de chaves), ele retorna '0'.

.EXAMPLE
    .\Detect-LenovoSecureBoot.ps1

    Descrição:
    Executa o script de detecção. O resultado é comunicado através de seu código de saída.
    - Saída 0: Indica que o dispositivo está compatível ou que a remediação não é aplicável.
    - Saída 1: Indica que o Secure Boot está desativado no BIOS e a remediação é necessária.

.INPUTS
    Nenhum. Este script não aceita entradas via pipeline.

.OUTPUTS
    System.Int32. O script retorna códigos de saída específicos para o Intune.
    - [0]: COMPATÍVEL. Retornado se o Secure Boot já está ativo, se o dispositivo não é um Lenovo, ou em caso de erro para evitar uma remediação incorreta.
    - [1]: REMEDIAÇÃO NECESSÁRIA. Retornado apenas se o Secure Boot estiver confirmado como 'Disable' no WMI da Lenovo.

.NOTES
    Versão:       1.0
    Requisitos:
    - Deve ser executado com privilégios de SYSTEM.
    - Requer um host PowerShell de 64 bits.

    Lógica de Saída Segura:
    O script foi projetado para sair com código 0 em caso de erro ou estado incerto. Isso garante que o script de remediação não seja executado acidentalmente em dispositivos onde a detecção falhou ou em cenários complexos (como problemas de gerenciamento de chaves do Secure Boot) que requerem intervenção manual.

    Log:
    As operações são registradas em 'C:\ProgramData\IntuneScripts\LenovoSecureBoot_Detection.log'.

.LINK
    Documentação do Intune Proactive Remediations:
    https://learn.microsoft.com/mem/analytics/proactive-remediations

    Documentação do cmdlet Confirm-SecureBootUEFI:
    https://learn.microsoft.com/powershell/module/secureboot/confirm-securebootuefi
#>

# Start logging
$logPath = "C:\ProgramData\IntuneScripts"
if (-not (Test-Path $logPath)) {
    New-Item -Path $logPath -ItemType Directory -Force | Out-Null
}
$logFile = "$logPath\LenovoSecureBoot_Detection.log"

function Write-Log {
    param ([string]$Message)
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "$Timestamp - $Message"
    Add-Content -Path $logFile -Value $logEntry
}

Write-Log "Starting Secure Boot detection script."

try {
    # Primary Check: Use the OS-level cmdlet to determine the functional state.
    $secureBootEnabled = Confirm-SecureBootUEFI
    
    if ($secureBootEnabled) {
        Write-Log "SUCCESS: Confirm-SecureBootUEFI returned True. Device is compliant."
        Write-Host "Secure Boot is enabled and functional."
        exit 0
    } else {
        Write-Log "INFO: Confirm-SecureBootUEFI returned False. Proceeding to check Lenovo WMI."
        
        # Secondary Check: Verify manufacturer and BIOS setting via WMI.
        $manufacturer = (Get-CimInstance -ClassName Win32_ComputerSystem).Manufacturer
        if ($manufacturer -ne "Lenovo") {
            Write-Log "INFO: Device manufacturer is '$manufacturer', not Lenovo. Marking as compliant/not applicable."
            Write-Host "Not a Lenovo device. Skipping."
            exit 0
        }

        # Query Lenovo WMI for the specific Secure Boot setting.
        # This confirms the issue is a disabled setting that our remediation script can fix.
        $secureBootSetting = Get-WmiObject -Namespace root\wmi -Class Lenovo_BiosSetting | Where-Object { $_.CurrentSetting -like 'Secure*Boot,*' }

        if ($null -eq $secureBootSetting) {
            Write-Log "WARNING: Could not find Secure Boot setting in Lenovo WMI. Assuming compliant to avoid remediation errors."
            Write-Host "Could not query Lenovo Secure Boot setting."
            exit 0
        }

        $currentStatus = ($secureBootSetting.CurrentSetting.Split(','))
        Write-Log "INFO: Lenovo WMI reports Secure Boot status as '$currentStatus'."

        if ($currentStatus -eq "Disable" -or $currentStatus -eq "Disabled") {
            Write-Log "DETECTION: Secure Boot is disabled in BIOS. Remediation required."
            Write-Host "Secure Boot is disabled in BIOS."
            exit 1
        } else {
            Write-Log "INFO: Secure Boot is not disabled in BIOS (Status: $currentStatus), but OS reports it as non-functional. This may be a key management issue (Setup Mode). No remediation will be attempted."
            Write-Host "BIOS setting is enabled, but OS reports Secure Boot is off. Manual intervention may be required."
            exit 0
        }
    }
} catch {
    Write-Log "ERROR: An unexpected error occurred during detection. Error: $($_.Exception.Message)"
    # Exit 0 to prevent remediation on an unknown error state.
    exit 0
}
