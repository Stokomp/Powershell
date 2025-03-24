<#

Titulo: Toast Images

Descrição: Script responsavel por movimentar os arquivos .jg e .png para uma pasta espefica. Os arquivos sao compactados pelo Intune App Win, e
com isso ficam sem permissao, o script ira definir permissao de apenas leitura para "domain users". O script de remediacao de reinicializacao depende
desses arquivos para ter sucesso na execucao. 

.Autor: Marcos Paulo Stoko

Escopo:

0. O script define o caminho da pasta onde os arquivos serão armazenados: C:\Public\Documents\Toast_Notification\Reboot.

1. Verificação e Criação da Pasta:

- Verifica se a pasta especificada existe usando Test-Path.
- Se a pasta não existir, ela é criada com New-Item e uma mensagem de sucesso é exibida.
- Se a pasta já existir, uma mensagem indicando isso é exibida.

2. Definição dos Caminhos dos Arquivos:

- Define os caminhos dos arquivos .png e .jpg usando a variável $PSScriptRoot, que representa o diretório onde o script está sendo executado.

3. Movimentação dos Arquivos:

- Utiliza Get-ChildItem para obter todos os arquivos .png e .jpg no diretório do script.
- Cada arquivo encontrado é copiado para a pasta especificada ($folderPath) usando Copy-Item.
- Mensagens são exibidas para cada arquivo copiado.
- Definição de Permissões de Leitura:

4. Define permissões de leitura para o grupo "Domain Users".

- Cria uma regra de acesso (FileSystemAccessRule) que permite leitura para "Domain Users".

5. Aplicação das Permissões:

- Obtém a lista de arquivos na pasta especificada.
- Para cada arquivo, obtém a lista de controle de acesso (ACL) atual e adiciona a regra de acesso definida.
- Aplica a nova ACL apenas de leitura ao arquivo usando Set-Acl.
- Mensagens são exibidas dentro do prompt para cada arquivo indicando que as permissões de leitura foram aplicadas.

#>


# Define o caminho da pasta
$folderPath = "C:\Public\Documents\Toast_Notification\Reboot"

# Verifica se a pasta existe
if (-Not (Test-Path -Path $folderPath)) {
    # Cria a pasta se não existir
    New-Item -Path $folderPath -ItemType Directory
    Write-Output "A pasta '$folderPath' foi criada com sucesso."
} else {
    Write-Output "A pasta '$folderPath' já existe."
}

# Define o caminho dos arquivos .png e .jpg usando $PSScriptRoot
$sourcePathPng = "$PSScriptRoot\*.png"
$sourcePathJpg = "$PSScriptRoot\*.jpg"

# Move os arquivos .png para a pasta criada
Get-ChildItem -Path $sourcePathPng | ForEach-Object {
    Copy-Item -Path $_.FullName -Destination $folderPath
    Write-Output "O arquivo '$($_.Name)' foi copiado para '$folderPath'."
}

# Move os arquivos .jpg para a pasta criada
Get-ChildItem -Path $sourcePathJpg | ForEach-Object {
    Copy-Item -Path $_.FullName -Destination $folderPath
    Write-Output "O arquivo '$($_.Name)' foi copiado para '$folderPath'."
}

# Define permissões de leitura para "Domain Users"
$identityDomainUsers = [System.Security.Principal.NTAccount]::new("Domain Users")
$permissionDomainUsers = [System.Security.AccessControl.FileSystemRights]::Read
$accessControlType = [System.Security.AccessControl.AccessControlType]::Allow

# Aplica as permissões de leitura para todos os arquivos na pasta
Get-ChildItem -Path "$folderPath\*" | ForEach-Object {
    $acl = Get-Acl $_.FullName
    $accessRuleDomainUsers = New-Object System.Security.AccessControl.FileSystemAccessRule($identityDomainUsers, $permissionDomainUsers, $accessControlType)
    $acl.SetAccessRule($accessRuleDomainUsers)
    Set-Acl $_.FullName $acl
    Write-Output "Permissões de leitura foram aplicadas ao arquivo '$($_.Name)'."
}
