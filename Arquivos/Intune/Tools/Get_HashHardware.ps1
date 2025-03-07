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
        $csvContent | ForEach-Object {
            $_ | Add-Member -MemberType NoteProperty -Name "Group Tag" -Value $global:GroupTag
        }
        $csvContent | Export-Csv -Path $OutputFile -NoTypeInformation -Delimiter ";"
        return "Arquivo AutopilotImport.csv criado com sucesso em C:\temp\AutopilotImport.csv"
    } else {
        return "Arquivo $InputFile não encontrado."
    }
}

# Função para obter informações do dispositivo
function Obter-InformacoesDoDispositivo {
    $info = @{
        DeviceModel = (Get-WmiObject -Class Win32_ComputerSystem).Model
        DeviceName = (Get-WmiObject -Class Win32_ComputerSystem).Name
        Manufacturer = (Get-WmiObject -Class Win32_ComputerSystem).Manufacturer
        SerialNumber = (Get-WmiObject -Class Win32_BIOS).SerialNumber
    }
    return $info
}

# Criar a interface gráfica
[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Autopilot Import GUI" WindowState="Maximized" Background="#1E3838" Foreground="White" WindowStartupLocation="CenterScreen">
    <Grid Margin="20">
        <StackPanel HorizontalAlignment="Center" VerticalAlignment="Center">
            <TextBlock Text="Autopilot Import GUI" FontSize="24" FontWeight="Bold" Margin="10" Foreground="#FFBC82" TextAlignment="Center"/>
            <Separator Height="2" Width="500" Background="White"/>
            <TextBlock Text="Device Information" FontSize="18" Margin="10" FontWeight="Bold" TextAlignment="Center"/>
            <StackPanel HorizontalAlignment="Center">
                <TextBlock Name="DeviceModelTextBlock" Text="Device Model:" Margin="5" FontWeight="Bold"/>
                <TextBlock Name="DeviceNameTextBlock" Text="Device Name:" Margin="5" FontWeight="Bold"/>
                <TextBlock Name="ManufacturerTextBlock" Text="Manufacturer:" Margin="5" FontWeight="Bold"/>
                <TextBlock Name="SerialNumberTextBlock" Text="Serial Number:" Margin="5" FontWeight="Bold"/>
            </StackPanel>
            <Separator Height="2" Width="500" Background="White"/>
            <TextBlock Text="Gerar Hash de Hardware" FontSize="16" Margin="10" FontWeight="Bold"/>
            <Button Name="ExportHashButton" Content="Export Hash to CSV" Margin="10" Background="#FFBC82" Foreground="Black" Padding="5"/>
            <TextBlock x:Name="ResultadoTextBlock" Margin="10" FontStyle="Italic"/>
            <TextBlock Text="Grave a TAG" FontSize="16" Margin="10" FontWeight="Bold"/>
            <TextBox Name="GroupTagTextBox" Width="300" Margin="5" Background="#FFFFFF" Foreground="Black" Padding="5"/>
            <Button Name="SaveTagButton" Content="Salvar TAG" Margin="10" Background="#FFBC82" Foreground="Black" Padding="5"/>
            <Separator Height="2" Width="500" Background="White"/>
            <TextBlock Text="Exportar Arquivo para Autopilot" FontSize="16" Margin="10" FontWeight="Bold"/>
            <Button Name="GenerateAutopilotFileButton" Content="Gerar Arquivo de Importação" Margin="10" Background="#FFBC82" Foreground="Black" Padding="5"/>
        </StackPanel>
    </Grid>
</Window>
"@

# Carregar o XAML
$reader = (New-Object System.Xml.XmlNodeReader $xaml)
$window = [Windows.Markup.XamlReader]::Load($reader)

# Obter informações do dispositivo
$info = Obter-InformacoesDoDispositivo

# Preencher os campos de informações do dispositivo
$DeviceModelTextBlock = $window.FindName("DeviceModelTextBlock")
$DeviceNameTextBlock = $window.FindName("DeviceNameTextBlock")
$ManufacturerTextBlock = $window.FindName("ManufacturerTextBlock")
$SerialNumberTextBlock = $window.FindName("SerialNumberTextBlock")

$DeviceModelTextBlock.Text += " $($info.DeviceModel)"
$DeviceNameTextBlock.Text += " $($info.DeviceName)"
$ManufacturerTextBlock.Text += " $($info.Manufacturer)"
$SerialNumberTextBlock.Text += " $($info.SerialNumber)"

# Adicionar eventos aos botões
$ExportHashButton = $window.FindName("ExportHashButton")
$ResultadoTextBlock = $window.FindName("ResultadoTextBlock")
$GroupTagTextBox = $window.FindName("GroupTagTextBox")
$SaveTagButton = $window.FindName("SaveTagButton")
$GenerateAutopilotFileButton = $window.FindName("GenerateAutopilotFileButton")

$ExportHashButton.Add_Click({
    $ResultadoTextBlock.Text = Capturar-HashDoHardware
})

$SaveTagButton.Add_Click({
    $Tag = $GroupTagTextBox.Text
    if (-not $Tag) {
        $ResultadoTextBlock.Text = "Group Tag é obrigatória."
    } else {
        $ResultadoTextBlock.Text = Gravar-Tag -Tag $Tag
    }
})

$GenerateAutopilotFileButton.Add_Click({
    $ResultadoTextBlock.Text = Criar-AutopilotImportCSV
})

# Mostrar a janela
$window.ShowDialog() | Out-Null