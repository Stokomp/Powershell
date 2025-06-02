Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

#region Definição de Cores e Fontes (Inspirado no Powersign_tool.ps1)
$colorFundoApp = [System.Drawing.ColorTranslator]::FromHtml("#F5F1EB")
$colorBotaoPrincipal = [System.Drawing.ColorTranslator]::FromHtml("#264FEC")
$colorBotaoSecundario = [System.Drawing.ColorTranslator]::FromHtml("#505050")
$colorBotaoPerigo = [System.Drawing.ColorTranslator]::FromHtml("#D32F2F")
$colorTextoBotao = [System.Drawing.Color]::White
$colorTextoPrincipal = [System.Drawing.ColorTranslator]::FromHtml("#011E38")
$colorTextoSucesso = [System.Drawing.Color]::Green
$colorTextoErro = [System.Drawing.Color]::Red
$colorTextoInfo = [System.Drawing.Color]::DarkSlateGray

$fontePadrao = New-Object System.Drawing.Font("Segoe UI", 10)
$fonteTitulo = New-Object System.Drawing.Font("Segoe UI", 16, [System.Drawing.FontStyle]::Bold)
$fonteGroupBox = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$fonteStatus = New-Object System.Drawing.Font("Consolas", 9)
#endregion

# Instalar o módulo Microsoft.Graph.DeviceManagement.Enrollment se não estiver instalado
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph.DeviceManagement.Enrollment)) {
    try {
        Install-Module Microsoft.Graph.DeviceManagement.Enrollment -Scope CurrentUser -Force -Confirm:$false -SkipPublisherCheck
        Write-Host "Módulo Microsoft.Graph.DeviceManagement.Enrollment instalado."
    } catch {
        Write-Warning "Falha ao instalar o módulo Microsoft.Graph.DeviceManagement.Enrollment. $($_.Exception.Message)"
    }
}

# Variáveis globais
$global:GroupTag = ""
$global:ExternalCsvPath = ""
$global:LastGeneratedCsvPath = "" # Para armazenar o caminho do último CSV de importação gerado

#region Funções de Backend (Lógica do Autopilot)
function Capturar-HashDoHardware {
    $OutputFile = "C:\HWID\AutopilotHWID.csv"
    $OutputDirectory = "C:\HWID"

    if (!(Test-Path $OutputDirectory)) {
        try {
            New-Item -Path $OutputDirectory -ItemType Directory -Force | Out-Null
        } catch {
            return "Erro ao criar o diretório '{0}': {1}" -f $OutputDirectory, $_.Exception.Message
        }
    }

    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        if (-not (Get-Command Get-WindowsAutopilotInfo -ErrorAction SilentlyContinue)) {
            Write-Host "Script Get-WindowsAutopilotInfo não encontrado, tentando instalar..."
            Install-Script -Name Get-WindowsAutopilotInfo -Force -Scope CurrentUser -Confirm:$false -SkipPublisherCheck
        }
        Push-Location $OutputDirectory
        Get-WindowsAutopilotInfo -OutputFile AutopilotHWID.csv
        Pop-Location
        $global:ExternalCsvPath = ""
        if ($textBoxExternalCsvPath) { $textBoxExternalCsvPath.Text = "" }
        return "Hash do hardware capturado e salvo em $OutputFile. Seleção de CSV externo foi limpa."
    } catch {
        return "Erro ao capturar o hash do hardware: $($_.Exception.Message)"
    }
}

function Gravar-Tag {
    param ([string]$Tag)
    if ([string]::IsNullOrWhiteSpace($Tag)) {
        return "Erro: A TAG não pode estar vazia."
    }
    $global:GroupTag = $Tag
    return "TAG '$Tag' gravada com sucesso."
}

function Criar-AutopilotImportCSV {
    $InputFileDefault = "C:\HWID\AutopilotHWID.csv"
    $InputFile = $InputFileDefault
    $InputFileSourceMessage = "usando o arquivo capturado ($InputFile)"

    if (-not [string]::IsNullOrWhiteSpace($global:ExternalCsvPath) -and (Test-Path $global:ExternalCsvPath)) {
        $InputFile = $global:ExternalCsvPath
        $InputFileSourceMessage = "usando o arquivo CSV externo selecionado ($InputFile)"
    } elseif (-not [string]::IsNullOrWhiteSpace($global:ExternalCsvPath)) {
        return "Erro: O arquivo CSV externo selecionado ('$($global:ExternalCsvPath)') não foi encontrado. Verifique o caminho ou selecione outro arquivo."
    }

    $BaseOutputDirectory = "C:\temp"
    $BaseFileName = "AutopilotImport"
    $FileExtension = ".csv"
    
    if ([string]::IsNullOrWhiteSpace($global:GroupTag)) {
        return "Erro: A Group Tag é obrigatória. Por favor, salve uma TAG primeiro."
    }
    if (!(Test-Path $InputFile)) {
        if ($InputFile -eq $global:ExternalCsvPath) {
             return "Erro: Arquivo CSV externo de origem $InputFile não encontrado."
        } else {
             return "Erro: Arquivo de origem padrão $InputFileDefault não encontrado. Exporte o Hash primeiro ou selecione um CSV externo."
        }
    }
    
    if (!(Test-Path $BaseOutputDirectory)) {
        try {
            New-Item -Path $BaseOutputDirectory -ItemType Directory -Force | Out-Null
        } catch {
            return "Erro ao criar o diretório '{0}': {1}" -f $BaseOutputDirectory, $_.Exception.Message
        }
    }

    $OutputFile = Join-Path -Path $BaseOutputDirectory -ChildPath ($BaseFileName + $FileExtension)
    $Counter = 1
    while (Test-Path $OutputFile) {
        $NewFileName = "{0}_{1}{2}" -f $BaseFileName, $Counter, $FileExtension
        $OutputFile = Join-Path -Path $BaseOutputDirectory -ChildPath $NewFileName
        $Counter++
    }
    
    try {
        Update-ResultadoTextBox -TextBox $textBoxResultado -Message "Lendo dados $InputFileSourceMessage..." -Type "Info"
        $csvContent = Import-Csv $InputFile
        $csvFormatted = @()
        foreach ($row in $csvContent) {
            if (-not ($row.PSObject.Properties.Name -contains "Device Serial Number" -and `
                       $row.PSObject.Properties.Name -contains "Windows Product ID" -and `
                       $row.PSObject.Properties.Name -contains "Hardware Hash")) {
                return "Erro: O arquivo CSV '$InputFile' não contém as colunas esperadas ('Device Serial Number', 'Windows Product ID', 'Hardware Hash'). Verifique o formato do arquivo."
            }

            $csvFormatted += [PSCustomObject]@{
                "Device Serial Number" = $row."Device Serial Number"
                "Windows Product ID"   = $row."Windows Product ID"
                "Hardware Hash"        = $row."Hardware Hash"
                "Group Tag"            = $global:GroupTag
                "Assigned User"        = ""
            }
        }
        $csvFormatted | Export-Csv -Path $OutputFile -NoTypeInformation -Delimiter "," -Encoding UTF8
        $global:LastGeneratedCsvPath = $OutputFile # Armazena o caminho do arquivo realmente gerado
        return "Arquivo '$((Split-Path $OutputFile -Leaf))' criado com sucesso em $BaseOutputDirectory $InputFileSourceMessage."
    } catch {
        return "Erro ao criar o arquivo '$((Split-Path $OutputFile -Leaf))': $($_.Exception.Message). Verifique o formato e conteúdo do arquivo '$InputFile'."
    }
}

function Autenticar-MicrosoftGraph {
    try {
        Connect-MgGraph -Scopes "DeviceManagementServiceConfig.ReadWrite.All"
        $context = Get-MgContext
        if ($context.Account) {
            return "Autenticado com sucesso no Microsoft Graph como $($context.Account)."
        } else {
            return "Falha na autenticação com o Microsoft Graph. Nenhuma conta conectada."
        }
    } catch {
        # CORREÇÃO APLICADA AQUI: Garantir que uma string de mensagem seja retornada
        $errorMessage = $_.Exception.Message
        return "Erro durante a autenticação no Microsoft Graph: $errorMessage"
    }
}

function Importar-DispositivosAutopilotViaAPI {
    if ([string]::IsNullOrWhiteSpace($global:LastGeneratedCsvPath) -or !(Test-Path $global:LastGeneratedCsvPath)) {
        return "Erro: Nenhum arquivo CSV de importação foi gerado recentemente ou o caminho não é válido. Por favor, gere o arquivo CSV primeiro."
    }
    $csvFile = $global:LastGeneratedCsvPath

    try {
        Update-ResultadoTextBox -TextBox $textBoxResultado -Message "Carregando módulo 'Microsoft.Graph.DeviceManagement.Enrollment'..." -Type "Info"
        Import-Module Microsoft.Graph.DeviceManagement.Enrollment -Force -ErrorAction Stop
        Update-ResultadoTextBox -TextBox $textBoxResultado -Message "Módulo 'Microsoft.Graph.DeviceManagement.Enrollment' carregado." -Type "Success"
    } catch {
        Update-ResultadoTextBox -TextBox $textBoxResultado -Message "Erro ao carregar 'Microsoft.Graph.DeviceManagement.Enrollment': $($_.Exception.Message). `nConsidere executar 'Update-Module Microsoft.Graph' em uma nova sessão PowerShell e reiniciar o aplicativo." -Type "Error"
        return "Erro: Falha ao carregar o módulo Microsoft.Graph.DeviceManagement.Enrollment."
    }

    $authResult = Autenticar-MicrosoftGraph # $authResult agora será sempre uma string
    if ($authResult -like "Erro*" -or $authResult -like "Falha*") {
        Update-ResultadoTextBox -TextBox $textBoxResultado -Message $authResult -Type "Error"
        return $authResult
    }
    Update-ResultadoTextBox -TextBox $textBoxResultado -Message $authResult -Type "Success"

    try {
        Update-ResultadoTextBox -TextBox $textBoxResultado -Message "Importando dispositivos do arquivo '$((Split-Path $csvFile -Leaf))'..." -Type "Info"
        $csvContent = Import-Csv $csvFile
        $importResults = @()
        foreach ($row in $csvContent) {
            if ([string]::IsNullOrWhiteSpace($row."Device Serial Number") -or `
                [string]::IsNullOrWhiteSpace($row."Hardware Hash") -or `
                [string]::IsNullOrWhiteSpace($row."Group Tag")) {
                $importResults += "Erro: Linha ignorada devido a dados ausentes (Serial, Hash ou Tag) para: $($row | Out-String)"
                continue
            }
            
            $params = @{
                GroupTag = $row."Group Tag"
                SerialNumber = $row."Device Serial Number"
                ProductKey = $row."Windows Product ID"
                HardwareIdentifier = [System.Convert]::FromBase64String($row."Hardware Hash") 
            }
            if (-not [string]::IsNullOrWhiteSpace($row."Assigned User")) {
                $params.AssignedUserPrincipalName = $row."Assigned User"
            }

            try {
                $response = New-MgDeviceManagementImportedWindowsAutopilotDeviceIdentity -BodyParameter $params
                $importResults += "Dispositivo $($row.'Device Serial Number') importado. ID: $($response.Id)"
            } catch {
                $errorMessage = $_.Exception.Message
                if ($_.Exception.Response) {
                    $errorResponse = $_.Exception.Response.GetResponseStream()
                    $reader = New-Object System.IO.StreamReader($errorResponse)
                    $errorText = $reader.ReadToEnd()
                    $reader.Close()
                    $errorMessage += " | Detalhes da API: $errorText"
                }
                $importResults += "Erro ao importar dispositivo $($row.'Device Serial Number'): $errorMessage"
            }
        }
        return "Processo de importação concluído.`n" + ($importResults -join "`n")
    }
    catch {
        return "Erro geral ao importar dispositivos via API: $($_.Exception.Message)"
    }
}
#endregion

#region Funções da UI (WinForms)
function Update-ResultadoTextBox {
    param (
        [Parameter(Mandatory=$true)]
        [System.Windows.Forms.TextBox]$TextBox,
        [Parameter(Mandatory=$true)]
        [string]$Message,
        [Parameter(Mandatory=$false)]
        [string]$Type = "Info"
    )
    $Timestamp = Get-Date -Format "HH:mm:ss"
    $FormattedMessage = "$Timestamp - $Message`r`n"
    
    $TextBox.AppendText($FormattedMessage)
    switch ($Type) {
        "Success" { $TextBox.ForeColor = $colorTextoSucesso } 
        "Error"   { $TextBox.ForeColor = $colorTextoErro }   
        default   { $TextBox.ForeColor = $colorTextoInfo } 
    }
    $TextBox.ScrollToCaret() 
}

function Show-WinFormsMessageBox ($message, $title, [System.Windows.Forms.MessageBoxButtons]$buttons = [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]$icon = [System.Windows.Forms.MessageBoxIcon]::Information) {
    return [System.Windows.Forms.MessageBox]::Show($message, $title, $buttons, $icon)
}
#endregion

#region Configuração do Formulário Principal
$form = New-Object System.Windows.Forms.Form
$form.Text = "Autopilot Import GUI (WinForms)"
$form.Size = New-Object System.Drawing.Size(650, 800) 
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
$form.MaximizeBox = $false
$form.MinimizeBox = $true
$form.BackColor = $colorFundoApp
$form.Font = $fontePadrao
#endregion

#region Controles da UI
$labelTituloApp = New-Object System.Windows.Forms.Label
$labelTituloApp.Text = "Autopilot Import GUI"
$labelTituloApp.Font = $fonteTitulo
$labelTituloApp.ForeColor = $colorTextoPrincipal
$labelTituloApp.AutoSize = $true
$labelTituloApp.Location = New-Object System.Drawing.Point(20, 20)
$form.Controls.Add($labelTituloApp)

$groupTagsPermitidas = New-Object System.Windows.Forms.GroupBox
$groupTagsPermitidas.Text = "TAGs Permitidas (Exemplos)"
$groupTagsPermitidas.Font = $fonteGroupBox
$groupTagsPermitidas.ForeColor = $colorTextoPrincipal
$groupTagsPermitidas.Location = New-Object System.Drawing.Point(20, ($labelTituloApp.Bottom + 15))
$groupTagsPermitidas.Size = New-Object System.Drawing.Size(590, 120)
$form.Controls.Add($groupTagsPermitidas)

$labelTagExemplo1 = New-Object System.Windows.Forms.Label; $labelTagExemplo1.Text = "• OMSBR"; $labelTagExemplo1.Location = New-Object System.Drawing.Point(15, 30); $labelTagExemplo1.AutoSize = $true; $labelTagExemplo1.Font = $fontePadrao; $labelTagExemplo1.ForeColor = $colorTextoPrincipal; $groupTagsPermitidas.Controls.Add($labelTagExemplo1)
$labelTagExemplo2 = New-Object System.Windows.Forms.Label; $labelTagExemplo2.Text = "• OMBRESP"; $labelTagExemplo2.Location = New-Object System.Drawing.Point(15, ($labelTagExemplo1.Bottom + 5)); $labelTagExemplo2.AutoSize = $true; $labelTagExemplo2.Font = $fontePadrao; $labelTagExemplo2.ForeColor = $colorTextoPrincipal; $groupTagsPermitidas.Controls.Add($labelTagExemplo2)
$labelTagExemplo3 = New-Object System.Windows.Forms.Label; $labelTagExemplo3.Text = "• OMSCOL"; $labelTagExemplo3.Location = New-Object System.Drawing.Point(15, ($labelTagExemplo2.Bottom + 5)); $labelTagExemplo3.AutoSize = $true; $labelTagExemplo3.Font = $fontePadrao; $labelTagExemplo3.ForeColor = $colorTextoPrincipal; $groupTagsPermitidas.Controls.Add($labelTagExemplo3)
$labelNotaTag = New-Object System.Windows.Forms.Label; $labelNotaTag.Text = "Nota: Insira a TAG exata requerida pelo seu ambiente."; $labelNotaTag.Location = New-Object System.Drawing.Point(15, ($labelTagExemplo3.Bottom + 10)); $labelNotaTag.AutoSize = $true; $labelNotaTag.Font = New-Object System.Drawing.Font($fontePadrao, [System.Drawing.FontStyle]::Italic); $labelNotaTag.ForeColor = $colorTextoPrincipal; $groupTagsPermitidas.Controls.Add($labelNotaTag)

$buttonExportHash = New-Object System.Windows.Forms.Button
$buttonExportHash.Text = "1. Capturar Hash do Hardware (.csv)"
$buttonExportHash.Size = New-Object System.Drawing.Size(590, 35)
$buttonExportHash.Location = New-Object System.Drawing.Point(20, ($groupTagsPermitidas.Bottom + 15))
$buttonExportHash.BackColor = $colorBotaoPrincipal
$buttonExportHash.ForeColor = $colorTextoBotao
$buttonExportHash.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$buttonExportHash.FlatAppearance.BorderSize = 0
$form.Controls.Add($buttonExportHash)

$groupExternalCsv = New-Object System.Windows.Forms.GroupBox
$groupExternalCsv.Text = "Ou Usar CSV de Dispositivos Externo"
$groupExternalCsv.Font = $fonteGroupBox
$groupExternalCsv.ForeColor = $colorTextoPrincipal
$groupExternalCsv.Location = New-Object System.Drawing.Point(20, ($buttonExportHash.Bottom + 10))
$groupExternalCsv.Size = New-Object System.Drawing.Size(590, 80)
$form.Controls.Add($groupExternalCsv)

$labelExternalCsv = New-Object System.Windows.Forms.Label
$labelExternalCsv.Text = "Arquivo CSV:"
$labelExternalCsv.Location = New-Object System.Drawing.Point(15, 35)
$labelExternalCsv.AutoSize = $true
$labelExternalCsv.Font = $fontePadrao
$labelExternalCsv.ForeColor = $colorTextoPrincipal
$groupExternalCsv.Controls.Add($labelExternalCsv)

$textBoxExternalCsvPath = New-Object System.Windows.Forms.TextBox
$textBoxExternalCsvPath.Location = New-Object System.Drawing.Point(120, 32)
$textBoxExternalCsvPath.Size = New-Object System.Drawing.Size(280, $textBoxExternalCsvPath.Height)
$textBoxExternalCsvPath.Font = $fontePadrao
$textBoxExternalCsvPath.ReadOnly = $true
$groupExternalCsv.Controls.Add($textBoxExternalCsvPath)

$buttonBrowseExternalCsv = New-Object System.Windows.Forms.Button
$buttonBrowseExternalCsv.Text = "Procurar CSV..."
$buttonBrowseExternalCsv.Location = New-Object System.Drawing.Point(410, 30)
$buttonBrowseExternalCsv.Size = New-Object System.Drawing.Size(165, 29)
$buttonBrowseExternalCsv.Font = $fontePadrao
$buttonBrowseExternalCsv.BackColor = $colorBotaoSecundario
$buttonBrowseExternalCsv.ForeColor = $colorTextoBotao
$buttonBrowseExternalCsv.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$buttonBrowseExternalCsv.FlatAppearance.BorderSize = 0
$groupExternalCsv.Controls.Add($buttonBrowseExternalCsv)

$groupGroupTag = New-Object System.Windows.Forms.GroupBox
$groupGroupTag.Text = "Configurar Group TAG"
$groupGroupTag.Font = $fonteGroupBox
$groupGroupTag.ForeColor = $colorTextoPrincipal
$groupGroupTag.Location = New-Object System.Drawing.Point(20, ($groupExternalCsv.Bottom + 15))
$groupGroupTag.Size = New-Object System.Drawing.Size(590, 80)
$form.Controls.Add($groupGroupTag)

$labelGroupTag = New-Object System.Windows.Forms.Label; $labelGroupTag.Text = "Group TAG:"; $labelGroupTag.Location = New-Object System.Drawing.Point(15, 35); $labelGroupTag.AutoSize = $true; $labelGroupTag.Font = $fontePadrao; $labelGroupTag.ForeColor = $colorTextoPrincipal; $groupGroupTag.Controls.Add($labelGroupTag)
$textBoxGroupTag = New-Object System.Windows.Forms.TextBox; $textBoxGroupTag.Location = New-Object System.Drawing.Point(120, 32); $textBoxGroupTag.Size = New-Object System.Drawing.Size(280, $textBoxGroupTag.Height); $textBoxGroupTag.Font = $fontePadrao; $groupGroupTag.Controls.Add($textBoxGroupTag)
$buttonSaveTag = New-Object System.Windows.Forms.Button; $buttonSaveTag.Text = "2. Salvar TAG"; $buttonSaveTag.Location = New-Object System.Drawing.Point(410, 30); $buttonSaveTag.Size = New-Object System.Drawing.Size(165, 29); $buttonSaveTag.Font = $fontePadrao; $buttonSaveTag.BackColor = $colorBotaoSecundario; $buttonSaveTag.ForeColor = $colorTextoBotao; $buttonSaveTag.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat; $buttonSaveTag.FlatAppearance.BorderSize = 0; $groupGroupTag.Controls.Add($buttonSaveTag)

$buttonGenerateCsv = New-Object System.Windows.Forms.Button
$buttonGenerateCsv.Text = "3. Gerar Arquivo de Importação (.csv)"
$buttonGenerateCsv.Size = New-Object System.Drawing.Size(590, 35)
$buttonGenerateCsv.Location = New-Object System.Drawing.Point(20, ($groupGroupTag.Bottom + 15))
$buttonGenerateCsv.BackColor = $colorBotaoPrincipal
$buttonGenerateCsv.ForeColor = $colorTextoBotao
$buttonGenerateCsv.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$buttonGenerateCsv.FlatAppearance.BorderSize = 0
$form.Controls.Add($buttonGenerateCsv)

$buttonImportDevices = New-Object System.Windows.Forms.Button
$buttonImportDevices.Text = "4. Importar Dispositivos via API Graph"
$buttonImportDevices.Size = New-Object System.Drawing.Size(590, 35)
$buttonImportDevices.Location = New-Object System.Drawing.Point(20, ($buttonGenerateCsv.Bottom + 10)) 
$buttonImportDevices.BackColor = $colorBotaoPrincipal
$buttonImportDevices.ForeColor = $colorTextoBotao
$buttonImportDevices.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$buttonImportDevices.FlatAppearance.BorderSize = 0
$form.Controls.Add($buttonImportDevices)

$groupStatus = New-Object System.Windows.Forms.GroupBox
$groupStatus.Text = "Status"
$groupStatus.Font = $fonteGroupBox
$groupStatus.ForeColor = $colorTextoPrincipal
$groupStatus.Location = New-Object System.Drawing.Point(20, ($buttonImportDevices.Bottom + 15))
$groupStatus.Size = New-Object System.Drawing.Size(590, 150) 
$form.Controls.Add($groupStatus)

$textBoxResultado = New-Object System.Windows.Forms.TextBox
$textBoxResultado.Location = New-Object System.Drawing.Point(15, 25)
$textBoxResultado.Size = New-Object System.Drawing.Size(560, 110) 
$textBoxResultado.Multiline = $true
$textBoxResultado.ScrollBars = "Vertical"
$textBoxResultado.ReadOnly = $true
$textBoxResultado.Font = $fonteStatus
$textBoxResultado.BackColor = [System.Drawing.Color]::White
$textBoxResultado.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Bottom -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right
$groupStatus.Controls.Add($textBoxResultado)

$buttonExit = New-Object System.Windows.Forms.Button
$buttonExit.Text = "Sair"
$buttonExit.Size = New-Object System.Drawing.Size(120, 35)
$xPosExitButton = ($form.ClientSize.Width - $buttonExit.Width) / 2
$yPosExitButton = $groupStatus.Bottom + 30
$buttonExit.Location = New-Object System.Drawing.Point($xPosExitButton, $yPosExitButton)
$buttonExit.BackColor = $colorBotaoPerigo
$buttonExit.ForeColor = $colorTextoBotao
$buttonExit.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$buttonExit.FlatAppearance.BorderSize = 0
$form.Controls.Add($buttonExit)
#endregion

#region Lógica dos Eventos
$buttonExportHash.Add_Click({
    Update-ResultadoTextBox -TextBox $textBoxResultado -Message "Capturando hash do hardware..." -Type "Info"
    $result = Capturar-HashDoHardware 
    $textBoxExternalCsvPath.Text = "" 
    if ($result -like "Erro*") {
        Update-ResultadoTextBox -TextBox $textBoxResultado -Message $result -Type "Error"
        Show-WinFormsMessageBox -message $result -title "Erro na Captura" -icon Error
    } else {
        Update-ResultadoTextBox -TextBox $textBoxResultado -Message $result -Type "Success"
        Show-WinFormsMessageBox -message $result -title "Captura Concluída" -icon Information
    }
})

$buttonBrowseExternalCsv.Add_Click({
    $openFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $openFileDialog.Title = "Selecionar Arquivo CSV de Dispositivos"
    $openFileDialog.Filter = "Arquivos CSV (*.csv)|*.csv|Todos os arquivos (*.*)|*.*"
    if ($openFileDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $global:ExternalCsvPath = $openFileDialog.FileName
        $textBoxExternalCsvPath.Text = $global:ExternalCsvPath
        Update-ResultadoTextBox -TextBox $textBoxResultado -Message "Arquivo CSV externo selecionado: $($global:ExternalCsvPath)" -Type "Info"
    }
})

$buttonSaveTag.Add_Click({
    $tag = $textBoxGroupTag.Text
    Update-ResultadoTextBox -TextBox $textBoxResultado -Message "Salvando TAG '$tag'..." -Type "Info"
    $result = Gravar-Tag -Tag $tag
    if ($result -like "Erro*") {
        Update-ResultadoTextBox -TextBox $textBoxResultado -Message $result -Type "Error"
        Show-WinFormsMessageBox -message $result -title "Erro ao Salvar TAG" -icon Error
    } else {
        Update-ResultadoTextBox -TextBox $textBoxResultado -Message $result -Type "Success"
        Show-WinFormsMessageBox -message $result -title "TAG Salva" -icon Information
    }
})

$buttonGenerateCsv.Add_Click({
    Update-ResultadoTextBox -TextBox $textBoxResultado -Message "Gerando arquivo AutopilotImport..." -Type "Info" 
    $result = Criar-AutopilotImportCSV
    if ($result -like "Erro*") {
        Update-ResultadoTextBox -TextBox $textBoxResultado -Message $result -Type "Error"
        Show-WinFormsMessageBox -message $result -title "Erro na Geração do CSV" -icon Error
    } else {
        Update-ResultadoTextBox -TextBox $textBoxResultado -Message ($result + "`nPróximo arquivo a ser importado (se aplicável): " + $global:LastGeneratedCsvPath) -Type "Success"
        Show-WinFormsMessageBox -message $result -title "CSV Gerado" -icon Information
    }
})

$buttonImportDevices.Add_Click({
    Update-ResultadoTextBox -TextBox $textBoxResultado -Message "Iniciando importação de dispositivos via API..." -Type "Info"
    $result = Importar-DispositivosAutopilotViaAPI
    if ($result -like "Erro*") {
        Update-ResultadoTextBox -TextBox $textBoxResultado -Message $result -Type "Error"
        Show-WinFormsMessageBox -message $result -title "Erro na Importação" -icon Error
    } else {
        Update-ResultadoTextBox -TextBox $textBoxResultado -Message $result -Type "Success"
        Show-WinFormsMessageBox -message "Processo de importação via API concluído. Verifique o status para detalhes." -title "Importação Concluída" -icon Information
    }
})

$buttonExit.Add_Click({
    $form.Close()
})
#endregion

#region Inicialização do Formulário
$form.Add_Shown({
    Update-ResultadoTextBox -TextBox $textBoxResultado -Message "Interface carregada. Aguardando ação." -Type "Info"
})

$form.Add_FormClosing({
})

$null = $form.ShowDialog()
$form.Dispose()
disconnect-mggraph
Write-Host "Aplicação Autopilot Import GUI encerrada."
#endregion