#!/bin/bash

doss_sauv=("/var/www/wapt/" "/var/www/wapt-host/" "/var/www/waptwua/" \
"/var/www/wads/" "/opt/wapt/conf/" "/opt/wapt/waptserver/ssl/" "/var/www/*.json")


for element in "${doss_sauv[@]}";
  do
    # on créé une archive : https://axelstudios.github.io/7z/#!/
    fichier_archive="/srv${element%%/}-""$(date --rfc-3339 date)".7z
    if [[ -f "$fichier_archive" ]];
      then 
        rm "$fichier_archive"
      fi

    7z a -mx9 -mfb96 -ms1g -mmt3 "$fichier_archive" "$element"
    scp "$fichier_archive" root@192.189.2.2:C:\\Bonjour

  done

