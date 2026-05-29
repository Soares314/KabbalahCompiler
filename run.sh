#!/bin/bash

VERDE='\033[0;32m'
AZUL='\033[0;34m'
SEM_COR='\033[0m'

echo -e "${AZUL}[Etapa 1] Executando o Front-end (Flex/Bison/C)...${SEM_COR}"
./meu_compilador < entradas/entrada.txt

if [ $? -eq 0 ]; then
    echo -e "${AZUL}[Etapa 2] Otimizando o código intermediário (Python)...${SEM_COR}"
    python3 otimizador.py

    echo -e "${AZUL}[Etapa 3] Gerando código final Assembly (RISC-V)...${SEM_COR}"
    python3 gerador_assembly.py
    
    echo -e "${VERDE}✔ Processo concluído com sucesso!${SEM_COR}"
else
    echo "❌ Erro na análise sintática/semântica. Processo interrompido."
fi