%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <windows.h>

int yylex(void);
void yyerror(const char *s);

// --- INÍCIO DA TABELA DE SÍMBOLOS ---
struct Symbol {
    char name[50];
    char type[20];
};

struct Symbol symTable[100];
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
// --- FIM DA TABELA DE SÍMBOLOS ---
%}

/* Tipos de dados que o Lexer pode enviar */
%union {
    int num;
    char* str;
}

/* Declaração de todos os tokens retornados pelo Lexer */
%token KW_DEFINE KW_RETURN TYPE_VOID TYPE_INT TYPE_CHAR TYPE_FLOAT TYPE_LONG
%token KW_ADD KW_SIZEOF KW_IF KW_FOR KW_FOREACH KW_WHILE
%token ASSIGN SEMICOLON

/* Tokens que carregam valores específicos (definidos no %union) */
%token <str> IDENTIFIER
%token <num> NUM

/* Precedência de operadores para evitar ambiguidades matemáticas */
%left '+' '-'
%left '*' '/'

%% /* ================= PRIMEIRO %%: INÍCIO DAS REGRAS ================= */

program: 
    statements 
    ;

statements: 
    statement 
  | statements statement 
  ;

statement: 
    TYPE_INT IDENTIFIER ASSIGN NUM SEMICOLON {
        add_symbol("int", $2);
    }
  | IDENTIFIER '+' IDENTIFIER ASSIGN IDENTIFIER SEMICOLON {
        printf("Semântico: Operação lida com sucesso.\n");
    }
  ;

%% /* ================= SEGUNDO %%: CÓDIGO C FINAL ================= */

void yyerror(const char *s) {
    fprintf(stderr, "Erro Sintático: %s\n", s);
}

int main(void) {
    SetConsoleOutputCP(CP_UTF8);
    printf("Iniciando a compilação...\n");
    if (yyparse() == 0) {
        printf("\nCompilação concluída com sucesso! Nenhuma falha sintática ou semântica.\n");
    }
    return 0;
}