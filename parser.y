%{
#include <stdio.h>
#include <stdlib.h>
int yylex(void);
void yyerror(const char *s);
%}

/* Bison Declarations */
%token NUM
%left '+'
%left '*'

%% /* Grammar Rules */

input:    /* empty */

        | input line
;

line:     '\n'
        | exp '\n'      { printf("\tResult: %d\n", $1); }
;

exp:      NUM           { $$ = $1; }

        | exp '+' exp   { $$ = $1 + $3; }
        | exp '*' exp   { $$ = $1 * $3; }
;

%% /* Additional C Code */

void yyerror(const char *s) {
    fprintf(stderr, "Error: %s\n", s);
}

int main(void) {
    return yyparse();
}
