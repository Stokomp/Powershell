<#
.SYNOPSIS
    Script de remediação para Remediações do Intune que habilita ("liga") o chip TPM na BIOS de dispositivos Lenovo.

.DESCRIPTION
    Este script foi projetado para ser executado pelo serviço de Remediações do Intune quando o script de detecção 
    correspondente falha. Baseado na análise de um arquivo de configuração da BIOS, este script define diretamente
    a configuração "SecurityChip" para "Enable".
    
    Ele não tenta mais descobrir dinamicamente as opções disponíveis, o que o torna mais robusto para modelos
    onde essa função WMI não se comporta como esperado.

.NOTES
    Versão:         3.0
    Data de Criação: 15/09/2025
    Histórico de Revisão:
        v2.3 - Adicionada lógica de diagnóstico para tratar dados da BIOS.
        v3.0 - Removida a descoberta dinâmica de configurações (GetBiosSelections). 
               O script agora define diretamente "SecurityChip" para "Enable" com base em dados concretos.

    IMPORTANTE: Uma reinicialização do dispositivo é necessária para aplicar as alterações da BIOS.
#>

try {
    # Verificação de segurança para garantir que o script seja executado apenas em um dispositivo Lenovo.
    $manufacturer = (Get-WmiObject -Class Win32_ComputerSystem -ErrorAction Stop).Manufacturer
    if ($manufacturer -notlike "*LENOVO*") {
        Write-Warning "Dispositivo não é um Lenovo. O script de remediação será encerrado por segurança."
        Exit 1
    }

    $tpmSettingName = "SecurityChip"
    # Com base no arquivo de configuração, o valor para habilitar será "Enable".
    $enableValue = "Enable"

    Write-Host "Análise do arquivo de configuração confirmou o nome '$tpmSettingName' e o estado alvo '$enableValue'."

    # Etapa 1: Habilitar o Security Chip na BIOS
    Write-Output "Tentando definir a configuração '$tpmSettingName' para '$enableValue' na BIOS..."
    (Get-WmiObject -Namespace "root\wmi" -Class Lenovo_SetBiosSetting -ErrorAction Stop).SetBiosSetting("$tpmSettingName,$enableValue")

    # Etapa 2: Salvar as configurações da BIOS
    Write-Output "Salvando as alterações na BIOS..."
    (Get-WmiObject -Namespace "root\wmi" -Class Lenovo_SaveBiosSettings -ErrorAction Stop).SaveBiosSettings()

    Write-Output "Comando para habilitar o Security Chip (TPM) na BIOS foi enviado com sucesso. Uma REINICIALIZAÇÃO é necessária para que as alterações entrem em vigor."
    Exit 0
}
catch {
    Write-Error "Falha crítica ao executar o script de remediação: $($_.Exception.Message)"
    Exit 1
}
