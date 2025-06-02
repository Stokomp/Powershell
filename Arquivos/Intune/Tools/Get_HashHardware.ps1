<#
.SYNOPSIS
    Interface gráfica para captura de hash Autopilot, geração de CSV e importação de dispositivos via Microsoft Graph.

.DESCRIPTION
    Este script PowerShell com interface WPF facilita o processo de registro de dispositivos no Windows Autopilot.
    Ele executa as seguintes etapas:
        1. Captura do hash do hardware (HWID) do dispositivo local.
        2. Gravação da Group Tag definida pelo usuário.
        3. Geração do arquivo AutopilotImport.csv.
        4. Autenticação no Microsoft Graph com escopo 'DeviceManagementServiceConfig.ReadWrite.All'.
        5. Importação dos dispositivos para o Intune via API REST do Microsoft Graph.

    A interface gráfica foi criada com XAML e personalizada com instruções e validações para facilitar o uso por técnicos em campo.

.NOTES
    Requisitos:
        - PowerShell 5.1 ou superior.
        - Permissões de administrador local para execução de scripts.
        - Acesso à Internet para baixar módulos e autenticar no Microsoft Graph.
        - Permissões no Microsoft Graph (Intune) para importar dispositivos (scope: DeviceManagementServiceConfig.ReadWrite.All).

    Diretórios utilizados:
        - C:\HWID: para salvar o arquivo de hash gerado.
        - C:\temp: para salvar o arquivo AutopilotImport.csv.

.AUTHOR
    Marcos Paulo Stoko - 2025

.VERSION
    2.0

.LICENSE
    Uso interno corporativo. Modificações permitidas para adequação à infraestrutura da organização.
#>

# Este comando carrega a biblioteca necessária para a interface gráfica
Add-Type -AssemblyName PresentationFramework

# Instalar o módulo Microsoft.Graph.DeviceManagement.Enrollment se não estiver instalado
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.DeviceManagement.Enrollment)) {
    Install-Module Microsoft.Graph.DeviceManagement.Enrollment -Scope CurrentUser -Force
}

# Variável global para armazenar a TAG digitada
$global:GroupTag = ""

# Função para capturar o hash do hardware
function Capturar-HashDoHardware {
    $OutputFile = "C:\HWID\AutopilotHWID.csv"

    if (!(Test-Path "C:\HWID")) {
        New-Item -Path "C:\HWID" -ItemType Directory -Force
    }

    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        Set-Location -Path "C:\HWID"
        Install-Script -Name Get-WindowsAutopilotInfo -Force
        Get-WindowsAutopilotInfo -OutputFile AutopilotHWID.csv
        return "Hash do hardware capturado e salvo em C:\HWID\AutopilotHWID.csv"
    } catch {
        return "Erro ao capturar o hash do hardware: $_"
    }
}

# Função para gravar a TAG digitada
function Gravar-Tag {
    param ([string]$Tag)
    $global:GroupTag = $Tag
    return "TAG '$Tag' gravada com sucesso."
}

# Função para criar o arquivo AutopilotImport.csv
function Criar-AutopilotImportCSV {
    $InputFile = "C:\HWID\AutopilotHWID.csv"
    $OutputFile = "C:\temp\AutopilotImport.csv"

    if (-not $global:GroupTag) {
        return "Group Tag é obrigatória."
    }

    if (Test-Path $InputFile) {
        $csvContent = Import-Csv $InputFile
        $csvFormatted = @()

        foreach ($row in $csvContent) {
            $csvFormatted += [PSCustomObject]@{
                "Device Serial Number" = $row."Device Serial Number"
                "Windows Product ID"   = $row."Windows Product ID"
                "Hardware Hash"        = $row."Hardware Hash"
                "Group Tag"            = $global:GroupTag
                "Assigned User"        = ""
            }
        }

        if (!(Test-Path "C:\temp")) {
            New-Item -Path "C:\temp" -ItemType Directory -Force
        }

        $csvFormatted | Export-Csv -Path $OutputFile -NoTypeInformation -Delimiter ","
        return "Arquivo AutopilotImport.csv criado com sucesso em C:\temp\AutopilotImport.csv"
    } else {
        return "Arquivo $InputFile não encontrado."
    }
}

# Função para autenticar no Microsoft Graph
function Autenticar-MicrosoftGraph {
    Connect-MgGraph -Scopes "DeviceManagementServiceConfig.ReadWrite.All"
}

# Função para importar dispositivos via API do Microsoft Graph
function Importar-DispositivosAutopilotViaAPI {
    $csvFile = "C:\temp\AutopilotImport.csv"
    if (!(Test-Path $csvFile)) {
        return "Erro: Arquivo AutopilotImport.csv não encontrado."
    }

    try {
        Autenticar-MicrosoftGraph
        Import-Module Microsoft.Graph.DeviceManagement.Enrollment

        $csvContent = Import-Csv $csvFile

        foreach ($row in $csvContent) {
            $params = @{
                "@odata.type" = "#microsoft.graph.importedWindowsAutopilotDeviceIdentity"
                groupTag = $row."Group Tag"
                serialNumber = $row."Device Serial Number"
                productKey = $row."Windows Product ID"
                hardwareIdentifier = [System.Convert]::FromBase64String($row."Hardware Hash")
                assignedUserPrincipalName = $row."Assigned User"
            }

            try {
                $response = New-MgDeviceManagementImportedWindowsAutopilotDeviceIdentity -BodyParameter $params
                Write-Host "Dispositivo importado com sucesso: $($response | ConvertTo-Json -Depth 3)"
            } catch {
                Write-Host "Erro ao importar dispositivo: $_"
            }
        }

        return "Processo de importação concluído."
    }
    catch {
        return "Erro ao importar dispositivos via API: $_"
    }
}

# Criar interface gráfica
[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Autopilot Import GUI" Height="600" Width="650" WindowStartupLocation="CenterScreen">
    <Grid Background="#20232A">
        <StackPanel HorizontalAlignment="Center" VerticalAlignment="Top" Margin="20">
            <TextBlock Text="Hash2Intune" FontSize="24" Foreground="White" FontWeight="Bold" HorizontalAlignment="Center" Margin="10"/>

            <TextBlock Text="Como utilizar?" FontSize="16" Foreground="#FFBC82" FontWeight="Bold" Margin="5"/>
            <TextBlock Text="1. Clique em 'Export Hash to CSV' para capturar o hash do dispositivo." Foreground="LightGray" Margin="2"/>
            <TextBlock Text="2. Escolha a TAG apropriada no campo TAG e clique em 'Save Group Tag'." Foreground="LightGray" Margin="2"/>
            <TextBlock Text="3. Gere o arquivo CSV clicando em 'Generate Autopilot CSV'." Foreground="LightGray" Margin="2"/>
            <TextBlock Text="4. Clique em 'Import Devices via API' para enviar os dados ao Intune." Foreground="LightGray" Margin="2"/>

            <Border BorderBrush="#FFBC82" BorderThickness="2" CornerRadius="10" Padding="10" Margin="10">
                <StackPanel>
                    <TextBlock Text="TAGs Permitidas:" FontSize="16" Foreground="White" FontWeight="Bold" Margin="0,0,0,10"/>
                    <TextBlock Text="1 - OMSBR" Foreground="LightGray" Margin="0,0,0,5"/>
                    <TextBlock Text="2 - OMBRESP" Foreground="LightGray" Margin="0,0,0,5"/>
                    <TextBlock Text="3 - OMSCOL" Foreground="LightGray" Margin="0,0,0,5"/>
                </StackPanel>
            </Border>

            <Button Name="ExportHashButton" Content="1 - Export Hash to CSV" Background="#FFBC82" Foreground="Black" Margin="5" Height="35"/>
            <TextBlock Name="ResultadoTextBlock" Foreground="White" Margin="10" TextWrapping="Wrap"/>

            <Border BorderBrush="#FFBC82" BorderThickness="2" CornerRadius="10" Padding="10" Margin="10">
                <StackPanel Orientation="Horizontal" HorizontalAlignment="Center" Margin="5">
                    <TextBlock Text="TAG:" FontSize="16" Foreground="White" FontWeight="Bold" Margin="5" VerticalAlignment="Center"/>
                    <TextBox Name="GroupTagTextBox" Width="120" Margin="5"/>
                </StackPanel>
            </Border>

            <Button Name="SaveTagButton" Content="2 - Save Group Tag" Background="#FFBC82" Foreground="Black" Margin="5" Height="35"/>
            <Button Name="GenerateAutopilotFileButton" Content="3 - Generate Autopilot CSV" Background="#FFBC82" Foreground="Black" Margin="5" Height="35"/>
            <Button Name="ImportDevicesButton" Content="4 - Import Devices via API" Background="#FFBC82" Foreground="Black" Margin="5" Height="35"/>
            <Button Name="ExitButton" Content="Exit" Background="Red" Foreground="White" Margin="5" Height="30" Width="100" HorizontalAlignment="Center"/>
        </StackPanel>
    </Grid>
</Window>
"@

# Carregar o XAML
$reader = (New-Object System.Xml.XmlNodeReader $xaml)
$window = [Windows.Markup.XamlReader]::Load($reader)

# Eventos dos botões
$window.FindName("ExportHashButton").Add_Click({ $window.FindName("ResultadoTextBlock").Text = Capturar-HashDoHardware })
$window.FindName("SaveTagButton").Add_Click({ $window.FindName("ResultadoTextBlock").Text = Gravar-Tag -Tag $window.FindName("GroupTagTextBox").Text })
$window.FindName("GenerateAutopilotFileButton").Add_Click({ $window.FindName("ResultadoTextBlock").Text = Criar-AutopilotImportCSV })
$window.FindName("ImportDevicesButton").Add_Click({ $window.FindName("ResultadoTextBlock").Text = Importar-DispositivosAutopilotViaAPI })
$window.FindName("ExitButton").Add_Click({ $window.Close() })

# Mostrar a janela
$window.ShowDialog() | Out-Null
