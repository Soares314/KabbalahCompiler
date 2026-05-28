%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
// #include <windows.h>

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

// --- AST ---
typedef struct ASTNode {
    char value[50];
    char type[20];
    struct ASTNode* left;
    struct ASTNode* right;
    char code[50]; // guarda o nome da temporária ou valor para o código intermediário
} ASTNode;

ASTNode* new_node(char* value, char* type, ASTNode* left, ASTNode* right) {
    ASTNode* node = (ASTNode*)malloc(sizeof(ASTNode));
    strcpy(node->value, value);
    strcpy(node->type, type);
    strcpy(node->code, "");
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
        
        printf("Intermediário: ifFalse %s goto %s\n", $3->code, l_false);
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
        printf("Intermediário: label %s\n\n", $1);
    }

    | if_prefix '{' statements '}' KW_ELSE {
        // IF com ELSE
        $<str>$ = new_label();
        printf("Intermediário: goto %s\n", $<str>$);
        printf("Intermediário: label %s\n", $1);
    } '{' statements '}' {
        printf("Intermediário: label %s\n\n", $<str>6);
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
    printf("Iniciando a compilação...\n\n");
    if (yyparse() == 0) {
        printf("Compilação concluída com sucesso!\n");
    }
    return 0;
}