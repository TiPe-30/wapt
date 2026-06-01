FROM ghcr.io/requarks/wiki:2

# image personnalisé afin de modifier le ssl
COPY my-config.yml /wiki/config.yml

# on copie la clé dans le dossier wiki 
COPY key.pem /wiki/wiki-key.pem

# on copie le certificat
COPY cert.pem /wiki/wiki-cert.pem