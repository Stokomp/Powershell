# Parar o serviço de Entrega Otimizada (se estiver em execução)
Stop-Service -Name "DoSvc" -Force -ErrorAction SilentlyContinue

# Redefinir as configurações do serviço Delivery Optimization
sc.exe config DoSvc start= auto
sc.exe failure DoSvc reset= 0 actions= restart/60000

# Remover as configurações corrompidas
Remove-Item -Path "C:\ProgramData\Microsoft\Network\Downloader\*" -Force -Recurse -ErrorAction SilentlyContinue

# Re-registrar o serviço de Entrega Otimizada
$DORegPath = "HKLM:\SYSTEM\CurrentControlSet\Services\DoSvc"
if (Test-Path $DORegPath) {
    Remove-Item -Path $DORegPath -Recurse -Force
}

# Reinstalar o serviço de Entrega Otimizada
sc.exe create DoSvc binpath= "C:\Windows\System32\svchost.exe -k NetworkService -p" start= auto

# Iniciar o serviço de Entrega Otimizada
Start-Service -Name "DoSvc"

# Verificar o status do serviço
Get-Service -Name "DoSvc"