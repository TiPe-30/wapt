#!/bin/bash

############################################################################
#                                  VARIABLE
############################################################################

readonly machine_sauv="Administrateur@192.220.19.38:F:\\projets\\sauvegarde_wapt"

readonly services=("nginx" "waptserver" "wapttasks")

# tous les dossiers qu'il faut sauvegarder
declare -A doss_sauv=([wapt]="/var/www/wapt/" [wapt-host]="/var/www/wapt-host/" [waptwua]="/var/www/waptwua/" \
[wads]="/var/www/wads/" [conf]="/opt/wapt/conf/" [ssl]="/opt/wapt/waptserver/ssl/")

readonly doss_sauv
# on récupère la date pour dater la sauvegarde
date_jour=$(date --rfc-3339 date)
readonly date_jour

readonly fichier_kerberos="http-krb5.keytab-$date_jour"

readonly archive_json="archive-json-$date_jour.7z"
# sauvegarde du fichier postgresql
readonly fichier_postgresql="backup_pgsql-$date_jour.sql"

############################################################################
#                             PROGRAMME
############################################################################

# ssh-agent ./sauv-wapt.sh pour lancer le programme
ssh-add /home/srvwapt/.ssh/wapt
# on stoppe les services avant de réaliser la sauvegarde 
# comme dans la documentation
for service in "${services[@]}";
  do 
    systemctl stop "$service"
  done

for element in "${!doss_sauv[@]}";
  do
  
    # on créé une archive : https://axelstudios.github.io/7z/#!/
    fichier_archive="/srv/$element-$date_jour.7z"

    # on créé une archive : https://axelstudios.github.io/7z/#!/
    7z a -mx9 -mfb96 -ms1g -mmt3 "$fichier_archive" "${doss_sauv[$element]}"
    
    # on créé un checksums pour vérifier l'authenticité des fichiers
    sha256sum "$fichier_archive" | cut -d ' ' -f1 | sudo tee /srv/checksums-"$element-$date_jour".txt

    # on téléverse le fichier archive sur le serveur de manière sécurisée
    scp /srv/checksums-"$element-$date_jour".txt "$fichier_archive" "$machine_sauv"
    rm "$fichier_archive" /srv/checksums-"$element-$date_jour".txt
  done

#/var/www/*.json
# On sauvegarde et ajoute à l'arhive le json
7z a -mx9 -mfb96 -ms1g -mmt3 /srv/"$archive_json" /var/www/*.json
sha256sum /srv/"$archive_json" | cut -d ' ' -f1 | sudo tee /srv/checksums-"$archive_json".txt

# sauvegarde du keytab kerberos
7z a -mx9 -mfb96 -ms1g -mmt3 /srv/"$fichier_kerberos".7z /etc/nginx/http-krb5.keytab
sha256sum /srv/"$fichier_kerberos" | cut -d ' ' -f1 | sudo tee /srv/checksums-"$fichier_kerberos".txt
# sauvegarde de la base de donnée postgresql
sudo -u postgres pg_dumpall | sudo tee /srv/"$fichier_postgresql" > /dev/null
sha256sum /srv/"$fichier_postgresql" | cut -d ' ' -f1 | sudo tee /srv/checksums-"$fichier_postgresql".txt
# on téléverse le fichiers 
scp /srv/"$archive_json" /srv/checksums-"$archive_json".txt /srv/"$fichier_postgresql" /srv/"$fichier_kerberos".7z \
 /srv/checksums-"$fichier_kerberos".txt /srv/checksums-"$fichier_postgresql".txt "$machine_sauv"

rm /srv/"$archive_json".txt /srv/"$fichier_postgresql" /srv/"$fichier_kerberos".7z \
 /srv/checksums-"$fichier_kerberos".txt /srv/checksums-"$fichier_postgresql".txt

for service in "${services[@]}";
  do 
    systemctl start "$service"
  done

