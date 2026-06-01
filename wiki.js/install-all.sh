#!/bin/bash

# Script d'installation du Wiki avec docker, ce wiki fonctionne avec une base de donnée
# postgresql, et permet de mettre en place une documentation.
# Une fois docker installé, donnez le groupe docker à l'utilisateur et redemmarez !

# on met en place un tableau pour ajouter plus facilement des 
# logiciels à installer !
logiciel=("docker" "docker-compose" "openssl")

# pour chaque logiciel, on vérifie que celui ci est bien installé !
for element in "${logiciel[@]}";
  do 
    if ! which "$element" > /dev/null ;
      then
        echo "Erreur : [logiciel : $element] n'est pas installé !"
        exit 1
      fi
  done

# création du certificat openssl
# docker exec -it [ID container] bash -> permet de se rendre dans le conteneur en cours
# d'éxecution.

# récupère le fichier config.yml dont nous avons besoins pour mettre en place le ssl
if [[ ! -f "./wiki/my-config.yml" ]];
  then 
    docker run -i --rm ghcr.io/requarks/wiki:2 cat /wiki/config.yml > ./wiki/my-config.yml
  fi 

# création d'un certificat autosigné
# il faudra par la suite un signé par une autorité de certification reconnue.
if [[ ! -f "./wiki/key.pem" ]] || [[ ! -f "./wiki/cert.pem" ]];
  then 
    
    # on signe le certfificat
    openssl req -new -x509 -nodes -out server.crt -keyout server.key

    # on convertit la clé et le certificat en format PEM
    # comme demandé dans la documentation
    openssl x509 -in server.crt -out ./wiki/cert.pem -outform PEM
    openssl rsa -in server.key -out ./wiki/key.pem

    # on change les permissions pour le docker
    chmod 644 ./wiki/key.pem ./wiki/cert.pem
    exit 3
  fi

# lancement de docker-compose
# permet de lancer le conteneur en mode détacher (persistent)
docker compose up -d

# pour voir les logs : docker compose logs (assurez vous d'être dans le répertoire
# de docker compose )