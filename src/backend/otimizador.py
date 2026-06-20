import re

# Compilamos os regex globais para usar em todas as funções
# CORREÇÃO 4: Adicionado o '!' e '=' no grupo de operadores lógicos!
re_binop = re.compile(r'^(\w+)\s*=\s*([a-zA-Z0-9_]+)\s*([\+\-\*/<>=!]+)\s*([a-zA-Z0-9_]+)$')
re_assign = re.compile(r'^(\w+)\s*=\s*([a-zA-Z0-9_]+)$')
re_if = re.compile(r'^ifFalse\s+([a-zA-Z0-9_]+)\s+goto\s+(\w+)$')
re_goto = re.compile(r'^goto\s+(\w+)$')
re_label = re.compile(r'^label\s+(\w+)$')

def propagacao_e_algebra(linhas):
    constantes = {}
    linhas_passo1 = []
    
    for linha in linhas:
        if linha.startswith('label ') or linha.startswith('goto '):
            constantes.clear()
            linhas_passo1.append(linha)
            continue
            
        match_binop = re_binop.match(linha)
        if match_binop:
            res, arg1, op, arg2 = match_binop.groups()
            val1 = constantes.get(arg1, arg1)
            val2 = constantes.get(arg2, arg2)
            is_num1 = str(val1).lstrip('-').isnumeric()
            is_num2 = str(val2).lstrip('-').isnumeric()
            
            # Realiza operações com constantes
            if is_num1 and is_num2 and op in ['+', '-', '*', '/', '==', '!=', '<', '>', '<=', '>=']:
                try:
                    calc = int(eval(f"{val1} {op} {val2}"))
                    constantes[res] = calc
                    linhas_passo1.append(f"{res} = {calc}")
                    continue
                except ZeroDivisionError:
                    pass
                    
            # Simplifica a álgebra
            if is_num1 and not is_num2:
                if str(val1) == '0' and op == '+':
                    linhas_passo1.append(f"{res} = {val2}"); continue
                if str(val1) == '1' and op == '*':
                    linhas_passo1.append(f"{res} = {val2}"); continue
                if str(val1) == '0' and op == '*':
                    constantes[res] = 0
                    linhas_passo1.append(f"{res} = 0"); continue

            if is_num2 and not is_num1:
                if str(val2) == '0' and op in ['+', '-']:
                    linhas_passo1.append(f"{res} = {val1}"); continue
                if str(val2) == '1' and op in ['*', '/']:
                    linhas_passo1.append(f"{res} = {val1}"); continue
                if str(val2) == '0' and op == '*':
                    constantes[res] = 0
                    linhas_passo1.append(f"{res} = 0"); continue
                    
            linhas_passo1.append(f"{res} = {val1} {op} {val2}")
            if res in constantes: del constantes[res]
            continue
            
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
            
        match_if = re_if.match(linha)
        if match_if:
            cond, lbl = match_if.groups()
            val_cond = constantes.get(cond, cond)
            linhas_passo1.append(f"ifFalse {val_cond} goto {lbl}")
            continue
            
        linhas_passo1.append(linha)
        
    return linhas_passo1

def simplificar_condicoes(linhas):
    linhas_simplificadas = []
    for linha in linhas:
        match = re_if.match(linha)
        if match:
            cond, lbl = match.groups()
            if cond == '0':
                # ifFalse 0 (Falso) -> Significa Verdadeiro! Ele SEMPRE pula. Vira um goto incondicional.
                linhas_simplificadas.append(f"goto {lbl}")
            elif cond.isnumeric() and cond != '0':
                # ifFalse 1 (Verdadeiro) -> Significa Falso! Ele NUNCA pula. Linha ignorada/morta.
                continue
            else:
                linhas_simplificadas.append(linha)
        else:
            linhas_simplificadas.append(linha)
            
    return linhas_simplificadas

def eliminar_codigo_morto_reachability(linhas):
    if not linhas: return []

    # Mapeia onde cada label está no código
    labels_map = {}
    for i, linha in enumerate(linhas):
        if match := re_label.match(linha):
            labels_map[match.group(1)] = i

    reachable_idx = set()
    queue = [0]

    # Percorre os caminhos possíveis
    while queue:
        idx = queue.pop(0)
        if idx in reachable_idx or idx >= len(linhas):
            continue

        reachable_idx.add(idx)
        linha = linhas[idx]

        if match := re_goto.match(linha):
            lbl = match.group(1)
            if lbl in labels_map:
                queue.append(labels_map[lbl])
            
        elif match := re_if.match(linha):
            lbl = match.group(2)
            if lbl in labels_map:
                queue.append(labels_map[lbl])
            queue.append(idx + 1)
            
        else:
            queue.append(idx + 1)

    labels_alvos = set()
    for linha in linhas:
        if match := re_goto.match(linha): labels_alvos.add(match.group(1))
        elif match := re_if.match(linha): labels_alvos.add(match.group(2))

    # O filtro de limpeza agora é mais inteligente
    linhas_limpas = []
    for i in sorted(list(reachable_idx)):
        linha = linhas[i]
        if match := re_label.match(linha):
            if match.group(1) in labels_alvos:
                linhas_limpas.append(linha)
            else:
                # Label inútil sem nenhum salto apontando para ele
                continue 
        else:
            linhas_limpas.append(linha)
    return linhas_limpas
    

def eliminar_variaveis_mortas(linhas):
    variaveis_vivas = set()
    linhas_finais = []

    def eh_temporario_do_compilador(nome_variavel):
        return '_' not in nome_variavel
    
    # Se a variável não for usada ou for só de fantoche (é atribuída várias vezes e nunca usada em cálculo), ela é deletada
    # Basicamente verifica se ela já esteve do lado direito de uma operação
    variaveis_por_label = {}
    current_label = None
    
    for linha in linhas:
        if match := re_label.match(linha):
            current_label = match.group(1)
            variaveis_por_label[current_label] = set()
        elif current_label:
            if match := re_binop.match(linha):
                res, arg1, op, arg2 = match.groups()
                if not arg1.isnumeric(): variaveis_por_label[current_label].add(arg1)
                if not arg2.isnumeric(): variaveis_por_label[current_label].add(arg2)
            elif match := re_assign.match(linha):
                res, arg1 = match.groups()
                if not arg1.isnumeric(): variaveis_por_label[current_label].add(arg1)
            elif match := re_if.match(linha):
                cond, lbl = match.groups()
                if not cond.isnumeric(): variaveis_por_label[current_label].add(cond)

    for linha in reversed(linhas): 
        if linha.startswith('label '):
            linhas_finais.append(linha)
            continue
            
        if match := re_goto.match(linha):
            lbl_destino = match.group(1)
            if lbl_destino in variaveis_por_label:
                variaveis_vivas.update(variaveis_por_label[lbl_destino])
            linhas_finais.append(linha)
            continue
            
        match_if = re_if.match(linha)
        if match_if:
            cond, lbl = match_if.groups()
            if not cond.isnumeric(): variaveis_vivas.add(cond)
            if lbl in variaveis_por_label:
                variaveis_vivas.update(variaveis_por_label[lbl])
            linhas_finais.append(linha)
            continue
            
        match_binop = re_binop.match(linha)
        if match_binop:
            res, arg1, op, arg2 = match_binop.groups()            
            
            if eh_temporario_do_compilador(res) and res not in variaveis_vivas:
                continue         
            
            if res in variaveis_vivas: variaveis_vivas.remove(res)
            if not arg1.isnumeric(): variaveis_vivas.add(arg1)
            if not arg2.isnumeric(): variaveis_vivas.add(arg2)
            linhas_finais.append(linha)
            continue
            
        match_assign = re_assign.match(linha)
        if match_assign:
            res, arg1 = match_assign.groups()          
            
            if eh_temporario_do_compilador(res) and res not in variaveis_vivas:
                continue           
            
            if res in variaveis_vivas: variaveis_vivas.remove(res)
            if not arg1.isnumeric(): variaveis_vivas.add(arg1)
            linhas_finais.append(linha)
            continue
            
        linhas_finais.append(linha)
        
    linhas_finais.reverse()
    return linhas_finais


def otimizar_tac(arquivo_entrada, arquivo_saida):
    with open(arquivo_entrada, 'r') as f:
        linhas = [linha.strip() for linha in f if linha.strip()]

    l1 = propagacao_e_algebra(linhas)
    l2 = simplificar_condicoes(l1)
    l3 = eliminar_codigo_morto_reachability(l2)
    l4 = eliminar_variaveis_mortas(l3)

    with open(arquivo_saida, 'w') as f:
        for linha in l4:
            f.write(linha + '\n')
            
    print("[Otimização concluída com sucesso e salva em 'saida_otimizada.tac'!")

if __name__ == "__main__":
    otimizar_tac('saida.tac', 'saida_otimizada.tac')