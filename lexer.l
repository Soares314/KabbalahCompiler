%{
#include "parser.tab.h"
#include <stdio.h>
%}

%%
"define" { printf("<keyword,function> "); }
"return" { printf("<keyword,return> "); }
"void" { printf("<keyword,void> "); }
"int" { printf("<keyword,int> "); }
"char" { printf("<keyword,char> "); }
"float" { printf("<keyword,float> "); }
"long" { printf("<keyword,long> "); }
"add" { printf("<keyword,add-to-array> "); }
"sizeof" { printf("<keyword,size-array> "); }
"if" { printf("<keyword,conditional> "); }
"for" { printf("<keyword,loop-for> "); }
"foreach" { printf("<keyword,loop-foreach> "); }
"while" { printf("<keyword,loop-while> "); }
[a-zA-Z_][a-zA-Z0-9_]* { printf("<id,%s> ", yytext); }
[0-9]+      { yylval = atoi(yytext); return NUM; }
"=" { printf("<atribuição,=> "); }
"+" { return '+'; }
"-" { return '-'; }
"/" { return '/'; }
"*" { return '*'; }
"(" { return '('; }
")" { return ')'; }
";" { printf("<delimitador,;> "); }

[ \t] ;     /* ignora apenas espaços e tabs */
\n    { return '\n'; } /* Devolve o Enter para o Bison saber que a conta acabou */
"//".*    { printf("<comentário,%s> ", yytext); }
. { printf("<erro,%s> ", yytext); }
%%

    /*int main(void) {
        yylex();
    return 0;
}*/

int yywrap(void) {
    return 1;
}