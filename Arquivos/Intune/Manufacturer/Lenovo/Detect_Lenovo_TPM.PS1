<#
.SYNOPSIS
    Script de detecção para Remediações do Intune que verifica se o chip TPM está ativado na BIOS de dispositivos Lenovo.

.DESCRIPTION
    Este script foi projetado para ser usado com o recurso de "Remediações" do Microsoft Intune. Ele verifica diretamente a 
    interface WMI da Lenovo (root\wmi:Lenovo_BiosSetting) para determinar o estado da configuração "SecurityChip". 
    
    Este método é mais confiável do que o cmdlet 'Get-Tpm', pois funciona mesmo quando o TPM está completamente desabilitado 
    na BIOS (um cenário em que 'Get-Tpm' incorretamente relataria o TPM como ausente).
    
    O script pressupõe que seu direcionamento é feito por meio de um filtro do Intune para ser executado apenas em hardware Lenovo.
    
    Ele determina o status da seguinte forma:
    - Exit Code 0 (Sucesso): O "SecurityChip" está ativado na BIOS. Nenhuma ação é necessária.
    - Exit Code 1 (Falha): O "SecurityChip" está desativado na BIOS ou não foi encontrado. A remediação é necessária.

.NOTES
    Versão:         3.1
    Data de Criação: 15/09/2025
    Histórico de Revisão:
        v1.0 - Versão inicial usando Get-Tpm.
        v2.0 - Lógica alterada para consultar a WMI da Lenovo e adicionar verificação de fabricante.
        v3.0 - Verificação de fabricante removida para depender de filtros do Intune.
        v3.1 - Adicionado cabeçalho de documentação detalhado.

    Requisitos:
    - Execução com privilégios de Administrador (o Intune lida com isso).
    - Hardware Lenovo com a interface WMI da BIOS funcional.
    - Ser implantado como um "Script de detecção" nas Remediações do Intune.
    - Direcionamento para dispositivos Lenovo via grupo de atribuição e/ou filtro do Intune.

.EXAMPLE
    1. No portal do Microsoft Intune, navegue até "Dispositivos > Scripts e remediações".
    2. Crie um novo pacote de scripts.
    3. Faça o upload deste arquivo (Detect-LenovoTPMStatus.ps1) no campo "Arquivo do script de detecção".
    4. Faça o upload do script de remediação correspondente no campo "Arquivo do script de remediação".
    5. Atribua o pacote a um grupo de dispositivos Lenovo.
    
    O serviço do Intune executará este script de acordo com a programação definida.
#>

try {
    Write-Output "Assumindo que este é um dispositivo Lenovo (conforme filtro do Intune). Verificando o status do 'SecurityChip' na BIOS."

    # Etapa 1: Verificar a configuração do TPM na BIOS da Lenovo
    # Esta é a fonte da verdade, pois o Get-Tpm falhará se estiver desabilitado aqui.
    $tpmBiosSetting = Get-WmiObject -Class Lenovo_BiosSetting -Namespace "root\wmi" -ErrorAction Stop | Where-Object { $_.CurrentSetting -match "SecurityChip" }

    if ($null -eq $tpmBiosSetting) {
        Write-Warning "Não foi possível encontrar a configuração 'SecurityChip' na BIOS da Lenovo. O dispositivo pode não suportar essa interface WMI."
        Exit 1 # Falha, pois não podemos confirmar o status
    }

    # A saída é como "SecurityChip,Active". Nós queremos a segunda parte.
    $settingValue = ($tpmBiosSetting.CurrentSetting).Split(',')[1].Trim()

    # Variações comuns para o status de "habilitado"
    $enabledStates = @("Active", "Enable", "Enabled")

    if ($enabledStates -contains $settingValue) {
        Write-Output "O Security Chip (TPM) está habilitado na BIOS com o status: '$settingValue'."
        Exit 0 # Sucesso
    } else {
        Write-Warning "O Security Chip (TPM) está desabilitado ou inativo na BIOS. Status atual: '$settingValue'."
        Exit 1 # Falha, remediação necessária
    }
}
catch {
    Write-Error "Ocorreu um erro durante a execução do script de detecção: $($_.Exception.Message)"
    Exit 1 # Falha
}
