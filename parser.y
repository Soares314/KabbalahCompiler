%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <windows.h>

int yylex(void);
void yyerror(const char *s);

// --- TABELA DE SÍMBOLOS ---
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

// --- AST ---
typedef struct ASTNode {
    char value[50];        // valor do nó: nome da variável, número ou operador
    char type[20];         // tipo semântico: "int", "op", "assign", etc
    struct ASTNode* left;  // filho esquerdo
    struct ASTNode* right; // filho direito
} ASTNode;

ASTNode* new_node(char* value, char* type, ASTNode* left, ASTNode* right) {
    ASTNode* node = (ASTNode*)malloc(sizeof(ASTNode));
    strcpy(node->value, value);
    strcpy(node->type, type);
    node->left  = left;
    node->right = right;
    return node;
}

void print_ast(ASTNode* node, int level) {
    if (node == NULL) return;
    for (int i = 0; i < level; i++) printf("  ");
    printf("[%s] %s\n", node->type, node->value);
    print_ast(node->left,  level + 1);
    print_ast(node->right, level + 1);
}

void free_ast(ASTNode* node) {
    if (node == NULL) return;
    free_ast(node->left);
    free_ast(node->right);
    free(node);
}

// --- CÓDIGO INTERMEDIÁRIO ---
int tempCount = 0;

char* new_temp() {
    char* temp = (char*)malloc(10);
    sprintf(temp, "t%d", ++tempCount);
    return temp;
}

void emit(char* result, char* op1, char* op, char* op2) {
    if (op2 == NULL) {
        printf("Intermediário: %s = %s\n", result, op1);
    } else {
        printf("Intermediário: %s = %s %s %s\n", result, op1, op, op2);
    }
}
%}

%union {
    int num;
    char* str;
}

%token KW_DEFINE KW_RETURN TYPE_VOID TYPE_INT TYPE_CHAR TYPE_FLOAT TYPE_LONG
%token KW_ADD KW_SIZEOF KW_IF KW_FOR KW_FOREACH KW_WHILE
%token ASSIGN SEMICOLON

%token <str> IDENTIFIER
%token <num> NUM

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

statement:
    TYPE_INT IDENTIFIER ASSIGN NUM SEMICOLON {
        // Tabela de símbolos
        add_symbol("int", $2);

        // Monta a AST:  ASSIGN
        //              /      \
        //        IDENTIFIER   NUM
        char numStr[20];
        sprintf(numStr, "%d", $4);
        ASTNode* id_node  = new_node($2,     "identifier", NULL, NULL);
        ASTNode* num_node = new_node(numStr, "int",        NULL, NULL);
        ASTNode* root     = new_node("=",    "assign",     id_node, num_node);

        printf("\nAST da declaração '%s = %s':\n", $2, numStr);
        print_ast(root, 0);
        free_ast(root);

        // Código intermediário
        emit($2, numStr, NULL, NULL);
        printf("\n");
    }
  | IDENTIFIER '+' IDENTIFIER ASSIGN IDENTIFIER SEMICOLON {
        // Monta a AST:    ASSIGN
        //                /      \
        //               +        z
        //              / \
        //             y   x
        ASTNode* left_id  = new_node($1, "identifier", NULL, NULL);
        ASTNode* right_id = new_node($3, "identifier", NULL, NULL);
        ASTNode* plus     = new_node("+", "op",        left_id, right_id);
        ASTNode* result   = new_node($5, "identifier", NULL, NULL);
        ASTNode* root     = new_node("=", "assign",    result, plus);

        printf("\nAST da operação '%s + %s = %s':\n", $1, $3, $5);
        print_ast(root, 0);
        free_ast(root);

        // Código intermediário
        char* temp = new_temp();
        emit(temp, $1, "+", $3);
        emit($5, temp, NULL, NULL);
        free(temp);
        printf("\n");
    }
  ;

%% /* ================= CÓDIGO C FINAL ================= */

void yyerror(const char *s) {
    fprintf(stderr, "Erro Sintático: %s\n", s);
}

int main(void) {
    SetConsoleOutputCP(CP_UTF8);
    printf("Iniciando a compilação...\n\n");
    if (yyparse() == 0) {
        printf("Compilação concluída com sucesso!\n");
    }
    return 0;
}
