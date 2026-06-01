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
- Otimizador: script autoral, em Python v3.10.12

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
rm -f build/lex.yy.c build/parser.tab.c build/compilador
bison -d -o build/parser.tab.c src/frontend/parser.y
flex -o build/lex.yy.c src/frontend/lexer.l
gcc -I src/frontend src/frontend/ast.c src/frontend/t_simbolos.c build/lex.yy.c build/parser.tab.c -o build/compilador
./run.sh
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

A seguinte estrutura de pastas foi adotada para melhor modularidade do código e legibilidade:

```
meu-compilador/
├── src/                    # Código-fonte do projeto
│   ├── frontend/           # Parte em C (Flex e Bison)
│   │   ├── lexer.l         # Arquivo do Flex
│   │   ├── parser.y        # Arquivo do Bison
│   │   └── ast.h / ast.c   # Definição da AST
│   │
│   └── backend/            # Parte em Python
│       ├── main_backend.py # Script principal do backend
│       ├── optimizer.py    # Otimização do código
│       └── codegen.py      # Gerador de código Assembly
│
├── tests/                  # Entradas de teste do compilador
│   ├── entrada.txt
│   └── entrada_if.txt
│
├── build/                  # Arquivos gerados automaticamente pelo build
│   ├── lex.yy.c
│   ├── parser.tab.c
│   ├── parser.tab.h
│   ├── compilador.exe      
│   └── saida.asm           
│
├── run.sh                 
└── README.md
```
___
<!-- Atualmente, o compilador suporta apenas atribuições simples e operações aritméticas básicas de inteiros. -->

## Possíveis Problemas

Sem permissão para executar <code>run.sh</code>

```
sudo chmod +x ./run.sh
```

Erro ao executar o <code>run.sh</code>: Se estiver usando o VSCode, no canto inferior direito, altere o método de fim de linha de CLRF para somente LF (Linux não reconhece CRLF, e esse arquivo é específico para sistemas Linux)

