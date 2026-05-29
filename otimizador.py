import re

def otimizar_tac(arquivo_entrada, arquivo_saida):
    with open(arquivo_entrada, 'r') as f:
        linhas = [linha.strip() for linha in f if linha.strip()]

    # ================= PROPAGAÇÃO E ÁLGEBRA ================= 
    constantes = {}
    linhas_passo1 = []

    # Regex para identificar os padrões do TAC
    re_binop = re.compile(r'^(\w+)\s*=\s*([a-zA-Z0-9_]+)\s*([\+\-\*/<>=]+)\s*([a-zA-Z0-9_]+)$')
    re_assign = re.compile(r'^(\w+)\s*=\s*([a-zA-Z0-9_]+)$')
    re_if = re.compile(r'^ifFalse\s+([a-zA-Z0-9_]+)\s+goto\s+(\w+)$')

    for linha in linhas:
        # Isso evita propagar um valor para dentro de um if/else acidentalmente.
        if linha.startswith('label ') or linha.startswith('goto '):
            constantes.clear()
            linhas_passo1.append(linha)
            continue

        # 1. Operações Matemáticas e Relacionais (t1 = a + b)
        match_binop = re_binop.match(linha)
        if match_binop:
            res, arg1, op, arg2 = match_binop.groups()

            # --- PROPAGAÇÃO DE CONSTANTES ---
            val1 = constantes.get(arg1, arg1)
            val2 = constantes.get(arg2, arg2)

            is_num1 = str(val1).lstrip('-').isnumeric()
            is_num2 = str(val2).lstrip('-').isnumeric()

            if is_num1 and is_num2 and op in ['+', '-', '*', '/']:
                try:
                    calc = int(eval(f"{val1} {op} {val2}"))
                    constantes[res] = calc
                    linhas_passo1.append(f"{res} = {calc}")
                    continue
                except ZeroDivisionError:
                    pass

            # --- SIMPLIFICAÇÕES ALGÉBRICAS ---
            if is_num1 and not is_num2:
                if str(val1) == '0' and op == '+':
                    linhas_passo1.append(f"{res} = {val2}")
                    continue
                if str(val1) == '1' and op == '*':
                    linhas_passo1.append(f"{res} = {val2}")
                    continue
                if str(val1) == '0' and op == '*':
                    constantes[res] = 0
                    linhas_passo1.append(f"{res} = 0")
                    continue

            if is_num2 and not is_num1:
                if str(val2) == '0' and op in ['+', '-']:
                    linhas_passo1.append(f"{res} = {val1}")
                    continue
                if str(val2) == '1' and op in ['*', '/']:
                    linhas_passo1.append(f"{res} = {val1}")
                    continue
                if str(val2) == '0' and op == '*':
                    constantes[res] = 0
                    linhas_passo1.append(f"{res} = 0")
                    continue

            linhas_passo1.append(f"{res} = {val1} {op} {val2}")
            if res in constantes: del constantes[res]
            continue

        # 2. Atribuição Simples (x = 10)
        match_assign = re_assign.match(linha)
        if match_assign:
            res, arg1 = match_assign.groups()
            val1 = constantes.get(arg1, arg1)

            if str(val1).lstrip('-').isnumeric():
                constantes[res] = val1
            else:
                if res in constantes: del constantes[res]
            
            linhas_passo1.append(f"{res} = {val1}")
            continue

        # 3. Condicionais (ifFalse t1 goto L1)
        match_if = re_if.match(linha)
        if match_if:
            cond, lbl = match_if.groups()
            val_cond = constantes.get(cond, cond)
            linhas_passo1.append(f"ifFalse {val_cond} goto {lbl}")
            continue

        linhas_passo1.append(linha) # Caiu aqui, é um print ou comando não reconhecido

    # ================= DEAD CODE ELIMINATION =================
    # Feita de baixo para cima
    variaveis_vivas = set()
    linhas_finais = []

    for linha in reversed(linhas_passo1):
        if linha.startswith('label ') or linha.startswith('goto '):
            linhas_finais.append(linha)
            continue

        match_if = re_if.match(linha)
        if match_if:
            cond, lbl = match_if.groups()
            if not str(cond).isnumeric(): variaveis_vivas.add(cond)
            linhas_finais.append(linha)
            continue

        match_binop = re_binop.match(linha)
        if match_binop:
            res, arg1, op, arg2 = match_binop.groups()
            
            # Variável temporária morta
            if res.startswith('t') and res not in variaveis_vivas:
                continue 
            
            if not str(arg1).isnumeric(): variaveis_vivas.add(arg1)
            if not str(arg2).isnumeric(): variaveis_vivas.add(arg2)
            linhas_finais.append(linha)
            continue

        match_assign = re_assign.match(linha)
        if match_assign:
            res, arg1 = match_assign.groups()
            
            # Variável temporária morta
            if res.startswith('t') and res not in variaveis_vivas:
                continue
            
            if not str(arg1).isnumeric(): variaveis_vivas.add(arg1)
            linhas_finais.append(linha)
            continue

        linhas_finais.append(linha)

    linhas_finais.reverse()

    with open(arquivo_saida, 'w') as f:
        for linha in linhas_finais:
            f.write(linha + '\n')
            
    print("[Otimização concluída com sucesso e salva em 'saida_otimizada.tac'!")

if __name__ == "__main__":
    otimizar_tac('saida.tac', 'saida_otimizada.tac')