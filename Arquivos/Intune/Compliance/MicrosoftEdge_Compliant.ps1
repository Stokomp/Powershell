<#Script de descoberta do Microsoft Edge#>


$Edge = Get-ItemProperty "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"|
        Where-Object { $_.DisplayName -like "*Microsoft Edge*" }

$IsEdgeInstalled = if ($Edge) { $true } else { $false }

$hash = @{
    EdgeInstalled = $IsEdgeInstalled
}

return $hash | ConvertTo-Json -Compress