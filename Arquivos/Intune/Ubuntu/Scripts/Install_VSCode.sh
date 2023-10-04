#!/bin/bash
# Atualizar o cache do repositório de pacotes
sudo apt update

# Instalar as dependências necessárias
sudo apt install -y curl software-properties-common apt-transport-https

# Adicionar a chave de assinatura do repositório do VS Code
curl -sSL https://packages.microsoft.com/keys/microsoft.asc | sudo apt-key add -

# Adicionar o repositório do VS Code
sudo add-apt-repository "deb [arch=amd64] https://packages.microsoft.com/repos/vscode stable main"

# Atualizar o cache do repositório de pacotes novamente
sudo apt update

# Instalar o Visual Studio Code
sudo apt install -y code