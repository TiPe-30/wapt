#ifndef LIST_H
#define LIST_H

#include <stdbool.h>

#define MAX_SIZE_WORD 64

typedef struct word {
    char * letter_word;
    struct word * next_word;
}word_t;

typedef enum error {
    VALIDE,
    ERROR_ALLOC_WORD,
    WORD_NULL
}error_word_t;

extern error_word_t init_word (word_t * word_init, const char * letter_word) __attribute__((nonnull (2)));

extern error_word_t append_word_end (word_t * list_word, word_t * word_insert);

extern error_word_t append_word_begin (word_t * list_word, word_t * word_insert);

extern bool word_is_present(word_t * list_word, word_t * word_check) __attribute__ ((nonnull));

extern void print_list(const word_t * list_word);

extern void clear_list (word_t * list_word);

#endif