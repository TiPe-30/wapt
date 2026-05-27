#!/bin/bash

# Le script de sauvegarde des dossiers WAPT doit s'executer sur le compte root
# dans le crontab du super utilisateur. Tous les jours vers minuit, lorsqu'aucune 
# personne n'est connecté, et que la majorité des machines sont sensés être éteinte
# une sauvegarde est lancé ; et les données sont envoyés sur un serveur de fichiers
# de l'active directory : les informations présentes dans les variables devront
# être changé au fur et à mesure.


############################################################################
#                                  VARIABLE
############################################################################

# machine distante, nom d'utilisateur, et dossier dans lequel nous allons envoyer les sauvegardes
# et les archives.
readonly machine_sauv="Administrateur@192.220.19.38:F:\\projets\\sauvegarde_wapt"

# les services wapt doivent être arrété avant la sauvegarde
# et après la sauvegarde.
readonly services=("nginx" "waptserver" "wapttasks")

# tous les dossiers qu'il faut sauvegarder, on met -A pour un tableau associatif et l'option -r pour
# que le tableau soit uniquement accessible en lecture
declare -r -A doss_sauv=([wapt]="/var/www/wapt/" [wapt-host]="/var/www/wapt-host/" [waptwua]="/var/www/waptwua/" \
[wads]="/var/www/wads/" [conf]="/opt/wapt/conf/" [ssl]="/opt/wapt/waptserver/ssl/")

# on récupère la date pour dater la sauvegarde
date_jour=$(date --rfc-3339 date)
readonly date_jour
code_erreur=0

# le keytab de l'authentification kerberos avec active directory et les clients.
readonly fichier_kerberos="http-krb5.keytab-$date_jour"

# les fichiers json sont des fichiers et non des dossiers, il seront donc sauvegardés à part
readonly archive_json="archive-json-$date_jour.7z"
# sauvegarde du fichier postgresql
readonly fichier_postgresql="backup_pgsql-$date_jour.sql"

############################################################################
#                                  FONCTIONS
############################################################################

function logg_journalctl {

local message="[CRON-SAVE] $1 : $2"
  
  if [[ $1 = "SUCCESS" ]] || [[ $1 = "INFO" ]];
    then
      # man logger, afin d'avoir le manuel et comprendre les options.
      logger -p syslog.info "$message"
    else
      logger -p syslog.err "$message"
    fi

}

function save_directory {

local error=0

for element in "${!doss_sauv[@]}";
  do

    # permet de féfinir le lieu ou sera stocké l'archive
    # son nom : nom dossier-date du jour.7z
    fichier_archive="/srv/$element-$date_jour.7z"

    logg_journalctl "INFO" "Création de l'archive : $fichier_archive en cours..."

    # on créé une archive : https://axelstudios.github.io/7z/#!/
    7z a -mx9 -mfb96 -ms1g -mmt3 "$fichier_archive" "${doss_sauv[$element]}" > /dev/null
    error=$?
    
    # si une erreur a eu lieu, on l'affiche et sort de la boucle
    if [[ $error -ne 0 ]];
      then
        logg_journalctl "ERROR" "Erreur de création de l'archive $fichier_archive"
        return "$error"
      fi
    
    # on créé un checksums pour vérifier l'authenticité des fichiers
    sha256sum "$fichier_archive" | cut -d ' ' -f1 | sudo tee /srv/checksums-"$element-$date_jour".txt
    error=$?

    if [[ $error -ne 0 ]];
      then
        logg_journalctl "ERROR" "Erreur de création du checksums de $fichier_archive"
        return "$error"
      fi

    # on téléverse le fichier archive sur le serveur de manière sécurisée
    scp /srv/checksums-"$element-$date_jour".txt "$fichier_archive" "$machine_sauv" > /dev/null
    error=$?

    if [[ $error -ne 0 ]];
      then
        logg_journalctl "ERROR" "Erreur du télévérsement des fichiers $fichier_archive"
        return "$error"
      fi

    rm "$fichier_archive" /srv/checksums-"$element-$date_jour".txt
  done

  logg_journalctl "SUCCESS" "Tous les dossiers archive ont bien été envoyé sur le serveur !"

  return "$error"
}

function save_file {
  #/var/www/*.json
  # On sauvegarde et ajoute à l'arhive le json
  local error=0
  7z a -mx9 -mfb96 -ms1g -mmt3 /srv/"$archive_json" /var/www/*.json
  sha256sum /srv/"$archive_json" | cut -d ' ' -f1 | sudo tee /srv/checksums-"$archive_json".txt

  # sauvegarde du keytab kerberos
  7z a -mx9 -mfb96 -ms1g -mmt3 /srv/"$fichier_kerberos".7z /etc/nginx/http-krb5.keytab
  sha256sum /srv/"$fichier_kerberos".7z | cut -d ' ' -f1 | sudo tee /srv/checksums-"$fichier_kerberos".txt
  # sauvegarde de la base de donnée postgresql
  sudo -u postgres pg_dumpall | sudo tee /srv/"$fichier_postgresql" > /dev/null
  sha256sum /srv/"$fichier_postgresql" | cut -d ' ' -f1 | sudo tee /srv/checksums-"$fichier_postgresql".txt
  # on téléverse le fichiers 

  if scp /srv/"$archive_json" /srv/checksums-"$archive_json".txt /srv/"$fichier_postgresql" /srv/"$fichier_kerberos".7z \
  /srv/checksums-"$fichier_kerberos".txt /srv/checksums-"$fichier_postgresql".txt "$machine_sauv" > /dev/null;
    then
    # on supprime les fichiers générés
    rm /srv/"$archive_json" /srv/checksums-"$archive_json".txt /srv/"$fichier_postgresql" /srv/"$fichier_kerberos".7z \
  /srv/checksums-"$fichier_kerberos".txt /srv/checksums-"$fichier_postgresql".txt
    return "$error"
    else
      logg_journalctl "ERROR" "Les fichiers n'ont pas pu être correctement envoyé sur le serveur"
    fi 
}

############################################################################
#                             PROGRAMME
############################################################################

# ssh-agent ./sauv-wapt.sh pour lancer le programme
# on ajoute la clé ssh au trousseau de l'agent
ssh-add /home/srvwapt/.ssh/wapt

# on stoppe les services avant de réaliser la sauvegarde 
# comme dans la documentation
for service in "${services[@]}";
  do 
    systemctl stop "$service"
  done

# on sauvegarde 

code_erreur=$(save_directory)

if [[ $code_erreur -ne 0 ]];
  then
code_erreur=$(save_file)
  fi

for service in "${services[@]}";
  do 
    systemctl start "$service"
  done

exit "$code_erreur"