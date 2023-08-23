<#Script de descoberta do NotePad ++#>

$NotePad = Get-ItemProperty "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"|
        Where-Object { $_.DisplayName -like "*Notepad++ (64-bit x64)*" }

$IsNotePadInstalled = if ($NotePad) { $true } else { $false }

$hash = @{
    NotePadInstalled = $IsNotePadInstalled
}

return $hash | ConvertTo-Json -Compress