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

    # --- GERENCIADOR DE REGISTRADORES ---
    regs_disponiveis = [f"t{i}" for i in range(6)] + [f"a{i}" for i in range(8)]
    mapa_variaveis = {}

    def obter_reg(variavel):
        """Retorna o registrador associado a uma variável (ou cria um novo)"""
        if variavel not in mapa_variaveis:
            reg = regs_disponiveis[len(mapa_variaveis) % len(regs_disponiveis)]
            mapa_variaveis[variavel] = reg
        return mapa_variaveis[variavel]

    codigo_asm = []

    # Cabeçalho padrão RISC-V
    codigo_asm.append(".text")
    codigo_asm.append(".globl main")
    codigo_asm.append("main:")

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
            instrucao = (
                "BINOP",
                match.group(1),
                match.group(2),
                match.group(3),
                match.group(4),
            )
        else:
            continue

        # ========================================================
        # MATCH-CASE PARA TRADUÇÃO RISC-V
        # ========================================================
        match instrucao:

            case ("LABEL", lbl):
                codigo_asm.append(f"{lbl}:")

            case ("GOTO", lbl):
                codigo_asm.append(f"    j {lbl}")

            case ("IFFALSE", cond, lbl):
                reg_cond = obter_reg(cond)
                codigo_asm.append(f"    beqz {reg_cond}, {lbl}")

            case ("ASSIGN", res, arg1):
                reg_res = obter_reg(res)
                if arg1.lstrip("-").isnumeric():
                    codigo_asm.append(f"    li {reg_res}, {arg1}")
                else:
                    reg_arg = obter_reg(arg1)
                    codigo_asm.append(f"    mv {reg_res}, {reg_arg}")

            case ("BINOP", res, arg1, op, arg2):
                reg_res = obter_reg(res)

                reg_arg1 = obter_reg(arg1) if not arg1.lstrip("-").isnumeric() else "t6"
                if arg1.lstrip("-").isnumeric():
                    codigo_asm.append(f"    li t6, {arg1}")

                reg_arg2 = obter_reg(arg2) if not arg2.lstrip("-").isnumeric() else "t6"
                if arg2.lstrip("-").isnumeric():
                    reg_arg2 = "t6" if not arg1.lstrip("-").isnumeric() else "t5"
                    codigo_asm.append(f"    li {reg_arg2}, {arg2}")

                match op:
                    case "+":
                        codigo_asm.append(f"    add {reg_res}, {reg_arg1}, {reg_arg2}")
                    case "-":
                        codigo_asm.append(f"    sub {reg_res}, {reg_arg1}, {reg_arg2}")
                    case "*":
                        codigo_asm.append(f"    mul {reg_res}, {reg_arg1}, {reg_arg2}")
                    case "/":
                        codigo_asm.append(f"    div {reg_res}, {reg_arg1}, {reg_arg2}")
                    case "<":
                        codigo_asm.append(f"    slt {reg_res}, {reg_arg1}, {reg_arg2}")
                    case ">":
                        codigo_asm.append(f"    slt {reg_res}, {reg_arg2}, {reg_arg1}")
                    case "==":
                        codigo_asm.append(f"    sub {reg_res}, {reg_arg1}, {reg_arg2}")
                        codigo_asm.append(f"    seqz {reg_res}, {reg_res}")

    # Syscall 10 para Sair
    codigo_asm.append("\n    # Fim do programa")
    codigo_asm.append("    li a7, 10")
    codigo_asm.append("    ecall")

    with open(arquivo_saida, "w") as f:
        for linha in codigo_asm:
            f.write(linha + "\n")

    print(f"[RISC-V] Arquivo '{arquivo_saida}' gerado com sucesso!")


if __name__ == "__main__":
    gerar_assembly_riscv("saida_otimizada.tac", "programa_final.s")
