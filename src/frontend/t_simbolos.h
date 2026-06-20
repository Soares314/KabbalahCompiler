#ifndef T_SIMBOLOS_H
#define T_SIMBOLOS_H

// TODO: Adicionar escopo de variáveis
typedef struct Symbol {
    char name[50];
    char type[20];
    int scope_level;
} Symbol;

void add_symbol(char* , char*);
Symbol* get_symbol(char* name);
void enter_scope();
void exit_scope();
int get_scope();

#endif