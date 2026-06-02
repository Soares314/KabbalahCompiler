#include <stdio.h>
#include <stdlib.h>
#include <stddef.h>
#include <string.h>
#include "t_simbolos.h"

Symbol symTable[100];
int symCount = 0;
int current_scope = 0; // Escopo começa no 0 (global)

void add_symbol(char* type, char* name) {
    for(int i = 0; i < symCount; i++) {
        if(strcmp(symTable[i].name, name) == 0 && symTable[i].scope_level == current_scope) {
            
            printf("Erro Semântico: Variável '%s' já declarada neste escopo!\n", name);
            exit(1);
        }
    }
    strcpy(symTable[symCount].type, type);
    strcpy(symTable[symCount].name, name);
    symTable[symCount].scope_level = current_scope;

    symCount++;
    printf("Semântico: Variável '%s' do tipo '%s' salva na tabela.\n", name, type);
}

Symbol* get_symbol(char* name) {
    for(int i = symCount - 1; i >= 0; i--) {
        if(strcmp(symTable[i].name, name) == 0) {
            return &symTable[i];
        }
    }
    return NULL;
}

void enter_scope() {
    current_scope++;
    printf("Abrindo escopo de nível [%d]\n", current_scope);
}

void exit_scope() {
    // Quando saímos de um escopo, todas as variáveis declaradas nele "morrem".
    // Como a tabela preenche do início pro fim, as variáveis mais novas estão no final.
    // Basta diminuir o symCount até tirar todas as do escopo atual!
    while (symCount > 0 && symTable[symCount - 1].scope_level == current_scope) {
        symCount--; // "Apaga" a variável simplesmente ignorando ela
    }
    // printf("[DEBUG] Saindo do escopo %d. Símbolos locais não serão apagados ainda.\n", current_scope);
    current_scope--;
    
    printf("Retornando ao escopo de nível [%d]\n", current_scope);
}

int get_scope() {
    return current_scope;
}