%{
#include "parser.tab.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
%}

%%
    /* Palavras-chave */
"define"  { return KW_DEFINE; }
"return"  { return KW_RETURN; }
"sizeof"  { return KW_SIZEOF; }
"if"      { return KW_IF; }
"else"    { return KW_ELSE; }
"for"     { return KW_FOR; }
"foreach" { return KW_FOREACH; }
"while"   { return KW_WHILE; }
"break"   { return KW_BREAK; }
"continue"   { return KW_CONTINUE; }

    /* Palavras-chave, para tipos */
"int"     { return TYPE_INT; }
"char"    { return TYPE_CHAR; }
"float"   { return TYPE_FLOAT; }
"long"    { return TYPE_LONG; }
"void"    { return TYPE_VOID; }

    /* Identificadores (salvos em yylval.str) */
[a-zA-Z_][a-zA-Z0-9_]* { 
    yylval.str = strdup(yytext); 
    return IDENTIFIER; 
}

    /* Números: salvamos o valor numérico em yylval.num */
[0-9]+ { 
    yylval.num = atoi(yytext); 
    return NUM; 
}
[0-9]+\.[0-9]+ { 
    yylval.str = strdup(yytext); 
    return NUM_FLOAT; 
}

    /* Caracteres: passamos diretamente o valor ASCII dele como inteiro */
\'[^\'\\]\' { 
        // Captura caracteres normais ex: 'A', 'x', ' '
        yylval.num = yytext[1]; 
        return CHAR_LITERAL; 
    }

\'\\[nt0]\' {
        // Captura caracteres de escape especiais ex: '\n', '\t', '\0'
        if (yytext[2] == 'n') yylval.num = 10;       // ASCII do newline
        else if (yytext[2] == 't') yylval.num = 9;   // ASCII do tab
        else if (yytext[2] == '0') yylval.num = 0;   // ASCII do null
        return CHAR_LITERAL;
    }

    /* Operadores e Pontuação */
"="   { return ASSIGN; }
";"   { return SEMICOLON; }
"+"   { return '+'; }
"-"   { return '-'; }
"/"   { return '/'; }
"*"   { return '*'; }
"("   { return '('; }
")"   { return ')'; }
"{"   { return '{'; }
"}"   { return '}'; }
"=="  { return OP_EQ; }
"!="  { return OP_NEQ; }
"<"   { return OP_LT; }
"<="   { return OP_LE; }
">"   { return OP_GT; }
">="   { return OP_GE; }

[ \t\r\n]+  ; 
"//".* ; 

    /* Tratamento de Erros Léxicos */
. { printf("Erro Lexico: Caractere não reconhecido '%s'\n", yytext); }
%%

int yywrap(void) {
    return 1;
}