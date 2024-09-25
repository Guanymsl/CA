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


################################################################################

result:
    addi t0,a0,0
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