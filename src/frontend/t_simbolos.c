#include <stdio.h>
#include <stdlib.h>
#include <stddef.h>
#include <string.h>
#include "t_simbolos.h"

Symbol symTable[100];
int symCount = 0;

void add_symbol(char* type, char* name) {
    for(int i = 0; i < symCount; i++) {
        if(strcmp(symTable[i].name, name) == 0) {
            printf("Erro Semântico: Variável '%s' já declarada!\n", name);
            exit(1);
        }
    }
    strcpy(symTable[symCount].type, type);
    strcpy(symTable[symCount].name, name);
    symCount++;
    printf("Semântico: Variável '%s' do tipo '%s' salva na tabela.\n", name, type);
}

int symbol_exists(char* name) {
    for(int i = 0; i < symCount; i++) {
        if(strcmp(symTable[i].name, name) == 0) return 1;
    }
    return 0;
}