<#
.SYNOPSIS
    Exibição de Toast Notification de Hardware (Bateria) multi-idioma para endpoint management.

.DESCRIPTION
    Script Otimizado para execução via Intune Remediations (Contexto do usuário logado: SIM).
    Implementa Hash Tables O(1) e anula o uso de pipelines pesados visando consumo zero de CPU ociosa.

    ESTRUTURA E FLUXO DO SCRIPT:
    
    1. Dicionário de Idiomas O(1):
       Armazena em memória uma estrutura de Hash Table contendo as traduções (Cabeçalho, Corpo e Botões) 
       para múltiplos idiomas ('pt', 'en', 'es'), permitindo acesso instantâneo sem buscas em arquivos externos.

    2. Detecção de Idioma do Sistema Operacional:
       Utiliza o cmdlet `Get-UICulture` para extrair o código ISO de duas letras do idioma atual da máquina. 
       Caso o idioma não esteja mapeado no dicionário, aplica automaticamente o fallback para o inglês ('en').

    3. Registro do AUMID Corporativo e Identidade Visual do Cabeçalho:
       Configura e valida a chave no Registro do Usuário (`HKCU:\Software\Classes\AppUserModelId\`) 
       para registrar um App User Model ID customizado (`InvokeManagement.Endpoint.Notifier.v3`). 
       Define explicitamente o nome exibido como "Invoke Management" e injeta um ícone nativo do sistema 
       (`SecurityAndMaintenance_Alert.png`) para substituir o ícone padrão no cabeçalho da notificação.

    4. Pathing Corporativo e Validação de Ativos Visuais:
       Define o diretório padrão no perfil do sistema (`$env:ProgramData`) para localizar os ativos corporativos:
       - Hero Image (`Battery.gif`)
       - Logotipo Interno da Aplicação (`InvokeManagement.png`).
       Converte os caminhos locais do Windows em URLs/URIs de arquivo compatíveis (`file:///`).

    5. Construção Dinâmica do XML (ToastTemplate):
       Monta o payload XML estruturado utilizando o template `ToastGeneric`. Inclui a tag `<image placement="appLogoOverride">` 
       para o logotipo interno, a tag `<image placement="hero">` para a imagem de destaque, seguidas pelos 
       blocos de texto e pelos botões de ação interativa ("Agendar Troca" / "Lembrar mais tarde").

    6. Carregamento de WinRT (Windows Runtime):
       Realiza o casting explícito para carregar os namespaces do .NET/WinRT necessários para interagir 
       diretamente com a API de notificações nativa do Windows (`Windows.UI.Notifications` e `Windows.Data.Xml.Dom`).

    7. Instanciação e Submissão ao WNF (Windows Notification Framework):
       Converte a string XML em um documento DOM válido, instancia o objeto de notificação e utiliza o 
       `ToastNotifier` vinculado ao AUMID corporativo para disparar o pop-up na tela do usuário.

    8. Tratamento de Erros e Controle de Fluxo:
       Envolve todo o bloco operacional em uma estrutura `try/catch`. Retorna `Exit 0` em caso de sucesso 
       (essencial para relatórios de remediação do Intune) ou `Exit 1` com a respectiva mensagem de exceção em caso de falha.

.NOTES
    Engenharia: Invoke Management
    Contexto de Execução: Usuário Logado
    Exit Codes: 0 (Sucesso), 1 (Falha)
#>

[CmdletBinding()]
param ()

try {

    # 1. Definição do Dicionário de Idiomas em Memória O(1)

    $LangDict = @{
        'pt' = @{
            Header = "Atenção: Substituição de Bateria"
            Body   = "A bateria deste equipamento atingiu o fim da sua vida útil. Recomendamos a substituição para evitar desligamentos inesperados durante o uso."
            Btn1   = "Agendar Troca"
            Btn2   = "Lembrar mais tarde"
        }

        'en' = @{
            Header = "Attention: Battery Replacement"
            Body   = "This device's battery has reached the end of its lifespan. We recommend replacing it to prevent unexpected shutdowns during use."
            Btn1   = "Schedule Replacement"
            Btn2   = "Remind me later"
        }

        'es' = @{
            Header = "Atención: Reemplazo de Batería"
            Body   = "La batería de este equipo ha llegado al final de su vida útil. Recomendamos reemplazarla para evitar apagones inesperados durante su uso."
            Btn1   = "Programar Cambio"
            Btn2   = "Recordar más tarde"
        }
    }

    # 2. Detecção Otimizada de Idioma do Sistema Operacional

    $OSLang = (Get-UICulture).TwoLetterISOLanguageName

    if (-not $LangDict.ContainsKey($OSLang)) {
        $OSLang = 'en'
    }

    $PayloadStr = $LangDict[$OSLang]

    # 3. Registro do AUMID Corporativo (Alterando Nome para 'Invoke Management' e Ícone do Cabeçalho)

    $AppName        = "Invoke Management" #Ajuste conforme a sua necessidade
   $AUMID = "InvokeManagement.Endpoint.Notifier_v1" # Altere o sufixo (ex: _v2) para forçar o Windows a limpar o cache do ícone/nome
    $HeaderIconPath = "C:\Windows\System32\SecurityAndMaintenance_Alert.png" # Usando o ícone do sistema

    $RegistryPath = "HKCU:\Software\Classes\AppUserModelId\$AUMID"

    if (-not (Test-Path $RegistryPath)) {
        New-Item -Path $RegistryPath -Force | Out-Null
    }

    # Define o Nome exibido no topo do Toast
    New-ItemProperty `
        -Path $RegistryPath `
        -Name "DisplayName" `
        -Value $AppName `
        -PropertyType String `
        -Force | Out-Null

    # Define o Ícone do cabeçalho
    if (Test-Path -Path $HeaderIconPath) {
        New-ItemProperty `
            -Path $RegistryPath `
            -Name "IconUri" `
            -Value $HeaderIconPath `
            -PropertyType String `
            -Force | Out-Null
    }

    # 4. Pathing Corporativo (Hero e Logotipo Interno)

    $GifPath  = "$env:ProgramData\InvokeManagement\Assets\Battery\Battery.gif"
    $LogoPath = "$env:ProgramData\InvokeManagement\Assets\icon\InvokeManagement.png"

    if (-not (Test-Path -Path $GifPath)) {
        Write-Warning "Asset visual (Hero) não encontrado. O Toast será processado sem a imagem de destaque."
    }

    if (-not (Test-Path -Path $LogoPath)) {
        Write-Warning "Asset visual (Logo interno) não encontrado. O Toast será processado sem o logotipo customizado."
    }

    $UriHeroPath = "file:///$($GifPath -replace '\\', '/')"
    $UriLogoPath = "file:///$($LogoPath -replace '\\', '/')"

    # 5. Construção do XML Dinâmico (Com Logo, Hero Image, Textos e Ações)

    $ToastXML = @"
<toast duration="long">
    <visual>
        <binding template="ToastGeneric">
            <image placement="appLogoOverride" src="$UriLogoPath"/>
            <image placement="hero" src="$UriHeroPath"/>
            <text hint-maxLines="1">$($PayloadStr.Header)</text>
            <text>$($PayloadStr.Body)</text>
        </binding>
    </visual>
    <actions>
        <action content="$($PayloadStr.Btn1)" arguments="action=agendar"/>
        <action content="$($PayloadStr.Btn2)" arguments="action=lembrar"/>
    </actions>
</toast>
"@

    # 6. Carregamento de WinRT

    [void][Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime]
    [void][Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime]

    # 7. Criação em memória e submissão ao WNF

    $XmlDocument = [Windows.Data.Xml.Dom.XmlDocument]::new()
    $XmlDocument.LoadXml($ToastXML)

    $Toast = [Windows.UI.Notifications.ToastNotification]::new($XmlDocument)

    # 8. Publicação via AUMID customizado

    [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier($AUMID).Show($Toast)

    Write-Output "Status: Success | Language Rendered: $OSLang | AUMID: $AUMID"

    exit 0

}
catch {

    Write-Error "Status: Failed | Exception: $($_.Exception.Message)"

    exit 1
}