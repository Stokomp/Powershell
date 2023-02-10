REM Arquivo bat criado para criar usuário local e colocar ele no grupo de adm local.

@echo off Criando Pernalonga
net user Pernalonga Pa$$w0rd /add

@echo off Adicionar Pernalonga no grupo de administradores locais
net localgroup administradores Pernalonga /add

@echo off Exportando log
@echo A senha foi alterada em %date%-%time% >> c:\Windows\temp\ChangePassword.txt