$CurrentDir = get-location
$imagem = "$PSScriptRoot\logo_header2.png"

#Specify Launcher App ID
$LauncherID = "{1AC14E77-02E7-4E5D-B744-2EB1AE5198B7}\WindowsPowerShell\v1.0\powershell.exe"

#Load Assemblies
[Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] | Out-Null
[Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime] | Out-Null

#Build XML Template
[xml]$ToastTemplate = @"
<toast>
    <visual>
        <binding template="ToastGeneric">
            <text id="1">ATUALIZAÇÃO</text>
            <text id="3">Estamos migrando a solução de navegação web (Proxy) e uma reinicialização será realizada ao final da tarefa. Em caso de dúvidas, entre em contato com o Service Desk.</text>
            <text placement="attribution">SEGURANÇA DA INFORMAÇÃO</text>
            <image src="$imagem" placement="hero" />
        </binding>
    </visual>
</toast>
"@

#Prepare XML
$ToastXml = [Windows.Data.Xml.Dom.XmlDocument]::New()
$ToastXml.LoadXml($ToastTemplate.OuterXml)

#Prepare and Create Toast
$ToastMessage = [Windows.UI.Notifications.ToastNotification]::New($ToastXML)
[Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier($LauncherID).Show($ToastMessage)

#log
$Data = get-date
write-output "A notificacao foi exibida em $Data." | out-file C:\WINDOWS\TEMP\modernnotification.log