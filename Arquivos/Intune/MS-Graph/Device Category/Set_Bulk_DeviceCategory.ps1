<#

Criado por: Marcos Paulo Stoko
Descrição: Utilize este script powershell para aplicar uma categoria espeficica em dispositivos ingressados no Intune. Obrigatorio criar a categoria primeiro no Intune para o script funcionar, 
pois, o script fara a validacao da categoria e aplicara se ela existir.
Versão: 1.0

Autenticação:
Certifique-se de que você está autenticado no Microsoft Graph com as permissões necessárias (DeviceManagementManagedDevices.ReadWrite.All) 
utilizando o comando Connect-MgGraph.

Parâmetros:
DeviceId: ID do dispositivo no Intune.
DeviceCategory: Pode ser o display name da categoria ou o ID da categoria (se estiver no formato GUID).

#>

Function Change-DeviceCategory {
    param(
        [Parameter(Mandatory)]
        [string]$DeviceName,
        
        [Parameter(Mandatory)]
        [string]$DeviceCategory
    )

    # Busca o dispositivo pelo nome para obter o DeviceId
    Write-Host "Buscando dispositivo com nome '$DeviceName'..."
    $device = Get-MgDeviceManagementManagedDevice -Filter "deviceName eq '$DeviceName'" | Select-Object -First 1
    if (-not $device) {
        Write-Error "Dispositivo '$DeviceName' não encontrado!"
        return
    }
    $DeviceId = $device.id
    Write-Host "Encontrado: '$DeviceName' com ID '$DeviceId'"

    # URI para atualizar a categoria do dispositivo (endpoint beta)
    $Ref = '$Ref'
    $Uri = "https://graph.microsoft.com/beta/deviceManagement/managedDevices('$DeviceId')/deviceCategory/$Ref"
    
    # Se o parâmetro DeviceCategory estiver no formato GUID, utilizamos diretamente
    if ($DeviceCategory -match '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$') {
        $CategoryId = $DeviceCategory
    }
    else {
        # Busca a categoria pelo DisplayName
        (Get-MgBetaDeviceManagementDeviceCategory -Filter "DisplayName eq '$DeviceCategory'" | Select-Object -ExpandProperty Id)
    }
    
    if (-not $CategoryId) {
        Write-Error "Categoria '$DeviceCategory' não encontrada!"
        return
    }
    
    # Corpo da requisição contendo o @odata.id da categoria
    $Body = @{
        "@odata.id" = "https://graph.microsoft.com/beta/deviceManagement/deviceCategories/$CategoryId"
    } | ConvertTo-Json

    # Chama o endpoint PUT para atualizar a categoria do dispositivo
    Invoke-MgGraphRequest -Uri $Uri -Body $Body -Method PUT -ContentType "application/json"
    
    Write-Host "Categoria com ID '$CategoryId' atribuída ao dispositivo '$DeviceName' com sucesso!" -ForegroundColor Green
}

# Processamento em Massa

# Caminho do arquivo contendo os nomes dos dispositivos (um por linha)
$DeviceListFile = "C:\Scripts\PSscripts\Microsoft Graph\Devices\Endpoints.txt"

# Categoria a ser atribuída (pode ser o display name ou o ID da categoria).
# Neste exemplo, usamos o ID fornecido:
$DeviceCategoryValue = "42651fa8-87ba-47e3-bc3c-c5131ccf65af"

# Conecta e garante que estamos autenticados
if (-not (Get-MgProfile)) {
    Connect-MgGraph -Scopes "DeviceManagementManagedDevices.ReadWrite.All"
}

if (Test-Path $DeviceListFile) {
    $DeviceNames = Get-Content -Path $DeviceListFile
    foreach ($DeviceName in $DeviceNames) {
         Write-Host "Processando dispositivo: $DeviceName"
         Change-DeviceCategory -DeviceName $DeviceName -DeviceCategory $DeviceCategoryValue
    }
} else {
    Write-Error "Arquivo '$DeviceListFile' não encontrado."
}
