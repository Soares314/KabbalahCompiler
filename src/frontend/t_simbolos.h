#ifndef T_SIMBOLOS_H
#define T_SIMBOLOS_H

// TODO: Adicionar escopo de variáveis
typedef struct Symbol {
    char name[50];
    char type[20];
} Symbol;

void add_symbol(char* , char*);
Symbol* get_symbol(char* name);

#endif