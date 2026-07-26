<#
.SYNOPSIS
    Exibição de Toast Notification multi-idioma para recomendação de reinicialização do sistema.

.DESCRIPTION
    Script otimizado para execução via Microsoft Intune Remediations (Contexto do usuário logado).
    Desenvolvido para ambientes corporativos, realiza a exibição de uma Toast Notification nativa do Windows 11
    quando o dispositivo permanece ligado continuamente por um período superior ao limite definido pela organização
    (ex.: 7 dias de uptime).

    O objetivo da notificação é incentivar a reinicialização periódica do equipamento, contribuindo para a
    aplicação de atualizações pendentes, liberação de recursos do sistema operacional, melhoria do desempenho,
    aumento da estabilidade e manutenção da conformidade do dispositivo.

    O script utiliza exclusivamente APIs nativas do Windows Runtime (WinRT), garantindo baixo consumo de recursos,
    compatibilidade com Windows 10/11 e integração com o Windows Notification Framework (WNF).

    ESTRUTURA E FLUXO DO SCRIPT

    1. Dicionário de Idiomas (Hash Table O(1))
       Implementa um dicionário em memória contendo todas as mensagens da notificação
       (Título, Corpo e Botões) para múltiplos idiomas suportados.

       Idiomas atualmente implementados:
           • Português (pt)
           • Inglês (en)
           • Espanhol (es)

       O acesso ocorre em tempo constante (O(1)), eliminando pesquisas sequenciais
       e reduzindo o consumo de CPU.

    2. Detecção Automática do Idioma
       Obtém o idioma atual do sistema operacional utilizando Get-UICulture e
       seleciona automaticamente o conjunto de textos correspondente.

       Caso o idioma não esteja implementado, aplica fallback automático para
       o idioma inglês.

    3. Registro do AUMID Corporativo
       Cria (ou atualiza) um AppUserModelID personalizado em:

           HKCU:\Software\Classes\AppUserModelId\

       O AUMID permite que o Windows identifique a notificação como pertencente
       à aplicação corporativa, possibilitando:

           • Nome personalizado no cabeçalho
           • Ícone personalizado
           • Histórico separado na Central de Notificações
           • Cache independente das notificações

    4. Configuração da Identidade Visual
       Define os ativos gráficos utilizados pela notificação:

           • Ícone do cabeçalho (IconUri)
           • Hero Image (Banner principal)
           • Logo corporativo (AppLogoOverride)

       Todos os arquivos são carregados a partir da estrutura corporativa localizada
       em ProgramData e convertidos automaticamente para URIs compatíveis com o
       mecanismo de notificações do Windows.

    5. Construção Dinâmica do Payload XML
       Gera dinamicamente o XML da Toast Notification utilizando o template
       ToastGeneric.

       O payload contém:

           • Hero Image
           • Logotipo da aplicação
           • Cabeçalho
           • Corpo da mensagem
           • Botões de ação

       A construção dinâmica permite reutilização do framework para diferentes
       cenários corporativos apenas alterando os textos e ativos visuais.

    6. Carregamento das APIs WinRT
       Carrega os namespaces:

           • Windows.UI.Notifications
           • Windows.Data.Xml.Dom

       responsáveis pela criação e publicação da Toast Notification diretamente
       pelo Windows Runtime.

    7. Criação do Documento XML
       Converte a string XML em um objeto DOM válido utilizando
       Windows.Data.Xml.Dom.XmlDocument.

       Após a validação do XML, instancia o objeto ToastNotification em memória.

    8. Publicação da Notificação
       Publica a Toast Notification através do Windows Notification Framework (WNF),
       utilizando o AUMID corporativo previamente registrado.

       A notificação é exibida ao usuário utilizando a interface nativa do Windows,
       preservando compatibilidade com o Centro de Notificações.

    9. Tratamento de Erros
       Toda a execução é encapsulada em um bloco Try/Catch.

       Em caso de sucesso:
           Exit Code 0

       Em caso de falha:
           Exit Code 1

       As exceções são registradas para facilitar troubleshooting durante
       execuções via Microsoft Intune Remediations.

.NOTES
    Engenharia.............: Invoke Management
    Framework..............: Invoke Notification Framework
    Plataforma.............: Microsoft Intune
    Contexto de Execução...: Usuário Logado
    Sistema Operacional....: Windows 10 / Windows 11
    Tecnologia.............: Windows Runtime (WinRT)
    API....................: Windows.UI.Notifications
    Template...............: ToastGeneric
    Arquitetura............: 100% Nativa (Sem módulos externos)
    Compatibilidade........: Windows Notification Framework (WNF)
    Idiomas................: Português, Inglês e Espanhol
    Exit Codes.............: 0 (Sucesso) | 1 (Falha)

.VERSION
    1.0.0

.AUTHOR
    Invoke Management
#>

[CmdletBinding()]
param ()

try {

    # =========================================================================
    # 1. Dicionário de Idiomas
    # =========================================================================

 $LangDict = @{

    'pt' = @{
        Header = "Reinicialização Recomendada"
        Body   = "Seu computador está ligado há mais de 7 dias. Reiniciá-lo ajuda a melhorar o desempenho, aplicar atualizações pendentes e manter a estabilidade do sistema."
        Btn1   = "Reiniciar Agora"
        Btn2   = "Lembrar mais tarde"
    }

    'en' = @{
        Header = "Restart Recommended"
        Body   = "Your computer has been running for more than 7 days. Restarting it helps improve performance, apply pending updates, and maintain system stability."
        Btn1   = "Restart Now"
        Btn2   = "Remind me later"
    }

    'es' = @{
        Header = "Reinicio Recomendado"
        Body   = "Su equipo ha estado encendido durante más de 7 días. Reiniciarlo ayuda a mejorar el rendimiento, aplicar las actualizaciones pendientes y mantener la estabilidad del sistema."
        Btn1   = "Reiniciar Ahora"
        Btn2   = "Recordar más tarde"
    }

}

    # =========================================================================
    # 2. Idioma
    # =========================================================================

    $OSLang = (Get-UICulture).TwoLetterISOLanguageName

    if (-not $LangDict.ContainsKey($OSLang)) {
        $OSLang = "en"
    }

    $PayloadStr = $LangDict[$OSLang]

    # =========================================================================
    # 3. Registro do AUMID
    # =========================================================================

    $AppName = "Invoke Management | Compliance"

    # Incrementado para limpar cache do Windows
    $AUMID = "InvokeManagement.Endpoint.RebootNotifier_v2"

    $HeaderIconPath = "C:\Windows\System32\SecurityAndMaintenance_Alert.png"

    $RegistryPath = "HKCU:\Software\Classes\AppUserModelId\$AUMID"

    if (-not (Test-Path $RegistryPath)) {
        New-Item -Path $RegistryPath -Force | Out-Null
    }

    New-ItemProperty `
        -Path $RegistryPath `
        -Name DisplayName `
        -Value $AppName `
        -PropertyType String `
        -Force | Out-Null

    if (Test-Path $HeaderIconPath) {

        New-ItemProperty `
            -Path $RegistryPath `
            -Name IconUri `
            -Value $HeaderIconPath `
            -PropertyType String `
            -Force | Out-Null
    }

    # =========================================================================
    # 4. Assets
    # =========================================================================

    $HeroPath = "$env:ProgramData\InvokeManagement\Assets\Reboot\Reboot.gif"

    $LogoPath = "$env:ProgramData\InvokeManagement\Assets\icon\InvokeManagement.png"

    if (-not (Test-Path $HeroPath)) {
        Write-Warning "Hero Image não encontrada."
    }

    if (-not (Test-Path $LogoPath)) {
        Write-Warning "Logo corporativo não encontrado."
    }

    $UriHeroPath = "file:///$($HeroPath -replace '\\','/')"
    $UriLogoPath = "file:///$($LogoPath -replace '\\','/')"

    # =========================================================================
    # 5. XML
    # =========================================================================

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
        <action content="$($PayloadStr.Btn1)" arguments="action=restart"/>
        <action content="$($PayloadStr.Btn2)" arguments="action=dismiss"/>
    </actions>

</toast>
"@

    # =========================================================================
    # 6. WinRT
    # =========================================================================

    [void][Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime]

    [void][Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime]

    # =========================================================================
    # 7. Criação
    # =========================================================================

    $XmlDocument = [Windows.Data.Xml.Dom.XmlDocument]::new()

    $XmlDocument.LoadXml($ToastXML)

    $Toast = [Windows.UI.Notifications.ToastNotification]::new($XmlDocument)

    # =========================================================================
    # 8. Publicação
    # =========================================================================

    [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier($AUMID).Show($Toast)

    Write-Output "Status: Success"

    Write-Output "Language : $OSLang"

    Write-Output "Hero     : $HeroPath"

    Write-Output "Logo     : $LogoPath"

    Write-Output "AUMID    : $AUMID"

    exit 0
}
catch {

    Write-Error $_.Exception.Message

    exit 1
}