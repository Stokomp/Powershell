<#
.SYNOPSIS
Aplica uma Group Tag (Tag de Grupo) personalizada a dispositivos Autopilot com base em seus números de série.

.DESCRIPTION
Este script lê uma lista de números de série de um arquivo de texto e, para cada número de série, localiza o dispositivo correspondente no Windows Autopilot usando a API do Microsoft Graph. 
Em seguida, define ou atualiza a propriedade "groupTag" do dispositivo com o valor especificado.

O script utiliza autenticação interativa por meio do comando Connect-MgGraph e requer permissões específicas para funcionar corretamente.

.EXAMPLE
.\Set_tag.ps1

Executa o script utilizando os números de série contidos no arquivo 'SerialNumber.txt' e define a Group Tag "BTR" para os dispositivos encontrados.

.PARAMETER SerialNumber.txt
Arquivo de texto contendo uma lista de números de série, um por linha.

.NOTES
Autor: Marcos Paulo Stoko  
Data da última modificação: 11/06/2025  
Versão da API Graph: v1.0

.REQUIREMENTS
- PowerShell 5.1 ou superior (ou PowerShell Core)
- Módulo Microsoft.Graph instalado:
    Install-Module Microsoft.Graph -Scope CurrentUser
- Permissões adequadas para executar chamadas à API do Microsoft Graph

.PERMISSIONS
Permissões necessárias no Microsoft Graph:

Delegated (via login interativo com Connect-MgGraph):
    - DeviceManagementServiceConfig.ReadWrite.All
    - DeviceManagementManagedDevices.ReadWrite.All

Application (caso use autenticação por app registration):
    - As mesmas permissões acima, com consentimento administrativo (admin consent)

.FUNCTIONALITY
Este script interage com os seguintes endpoints do Microsoft Graph:
- GET  deviceManagement/windowsAutopilotDeviceIdentities
- PATCH deviceManagement/windowsAutopilotDeviceIdentities/{id}

O objetivo é atribuir automaticamente a propriedade "groupTag" nos dispositivos Autopilot, com base nos números de série informados.

.LINK
https://learn.microsoft.com/en-us/graph/api/resources/intune-enrollment-windowsautopilotdeviceidentity
https://learn.microsoft.com/en-us/powershell/microsoftgraph/overview
#>


$Resource = "deviceManagement/windowsAutopilotDeviceIdentities"
$Resource = "deviceManagement/managedDevices"
$graphApiVersion = "v1.0"
$uri = "https://graph.microsoft.com/$graphApiVersion/$($resource)"
#$authority = "https://login.microsoftonline.com/$ourTenantId"

#Conectar ao Microsoft Graph
Connect-MgGraph

$Grouptag = "BTR" #Specify the GroupTag Here
$SerialNumbers = Get-Content -Path "C:\Users\marcos.stoko\Documents\Scripts\Tag\SerialNumber.txt"
foreach ($Serial in $SerialNumbers) {
    $AutopilotDevice = Get-AutopilotDevice -serial $Serial
    
    # Verifique se $AutopilotDevice tem a propriedade SerialNumber para determinar o tipo
    if ($AutopilotDevice.SerialNumber) {
        # Se a propriedade SerialNumber existir, então considere o objeto como do tipo esperado
        Set-AutopilotDevice -Id $AutopilotDevice.Id -groupTag $Grouptag
        Write-Host "Tag adicionada com sucesso para o dispositivo com o serial $Serial."
    } else {
        Write-Host "O objeto retornado para o serial $Serial não é do tipo esperado."
        # Você pode adicionar manipulação adicional aqui, se necessário
    }
}
