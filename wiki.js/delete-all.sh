#!/bin/bash

docker compose stop

# suppression des conteneurs
for element in $(docker container ls -a | awk '{print $1}' | grep -v CONTAINER) ;
  do 
    docker container rm "$element"
  done

#suppression des volumes
for element in $(docker volume ls | awk '{print $2}' | grep -v 'VOLUME') ;
  do 
    docker volume rm "$element"
  done

#suppression des images
for element in $(docker image ls | awk '{print $3}' | grep -v 'IMAGE') ;
  do 
    docker image rm "$element"
  done