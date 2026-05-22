%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <windows.h>

int yylex(void);
void yyerror(const char *s);

// --- Tabela de Símbolos ---
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


// --- Codigo Intermediário ---
int tempCount = 0;

char* new_temp() {
    char* temp = (char*)malloc(10);
    sprintf(temp, "t%d", ++tempCount);
    return temp;
}

void emit(char* result, char* op1, char* operator, char* op2) {
    if (op2 == NULL) {
        printf("Intermediário: %s = %s\n", result, op1);
    } else {
        printf("Intermediário: %s = %s %s %s\n", result, op1, operator, op2);
    }
}
%}


/* Tipos de dados que o Lexer pode enviar */
%union {
    int num;
    char* str; /* Armazena com * pois não se sabe o tamanho do char */
}

/* Declaração de todos os tokens retornados pelo Lexer */
%token KW_DEFINE KW_RETURN TYPE_VOID TYPE_INT TYPE_CHAR TYPE_FLOAT TYPE_LONG
%token KW_ADD KW_SIZEOF KW_IF KW_FOR KW_FOREACH KW_WHILE
%token ASSIGN SEMICOLON

/* Tokens com valores específicos (definidos no %union) */
%token <str> IDENTIFIER
%token <num> NUM


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
        char numStr[20];
        sprintf(numStr, "%d", $4);
        emit($2, numStr, NULL, NULL);
    }
  | IDENTIFIER '+' IDENTIFIER ASSIGN IDENTIFIER SEMICOLON {
        char* temp = new_temp();
        emit(temp, $1, "+", $3);
        emit($5, temp, NULL, NULL);
        free(temp);
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