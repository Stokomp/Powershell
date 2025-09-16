<#
.SYNOPSIS
    Ativa o Secure Boot em dispositivos Lenovo suportados usando WMI.

.DESCRIPTION
    Este script de remediação, projetado para o Microsoft Intune Proactive Remediations, verifica e ativa o Secure Boot em dispositivos Lenovo.
    O processo automatizado inclui as seguintes etapas:
    1. Valida se o dispositivo está em modo UEFI, um pré-requisito para o Secure Boot.
    2. Suspende a proteção do BitLocker por uma reinicialização para evitar a entrada em modo de recuperação após a alteração no BIOS.
    3. Utiliza métodos WMI específicos da Lenovo (namespace root\wmi) para alterar a configuração do 'SecureBoot' para 'Enable'.
    4. Detecta e utiliza automaticamente o método de autenticação de senha de BIOS apropriado (moderno ou legado), caso uma senha seja fornecida.
    5. Salva as alterações no BIOS para que sejam aplicadas na próxima inicialização.
    
    Todas as ações são registradas em 'C:\ProgramData\IntuneScripts\LenovoSecureBoot_Remediation.log' para auditoria e troubleshooting.

.PARAMETER SupervisorPassword
    (Opcional) A Senha de Supervisor do BIOS.
    Se este parâmetro não for fornecido, o script tentará aplicar a alteração sem autenticação, o que só funcionará se nenhuma senha de supervisor estiver configurada.

.EXAMPLE
    .\Enable-LenovoSecureBoot.ps1

    Descrição:
    Executa o script para ativar o Secure Boot sem fornecer uma senha de supervisor. Ideal para ambientes onde os dispositivos não possuem uma senha de BIOS configurada.

.EXAMPLE
    .\Enable-LenovoSecureBoot.ps1 -SupervisorPassword "SuaSenhaSegura"

    Descrição:
    Executa o script para ativar o Secure Boot, fornecendo a senha de supervisor para autorizar a alteração no BIOS.

.INPUTS
    Nenhum. Este script não aceita entradas via pipeline.

.OUTPUTS
    Nenhum. O script não gera objetos de saída no pipeline.
    Ele utiliza códigos de saída para indicar sucesso (0) ou falha (1) e grava logs em um arquivo de texto.

.NOTES
    Versão:       3.0
    Requisitos:
    - Deve ser executado com privilégios de SYSTEM.
    - Requer um host PowerShell de 64 bits.
    - O dispositivo alvo deve ser um modelo Lenovo com suporte às classes WMI de gerenciamento de BIOS.
    - O dispositivo deve estar operando em modo UEFI.

    Aviso sobre reinicialização:
    Uma reinicialização é necessária para que a alteração do Secure Boot entre em vigor. Este script não força a reinicialização do sistema.

    Segurança da Senha:
    Para ambientes de produção, é altamente recomendável integrar o script com uma solução de cofre de senhas, como o Azure Key Vault, em vez de passar a senha como texto simples.

.LINK
    Documentação do Intune Proactive Remediations:
    https://learn.microsoft.com/mem/analytics/proactive-remediations

    Referência WMI para Lenovo:
    https://docs.lenovocdrt.com/
#>

param (
    [string]$SupervisorPassword
)

# Start logging
$logPath = "C:\ProgramData\IntuneScripts"
if (-not (Test-Path $logPath)) {
    New-Item -Path $logPath -ItemType Directory -Force | Out-Null
}
$logFile = "$logPath\LenovoSecureBoot_Remediation.log"

function Write-Log {
    param ([string]$Message)
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "$Timestamp - $Message"
    Add-Content -Path $logFile -Value $logEntry
    Write-Host $logEntry
}

Write-Log "--- Starting Secure Boot remediation script (v3.0 - Direct Logic) ---"

# --- Prerequisite Checks ---
# Check 1: Must be running in UEFI mode.
if ($env:firmware_type -ne 'UEFI') {
    Write-Log "FATAL: Device is not in UEFI mode (Firmware Type: $env:firmware_type). Cannot enable Secure Boot. Exiting."
    exit 1
}
Write-Log "SUCCESS: Prerequisite check passed - Device is in UEFI mode."

# Check 2: Suspend BitLocker to prevent recovery mode after BIOS change.
try {
    $bitlockerVolume = Get-BitLockerVolume -MountPoint "C:"
    if ($bitlockerVolume.ProtectionStatus -eq 'On') {
        Write-Log "INFO: BitLocker is enabled. Suspending protection for 1 reboot."
        Suspend-BitLocker -MountPoint "C:" -RebootCount 1
        Write-Log "SUCCESS: BitLocker protection suspended."
    } else {
        Write-Log "INFO: BitLocker is not enabled or already suspended. No action needed."
    }
} catch {
    Write-Log "WARNING: Failed to suspend BitLocker. This could lead to BitLocker recovery. Error: $($_.Exception.Message)"
    # Continue at risk, as enabling Secure Boot is the primary goal.
}

# --- Main Remediation Logic ---
try {
    Write-Log "INFO: Checking current Secure Boot status using direct query."
    $secureBootSetting = (Get-WmiObject -class Lenovo_BiosSetting -namespace root\wmi | Where-Object {$_.CurrentSetting -like "SecureBoot,*"}).CurrentSetting

    if ($secureBootSetting -eq "SecureBoot,Disable") {
        Write-Log "INFO: Secure Boot is disabled. Attempting to enable."
        
        $saveResult = $null

        if ([string]::IsNullOrEmpty($SupervisorPassword)) {
            Write-Log "INFO: No supervisor password provided. Attempting change without authentication."
            (Get-WmiObject -class Lenovo_SetBiosSetting –namespace root\wmi).SetBiosSetting("SecureBoot,Enable")
            $saveResult = (Get-WmiObject -class Lenovo_SaveBiosSettings -namespace root\wmi).SaveBiosSettings()
        } else {
            $modernAuthAvailable = $null -ne (Get-CimClass -Namespace root\wmi -ClassName Lenovo_WmiOpcodeInterface -ErrorAction SilentlyContinue)
            if ($modernAuthAvailable) {
                Write-Log "INFO: Modern authentication interface detected. Using WmiOpcodeInterface."
                (Get-WmiObject -class Lenovo_SetBiosSetting –namespace root\wmi).SetBiosSetting("SecureBoot,Enable")
                $wmiOpcode = Get-WmiObject -Namespace root\wmi -Class Lenovo_WmiOpcodeInterface
                $authResult = $wmiOpcode.WmiOpcodeInterface("WmiOpcodePasswordAdmin:$SupervisorPassword")
                Write-Log "INFO: Authentication result: $($authResult.return)."
                $saveResult = (Get-WmiObject -class Lenovo_SaveBiosSettings -namespace root\wmi).SaveBiosSettings()
            } else {
                Write-Log "INFO: Legacy authentication method detected."
                $passwordString = "$SupervisorPassword,ascii,us"
                (Get-WmiObject -class Lenovo_SetBiosSetting –namespace root\wmi).SetBiosSetting("SecureBoot,Enable,$passwordString")
                $saveResult = (Get-WmiObject -class Lenovo_SaveBiosSettings -namespace root\wmi).SaveBiosSettings($passwordString)
            }
        }

        Write-Log "INFO: SaveBiosSettings result: $($saveResult.return)."

        if ($saveResult.return -eq "Success") {
            Write-Log "SUCCESS: Secure Boot has been enabled in BIOS. A reboot is required for the change to take effect."
            exit 0
        } else {
            Write-Log "FATAL: Failed to save BIOS settings. Result: $($saveResult.return). Check for a BIOS supervisor password or other restrictions."
            exit 1
        }
    } else {
        Write-Log "INFO: Secure Boot is not disabled (Current status: '$secureBootSetting'). No action needed."
        exit 0
    }
} catch {
    Write-Log "FATAL: An unexpected error occurred during remediation. Error: $($_.Exception.Message)"
    exit 1
}
