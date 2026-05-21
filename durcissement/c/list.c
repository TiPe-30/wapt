#include "list.h"
#include <stdlib.h>
#include <stdio.h>
#include <string.h>

extern error_word_t init_word (word_t * word_init, const char * letter_word) {

    word_init = (word_t *) malloc(sizeof(word_t));

    if (word_init == NULL) 
        return ERROR_ALLOC_WORD;
    
    strncpy(word_init->letter_word,letter_word,MAX_SIZE_WORD);
    word_init->next_word = NULL;

    return VALIDE;
}

extern error_word_t append_word_end (word_t * list_word, word_t * word_insert){

    if (word_insert == NULL) 
        return WORD_NULL;

    if (list_word == NULL){
        list_word = word_insert;
    }else{
        if (list_word->next_word == NULL){
            list_word->next_word = word_insert;
        }else{
            while (list_word->next_word != NULL)
                list_word = list_word->next_word;
            
            list_word->next_word = word_insert;
        }
    }

    return VALIDE;
}

extern error_word_t append_word_begin (word_t * list_word, word_t * word_insert){
    if (word_insert == NULL) 
        return WORD_NULL;

    if (list_word == NULL){
        list_word = word_insert;
    }else{
        word_t * new_list = list_word;
        list_word = word_insert;
        word_insert->next_word = new_list;
    }


    return VALIDE;
}

extern bool word_is_present(word_t * list_word, word_t * word_check) {
    bool word_here = false;

    while (list_word != NULL && true != word_here){

        if (strncmp(list_word->letter_word, word_check->letter_word, MAX_SIZE_WORD) == 0)
            word_here = true;
        
        list_word = list_word->next_word;
    }

    return word_here;
}

extern void clear_list (word_t * list_word){
    word_t * precedente = list_word;
    word_t * courante = list_word->next_word;

    while(courante != NULL){
        free(precedente);
        precedente = courante;
        courante = courante->next_word;
    }

    free(precedente);

}

extern void print_list(word_t * list_word){
    while(list_word != NULL){
        printf("[%s]->",list_word->letter_word);
        list_word = list_word->letter_word;
    }
    puts("[NULL]");
}