#ifndef AST_H
#define AST_H

typedef struct ASTNode {
    char *value;
    char *type;
    char data_type[20];
    struct ASTNode *left;
    struct ASTNode *right;
    char code[50];
} ASTNode;

ASTNode * new_node(char *, char *, ASTNode *, ASTNode *);
void print_ast(ASTNode *, int);
void free_ast(ASTNode *);

#endif