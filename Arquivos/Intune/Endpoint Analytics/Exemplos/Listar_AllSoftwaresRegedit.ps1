# read all child keys (*) from all four locations and do not emit
# errors if one of these keys does not exist:
Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
                    'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*',
                    'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
                    'HKCU:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*' -ErrorAction Ignore |
# list only items with a displayname:
Where-Object DisplayName |
# show these registry values per item:
Select-Object -Property DisplayName, DisplayVersion, UninstallString, InstallDate |
# sort by displayname:
Sort-Object -Property DisplayName