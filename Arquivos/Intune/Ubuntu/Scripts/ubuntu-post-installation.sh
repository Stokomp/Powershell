#!/bin/bash
cd /tmp

#Install Figlet in snap 
snap install figlet

## Atualiza o sistema
figlet "Passo 1 -Atualizando o sistema"
apt update -y && apt upgrade -y

## Instala a engine de pacotes Flatpak
figlet "Passo 3 - Instala a engine de pacotes Flatpak"
apt install -y flatpak

## Adiciona o repositório oficial do Flatpak HUB 
figlet "Passo 4 - Adiciona o repositório oficial do Flatpak HUB"
add-apt-repository ppa:alexlarsson/flatpak -y

## Atualiza o flatpak engine
figlet "Passo 5 - Atualiza o flatpak engine"
apt -y install flatpak

## Instala a Gnome Software com suporte a FlatPak
figlet "Passo 6 - Instala a Gnome Software com suporte a FlatPak"
apt install -y gnome-software-plugin-flatpak

## Instala o Flathub se não existir
figlet "Passo 7- Instala o Flathub se não existir"
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo 

## Inicia o ciclo de instalação dos softwares necessários
figlet "Passo 8 - Inicia o ciclo de instalando Flatpak Softwares (VLC, LibreOffice, Remmina, Chromium, Teams)"
flatpak install -y org.videolan.VLC
flatpak install -y org.libreoffice.LibreOffice
flatpak install -y org.remmina.Remmina
flatpak install -y org.chromium.Chromium
flatpak install -y com.microsoft.Teams
flatpak install -y com.visualstudio.code

## Instalando Softwares em formato .DEB

figlet "Instalando softwares em pacotes formato .DEB"

## Instalando 7zip-full
figlet "Passo 9 - Instalando p7Zip-Full"
apt install -y p7zip-full

## Instala Google Chrome
figlet "Passo 10- Instalando Google Chrome"
wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
sudo apt install -y ./google-chrome-stable_current_amd64.deb

## Instala o Microsoft Edge Chromium
figlet "Passo 11 - Preparando para instalação do Microsoft Edge Chromium"
## Setup
curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg
install -o administrador -g administrador -m 644 microsoft.gpg /etc/apt/trusted.gpg.d/
sh -c 'echo "deb [arch=amd64] https://packages.microsoft.com/repos/edge stable main" > /etc/apt/sources.list.d/microsoft-edge-dev.list'
rm microsoft.gpg
## Install Edge Chromium
figlet "Passo 12 - Instalando Microsoft Edge Chromium"
apt -y update
apt install -y microsoft-edge-dev
apt -f install

## Limpa diretório corrente TMP
figlet "Passo 13- Limpando temp"
rm -r * 

## Limpa pacotes não mais necessários do sistema
figlet "Passo 14 - Verificando e limpando pacotes não mais necessarios se aplicavel"
apt autoremove -y

## Algumas alterações de log de sistema e NTP
figlet "Altera rotação de logs para 6 meses"
sed -i '10s/4/24/' /etc/logrotate.conf

## Join in Active Directory Domain
figlet "Passo 16 - nstala bibliotecas para associacao ao domínio"
apt -y install realmd sssd sssd-tools libnss-sss libpam-sss adcli samba-common-bin oddjob oddjob-mkhomedir packagekit
sed -i -e '$asession optional        pam_mkhomedir.so skel=/etc/skel umask=077' /etc/pam.d/common-session
realm discover tivit.corp

## Reinicie o sistema para efetuar as alterações
figlet "Passo 15 - Computador precisa ser reiniciado"