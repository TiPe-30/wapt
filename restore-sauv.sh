#!/bin/bash

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

date=$1

fichier_restor=("/var/www/wapt/" "/var/www/wapt-host/" "/var/www/waptwua/" \
"/var/www/wads/" "/opt/wapt/conf/" "/opt/wapt/waptserver/ssl/" /var/www/*.json)

# on vérifie que tous les fichiers ont bien été téléversé sur le serveur
for archive in "${fichier_restor[@]}";
  do
    emplacement="/srv/${archive%%/}-""$date".7z
    if [[ ! -f "$emplacement" ]];
      then 
        echo "Le fichier $archive n'est pas disponible à l'emplacement : $emplacement"
        echo "Vous devez le rappatrier, ou alors le mettre dans le bon dossier"
        exit 1
      fi

    # si un dossier est déjà présent on le supprime
    if [[ -d "$archive" ]] || [[ -f "$archive" ]];
      then 
        rm "$archive"
      fi

    7z x "$archive" "$emplacement"

  done


