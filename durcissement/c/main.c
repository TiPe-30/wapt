#include <unistd.h>
#include <stdlib.h>
#include <stdio.h>
#include <stdint.h>
#include <string.h>
#include <errno.h>
#include "list.h"

#define SIZE_BUFFER 512
#define NB_CHAR_SPLIT 7

static int decoupe_word_to_string(const char * file_name, word_t *list_init){

    FILE * file_get_token = fopen(file_name,"r");
    char buffer[SIZE_BUFFER];
    const char char_split[NB_CHAR_SPLIT] = {')','(', ' ', ',', ';', '.', ':'};
    error_word_t error_status = VALIDE;

    if (file_get_token == NULL){
        return errno;
    }

    while ((fgets(buffer,SIZE_BUFFER,file_get_token)) != NULL && error_status == VALIDE){

        char * courant = strtok(buffer,char_split);
        word_t * word_courant = NULL;

        while (courant != NULL && error_status == VALIDE){

            error_status = init_word(word_courant,courant);
            
            if (error_status == VALIDE){
                append_word_end(list_init,word_courant);
            }
            
        }

    }

    fclose(file_get_token);

    return (int)error_status;
}

int main(void)
{

    

    return EXIT_SUCCESS;
}