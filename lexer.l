%{
#include "parser.tab.h" // Arquivo gerado pelo Bison com a definição dos tokens
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
%}

%%
    /* Palavras-chave retornam tokens definidos no Bison */
"define"  { return KW_DEFINE; }
"return"  { return KW_RETURN; }
"void"    { return TYPE_VOID; }
"int"     { return TYPE_INT; }
"char"    { return TYPE_CHAR; }
"float"   { return TYPE_FLOAT; }
"long"    { return TYPE_LONG; }
"sizeof"  { return KW_SIZEOF; }
"if"      { return KW_IF; }
"else"    { return KW_ELSE; }
"for"     { return KW_FOR; }
"foreach" { return KW_FOREACH; }
"while"   { return KW_WHILE; }

    /* Identificadores: salvamos o nome da variável em yylval.str */
[a-zA-Z_][a-zA-Z0-9_]* { 
    yylval.str = strdup(yytext); 
    return IDENTIFIER; 
}

    /* Números: salvamos o valor numérico em yylval.num */
[0-9]+ { 
    yylval.num = atoi(yytext); 
    return NUM; 
}

    /* Operadores e Pontuação */
"=" { return ASSIGN; }
";" { return SEMICOLON; }
"+" { return '+'; }
"-" { return '-'; }
"/" { return '/'; }
"*" { return '*'; }
"(" { return '('; }
")" { return ')'; }
"{" { return '{'; }
"}" { return '}'; }
"=="      { return OP_EQ; }
"<"       { return OP_LT; }
">"       { return OP_GT; }

[ \t\r\n]+  ; 

"//".* ; 

    /* Tratamento de Erros Léxicos */
. { printf("Erro Lexico: Caractere não reconhecido '%s'\n", yytext); }
%%

int yywrap(void) {
    return 1;
}