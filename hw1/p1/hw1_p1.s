.globl __start

.rodata
    msge: .string "\n "
    msg0: .string "This is HW1-1: Extended Euclidean Algorithm\n"
    msg1: .string "Enter a number for input x: "
    msg2: .string "Enter a number for input y: "
    msg3: .string "The result is:\n "
    msg4: .string "GCD: "
    msg5: .string "a: "
    msg6: .string "b: "
    msg7: .string "inv(x modulo y): "

.text
################################################################################
  # You may write function here

gcd:
    beq a1, x0, baseCase
    
    rem t0, a0, a1
    div t1, a0, a1
    mv a0, a1
    mv a1, t0
    
    addi sp, sp, -12
    sw ra, 0(sp)
    sw t1, 4(sp)
    sw a1, 8(sp)

    jal ra, gcd
    
    lw ra, 0(sp)
    lw t1, 4(sp)
    lw a1, 8(sp)
    addi sp, sp, 12
    
    mv t0, s1
    mv s1, s2
    mul t1, t1, s2
    sub s2, t0, t1
    jalr x0, 0(ra)

baseCase:
    li s1, 1
    li s2, 0
    mv s0, a0
    jalr x0, 0(ra)

modInverse:
    addi t0, x0, 1
    bne s0, t0, noInverse
    
    mv a0, s1
    
    blt a0, x0, invPos
    beq x0, x0, invDone

noInverse:
    li s3, 0
    jalr x0, 0(ra)
    
invPos:
    add a0, a0, t2
    blt a0, x0, invPos
    beq x0, x0, invDone


invDone:
    mv s3, a0
    jalr x0, 0(ra)
    
    
################################################################################
__start:
  # Prints msg0
    addi a0, x0, 4
    la a1, msg0
    ecall

  # Prints msg1
    addi a0, x0, 4
    la a1, msg1
    ecall

  # Reads int1
    addi a0, x0, 5
    ecall
    add t0, x0, a0
    
  # Prints msg2
    addi a0, x0, 4
    la a1, msg2
    ecall
    
  # Reads int2
    addi a0, x0, 5
    ecall
    add a1, x0, a0
    add a0, x0, t0
    addi t0, x0, 0
    
################################################################################ 
  # You can do your main function here
    
    mv t2, a1
    jal ra, gcd
    jal ra, modInverse
    
################################################################################

result:
    addi t0, a0, 0
  # Prints msg
    addi a0, x0, 4
    la a1, msg3
    ecall
    
    addi a0, x0, 4
    la a1, msg4
    ecall

  # Prints the result in s0
    addi a0, x0, 1
    add a1, x0, s0
    ecall
    
    addi a0, x0, 4
    la a1, msge
    ecall
    addi a0, x0, 4
    la a1, msg5
    ecall
    
  # Prints the result in s1
    addi a0, x0, 1
    add a1, x0, s1
    ecall
    
    addi a0, x0, 4
    la a1, msge
    ecall
    addi a0, x0, 4
    la a1, msg6
    ecall
    
  # Prints the result in s2
    addi a0, x0, 1
    add a1, x0, s2
    ecall
    
    addi a0, x0, 4
    la a1, msge
    ecall
    addi a0, x0, 4
    la a1, msg7
    ecall
    
  # Prints the result in s3
    addi a0, x0, 1
    add a1, x0, s3
    ecall
    
  # Ends the program with status code 0
    addi a0, x0, 10
    ecall
    