<#
.DESCRIPTION
    Funcionamento do Script:
    
    Configurações Iniciais:
    - Define o TenantId, ClientId e ClientSecret para autenticação no Microsoft Graph.
    - Especifica o caminho do arquivo contendo os ObjectIds dos dispositivos e o valor do atributo personalizado a ser aplicado.
    
    Autenticação no Microsoft Graph:
    - Obtém um token de acesso usando o fluxo de credenciais de cliente (client_credentials).
    - O token é usado para autenticar as requisições à API do Microsoft Graph.
    
    Preparação do Corpo da Requisição:
    - Cria o corpo da requisição JSON contendo o valor do atributo de extensão a ser atualizado.
    
    Leitura do Arquivo de Dispositivos:
    - Lê os ObjectIds dos dispositivos a partir de um arquivo de texto.
    
    Atualização dos Atributos:
    - Para cada ObjectId no arquivo, envia uma requisição PATCH para atualizar o atributo de extensão no dispositivo correspondente.
    - Exibe mensagens de sucesso ou erro para cada dispositivo.

.NOTES
    Permissões Necessárias:
    - Device.ReadWrite.All: Permite ler e atualizar objetos de dispositivos no diretório.
    - Directory.ReadWrite.All: Permite ler e escrever dados do diretório, incluindo atributos de extensão.
    - Essas permissões devem ser atribuídas à aplicação registrada no Azure AD (identificada pelo $ClientId) e requerem consentimento administrativo.
    
    Autor: Marcos Paulo Stoko
    Data: 17.04.2025

#>


# Configurações
$TenantId = ""
$ClientId = ""
$ClientSecret = ""
$DeviceListFile = "C:\Scripts\PSscripts\Microsoft Graph\Devices\Endpoints.txt"
$CustomExtensionValue = "FBC3"

# Obter Token de Acesso para o Microsoft Graph
$Body = @{
    grant_type    = "client_credentials"
    client_id     = $ClientId
    client_secret = $ClientSecret
    scope         = "https://graph.microsoft.com/.default"
} 

$TokenResponse = Invoke-RestMethod -Uri "https://login.microsoftonline.com/$TenantId/oauth2/v2.0/token" -Method Post -Body $Body
$AccessToken = $TokenResponse.access_token
$Headers = @{ Authorization = "Bearer $AccessToken"; "Content-Type" = "application/json" }

# Define o corpo da requisição para atualizar o atributo
$UpdateBody = @{
    extensionAttributes = @{
        extensionAttribute1 = $CustomExtensionValue
    }
} | ConvertTo-Json -Depth 3

# Lê o arquivo com os ObjectIds
$DeviceObjectIds = Get-Content -Path $DeviceListFile

# Para cada ObjectId no arquivo, realiza a atualização
foreach ($DeviceObjectId in $DeviceObjectIds) {
    $PatchUrl = "https://graph.microsoft.com/v1.0/devices/$DeviceObjectId"
    try {
        # Atualiza o atributo no Entra ID
        Invoke-RestMethod -Uri $PatchUrl -Headers $Headers -Method Patch -Body $UpdateBody
        Write-Host "Atributo personalizado aplicado para o dispositivo com ObjectId '$DeviceObjectId'!" -ForegroundColor Green
    } catch {
        Write-Host "Erro ao aplicar o atributo para o dispositivo com ObjectId '$DeviceObjectId'. Erro: $_" -ForegroundColor Red
    }
}
