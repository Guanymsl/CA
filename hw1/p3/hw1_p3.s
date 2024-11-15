.globl __start

.rodata
    O_RDWR: .word 0b0000100
    msg1: .string "This is problem 3\n"
    msg2: .string " "
.text

__start:
  li a0, 4
  la a1, msg1
  ecall
  li a0, 13      # ecall code
  la a1, pattern
  lw a2, O_RDWR  # load O_RDWR open flag
  ecall
  # Load address of the input string into a0
  add a1, x0, a0
  li a0, 14      # ecall code
  li a2, 0x10200 # modify to a bigger number if your code is too long
  li a3, 94      # number of bytes to read
  ecall
  li a0, 16
  ecall
  addi t0, x0, 94
  add t1, x0, x0
Shift_ascii:
  add t3, t1, a2
  lb t2, 0(t3)
  addi t2, t2, -32
  add t3, t1, a2
  sb t2, 0(t3)
  addi t1, t1, 1
  bne t0, t1, Shift_ascii
  jal x0, your_function

Exit:
  li a0, 1
  add a1, x0, t0
  ecall
  beq t0, x0, Terminate
  li a0, 4
  la a1, msg2
  ecall
  li a0, 1
  add a1, x0, t1
  ecall
Terminate:
  addi a0, x0, 10
  ecall
################################################################################
# DO NOT MODIFY THE CODE ABOVE
################################################################################

.rodata
    pattern: .string "../../b12901024_hw1/p3/pattern0.txt"
    # pattern: .string "../../{student id}_hw1/p3/pattern1.txt"
    # pattern: .string "../../{student id}_hw1/p3/pattern2.txt"
.text

# Write your main function here.
# a2(i.e.,x12) stores the heads address
# store whether there is cycle in t0
# store the entry point in t1
# go to Exit when your function is finish

your_function:
    mv t2, a2
    li t5, 94
    li t6, -1

traverse:
    lb t3, 0(t2)
    beq t3, t5, noCycle
    
    add t3, t3, a2
    lb t4, 0(t3)
    beq t4, t6, cycleDetected

    sb t6, 0(t2)
    mv t2, t3
    beq x0, x0, traverse

noCycle:
    li t0, 0
    jal x0, Exit

cycleDetected:
    li t0, 1
    sub t3, t3, a2
    mv t1, t3
    jal x0, Exit
