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
        Title="Autopilot Import GUI" Height="550" Width="600" WindowStartupLocation="CenterScreen">
    <Grid Background="#20232A">
        <StackPanel HorizontalAlignment="Center" VerticalAlignment="Center">
            <TextBlock Text="Autopilot Import GUI" FontSize="22" Foreground="White" FontWeight="Bold" HorizontalAlignment="Center" Margin="10"/>
            
            <Border BorderBrush="#FFBC82" BorderThickness="2" CornerRadius="10" Padding="10" Margin="10">
                <StackPanel>
                    <TextBlock Text="TAGs Permitidas:" FontSize="16" Foreground="White" FontWeight="Bold"/>
                    <TextBlock Text="1 - OMSBR" Foreground="LightGray"/>
                    <TextBlock Text="2 - OMBRESP" Foreground="LightGray"/>
                    <TextBlock Text="3 - OMSCOL" Foreground="LightGray"/>
                </StackPanel>
            </Border>
            
            <Button Name="ExportHashButton" Content="1 - Export Hash to CSV" Background="#FFBC82" Foreground="Black" Margin="5"/>
            <TextBlock Name="ResultadoTextBlock" Foreground="White" Margin="10"/>
            
            <Border BorderBrush="#FFBC82" BorderThickness="2" CornerRadius="10" Padding="10" Margin="10">
                <StackPanel Orientation="Horizontal" HorizontalAlignment="Center" Margin="5">
                    <TextBlock Text="TAG:" FontSize="16" Foreground="White" FontWeight="Bold" Margin="5" VerticalAlignment="Center"/>
                    <TextBox Name="GroupTagTextBox" Width="100" Margin="5"/>
                </StackPanel>
            </Border>
            
            <Border BorderBrush="#FFBC82" BorderThickness="2" CornerRadius="10" Padding="10" Margin="10">
                <Button Name="SaveTagButton" Content="2 - Save Group Tag" Background="#FFBC82" Foreground="Black" Margin="5"/>
            </Border>
            
            <Button Name="GenerateAutopilotFileButton" Content="3 - Generate Autopilot CSV" Background="#FFBC82" Foreground="Black" Margin="5"/>
            
            <Button Name="ImportDevicesButton" Content="4 - Import Devices via API" Background="#FFBC82" Foreground="Black" Margin="5"/>
            
            <Button Name="ExitButton" Content="Exit" Background="Red" Foreground="White" Margin="5" HorizontalAlignment="Center"/>
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
