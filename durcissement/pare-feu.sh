#!/bin/bash

systemctl enable nftables.service

cat <<PARE-FEU > /etc/nftables.conf
#!/usr/sbin/nft -f

flush ruleset

# on déinit ici les adresse valide en entrée
define address_input_valid = { 22, 80, 443 }

#on définit ici les réseaux et sous réseaux ou on accepte une connexion ssh (réseaux admins)
define valid_net_ssh = { 195.220.20.96/27 }

# on définit les ports valide que le serveur peut utiliser pour faire des requêtes

define address_output_valid_tcp = { 80, 443, 53, 389, 636 }

define address_output_valid_udp = { 123, 88, 464, 53 }

# on définit l'ip du serveur active directory
define ip_ad = 10.10.0.5

table inet filter {

  chain input {

    type filter hook input priority filter; policy drop;

    jump security

    ct state established, related accept

    iif lo accept

    # si il s'agit bien de la plage de port que l\' on a définit va dans la chaine de filter_input

    tcp dport $address_input_valid limit rate 15/second goto filter_input

  }

  chain filter_input {

    tcp dport 443 ct state new log prefix "New HTTPS connexion from : " accept

    tcp dport 80 ct state new log prefix "New HTTP connexion from : " accept

    ip saddr $valid_net_ssh tcp dport 22 ct state new log prefix "New SSH connexion from : " accept

  }



  chain output {

    type filter hook output priority filter; policy drop;

    jump security

    ct state established, related accept

    oif lo accept
    # si les ports sont les bons on va dans la chaine address_output_valid_tcp et on limite le traffic

    tcp dport $address_output_valid_tcp limit rate 10/second goto filter_output_tcp

    # meme chose, la limitation du traffic permet de se prémunir contre les attaques dos

    udp dport $address_output_valid_udp limit rate 10/second goto filter_output_udp

  }

  chain filter_output_tcp {

    ip daddr $ip_ad goto filter_active_directory

    tcp dport { http, https } goto filter_repo_update

  }

  chain filter_active_directory {

    # résolution dns nécessaire pour les noms de domaine ldp ou internet

    # afin de télécharger les paquets

    tcp dport 53 ct state new log prefix "New DNS Controll domain to : " accept

    tcp dport 389 ct state new log prefix "New LDAP Auth to : " accept

    tcp dport 636 ct state new log prefix "New LDAPS Auth to : " accept

  }



  chain filter_repo_update {

    tcp dport 443 ct state new log prefix "New HTTPS request to : " accept

    tcp dport 80 ct state new log prefix "New HTTP request to : " accept

    # permet une résolution dns lorsque l'on veut résoudre les noms pour les requêtes HTTPS.

  }



  chain filter_output_udp {

    udp dport 123 ct state new log prefix "New NTP request to : " accept

    udp dport 88 ct state new log prefix "New Kerberos request to : " accept

    udp dport 464 ct state new log prefix "New LDAP controll request to : " accept

    ip daddr $ip_ad udp dport 53 ct state new log prefix "New DNS request to : " accept

  }



  chain security {

    # premier niveau qui permet de loger le traffic invalide

    ct state invalid log prefix "Bad connexion from : " drop

    # permet de détecter les paquets XMAS et les supprimer

    tcp flags & (fin|syn|rst|psh|ack|urg) == fin|syn|rst|psh|ack|urg log prefix "Invalid XMAS flags detected : " drop

    # si un paquet est null (sans flags tcp) on le drop

    tcp flags == 0 log prefix "Invalid NULL flags detected : " drop

  }

}
PARE-FEU

iconv -f UTF-8 -t ASCII//TRANSLIT /etc/nftables.conf -o /etc/nftables.conf
systemctl restart nftables.service
