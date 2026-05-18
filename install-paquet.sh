#!/bin/bash

# Mettre à jour et à niveau le système d’exploitation et s’assurer que le paquet d’Autorités de Certification par défaut de Debian est installé.
apt update && apt upgrade
apt install ca-certificates -y

# Mettre à jour la source APT, récupérer la clé .gpg de Tranquil IT, puis ajouter le dépôt de Tranquil IT.
apt install apt-transport-https lsb-release gnupg wget -y
bash -c 'wget -qO- https://wapt.tranquil.it/$(lsb_release -is)/tiswapt-pub-2026.gpg > /usr/share/keyrings/tiswapt-pub.gpg'
echo "deb [signed-by=/usr/share/keyrings/tiswapt-pub.gpg] https://wapt.tranquil.it/$(lsb_release -is)/wapt-2.6/ $(lsb_release -c -s) main" > /etc/apt/sources.list.d/wapt.list

# Installer les paquets du Serveur WAPT.
export DEBIAN_FRONTEND=noninteractive
apt update
apt install tis-waptserver tis-waptsetup -y
unset DEBIAN_FRONTEND

