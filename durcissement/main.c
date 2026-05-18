#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <errno.h>
#include <time.h>

#define NB_MESURE_TEMP 30

typedef struct releve {
    int temperature;
    struct releve * releve_suivante;
}releve_t;

/**
 * Initialise une releve vide donné en paramètre, avec le paramètre 
 * de type entier qu'elle contient.
 */
int init_releve_param(releve_t * releve_d, int temperature_p){

    // on alloue de la mémoire pour pouvoir acceuillir les données d'une releve
    // le pointeur renvoyant (void *) celui ci se doit être convertit.
    releve_t * releve = (releve_t *) malloc(sizeof(releve_t));

    // si releve vaut NULL, cela veut dire que malloc a échoué
    if (releve == NULL){
        // on renvoie l'erreur dans errno !
        return errno;
    }

    // on met en place la valeur 
    releve->temperature = temperature_p;
    // pour le moment aucune releve suivante : donc NULL.
    releve->releve_suivante = NULL;

    // on sauvegarde l'adresse de la releve créé dans 
    // le pointeur fournit en paramètre.
    releve_d = releve;

    // si nous sommes arrivés ici, aucune erreur, 
    // donc nous rennvoyons EXIT_SUCCESS soit 0.
    // en langage C, 0 signifie true sinon false.
    return EXIT_SUCCESS;
}

int main(void){
    
    srand(time(NULL));

    releve_t * premiere_releve = NULL, * releve_courante = NULL;

    for (uint8_t i = 0; i < NB_MESURE_TEMP; i++){
        
    }
    

    return EXIT_SUCCESS;
}