FROM postgres:18-alpine

# on met en place la connexion provenant d'ailleurs que celle locale
RUN echo "host all all all $POSTGRES_HOST_AUTH_METHOD" >> pg_hba.conf