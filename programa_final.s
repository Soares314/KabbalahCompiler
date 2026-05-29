.text
.globl main
main:
    add t0, t1, t2
    add t3, t4, t5
    mul a0, t0, t3
    mv a1, a0
    li t6, 2
    mul a2, t1, t6
    li t6, 4
    mul a3, t2, t6
    add a4, a2, a3
    mv a5, a4
    add a6, t1, t2
    add a7, t1, t2
    sub t0, a6, a7
    add t1, t0, t4
    mv t2, t1
    mv t3, a5
    mv t4, t3
    mv t5, t4
    mv a0, t5
    sub a1, t2, t2
    add a2, t1, a1
    mv a3, a2
    mv a4, a3
    add a5, t1, t2
    sub a6, t4, t5
    mul a7, a5, a6
    add t0, t1, t2
    sub t1, t2, t3
    mul t4, t0, t1
    add t5, a7, t4
    mv a0, t5
    li t6, 8
    mul a1, a2, t6
    li t6, 2
    mul a3, a2, t6
    add a4, a1, a3
    mv a5, a4
    add a6, a1, a5
    li t6, 2
    mul a7, a6, t6
    add t0, a1, a5
    mv t1, t0
    sub t2, a7, t1
    mv t3, t2
    li t6, 8
    mul t4, t1, t6
    li t6, 2
    mul t5, t1, t6
    add a0, t4, t5
    li t6, 4
    mul a1, t1, t6
    sub a2, a0, a1
    mv a3, a2

    # Fim do programa
    li a7, 10
    ecall
