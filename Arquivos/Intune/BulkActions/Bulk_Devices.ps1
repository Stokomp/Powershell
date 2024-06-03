<#
Bulk Import
Descricao: Script criado para consultar o objectID e exportar para um arquivo .txt. Esse recurso e necessario para a configuracao de bulk import, em outras palavras 
importacao em massa de dispositivos em um grupo do EntraID (AAD).

Pré-requisitos: Ter os módulos do EntraID (AAD) configurados
> Install-Module -Name AzureAD -AllowClobber

Microsoft Docs: https://learn.microsoft.com/en-us/powershell/module/azuread/connect-azuread?view=azureadps-2.0

#>

# Caminho do arquivo de texto contendo os hostnames
$arquivo = "C:\PSScripts\Bulk\Devices\hostname.txt"

# Caminho para exportar o arquivo de texto
$exportarPara = "C:\PSScripts\Bulk\Export\ObjectID.txt"

# Lê os hostnames do arquivo
$hostnames = Get-Content $arquivo

# Conecta-se ao Azure AD
Connect-AzureAD

# Array para armazenar os resultados
$resultados = @()

# Itera sobre cada hostname
foreach ($hostname in $hostnames) {
    # Busca o objeto correspondente no Azure AD
    $objetos = Get-AzureADDevice -SearchString $hostname
    
    # Verifica se o objeto foi encontrado
    if ($objetos) {
        foreach ($objeto in $objetos) {
            # Adiciona os resultados ao array
            $resultado = $objeto.ObjectId
            $resultados += $resultado
        }
    } else {
        Write-Output "Hostname '$hostname' não encontrado no Azure AD."
    }
}

# Exporta os resultados para um arquivo de texto
$resultados | Out-File -FilePath $exportarPara -Encoding UTF8
