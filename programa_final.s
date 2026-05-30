.text
.globl main
main:
    li t0, 2
    li t6, 2
    li t5, 5
    slt t1, t5, t6
    beqz t1, L1
    li t2, 1
    j L2
L1:
    li t3, 2
L2:

    # Fim do programa
    li a7, 10
    ecall
