%{
#include <stdio.h>
#include <stdlib.h>
#include <stddef.h>
#include <string.h>
#include "ast.h"
#include "t_simbolos.h"
// #include <windows.h>
FILE* out_file;

int yylex(void);
void yyerror(const char *s);

// --- CONTROLE DE ESCOPO LOOP ---
char loop_break_stack[20][20];    // Guarda os labels de fim (break)
char loop_continue_stack[20][20]; // Guarda os labels de topo (continue)
int loop_stack_top = -1;

void push_loop(char* label_break, char* label_continue) {
    loop_stack_top++;
    strcpy(loop_break_stack[loop_stack_top], label_break);
    strcpy(loop_continue_stack[loop_stack_top], label_continue);
}

void pop_loop() {
    loop_stack_top--;
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

// Saltos If-ELSE e While
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
%token KW_SIZEOF KW_IF KW_ELSE KW_FOR KW_FOREACH
%token KW_BREAK KW_CONTINUE
%token ASSIGN SEMICOLON
%token OP_EQ OP_LT OP_GT

%token <str> IDENTIFIER
%token <num> NUM
%token <str> NUM_FLOAT
%token <str> KW_WHILE

%type <node> expr
%type <str> tipo       /* Regra genérica de tipo para declaração */
%type <node> condicao  /* A condição vai retornar um nó da AST */
%type <str> if_prefix  /* Vai retornar o Label L1/L2 como string */
%type <node> loop_prefix

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

/* --- Marcadores para o Bison --- */
tipo:
    TYPE_INT   { $$ = "int"; }
  | TYPE_FLOAT { $$ = "float"; }
  | TYPE_CHAR  { $$ = "char"; }
  | TYPE_LONG  { $$ = "long"; }
  ;

abre_escopo:  { enter_scope(); } ;
fecha_escopo: { exit_scope();  } ;

block:
    '{' abre_escopo statements '}' fecha_escopo
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
        printf("\n");
    }
    ;

// Emite o label Antes da condição
while_start:
    KW_WHILE '(' {
        char* label_topo = new_label();
        emit_label(label_topo);
        $<str>$ = label_topo;
    }
    ;

loop_prefix:
    while_start condicao ')' {
        char* label_topo = $<str>1; 
        char* label_fim = new_label();
        push_loop(label_fim, label_topo);

        ASTNode* node_break = new_node(label_fim, "break", NULL, NULL, get_scope());
        ASTNode* node_continue = new_node(label_topo, "continue", NULL, NULL, get_scope());

        $$ = new_node("while", "while", node_break, node_continue, get_scope());
        
        printf("\nAST de Loop:\n");
        print_ast($2, 0);

        emit_if_false($2->code, node_break->value);
    }
    ;

statement:
    // --- DECLARAÇÕES ---
    tipo IDENTIFIER ASSIGN expr SEMICOLON {
        // Checa se o tipo da declaração é compatível ao valor passado
        // TODO: Colocar hierarquia de tipos entre 'int' < 'long'
        if (strcmp($1, $4->data_type) != 0) {
            printf("Erro Semântico: Tipo '%s' não é compatível com '%s'.\n", $4->data_type, $1);
            exit(1);
        }
        add_symbol($1, $2);

        ASTNode* id_node = new_node($2, "identifier", NULL, NULL, get_scope());
        ASTNode* root    = new_node("=", "assign", id_node, $4, get_scope());

        printf("\nAST da declaração '%s':\n", $2);
        print_ast(root, 0);
        free_ast(root);

        char nome_com_escopo[100];
        sprintf(nome_com_escopo, "%s_%d", $2, get_scope());

        emit(nome_com_escopo, $4->code, NULL, NULL);
        printf("\n");
    }

    // --- ATRIBUIÇÃO ---
    | IDENTIFIER ASSIGN expr SEMICOLON {
        Symbol* sym = get_symbol($1);
        if (sym == NULL) {
            printf("Erro Semântico: Variável '%s' não declarada!\n", $1);
            exit(1);
        }
        if (strcmp(sym->type, $3->data_type) != 0) {
            printf("Erro Semântico: Impossível converter '%s' para '%s'!\n", $3->data_type, sym->type);
            exit(1);
        }
        ASTNode* id_node = new_node($1, "identifier", NULL, NULL, get_scope());
        ASTNode* root    = new_node("=", "assign", id_node, $3, get_scope());

        printf("\nAST da atribuição '%s':\n", $1);
        print_ast(root, 0);
        free_ast(root);

        char nome_com_escopo[100];
        sprintf(nome_com_escopo, "%s_%d", sym->name, sym->scope_level);

        emit(nome_com_escopo, $3->code, NULL, NULL); 
        printf("\n");
    }

    // --- IF sem ELSE ---
    | if_prefix block {
        emit_label($1);
    }

    // --- IF COM ELSE ---
    | if_prefix block KW_ELSE {
        // label de FIM para o IF não invadir o ELSE
        char* label_fim = new_label();
        emit_goto(label_fim);
        emit_label($1);

        $<str>$ = label_fim;
    } block {
        emit_label($<str>4);
    }

    // --- LOOP WHILE E BREAK/CONTINUE ---
    | loop_prefix block {
        emit_goto($1->right->value);
        emit_label($1->left->value);

        pop_loop();
    }

    | KW_BREAK SEMICOLON {
        if (loop_stack_top < 0) {
            printf("Erro Semântico: 'break' usado fora de um laço de repetição!\n");
            exit(1);
        }
        emit_goto(loop_break_stack[loop_stack_top]); 
    }

    | KW_CONTINUE SEMICOLON {
        if (loop_stack_top < 0) {
            printf("Erro Semântico: 'continue' usado fora de um laço de repetição!\n");
            exit(1);
        }
        emit_goto(loop_continue_stack[loop_stack_top]); 
    }

    ;

condicao:
    expr OP_EQ expr {
        ASTNode* node = new_node("==", "relacional", $1, $3, get_scope());
        char* temp = new_temp();
        emit(temp, $1->code, "==", $3->code);
        strcpy(node->code, temp);
        free(temp);
        $$ = node;
    }
  | expr OP_LT expr {
        ASTNode* node = new_node("<", "relacional", $1, $3, get_scope());
        char* temp = new_temp();
        emit(temp, $1->code, "<", $3->code);
        strcpy(node->code, temp);
        free(temp);
        $$ = node;
    }
  | expr OP_GT expr {
        ASTNode* node = new_node(">", "relacional", $1, $3, get_scope());
        print_ast(node, 0);
        char* temp = new_temp();
        emit(temp, $1->code, ">", $3->code);
        strcpy(node->code, temp);
        free(temp);
        $$ = node;
    }
  | expr {
        // Cria um nó folha para o número "0" para pendurar na AST
        ASTNode* zero_node = new_node("0", "inteiro", NULL, NULL, get_scope());
        strcpy(zero_node->code, "0");

        // Cria o nó relacional != seguindo exatamente o seu padrão
        ASTNode* node = new_node("!=", "relacional", $1, zero_node, get_scope());
        print_ast(node, 0);

        char* temp = new_temp();
        // Usa a sua função padrão de emitir (se for emit_binop, basta ajustar o nome)
        emit(temp, $1->code, "!=", "0"); 
        
        strcpy(node->code, temp);
        free(temp);
        
        $$ = node;
    }
  ;

expr:
    expr '+' expr {
        // --- CHECAGEM DE TIPO ---
        if (strcmp($1->data_type, $3->data_type) != 0) {
            printf("Erro Semântico: Tipos incompatíveis para soma ('%s' + '%s').\n", $1->data_type, $3->data_type);
            exit(1);
        }
        // TODO: Implementar regras para operações com float
        if (strcmp($1->data_type, "float") == 0 || strcmp($3->data_type, "float") == 0) {
            printf("Erro: Operações com float ainda não são suportadas!\n");
            exit(1);
        }
        
        ASTNode* node = new_node("+", "op", $1, $3, get_scope());
        strcpy(node->data_type, $1->data_type); // Propaga o tipo para cima
        char* temp = new_temp();
        emit(temp, $1->code, "+", $3->code);
        strcpy(node->code, temp);
        free(temp);
        $$ = node;
    }
  | expr '-' expr {
        if (strcmp($1->data_type, $3->data_type) != 0) {
            printf("Erro Semântico: Tipos incompatíveis para subtração ('%s' - '%s').\n", $1->data_type, $3->data_type);
            exit(1);
        }
        if (strcmp($1->data_type, "float") == 0) {
            printf("Erro: Operações com float ainda não são suportadas!\n");
            exit(1);
        }
        
        ASTNode* node = new_node("-", "op", $1, $3, get_scope());
        strcpy(node->data_type, $1->data_type);
        
        char* temp = new_temp();
        emit(temp, $1->code, "-", $3->code);
        strcpy(node->code, temp);
        free(temp);
        $$ = node;
    }
  | expr '*' expr {
        if (strcmp($1->data_type, $3->data_type) != 0) {
            printf("Erro Semântico: Tipos incompatíveis para multiplicação ('%s' * '%s').\n", $1->data_type, $3->data_type);
            exit(1);
        }
        if (strcmp($1->data_type, "float") == 0) {
            printf("Erro: Operações com float ainda não são suportadas!\n");
            exit(1);
        }
        
        ASTNode* node = new_node("*", "op", $1, $3, get_scope());
        strcpy(node->data_type, $1->data_type);
        
        char* temp = new_temp();
        emit(temp, $1->code, "*", $3->code);
        strcpy(node->code, temp);
        free(temp);
        $$ = node;
    }
  | expr '/' expr {
        if (strcmp($1->data_type, $3->data_type) != 0) {
            printf("Erro Semântico: Tipos incompatíveis para divisão ('%s' / '%s').\n", $1->data_type, $3->data_type);
            exit(1);
        }
        if (strcmp($1->data_type, "float") == 0) {
            printf("Erro: Operações com float ainda não são suportadas!\n");
            exit(1);
        }
        
        ASTNode* node = new_node("/", "op", $1, $3, get_scope());
        strcpy(node->data_type, $1->data_type);
        
        char* temp = new_temp();
        emit(temp, $1->code, "/", $3->code);
        strcpy(node->code, temp);
        free(temp);
        $$ = node;
    }
  | '(' expr ')' {
        $$ = $2; // Os parênteses apenas repassam o nó inteiro, já com o tipo correto
    }
  | IDENTIFIER {
        // Busca o símbolo na tabela
        Symbol* sym = get_symbol($1);
        if (sym == NULL) {
            printf("Erro Semântico: Variável '%s' não declarada antes do uso!\n", $1);
            exit(1);
        }
        
        ASTNode* node = new_node($1, "identifier", NULL, NULL, get_scope());
        strcpy(node->data_type, sym->type); // Pega o tipo ("int") direto da tabela!

        // SALVA O ESCOPO JUNTO AO NOME DO NÓ
        sprintf(node->code, "%s_%d", sym->name, sym->scope_level);
        $$ = node;
    }
  | NUM {
        char numStr[20];
        sprintf(numStr, "%d", $1);
        ASTNode* node = new_node(numStr, "literal", NULL, NULL, get_scope());
        strcpy(node->data_type, "int"); // Literais puros são sempre inteiros
        strcpy(node->code, numStr);
        $$ = node;
    }
  | NUM_FLOAT {
        ASTNode* node = new_node($1, "literal", NULL, NULL, get_scope());
        strcpy(node->data_type, "float"); 
        strcpy(node->code, $1);
        $$ = node;
    }
  ;

%% /* ================= CÓDIGO C FINAL ================= */

void yyerror(const char *s) {
    fprintf(stderr, "Erro Sintático: %s\n", s);
    exit(1);
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