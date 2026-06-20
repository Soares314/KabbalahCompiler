import re


# ===== A arquitetura de Assembly escolhida foi a RISC-V
def gerar_assembly_riscv(arquivo_tac, arquivo_saida):
    re_label = re.compile(r"^label\s+(\w+)$")
    re_goto = re.compile(r"^goto\s+(\w+)$")
    re_if = re.compile(r"^ifFalse\s+([a-zA-Z0-9_]+)\s+goto\s+(\w+)$")
    re_assign = re.compile(r"^(\w+)\s*=\s*([a-zA-Z0-9_\-]+)$")
    re_binop = re.compile(
        r"^(\w+)\s*=\s*([a-zA-Z0-9_\-]+)\s*(==|!=|>=|<=|<|>|\+|\-|\*|\/)\s*([a-zA-Z0-9_\-]+)$"
    )

    with open(arquivo_tac, "r") as f:
        linhas = [linha.strip() for linha in f if linha.strip()]

    # --- SCAN DE VARIÁVEIS (Descobrindo o tamanho da Stack) ---
    variaveis_unicas = set()
    for linha in linhas:
        if match := re_assign.match(linha):
            variaveis_unicas.add(match.group(1))
            if not match.group(2).lstrip("-").isnumeric():
                variaveis_unicas.add(match.group(2))
        elif match := re_binop.match(linha):
            variaveis_unicas.add(match.group(1))
            if not match.group(2).lstrip("-").isnumeric(): variaveis_unicas.add(match.group(2))
            if not match.group(4).lstrip("-").isnumeric(): variaveis_unicas.add(match.group(4))
        elif match := re_if.match(linha):
            variaveis_unicas.add(match.group(1))

    # --- (Calculando Offsets) ---
    tamanho_frame = len(variaveis_unicas) * 4
    
    # RISC-V exige que a stack seja alinhada em 16 bytes
    if tamanho_frame % 16 != 0:
        tamanho_frame += 16 - (tamanho_frame % 16)

    print(f"[DEBUG] Tamanho do Stack Frame: {tamanho_frame} bytes")

    mapa_stack = {}
    offset_atual = 0
    for var in variaveis_unicas:
        mapa_stack[var] = offset_atual
        offset_atual += 4

    # --- FUNÇÕES AUXILIARES DE MEMÓRIA ---
    def carregar_valor(arg, reg_destino):
        """Se for número, faz um load immediate. Se for variável, busca da stack."""
        if arg.lstrip("-").isnumeric():
            return f"    li {reg_destino}, {arg}"
        else:
            offset = mapa_stack[arg]
            return f"    lw {reg_destino}, {offset}(sp)"

    def salvar_valor(var_destino, reg_origem):
        """Pega o valor do registrador e guarda no espaço da variável na stack."""
        offset = mapa_stack[var_destino]
        return f"    sw {reg_origem}, {offset}(sp)"

    # --- GERAÇÃO DE CÓDIGO ---
    codigo_asm = []

    # Cabeçalho e Stack
    codigo_asm.append(".text")
    codigo_asm.append(".globl main")
    codigo_asm.append("main:")
    codigo_asm.append(f"    addi sp, sp, -{tamanho_frame}")

    for linha in linhas:
        if match := re_label.match(linha):
            instrucao = ("LABEL", match.group(1))
        elif match := re_goto.match(linha):
            instrucao = ("GOTO", match.group(1))
        elif match := re_if.match(linha):
            instrucao = ("IFFALSE", match.group(1), match.group(2))
        elif match := re_assign.match(linha):
            instrucao = ("ASSIGN", match.group(1), match.group(2))
        elif match := re_binop.match(linha):
            instrucao = ("BINOP", match.group(1), match.group(2), match.group(3), match.group(4))
        else:
            continue
            
        # MATCH-CASE PARA TRADUÇÃO RISC-V (Agora baseado em memória!)
        match instrucao:
            case ("LABEL", lbl):
                codigo_asm.append(f"{lbl}:")

            case ("GOTO", lbl):
                codigo_asm.append(f"    j {lbl}")

            case ("IFFALSE", cond, lbl):
                codigo_asm.append(carregar_valor(cond, "t0"))
                codigo_asm.append(f"    beqz t0, {lbl}")

            case ("ASSIGN", res, arg1):
                codigo_asm.append(carregar_valor(arg1, "t0"))
                codigo_asm.append(salvar_valor(res, "t0"))

            case ("BINOP", res, arg1, op, arg2):
                codigo_asm.append(carregar_valor(arg1, "t0"))
                codigo_asm.append(carregar_valor(arg2, "t1"))

                match op:
                    case "+": codigo_asm.append("    add t0, t0, t1")
                    case "-": codigo_asm.append("    sub t0, t0, t1")
                    case "*": codigo_asm.append("    mul t0, t0, t1")
                    case "/": codigo_asm.append("    div t0, t0, t1")
                    case "<": codigo_asm.append("    slt t0, t0, t1")
                    case ">": codigo_asm.append("    slt t0, t1, t0")
                    case "==": 
                        codigo_asm.append("    sub t0, t0, t1")
                        codigo_asm.append("    seqz t0, t0")
                    case "!=":
                        codigo_asm.append("    sub t0, t0, t1")
                        codigo_asm.append("    sneqz t0, t0")
                    case "<=":
                        codigo_asm.append("    slt t0, t1, t0")
                        codigo_asm.append("    xori t0, t0, 1")
                    case ">=":
                        codigo_asm.append("    slt t0, t0, t1")
                        codigo_asm.append("    xori t0, t0, 1")

                codigo_asm.append(salvar_valor(res, "t0"))

    # Fim do programa
    codigo_asm.append("\n    # Fim do programa")
    codigo_asm.append(f"    addi sp, sp, {tamanho_frame}")
    codigo_asm.append("    li a7, 10")
    codigo_asm.append("    ecall")

    with open(arquivo_saida, "w") as f:
        for linha in codigo_asm:
            f.write(linha + "\n")

    print(f"[RISC-V] Arquivo '{arquivo_saida}' gerado com sucesso!")


if __name__ == "__main__":
    gerar_assembly_riscv("saida_otimizada.tac", "programa_final.s")
