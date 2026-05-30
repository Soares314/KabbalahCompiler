%{
#include <stdio.h>
#include <stdlib.h>
#include <stddef.h>
#include <string.h>
#include "ast.h"
// #include <windows.h>
FILE* out_file;

int yylex(void);
void yyerror(const char *s);

// --- TABELA DE SÍMBOLOS ---
// TODO: Adicionar escopo de variáveis
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

// --- CÓDIGO INTERMEDIÁRIO ---
int tempCount = 0;
int labelCount = 0;

char* new_temp() {
    char* temp = (char*)malloc(10);
    sprintf(temp, "t%d", ++tempCount);
    return temp;
}

/* Cria labels para fazer o JUMP de condicionais */ 
char* new_label() {
    char* lbl = (char*)malloc(10);
    sprintf(lbl, "L%d", ++labelCount);
    return lbl;
}

// ----- ANOTA CÓDIGO INTERMEDIÁRIO NO ARQUIVO 'saida.tac' -----
void emit(char* result, char* op1, char* op, char* op2) {
    if (op2 == NULL) {
        fprintf(out_file, "%s = %s\n", result, op1);
    } else {
        fprintf(out_file, "%s = %s %s %s\n", result, op1, op, op2);
    }
}

// Saltos If-ELSE
void emit_if_false(char* cond, char* label) {
    fprintf(out_file, "ifFalse %s goto %s\n", cond, label);
}

void emit_goto(char* label) {
    fprintf(out_file, "goto %s\n", label);
}

void emit_label(char* label) {
    fprintf(out_file, "label %s\n", label);
}
%}

%union {
    int num;
    char* str;
    struct ASTNode* node;
}

%token KW_DEFINE KW_RETURN TYPE_VOID TYPE_INT TYPE_CHAR TYPE_FLOAT TYPE_LONG
%token KW_SIZEOF KW_IF KW_ELSE KW_FOR KW_FOREACH KW_WHILE
%token ASSIGN SEMICOLON
%token OP_EQ OP_LT OP_GT

%token <str> IDENTIFIER
%token <num> NUM

%type <node> expr
%type <node> condicao  /* A condição vai retornar um nó da AST */
%type <str> if_prefix  /* Vai retornar o Label L1/L2 como string */

%left '+' '-'
%left '*' '/'

%% /* ================= REGRAS ================= */

program:
    statements
    ;

statements:
    statement
  | statements statement
  ;

/* ----- IF e ELSE ----- */
if_prefix:
    KW_IF '(' condicao ')' {
        char* l_false = new_label();
        
        printf("\nAST da Condição:\n");
        print_ast($3, 0);
        free_ast($3);
        
        emit_if_false($3->code, l_false);
        $$ = l_false;
    }
    ;

statement:
    TYPE_INT IDENTIFIER ASSIGN expr SEMICOLON {
        add_symbol("int", $2);
        ASTNode* id_node = new_node($2, "identifier", NULL, NULL);
        ASTNode* root    = new_node("=", "assign", id_node, $4);

        printf("\nAST da declaração '%s':\n", $2);
        print_ast(root, 0);
        free_ast(root);

        emit($2, $4->code, NULL, NULL);
        printf("\n");
    }

    | if_prefix '{' statements '}' {
        // IF sem ELSE
        emit_label($1);
    }

    | if_prefix '{' statements '}' KW_ELSE {
        // IF com ELSE
        $<str>$ = new_label();
        emit_goto($<str>$);
        emit_label($1);
    } '{' statements '}' {
        emit_label($<str>6);
    }

    | TYPE_FLOAT IDENTIFIER ASSIGN expr SEMICOLON {
        // Seu futuro float aqui
    }
    ;

condicao:
    expr OP_EQ expr {
        ASTNode* node = new_node("==", "relacional", $1, $3);
        char* temp = new_temp();
        emit(temp, $1->code, "==", $3->code);
        strcpy(node->code, temp);
        free(temp);
        $$ = node;
    }
  | expr OP_LT expr {
        ASTNode* node = new_node("<", "relacional", $1, $3);
        char* temp = new_temp();
        emit(temp, $1->code, "<", $3->code);
        strcpy(node->code, temp);
        free(temp);
        $$ = node;
    }
  | expr OP_GT expr {
        ASTNode* node = new_node(">", "relacional", $1, $3);
        char* temp = new_temp();
        emit(temp, $1->code, ">", $3->code);
        strcpy(node->code, temp);
        free(temp);
        $$ = node;
    }
  ;

expr:
    expr '+' expr {
        ASTNode* node = new_node("+", "op", $1, $3);
        char* temp = new_temp();
        emit(temp, $1->code, "+", $3->code);
        strcpy(node->code, temp);
        free(temp);
        $$ = node;
    }
  | expr '-' expr {
        ASTNode* node = new_node("-", "op", $1, $3);
        char* temp = new_temp();
        emit(temp, $1->code, "-", $3->code);
        strcpy(node->code, temp);
        free(temp);
        $$ = node;
    }
  | expr '*' expr {
        ASTNode* node = new_node("*", "op", $1, $3);
        char* temp = new_temp();
        emit(temp, $1->code, "*", $3->code);
        strcpy(node->code, temp);
        free(temp);
        $$ = node;
    }
  | expr '/' expr {
        ASTNode* node = new_node("/", "op", $1, $3);
        char* temp = new_temp();
        emit(temp, $1->code, "/", $3->code);
        strcpy(node->code, temp);
        free(temp);
        $$ = node;
    }
  | '(' expr ')' {
        $$ = $2;
    }
  | IDENTIFIER {
        ASTNode* node = new_node($1, "identifier", NULL, NULL);
        strcpy(node->code, $1);
        $$ = node;
    }
  | NUM {
        char numStr[20];
        sprintf(numStr, "%d", $1);
        ASTNode* node = new_node(numStr, "int", NULL, NULL);
        strcpy(node->code, numStr);
        $$ = node;
    }
  ;

%% /* ================= CÓDIGO C FINAL ================= */

void yyerror(const char *s) {
    fprintf(stderr, "Erro Sintático: %s\n", s);
}

int main(void) {
    // SetConsoleOutputCP(CP_UTF8);
    // Abre o arquivo para escrita
    out_file = fopen("saida.tac", "w");

    if (out_file == NULL) {
        printf("Erro: Não foi possível criar o arquivo de saída.\n");
        return 1;
    }

    printf("Iniciando a compilação...\n\n");
    if (yyparse() == 0) {
        printf("Compilação concluída com sucesso!\n");
        printf("O código intermediário foi salvo em 'saida.tac'.\n");
    }

    fclose(out_file);
    return 0;
}