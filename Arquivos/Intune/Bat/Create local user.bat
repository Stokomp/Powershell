REM Arquivo bat criado para criar usuário local e colocar ele no grupo de adm local.

@echo off Criando o admin
net user Administrador01 Suasenhaaqui01 /add

@echo off Adicionar o Administrador01 no grupo de administradores locais
net localgroup administradores Administrador01 /add

@echo off Exportando log
@echo O usuário foi criado em %date%-%time% >> c:\Windows\temp\Administrador01.txt