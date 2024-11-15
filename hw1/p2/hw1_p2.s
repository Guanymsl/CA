.globl __start

.rodata
    msg0: .string "This is HW1-2: Longest Substring without Repeating Characters\n"
    msg1: .string "Enter a string: "
    msg2: .string "Answer: "
.text

# Please use "result" to print out your final answer
################################################################################
# result function
# Usage:
#     1. Store the beginning address in t4
#     2. Use "j print_char"
#     The function will print the string stored t4
#     When finish, the whole program will return value 0
result:
    addi a0, x0, 4
    la a1, msg2
    ecall

    add a1, x0, t4
    ecall
# Ends the program with status code 0
    addi a0, x0, 10
    ecall
################################################################################

__start:
# Prints msg
    addi a0, x0, 4
    la a1, msg0
    ecall

    la a1, msg1
    ecall

    addi a0, x0, 8

    li a1, 0x10200
    addi a2, x0, 2047
    ecall
# Load address of the input string into a0
    add a0, x0, a1

################################################################################
# DO NOT MODIFY THE CODE ABOVE
################################################################################
# Write your main function here.
# a0 stores the beginning address (66048(0x10200)) of the Plaintext
    
    mv t0, a0
    mv t4, a0
    li t5, 0
    mv t6, a0
    
checkForward:
    lbu t2, 0(t0)
    beq t2, x0, end
    li t1, 10
    beq t2, t1, end
    
    mv t1, t0
    addi t1, t1, -1

checkBackward:
    blt t1, t6, terminate
    
    lbu t3, 0(t1)
    beq t3, t2, terminate
    
    addi t1, t1, -1
    j checkBackward
    
terminate:
    sub t3, t0, t1
    addi t6, t1, 1
    addi t0, t0, 1

    bge t3, t5, update

    j checkForward
    
update:
    mv t5, t3
    mv t4, t6
    j checkForward

end:
    add t1, t4, t5
    sb x0, 0(t1)
    j result
