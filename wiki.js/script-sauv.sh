#!/bin/bash

# @author Tristan Petit

# pour la sauvegarde, nous montons le volume déjà créé
# en leture seule dans le répertoire /rep-save
# puis, nous montons le répertoire courant de l'ordinateur dans le répertoire
# backup qui est lui dans le conteneur, et l'on créé dedans une archive des elements
# contenues dans le volume wikijs_db-data
docker run --rm --mount type=volume,src=wikijs_db-data,dst=/rep-save,ro \
  -v $(pwd):/backup --name wiki-save ubuntu tar cvf /backup/backup.tar /rep-save

# cela vient créer dans le réperoire courant un fichier backup.tar

# on l'image associé qui sont maintenant inutile
docker image rm ubuntu:latest