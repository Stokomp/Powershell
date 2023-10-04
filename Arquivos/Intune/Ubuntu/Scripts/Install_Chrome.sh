#!/bin/bash
# Adicionar a chave do repositório do Google Chrome
wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | sudo apt-key add -

# Adicionar o repositório do Google Chrome
echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" | sudo tee /etc/apt/sources.list.d/google-chrome.list

# Atualizar o cache do repositório de pacotes
sudo apt update

# Instalar o Google Chrome
sudo apt install google-chrome-stable -y