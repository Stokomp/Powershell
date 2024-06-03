# Caminho do arquivo de texto contendo os hostnames
$arquivo = "C:\BULK\hostnames.txt"

# Caminho para exportar o arquivo CSV
$exportarPara = "C:\BULK\ObjectID\resultado.csv"

# Lê os hostnames do arquivo
$hostnames = Get-Content $arquivo

# Conecta-se ao Azure AD
Connect-AzureAD

# Array para armazenar os resultados
$resultados = @()

# Itera sobre cada hostname
foreach ($hostname in $hostnames) {
    # Busca o objeto correspondente no Azure AD
    $objeto = Get-AzureADDevice -Filter "DisplayName eq '$hostname'"
    
    # Verifica se o objeto foi encontrado
    if ($objeto) {
        # Adiciona os resultados ao array
        $resultado = [PSCustomObject]@{
            "Hostname" = $objeto.DisplayName
            "ObjectID" = $objeto.ObjectId
        }
        $resultados += $resultado
    } else {
        Write-Output "Hostname '$hostname' não encontrado no Azure AD."
    }
}

# Exporta os resultados para um arquivo CSV
$resultados | Export-Csv -Path $exportarPara -NoTypeInformation