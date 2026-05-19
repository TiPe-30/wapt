#!/bin/bash

services=("nginx" "waptserver" "wapttasks")

# tous les dossiers qu'il faut sauvegarder
doss_sauv=("/var/www/wapt" "/var/www/wapt-host" "/var/www/waptwua" \
"/var/www/wads" "/opt/wapt/conf" "/opt/wapt/waptserver/ssl" /var/www/*.json)

# on récupère la date pour dater la sauvegarde
date_jour=$(date --rfc-3339 date)

fichier_kerberos=/srv/"$date_jour"-http-krb5.keytab

# sauvegarde du fichier postgresql
fichier_postgresql=/srv/backup_wapt-"$date_jour".sql

for service in "${services[@]}";
  do 
    systemctl stop "$service"
  done

for element in "${doss_sauv[@]}";
  do
  
    # on créé une archive : https://axelstudios.github.io/7z/#!/
    fichier_archive="/srv/${element##/}-""$(date --rfc-3339 date)".7z

    if [[ -f "$fichier_archive" ]];
      then 
        # si une archive à déjà été faite dans la journée, on la supprime !
        rm "$fichier_archive"
      fi

    # on créé une archive : https://axelstudios.github.io/7z/#!/
    7z a -mx9 -mfb96 -ms1g -mmt3 "$fichier_archive" "$element"

    # on créé un checksums pour vérifier l'authenticité des fichiers
    sha256sum "$fichier_archive" | cut -d ' ' -f1 | sudo tee checksums-"$fichier_archive".txt

    # on téléverse le fichier archive sur le serveur de manière sécurisée
    scp checksums-"$fichier_archive".txt "$fichier_archive" root@192.189.2.2:C:\\Bonjour

  done

# sauvegarde du keytab kerberos
7z a -mx9 -mfb96 -ms1g -mmt3 /srv/"$date_jour"-http-krb5.keytab /etc/nginx/http-krb5.keytab
sha256sum "$fichier_kerberos" | cut -d ' ' -f1 | sudo tee checksums-"$fichier_kerberos".txt
# sauvegarde de la base de donnée postgresql
sudo -u postgres pg_dumpall | sudo tee "$fichier_postgresql" > /dev/null
sha256sum "$fichier_postgresql" | cut -d ' ' -f1 | sudo tee checksums-"$fichier_postgresql".txt
# on téléverse le fichiers 
scp "$fichier_postgresql" "$fichier_kerberos" checksums-"$fichier_kerberos".txt checksums-"$fichier_postgresql".txt 


for service in "${services[@]}";
  do 
    systemctl start "$service"
  done

