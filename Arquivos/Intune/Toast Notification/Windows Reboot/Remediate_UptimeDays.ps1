<#

Este script foi desenvolvido para exibir uma notificação personalizada no sistema Windows, utilizando recursos de PowerShell e bibliotecas do Windows Runtime. A seguir está uma descrição detalhada de sua funcionalidade:

1. **Obtenção do Primeiro Nome**: O script utiliza o comando WMIC para acessar informações da conta de usuário do Windows e extrair o primeiro nome, armazenando-o na variável `$FirstName`. Isso ajuda a personalizar a saudação da notificação.

2. **Identificação da Cultura do Sistema**: Por meio do comando `Get-UICulture`, o script identifica o idioma configurado no sistema do usuário (como "pt-BR" para Português ou "es-MX" para Espanhol). As mensagens da notificação são adaptadas com base no idioma detectado.

3. **Definição de Textos e Títulos Personalizados**: Os títulos e mensagens da notificação são ajustados com base na cultura do sistema, oferecendo uma experiência mais relevante ao usuário.

4. **Configuração de Imagens**: Caminhos para imagens, como o fundo da notificação e o ícone, são definidos para melhorar a apresentação visual.

5. **Criação da Saudação Baseada no Período do Dia**: A saudação muda dependendo do horário em que o script é executado (bom dia, boa tarde ou boa noite), adicionando um toque mais humano à notificação.

6. **Template XML da Notificação**: Um arquivo XML é criado para especificar o layout e os elementos da notificação, como imagens, textos e ações. As ações permitem ao usuário abrir dicas ou ignorar a notificação.

7. **Exibição da Notificação**: Utilizando as bibliotecas de Windows UI Notifications, o script prepara e exibe uma notificação customizada na área de trabalho do usuário.

8. **Log de Execução**: A data e hora em que a notificação foi exibida são registradas em um arquivo de log para monitoramento e histórico.

9. **Encerramento**: O script finaliza com sucesso, após cumprir suas funções.

.Autor: Marcos Paulo Stoko 


#>



# Executa o comando CMD e armazena o resultado na variável $FirstName
$FirstName = & cmd /c 'for /f "tokens=2 delims==" %i in (''wmic useraccount where name^=''%username%'' get fullname /value'') do @for /f "tokens=1" %j in ("%i") do @echo %j'
Start-Sleep 15

# Obtém a cultura do usuário
$cultura = (Get-UICulture).Name

# Define as variáveis da mensagem com base na cultura
if ($cultura -eq "es-MX") {
    $Title = "Mejora de rendimiento 🚀"
    $SubtitleText2 = "Su computadora no se ha reiniciado en más de 5 días. Reinicie diariamente para mantener un buen rendimiento."
    $SubtitleText3 = "¿Optimizamos juntos? Haga clic en 'Consejos' 😉"
} else {
    # Padrão para PT-BR
    $Title = "Melhoria de desempenho 🚀"
    $SubtitleText2 = "Seu computador está há mais de 5 dias sem reiniciar. Reinicie diariamente para manter uma boa performance."
    $SubtitleText3 = "Vamos otimizar juntos? Clique em 'Dicas' 😉"
}

# Define o diretório atual
$CurrentDir = get-location

# Define o caminho da imagem de fundo
$imagem = "C:\Scripts\PSscripts\Intune\Toast Notification\Windows Reboot\Logo_header_OMS.png"
# Define o caminho do ícone redondo
$iconeRedondo = "C:\Scripts\PSscripts\Intune\Toast Notification\Windows Reboot\Logo_Circular_OMS.png"

# Especifica o ID do aplicativo Launcher
$LauncherID = "{1AC14E77-02E7-4E5D-B744-2EB1AE5198B7}\WindowsPowerShell\v1.0\powershell.exe"

# Carrega as assemblies necessárias
[Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] | Out-Null
[Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime] | Out-Null

# Obtém a hora atual para a saudação
$horaAtual = (Get-Date).Hour

# Define a saudação com base na hora
if ($horaAtual -lt 12) {
    $saudacao = "Bom dia $FirstName, tudo bem?"
} elseif ($horaAtual -lt 18) {
    $saudacao = "Boa tarde $FirstName, tudo bem?"
} else {
    $saudacao = "Boa noite $FirstName, tudo bem?"
}

# Cria o template XML da notificação
[xml]$ToastTemplate = @"
<toast duration='long'>
    <visual>
        <binding template='ToastGeneric'>
            <text>OMEUSOBRINHOSABE</text> 
            <image placement='hero' src='$imagem'/>
            <image id='1' placement='appLogoOverride' hint-crop='circle' src='$iconeRedondo'/>
            
                <group>
                <subgroup>
                    <text hint-style='base' hint-wrap='true' hint-color='white'>$Title</text>              
                </subgroup>
                </group>                    
                <group>
                <subgroup>
                    <text hint-style='caption' hint-wrap='true' hint-color='white'>$saudacao</text>             
                    <text hint-style='caption' hint-wrap='true' hint-color='white'>$SubtitleText2</text>
                </subgroup>
                </group>
            
                <group>
                <subgroup>
                    <text hint-style='caption' hint-wrap='true' hint-color='white'>$SubtitleText3</text>
                </subgroup>
            </group>
            
            <text placement='attribution' hint-color='white'>OMS</text>
        </binding>
    </visual>
    <actions>
        <action content='Dicas' arguments='https://www.youtube.com/@omeusobrinhosabe' activationType='protocol'/>
        <action content='Ignorar' arguments='dismiss' activationType='system'/>
    </actions>
</toast>
"@

# Prepara o XML
$ToastXml = [Windows.Data.Xml.Dom.XmlDocument]::New()
$ToastXml.LoadXml($ToastTemplate.OuterXml)

# Prepara e cria a notificação
$ToastMessage = [Windows.UI.Notifications.ToastNotification]::New($ToastXml)
[Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier($LauncherID).Show($ToastMessage)

# Registra a data e hora da exibição da notificação
$Data = get-date
write-output "A notificacao foi exibida em $Data." | out-file C:\WINDOWS\TEMP\modernnotification.log

Exit 0