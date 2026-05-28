# Compilador

> O repositório inclui um projeto de um mini compilador desenvolvidos para a disciplina de Compiladores, do curso de Ciências da Computação da UFT.

Este projeto está sendo desenvolvido pelos alunos Arthur Lima, Gabriel Fernandes, Klaus Henrique e Thiago Soares. Todas as ferramentas usadas são open-source, exceto o sistema Windows, que pode ser obtido pela internet de forma gratuita.

O software deve atender aos requisitos de todas as fases cruciais do processo de compilação, sendo essas:

<ol>
    <li>Análise léxica (Tokens, Lexemas)</li>
    <li>Análise sintática (BNF, Árvore de Derivação)</li>
    <li>Análise Semântica (Árvore Sintática Abstrata, Tabela de Símbolos)</li>
    <li>Geração de Código Intermediário (Código de Três Endereços, Triplas, Quádruplas)</li>
    <li>Otimização do Código (Propagação de Constantes, Simplificaçoes Algébricas, Dead Code)</li>
    <li>Código Final (Assembly ou outra linguagem de montagem)</li>
</ol>

## 🛠️ Ferramentas

- Sistema Operacional: Windows (principal), Ubuntu
- Linguagem alvo: C
- Lexer: Flex v2.6
- Parser: Bison v3.8
- Gerador de código intermediário: gcc v11.4

## 💻 Comandos

A seguinte sequência de comandos compila os Lexer e Parser, além de criar o executável capaz de ler o programa fonte e fornecer a análise linguística dele (léxica, sintática, semântica)

```powershell
bison -d parser.y
```

```powershell
flex lexer.l
```

```powershell
gcc parser.tab.c lex.yy.c -o meu_compilador.exe
```

Para usar as entradas de teste, rodar o comando (Windows):
```powershell
Get-Content entrada.txt | .\meu_compilador.exe
```

Linux:
```bash
cat entrada.txt | ./meu_compilador
./meu_compilador < entrada.txt # Forma alternativa nativa do Linux
```

Caso seja necessário, rode os seguintes comandos para deleção dos arquivos intermediários e garantir uma recompilação limpa

```bash
rm -f lex.yy.c parser.tab.c meu_compilador
bison -d parser.y
flex lexer.l
gcc parser.tab.c lex.yy.c -o meu_compilador
./meu_compilador < entrada.txt
```

## 🐋 Para rodar no container

Na pasta do projeto já está presente o arquivo <code>Dockerfile</code>, basta criar a imagem com:

```powershell
docker build -t ambiente-compiladores .
```

Com a imagem pronta, rodamos o container. Ele está associado a um volume, assim, uma mudança no código feita na IDE refletirá no container e vice-versa

Windows:
```docker
docker run -it --rm -v ${PWD}:/workspace ambiente-compiladores
```

Linux:
```docker
docker run -it --rm -v $(pwd):/workspace ambiente-compiladores
```

_Nota: Alguns comandos precisam ser alterados dependendo do sistema operacional por serem específicos de máquina, como a biblitoeca <code>windows.h</code>. Verificar no código estes pontos_

## Estrutura de Arquivos

...

<!-- ```
/projeto-compilador
├── /src
│   ├── lexer.l          # Definições lexicais
│   ├── parser.y         # Gramática e ações semânticas
│   └── main.c           # Entrada do programa
├── /tests
│   └── entrada.txt      # Arquivo de teste de exemplo
├── Makefile             # Script de automação de build
└── README.md
``` -->

___

Atualmente, o compilador suporta apenas atribuições simples e operações aritméticas básicas de inteiros.