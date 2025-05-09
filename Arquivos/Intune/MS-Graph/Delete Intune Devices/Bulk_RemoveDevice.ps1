<#
.SYNOPSIS
    Remove dispositivos do Intune usando o Microsoft Graph com base em uma lista de hostnames.

.DESCRIPTION
    Este script automatiza a remoção de dispositivos gerenciados via Intune, utilizando o módulo do Microsoft Graph.
    
    O script realiza as seguintes operações:

      - Verifica a existência de um arquivo de texto contendo os hostnames dos dispositivos.
      - Conecta-se ao Microsoft Graph utilizando o escopo "DeviceManagementManagedDevices.ReadWrite.All".
      - Valida a conexão utilizando o cmdlet Get-MgContext.
      - Lê os hostnames do arquivo, removendo linhas vazias e espaços em branco.
      - Para cada hostname lido, busca os dispositivos correspondentes através do filtro OData "deviceName eq 'hostname'".
      - Se um ou mais dispositivos forem encontrados, cada dispositivo é processado e removido utilizando seu ManagedDeviceId.
      - Em caso de erro durante a remoção de um dispositivo, o script captura e exibe as mensagens de erro correspondentes.
    
    Pré-requisitos:

      - Este script deve ser executado no PowerShell 7 ou superior, pois o módulo Microsoft.Graph depende do .NET Core.
      - O módulo Microsoft.Graph deve estar instalado e atualizado via PowerShell Gallery.
      - O usuário que executa o script precisa ter permissões suficientes para executar operações
        de gerenciamento de dispositivos (como DeviceManagementManagedDevices.ReadWrite.All) via Microsoft Graph.
    
.NOTES

    Autor       : Marcos Paulo Stoko
    Data        : 09/05/2025
    Versão      : 1.0
    Ambiente    : PowerShell 7+
    Requisitos:
                  - Microsoft.Graph PowerShell Module instalado
                  - Acesso ao Microsoft Graph com as permissões necessárias
    Link        : https://learn.microsoft.com/pt-br/graph/powershell/get-started
    
.EXAMPLE

    PS C:\> .\Bulk_RemoveDevice.ps1
    O script inicia conectando ao Microsoft Graph (Online), valida a conexão, lê o arquivo de hostnames e, em seguida,
    remove todos os dispositivos que correspondem aos hostnames listados.
    Caso algum hostname não sea encontrado no Intune, uma mensagem informativa será exibida.
    
#>

# Caminho para o arquivo de texto com os hostnames
$RemoveDevices = "C:\Scripts\PSscripts\Microsoft Graph\Devices\Endpoints.txt"

# Verifica se o arquivo com os hostnames existe
if (-Not (Test-Path $RemoveDevices)) {
    Write-Output "Arquivo não encontrado: $RemoveDevices"
    exit
}

# Conectar ao Microsoft Graph
Connect-MgGraph -Scopes "DeviceManagementManagedDevices.ReadWrite.All"

# Aguarda um breve momento e valida a conexão com Get-MgContext
Start-Sleep -Seconds 1
$context = Get-MgContext
if (-not $context) {
    Write-Output "Falha na autenticação. Por favor, verifique suas credenciais e tente novamente."
    exit
} else {
    Write-Output "Autenticado com sucesso no Microsoft Graph."
}

# Ler os hostnames do arquivo de texto, removendo linhas vazias e espaços
$hostnames = Get-Content -Path $RemoveDevices | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne "" }

foreach ($hostname in $hostnames) {
    # Obter o dispositivo pelo hostname (pode retornar múltiplos, se houver)
    $devices = Get-MgDeviceManagementManagedDevice -Filter "deviceName eq '$hostname'"
    
    if ($devices) {
        foreach ($device in $devices) {
            try {
                # Excluir o dispositivo usando o ManagedDeviceId
                Remove-MgDeviceManagementManagedDevice -ManagedDeviceId $device.Id -ErrorAction Stop
                Write-Output "Dispositivo $hostname (ID: $($device.Id)) excluído com sucesso."
            } catch {
                Write-Output "Falha ao remover o dispositivo $hostname (ID: $($device.Id)). Erro: $_"
            }
        }
    } else {
        Write-Output "Dispositivo $hostname não encontrado."
    }
}

#Desconectar do Microsoft Graph
Disconnect-MgGraph
Write-Output "Desconectado do Microsoft Graph."