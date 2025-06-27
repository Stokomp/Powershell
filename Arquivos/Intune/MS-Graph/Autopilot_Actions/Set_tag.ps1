<#
.SYNOPSIS
    Este script PowerShell automatiza a aplicação de uma tag específica a dispositivos Autopilot no Microsoft Intune, utilizando seus números de série.

.DESCRIPTION
    Este script foi projetado para simplificar o processo de atribuição de Group Tags (tags de grupo) a dispositivos Windows registrados no Microsoft Autopilot. Ele lê uma lista de números de série de um arquivo de texto, conecta-se ao Microsoft Graph para interagir com o Intune e, para cada número de série, busca o dispositivo correspondente e aplica a tag definida.

.PREREQUISITES
    Antes de executar este script, certifique-se de que o módulo 'WindowsAutopilotIntune' esteja instalado e importado em sua sessão PowerShell.
    Para instalar:
    Install-Module -Name WindowsAutopilotIntune -Scope CurrentUser

    Para importar (necessário em cada nova sessão, a menos que configurado para carregamento automático):
    Import-Module WindowsAutopilotIntune

    Além disso, certifique-se de que o arquivo 'SerialNumber.txt' exista no caminho especificado ('C:\temp\SerialNumber.txt') e contenha um número de série por linha.

.PARAMETER GroupTag
    Variável interna '$Grouptag' que define a tag a ser aplicada aos dispositivos. Por padrão, está configurada como "GBPOCBR". Este valor pode ser alterado diretamente no script para a tag desejada.

.INPUTS
    O script espera um arquivo de texto chamado 'SerialNumber.txt' contendo os números de série dos dispositivos, um por linha. O caminho padrão para este arquivo é 'C:\temp\SerialNumber.txt'.

.OUTPUTS
    O script imprime mensagens no console indicando se a tag foi adicionada com sucesso para um determinado número de série ou se o dispositivo não foi encontrado/o objeto retornado não é do tipo esperado.

.NOTES
    Versão: 1.0
    Data: 26 de junho de 2025
    Dependências: Módulo WindowsAutopilotIntune, Microsoft Graph API.
    Escopos Necessários para Conexão ao Microsoft Graph: DeviceManagementServiceConfig.ReadWrite.All

.EXAMPLE
    Para executar o script:
    1. Salve o conteúdo acima em um arquivo .ps1 (ex: Apply-AutopilotTag.ps1).
    2. Certifique-se de que o módulo 'WindowsAutopilotIntune' esteja instalado e importado.
    3. Crie o arquivo 'C:\temp\SerialNumber.txt' com os números de série.
    4. Abra o PowerShell como Administrador (ou com as permissões apropriadas) e execute:
       .\Apply-AutopilotTag.ps1

    Este exemplo conectará ao Microsoft Graph, lerá os números de série do arquivo e tentará aplicar a tag "GBPOCBR" a cada dispositivo.
#>


#Conectar ao Microsoft Graph
Connect-MgGraph -Scopes "DeviceManagementServiceConfig.ReadWrite.All"

$Grouptag = "COLOQUE AQUI SUA TAG" #Coloque a TAG nesta variavel
$SerialNumbers = Get-Content -Path "C:\temp\SerialNumber.txt"
foreach ($Serial in $SerialNumbers) {
    $AutopilotDevice = Get-AutopilotDevice -serial $Serial
    
    # Verifique se $AutopilotDevice tem a propriedade SerialNumber para determinar o tipo
    if ($AutopilotDevice.SerialNumber) {
        # Se a propriedade SerialNumber existir, então considere o objeto como do tipo esperado
        Set-AutopilotDevice -Id $AutopilotDevice.Id -groupTag $Grouptag
        Write-Host "Tag adicionada com sucesso para o dispositivo com o serial $Serial."
    } else {
        Write-Host "O objeto retornado para o serial $Serial não é do tipo esperado."
        
    }
}
