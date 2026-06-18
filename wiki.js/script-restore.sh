#!/bin/bash


# pour la restauration
# on mont le volume dans lequel on veut restaurer, on décompresse, et on quitte
docker run --rm --mount type=volume,src=wikijs_db-data,dst=/rep-save \
  -v $(pwd):/backup --name wiki-restor ubuntu \
  bash -c "cd /rep-save && tar xvf /backup/backup.tar --strip 1"

# on supprime le conteneur et l'image associé
docker image rm ubuntu:latest