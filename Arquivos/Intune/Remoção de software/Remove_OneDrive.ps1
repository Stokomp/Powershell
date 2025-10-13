<# 
.SYNOPSIS
Remove o OneDrive completamente e bloqueia reinstalação.
Compatível com Windows 10 e 11.
#>

$LogPath = "$env:ProgramData\IntuneOneDriveRemoval.log"
Start-Transcript -Path $LogPath -Append

Write-Output "=== Remoção definitiva do OneDrive iniciada ==="

# Finaliza qualquer processo
Stop-Process -Name "OneDrive*" -Force -ErrorAction SilentlyContinue

# Desinstala o setup
$OneDrivePaths = @(
    "$env:SystemRoot\System32\OneDriveSetup.exe",
    "$env:SystemRoot\SysWOW64\OneDriveSetup.exe"
)
foreach ($path in $OneDrivePaths) {
    if (Test-Path $path) {
        Write-Output "Desinstalando via $path"
        Start-Process $path "/uninstall" -NoNewWindow -Wait
    }
}

# Remove pastas residuais
$Folders = @(
    "$env:UserProfile\OneDrive",
    "$env:LocalAppData\Microsoft\OneDrive",
    "$env:ProgramData\Microsoft OneDrive"
)
foreach ($f in $Folders) {
    if (Test-Path $f) { Remove-Item -Path $f -Recurse -Force -ErrorAction SilentlyContinue }
}

# Remove tarefas agendadas
Get-ScheduledTask | Where-Object {$_.TaskName -like "*OneDrive*"} | Unregister-ScheduledTask -Confirm:$false -ErrorAction SilentlyContinue

# Remove o app provisionado
$Provisioned = Get-AppxProvisionedPackage -Online | Where-Object DisplayName -like "*OneDrive*"
if ($Provisioned) {
    Write-Output "Removendo pacote provisionado..."
    $Provisioned | Remove-AppxProvisionedPackage -Online
}

# Bloqueia reinstalação via política
$Key = "HKLM:\Software\Policies\Microsoft\Windows\OneDrive"
New-Item -Path $Key -Force | Out-Null
Set-ItemProperty -Path $Key -Name "DisableFileSyncNGSC" -Type DWord -Value 1
Set-ItemProperty -Path $Key -Name "DisableFileSync" -Type DWord -Value 1

Write-Output "Remoção concluída. Verifique $LogPath para detalhes."
Stop-Transcript