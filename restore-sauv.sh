#!/bin/bash

# le script de restauration permet d'éviter que 

############################################################################
#                               VERIFICATIONS
############################################################################

if [[ "$*" -eq 1 ]];
  then 
    echo "Vous devez fournir la date de la sauvegarde que vous souhaitez restaurer !"
    echo "La date s'obtiens avec : (date --rfc-3339 date) au format YYYY-MM-DD"
    exit 1
  fi

# vérfification du format de la date
# Le wiki : https://fr.wikibooks.org/wiki/Programmation_Bash/Regex
# Le debbuger : https://regex101.com/
if [[ ! "$1" =~ ^[0-9]{4}(-[0-9]{2}){2}$ ]];
  then 
    echo "Le format de la date de la restauration n'est pas la bonne !"
    exit 1
  fi

# vérifier la plage des valeurs en question :

annee=${date:0:4}
month=${date:5:2}
day=${date:8:2}

if (( "$annee" < 2026 )) || (( "$annee" > $(date +%Y) ));
  then
    echo "L'année rentrée est invalide"
    exit 1
  fi 

if (( "$month" < 1 )) || (( "$month" > 12 ));
  then
    echo "Le mois rentrée est invalide"
    exit 1
  fi

if (( "$day" < 1 )) || (( "$day" > 31 ));
  then
    echo "Le jour rentrée est invalide"
    exit 1
  fi


############################################################################
#                                  VARIABLE
############################################################################

# la machine, et le répertoire des sauvegarde
readonly machine_sauv="Administrateur@192.220.19.38:F:/projets/sauvegarde_wapt"

# la date de la sauvegarde une fois qu'elle est vérifié
declare -r date=$1

# le code d'erreur est déclaré comme un entier
declare -i error_code=0

# les services de wapt qui se doivent d'être arrêté et redeammé ensuite
declare -r -a services=("nginx" "waptserver" "wapttasks")

# tableau avec d'une part les noms de dossier qu'il est requis d'avoir dans lesquels ont veut restaurer l'archive 
# en valeur : en clé -> le nom de l'archive (dossier concerné) ; et en valeur associé -> le dossier d'arrivé des répertoires
declare -r -A archive_restor=([wapt]="/var/www/" [wapt-host]="/var/www/" [waptwua]="/var/www/" \
[wads]="/var/www/" [conf]="/opt/wapt/" [ssl]="/opt/wapt/waptserver/" [archive-json]="/var/www/")

# le keytab kerberos (nom seul) a restaurer
readonly kerberos_keytab="http-krb5.keytab-$date"

# le nom du backup de la base de donnée
readonly pgsql_bdd="backup_pgsql-$date"

############################################################################
#                                FONCTIONS
############################################################################

function recuper_doss_serveur {
  
  local error=0
  for archive in "${!archive_restor[@]}";
    do
      # on reconsitue le nom de l'archive distante
      archive_distante="$archive-$date.7z"
      checksums_distant="checksums-$archive-$date.txt"

      # on téléverse l'archive et son checksums
      scp "$machine_sauv/$archive_distante" "$machine_sauv/$checksums_distant" /srv/ > /dev/null
      error=$?
      

      if [[ $error -ne 0 ]];
        then 
          echo "Problème de récupération de l'archive et du checksums"
          return "$error"
        fi

      echo "La sauvegarde $machine_sauv/$archive_distante est téléhargé avec succès"

      # avant de restaurer la sauvegarde, nous vérifions qu'aucun problème n'est apparu lors du transit
      # des packages, et nous verifions donc l'intégrité de celle-ci avec la comparaison du checksums comme 
      # nous avons reçu l'archive par rapport à ce qu'il devrait être
      checksums_local=$(sha256sum /srv/"$archive_distante" | cut -d ' ' -f1 )

      if [[ "$checksums_local" != "$(cat /srv/"$checksums_distant")" ]];
        then
          echo "Problème de checksums l'archive téléchargé ne correspond pas !"
          return 1
        fi

      # on restaure la sauvegarde
      sync; echo 3 > /proc/sys/vm/drop_caches
      7z x /srv/"$archive_distante" -o"${archive_restor[$archive]}" -y > /dev/null
      error=$?

      if [[ $error -ne 0 ]];
        then
          echo "Erreur d'extraction de /srv/$archive_distante dans ${archive_restor[$archive]}"
          return "$error"
        fi

      echo "L'archive /srv/$archive_distante restauré correctement en ${archive_restor[$archive]}/$archive"
    done
  return "$error"
}

function recuper_file {

  local checksums_local=""
  local error=0

  scp "$machine_sauv/$kerberos_keytab".7z "$machine_sauv/$pgsql_bdd".sql \
  "$machine_sauv/checksums-$kerberos_keytab".txt "$machine_sauv/checksums-$pgsql_bdd".txt /srv/ > /dev/null
  error=$?  

  if [[ $error -ne 0 ]];
    then
      echo "Problème d'acquisition des fichiers kerberos et pgsql"
      return "$error"
    fi 

  checksums_local=$(sha256sum /srv/"$pgsql_bdd".sql | cut -d ' ' -f1)

  if [[ $checksums_local != "$(cat /srv/checksums-"$pgsql_bdd".txt)" ]];
    then
      echo "Le checksums de la base de données n'est pas le meme que celui distant !"
      return 2
    fi

  cd /srv || return 1
  sudo -u postgres psql -c "drop database wapt"
  sudo -u postgres psql -c "create database wapt with owner=wapt encoding='utf-8'"
  cat /srv/"$pgsql_bdd".sql | sudo -u postgres psql
  error=$?

  if [[ $error -ne 0 ]];
    then
      echo "Problème, la base de donnée n'a pu être restauré"
      return "$error"
    fi
  
  echo "La base de donnée à été restaurée avec succès"

  checksums_local=$(sha256sum  /srv/"$kerberos_keytab".7z | cut -d ' ' -f1)

  if [[ $checksums_local != "$(cat /srv/checksums-"$kerberos_keytab".txt)" ]];
    then
      echo "Le checksums de la base de données n'est pas le meme que celui distant !"
      return 2
    fi

  # on restaure le fichier kerberos
  7z x /srv/"$kerberos_keytab".7z -o/etc/nginx/ -y > /dev/null
  error=$?

  if [[ $error -ne 0 ]];
    then
      echo "Le fichier kerberos n'a pu être correctement restauré !"
      return "$error"
    fi

  sudo chmod 640 /etc/nginx/http-krb5.keytab
  sudo chown root:www-data /etc/nginx/http-krb5.keytab

  echo "Le fichier /etc/nginx/http-krb5.keytab a bien été restauré !"

  return "$error"
}

############################################################################
#                             PROGRAMME
############################################################################

# Première étape : récupérer les données correctement
# Un fois récupéré, faire la sauvegarde

# ssh-agent ./restore-wapt.sh pour lancer le programme
# on ajoute la clé ssh au trousseau de l'agent
ssh-add /home/srvwapt/.ssh/wapt

# on stoppe les services avant de réaliser la sauvegarde 
# comme dans la documentation
for service in "${services[@]}";
  do 
    systemctl stop "$service"
  done


error_code=$(recuper_doss_serveur)

# on remet les permissions telles quelles
chown -R wapt:www-data /var/www/wapt/ /var/www/wapt-host/ /var/www/waptwua/ /var/www/wads/ 
chown -R wapt /opt/wapt/conf/ /opt/wapt/waptserver/ssl/
chown wapt:www-data /var/www/*.jsonsa

if [[ $error_code -eq 0 ]];
  then
    error_code=$(recuper_file)
  fi

# on redemmare les services que l'on avait stoppé
# lors de la sauvegarde, afin de remettre le serveur en état de marche
for service in "${services[@]}";
  do
    systemctl start "$service"
  done

# on supprime les archives et les fichiers
rm /srv/*"$date"*

# on retourne le code du programme : 0 si tout c'est bien passé
# sinon un code d'errreur
exit "$error_code"