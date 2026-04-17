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
[-+]?[0-9]+(\.[0-9]+)?  { printf("<num,%s>", yytext); }
"=" { printf("<atribuição,=> "); }
"+" { printf("<op,+> "); }
"-" { printf("<op,-> "); }
"/" { printf("<op,/> "); }
"*" { printf("<op,*> "); }
";" { printf("<delimitador,;> "); }
"("    { printf("<delimitador, open parentheses>"); }
")"    { printf("<delimitador, close parentheses>"); }
[ \t\n] ; /* ignora espaços */
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