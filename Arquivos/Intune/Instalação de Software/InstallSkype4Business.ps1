######################
# Variables #
######################
$LocalPath = "c:\temp\s4b-basic2016\"
$URI = 'https://download.microsoft.com/download/B/C/7/BC7CC6F0-9928-4F22-BAF0-DAFCA9468AEF/LyncEntry_bypass_ship_x64_pt-br_exe/lyncentry.exe'
$xml_uri1 = "https://samgmtlab.blob.core.windows.net/repository/reinstalls4b.xml?sp=r&st=2021-09-22T14:30:59Z&se=2022-08-24T22:29:59Z&spr=https&sv=2020-08-04&sr=b&sig=WkPZMNV7JhG0ayJId97x6eTVqko9m2jFBMaBxQaILB4%3D"
$xml_uri2 = "https://samgmtlab.blob.core.windows.net/repository/uninstalls4b.xml?sp=r&st=2021-09-22T15:59:38Z&se=2022-09-14T23:59:38Z&spr=https&sv=2020-08-04&sr=b&sig=tD1vm6d8MMO6mFFLaxDYkk7HEBVW6BVIf4gX4TcFmlI%3D"
$xml_file1 = "C:\temp\s4b-basic2016\lync\reinstalls4b.xml"
$xml_file2 = "C:\temp\s4b-basic2016\lync\uninstalls4b.xml"
$Installer = 'lyncentry.exe'


####################################
# Test/Create Temp Directory #
####################################

#New-Item -Path c:\ -Name s4b-basic2016.log -ItemType File

if((Test-Path c:\temp) -eq $false) {
Add-Content -LiteralPath C:\s4b-basic2016.log "Create C:\temp Directory"
Write-Host `
-ForegroundColor Cyan `
-BackgroundColor Black `
"creating temp directory"
New-Item -Path c:\temp -ItemType Directory
}
else {
Add-Content -LiteralPath C:\s4b-basic2016.log "C:\temp Already Exists"
Write-Host `
-ForegroundColor Yellow `
-BackgroundColor Black `
"temp directory already exists"
}
if((Test-Path $LocalPath) -eq $false) {
Add-Content -LiteralPath C:\s4b-basic2016.log "Create C:\temp\s4b directory"
Write-Host `
-ForegroundColor Cyan `
-BackgroundColor Black `
"creating c:\temp\s4b directory"
New-Item -Path $LocalPath -ItemType Directory
}
else {
Add-Content -LiteralPath C:\s4b-basic2016.log "C:\temp\S4B Already Exists"
Write-Host `
-ForegroundColor Yellow `
-BackgroundColor Black `
"c:\temp\s4b directory already exists"
}
if((Test-Path C:\temp\s4b-basic2016\lync) -eq $false) {
Add-Content -LiteralPath C:\s4b-basic2016.log "Create lync Directory"
Write-Host `
-ForegroundColor Cyan `
-BackgroundColor Black `
"creating lync directory"
New-Item -Path C:\temp\s4b-basic2016\lync -ItemType Directory
}
else {
Add-Content -LiteralPath C:\s4b-basic2016.log "lync Already Exists"
Write-Host `
-ForegroundColor Yellow `
-BackgroundColor Black `
"lync directory already exists"
}

######################
# Download S4B #
######################
Write-Host "Downloading S4B"
Add-Content -LiteralPath C:\s4b-basic2016.log "Downloading S4B"
Invoke-WebRequest -Uri $URI -OutFile "$LocalPath$Installer"

Write-Host "Extracting lyncentry.exe"
Add-Content -LiteralPath C:\s4b-basic2016.log "Extracting lyncentry.exe"
Set-Location $LocalPath
.\lyncentry.exe /extract:C:\temp\s4b-basic2016\lync /quiet

Write-Host "Sleeping for 60 seconds"
Start-Sleep -Seconds 60

######################
# Download XML #
######################

Write-Host "Downloading XML 1"
Add-Content -LiteralPath C:\s4b-basic2016.log "Downloading XML 1"
$webclient = New-Object System.Net.WebClient
$webclient.DownloadFile($xml_uri1,$xml_file1)

Write-Host "Downloading XML 2"
Add-Content -LiteralPath C:\s4b-basic2016.log "Downloading XML 2"
$webclient = New-Object System.Net.WebClient
$webclient.DownloadFile($xml_uri2,$xml_file2)

#####################
# Install S4B #
#####################

Write-Host "Installing S4B"
Add-Content -LiteralPath C:\s4b-basic2016.log "Installing S4B"
Set-Location $LocalPath\lync
.\setup.exe /config .\reinstalls4b.xml

Write-Host "Sleeping for 180 seconds"
Add-Content -LiteralPath C:\s4b-basic2016.log "Sleeping for 180 seconds"
Start-Sleep -Seconds 180

#####################
# Uninstall S4B #
#####################

Write-Host "Uninstalling S4B"
Add-Content -LiteralPath C:\s4b-basic2016.log "Uninstalling S4B"
Set-Location "C:\Program Files\Common Files\Microsoft Shared\OFFICE16\Office Setup Controller"
.\setup.exe /uninstall LYNCENTRY /dll OSETUP.DLL /config $xml_file2

Write-Host "Sleeping for 120 seconds"
Add-Content -LiteralPath C:\s4b-basic2016.log "Sleeping for 120 seconds"
Start-Sleep -Seconds 120