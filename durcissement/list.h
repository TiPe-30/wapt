#ifndef LIST_H
#define LIST_H

#include <stdbool.h>

typedef struct word {
    char * letter_word;
    struct word * next_word;
}word_t;

typedef enum error {
    VALIDE,

}error_word_t;

extern error_word_t init_word (word_t * word_init, const char * letter_word);

extern error_word_t append_word_end (word_t * list_word, word_t * word_insert);

extern error_word_t append_word_begin (word_t * list_word, word_t * word_insert);

extern 

extern error_word_t clear_list (word_t * list_word);

#endif