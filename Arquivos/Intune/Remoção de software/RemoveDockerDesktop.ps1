$Local = "C:\Program Files\Docker\Docker\"

$parametro = "uninstall --quiet"

cd $Local

start-process "Docker Desktop Installer.exe" -ArgumentList $parametro