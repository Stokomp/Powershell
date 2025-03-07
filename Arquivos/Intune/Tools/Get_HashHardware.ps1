Add-Type -AssemblyName PresentationFramework

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
        New-Item -Type Directory -Path "C:\HWID" -Force
        Set-Location -Path "C:\HWID"
        $env:Path += ";C:\Program Files\WindowsPowerShell\Scripts"
        Set-ExecutionPolicy -Scope Process -ExecutionPolicy RemoteSigned -Force
        Install-Script -Name Get-WindowsAutopilotInfo -Force
        Get-WindowsAutopilotInfo -OutputFile AutopilotHWID.csv
        return "Hash do hardware capturado e salvo em C:\HWID\AutopilotHWID.csv"
    } catch {
        return "Erro ao capturar o hash do hardware: $_"
    }
}

# Função para gravar a TAG digitada
function Gravar-Tag {
    param (
        [string]$Tag
    )
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
                "Windows Product ID" = $row."Windows Product ID"
                "Hardware Hash" = $row."Hardware Hash"
                "Group Tag" = $global:GroupTag
                "Assigned User" = ""
            }
        }
        
        $csvFormatted | Export-Csv -Path $OutputFile -NoTypeInformation -Delimiter ","
        return "Arquivo AutopilotImport.csv criado com sucesso em C:\temp\AutopilotImport.csv"
    } else {
        return "Arquivo $InputFile não encontrado."
    }
}

# Criar a interface gráfica
[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Autopilot Import GUI" Height="500" Width="600" WindowStartupLocation="CenterScreen">
    <Grid Background="#011E38">
        <StackPanel HorizontalAlignment="Center" VerticalAlignment="Center">
            <TextBlock Text="Autopilot Import GUI" FontSize="20" Foreground="White" FontWeight="Bold" HorizontalAlignment="Center" Margin="10"/>
            <TextBlock Text="Device Information" FontSize="16" Foreground="White" FontWeight="Bold" HorizontalAlignment="Center" Margin="10"/>
            <TextBlock Name="DeviceModelTextBlock" Text="Device Model:" Foreground="White" FontWeight="Bold" Margin="5"/>
            <TextBlock Name="DeviceNameTextBlock" Text="Device Name:" Foreground="White" FontWeight="Bold" Margin="5"/>
            <TextBlock Name="ManufacturerTextBlock" Text="Manufacturer:" Foreground="White" FontWeight="Bold" Margin="5"/>
            <TextBlock Name="SerialNumberTextBlock" Text="Serial Number:" Foreground="White" FontWeight="Bold" Margin="5"/>
            <Button Name="ExportHashButton" Content="Export Hash to CSV" Background="#FFBC82" Foreground="Black" Margin="10"/>
            <TextBlock x:Name="ResultadoTextBlock" Foreground="White" Margin="10"/>
            <TextBlock Text="Group Tag" FontSize="16" Foreground="White" FontWeight="Bold" Margin="10"/>
            <TextBox Name="GroupTagTextBox" Width="200" Margin="5"/>
            <Button Name="SaveTagButton" Content="Save Group Tag" Background="#FFBC82" Foreground="Black" Margin="10"/>
            <Button Name="GenerateAutopilotFileButton" Content="Generate Autopilot CSV" Background="#FFBC82" Foreground="Black" Margin="10"/>
        </StackPanel>
    </Grid>
</Window>
"@

# Carregar o XAML
$reader = (New-Object System.Xml.XmlNodeReader $xaml)
$window = [Windows.Markup.XamlReader]::Load($reader)

# Obter informações do dispositivo
function Obter-InformacoesDoDispositivo {
    $info = @{
        DeviceModel = (Get-WmiObject -Class Win32_ComputerSystem).Model
        DeviceName = (Get-WmiObject -Class Win32_ComputerSystem).Name
        Manufacturer = (Get-WmiObject -Class Win32_ComputerSystem).Manufacturer
        SerialNumber = (Get-WmiObject -Class Win32_BIOS).SerialNumber
    }
    return $info
}

$info = Obter-InformacoesDoDispositivo
$window.FindName("DeviceModelTextBlock").Text += " $($info.DeviceModel)"
$window.FindName("DeviceNameTextBlock").Text += " $($info.DeviceName)"
$window.FindName("ManufacturerTextBlock").Text += " $($info.Manufacturer)"
$window.FindName("SerialNumberTextBlock").Text += " $($info.SerialNumber)"

# Adicionar eventos aos botões
$window.FindName("ExportHashButton").Add_Click({
    $window.FindName("ResultadoTextBlock").Text = Capturar-HashDoHardware
})

$window.FindName("SaveTagButton").Add_Click({
    $Tag = $window.FindName("GroupTagTextBox").Text
    if (-not $Tag) {
        $window.FindName("ResultadoTextBlock").Text = "Group Tag é obrigatória."
    } else {
        $window.FindName("ResultadoTextBlock").Text = Gravar-Tag -Tag $Tag
    }
})

$window.FindName("GenerateAutopilotFileButton").Add_Click({
    $window.FindName("ResultadoTextBlock").Text = Criar-AutopilotImportCSV
})

# Mostrar a janela
$window.ShowDialog() | Out-Null
