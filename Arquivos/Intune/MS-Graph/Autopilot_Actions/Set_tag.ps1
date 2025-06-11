<#
.Synopsis
Script Name:    Set-AutopilotGroupTagBySerial.ps1
Author:         Marcos Paulo Stoko
Descrição:      
    Este script utiliza o Microsoft Graph para aplicar uma Group Tag (Tag de Grupo) 
    personalizada em dispositivos Windows Autopilot com base em seus números de série. 

    O script realiza as seguintes ações:
    - Lê uma lista de números de série de um arquivo .txt.
    - Busca os dispositivos Autopilot associados a esses números de série via Microsoft Graph.
    - Define ou atualiza a Group Tag para cada dispositivo encontrado.

Pré-requisitos:
    - PowerShell 5.1+ ou PowerShell Core.
    - Módulo Microsoft.Graph instalado.
        Instale com: Install-Module Microsoft.Graph -Scope CurrentUser
    - Permissões corretas (veja abaixo).
    - Lista de números de série no arquivo SerialNumber.txt (um por linha).

Autenticação:
    - O script usa autenticação interativa com o comando Connect-MgGraph.
    - Você será solicitado a fazer login com uma conta que tenha permissões suficientes no Intune/MEM.

Permissões necessárias (Microsoft Graph Scopes):
    Para que o script funcione corretamente, a conta usada para autenticação precisa dos seguintes escopos:

    Delegated Permissions (via login interativo):
        - DeviceManagementServiceConfig.ReadWrite.All
        - DeviceManagementManagedDevices.ReadWrite.All

    Application Permissions (caso esteja usando autenticação por aplicativo):
        - As mesmas permissões acima, com consentimento administrativo aplicado.

    Estes escopos permitem:
        - Ler e atualizar informações de dispositivos Windows Autopilot.
        - Atribuir ou alterar a propriedade "groupTag" dos dispositivos.

API Utilizadas:
    - GET https://graph.microsoft.com/v1.0/deviceManagement/windowsAutopilotDeviceIdentities
    - PATCH https://graph.microsoft.com/v1.0/deviceManagement/windowsAutopilotDeviceIdentities/{id}

Importante:
    - O script faz validação básica para garantir que os dispositivos retornados possuam o número de série.
    - Caso um número de série não seja encontrado ou o objeto retornado seja inválido, ele será ignorado.

Versão da API Microsoft Graph:
    - v1.0
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
