%{
#include <stdio.h>
%}

%%
"int" { printf("<keyword,int> "); }
"char" { printf("<keyword,char> "); }
"float" { printf("<keyword,float> "); }
[a-zA-Z_][a-zA-Z0-9_]* { printf("<id,%s> ", yytext); }
{*} { printf("<id,%s> ", yytext); }
"=" { printf("<atribuição,=> "); }
"+" { printf("<op,+> "); }
";" { printf("<delimitador,;> "); }
[ \t\n] ; /* ignora espaços */
. { printf("<erro,%s> ", yytext); }
%%

int main(void) {
    yylex();
    return 0;
}