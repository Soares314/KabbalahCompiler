#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "ast.h"

ASTNode *new_node(char *value, char *type, ASTNode *left, ASTNode *right, int scope) {
    ASTNode* node = (ASTNode*)malloc(sizeof(ASTNode));
    if (node == NULL) {
        fprintf(stderr, "Erro: Falha ao alocar memória para o nó.\n");
        exit(1);
    }
    
    node->value = value ? strdup(value) : NULL;
    node->type  = type  ? strdup(type)  : NULL;
    strcpy(node->code, "");
    node->scope_level = scope;
    
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