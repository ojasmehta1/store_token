#Name: Ojas Mehta
	.data
TOKEN:	.word 	0x20202020,0x20202020
tokArray: .word	0:60
inBuf:	.space	80
retAddr: .word	0
st_prompt:	.asciiz	"Enter a new input line. \n"

	.text

.globl main
main:
	jal	getline
	li	$a3, 0
	li	$t5,0
	li	$s3,0			
	la	$s1, Q0			#goto next state

nextState:	lw	$s2, ($s1)
	jalr	$v1, $s2	# Save return addr in $v1

	abs	$s0, $s0
	sll	$s0, $s0, 2	# Multiply by 4 for word boundary
	add	$s1, $s1, $s0
	sra	$s0, $s0, 2 	#Divide by 4 to reset
	lw	$s1, 0($s1)
	b	nextState

cleanup:jal	printIn
	jal	printTab	
	jal	clearIn
	jal	clearTab
	b 	main

exit:		# stop program
			li	$v0,10
			syscall
ACT1: 
	lb	$a0, inBuf($t5)			# get next char
	jal	lin_search			# get char type
	addi	$t5, $t5, 1			# increment
	jr	$v1
	
ACT2:
	move	$s3, $0	#reset s3
	sb	$a0, TOKEN($s3) #get char from TOKEN
	addi	$s3, $s3, 1	#increment
	move	$t1, $s0	# char to TOKEN
	jr 	$v1
	
ACT3:
	bgt 	$s3, 7, ACT4 #goto ACT4 is s3 <= 7
	sb	$a0, TOKEN($s3)	#get char from TOKEN
	addi	$s3, $s3, 1	#increment
	jr 	$v1

ACT4:
	lw	$t9, TOKEN($0) #get word from TOKEN
	sw	$t9, tokArray($a3)	#add word to TokArray
	addi	$a3, $a3, 4 #increment
	lw	$t9, TOKEN+4($0)	#shift to next word and load it
	sw	$t9, tokArray($a3)	#store it in token array
	beq	$t1, 6, putPound	#add pound sign
	b	ACT4save
	
putPound:
	li $t1, 5 # adds '5' for a pound sign

ACT4save:
	addi	$t6, $t1, 48 #offset
	addi	$a3, $a3, 4	#increment
	sw 	$t6, tokArray($a3)	#save to tokArray
	lb	$t6, tokArray($a3)	#get from tokArray
	addi 	$a3, $a3, 1	#increment
	sb 	$t6, tokArray($a3)	#put it back to tokArray
	li	$t6, '\n'	
	addi	$a3, $a3, 1
	sb	$t6, tokArray($a3) #add new line to tokArray
	subi	$a3, $a3, 2 
	li	$t6, '\t'
	sb	$t6, tokArray($a3) #add tab to tokArray
	li	$t7, 0x20 #reset
	li	$t8, 0	

loop2:
	#get to the end of TOKEN
	sb	$t7, TOKEN($t8) 
	addi	$t8, $t8, 1
	blt	$t8, 8, loop2		
	addi	$a3, $a3, 4
	li	$s3, 0
	jr	$v1

printIn:
	la $a0, inBuf
	li $v0, 4
	syscall
	jr $ra	

# Print Table
printTab:
	li 	$t7, 0
	
printLoop:
	#go through tokArray to print
	la 	$a0, tokArray($t7)
	li	$v0, 4
	syscall
	addi	$t7, $t7, 12
	blt	$t7, 240, printLoop
	jr	$ra

clearIn:
	li $t7, 0
	li $s0, 0

cleanLoop:
	sb	$0, inBuf($t7)
	addi	$t7, $t7, 1
	ble	$t7, 80, cleanLoop
	li	$t0, 0
	jr 	$ra


clearTab:
	li	 $t7, 0	
	li	 $t8, 60
	
cleanTokArray:
		sb	$0, tokArray($t7)
		addi	$t7, $t7, 1
		blt 	$t7, $t8, cleanTokArray
		jr	$ra

ERROR:
	li	$v0, 4
	syscall
	
	jr	$v1
	
RETURN:
	beq	$t1, 5, cleanup
	la	$t8, Q3	
	lw	$t8, ($t8)	
	jalr	$v1, $t8	
	b 	cleanup
	
getline: 
	
	la	$a0, st_prompt		# Prompt to enter a new line
	li	$v0, 4
	syscall

	la	$a0, inBuf		# read a new line
	li	$a1, 80	
	li	$v0, 8
	syscall
	
	li 	$s4, 0
	li	$t8, '#'

getLoop:
	lb	$t7, inBuf($s4)
	bge	$s4, 79, lastChar
	beq	$t7, '\0', lastChar
	beq	$t7, '\n', lastChar
	addi 	$s4, $s4, 1
	b getLoop
	
lastChar:
	sb	$t8, inBuf($s4)
	jr 	$ra
	
	#########
	#
	# function lin_search
	#	input: search key in $s0
	#	output: char type in ...
	#
	########	
lin_search:
	li	$t0,0	
	li	$s0, 7		
loop:
	bge	$t0, 72, return
	sll	$t0, $t0, 3
	lw	$t9, Tabchar($t0)
	sra	$t0, $t0, 3
	bne	$t9, $a0, nextCharInc
	
	sll	$t0, $t0, 3
	addi	$t0, $t0, 4
	lw	$t8, Tabchar($t0)
	move	$s0,$t8	
	b	return
	
nextCharInc:
	addi	$t0, $t0, 1 
	b	loop
return:	jr	$ra

		.data
STAB:
Q0:     .word  ACT1
        .word  Q1   # T1
        .word  Q1   # T2
        .word  Q1   # T3
        .word  Q1   # T4
        .word  Q1   # T5
        .word  Q1   # T6
        .word  Q11  # T7

Q1:     .word  ACT2
        .word  Q2   # T1
        .word  Q5   # T2
        .word  Q3   # T3
        .word  Q3   # T4
        .word  Q0   # T5
        .word  Q4   # T6
        .word  Q11  # T7

Q2:     .word  ACT1
        .word  Q6   # T1
        .word  Q7   # T2
        .word  Q7   # T3
        .word  Q7   # T4
        .word  Q7   # T5
        .word  Q7   # T6
        .word  Q11  # T7

Q3:     .word  ACT4
        .word  Q0   # T1
        .word  Q0   # T2
        .word  Q0   # T3
        .word  Q0   # T4
        .word  Q0   # T5
        .word  Q0   # T6
        .word  Q11  # T7

Q4:     .word  ACT4
        .word  Q10  # T1
        .word  Q10  # T2
        .word  Q10  # T3
        .word  Q10  # T4
        .word  Q10  # T5
        .word  Q10  # T6
        .word  Q11  # T7

Q5:     .word  ACT1
        .word  Q8   # T1
        .word  Q8   # T2
        .word  Q9   # T3
        .word  Q9   # T4
        .word  Q9   # T5
        .word  Q9   # T6
        .word  Q11  # T7

Q6:     .word  ACT3
        .word  Q2   # T1
        .word  Q2   # T2
        .word  Q2   # T3
        .word  Q2   # T4
        .word  Q2   # T5
        .word  Q2   # T6
        .word  Q11  # T7

Q7:     .word  ACT4
        .word  Q1   # T1
        .word  Q1   # T2
        .word  Q1   # T3
        .word  Q1   # T4
        .word  Q1   # T5
        .word  Q1   # T6
        .word  Q11  # T7

Q8:     .word  ACT3
        .word  Q5   # T1
        .word  Q5   # T2
        .word  Q5   # T3
        .word  Q5   # T4
        .word  Q5   # T5
        .word  Q5   # T6
        .word  Q11  # T7

Q9:     .word  ACT4
        .word  Q1  # T1
        .word  Q1  # T2
        .word  Q1  # T3
        .word  Q1  # T4
        .word  Q1  # T5
        .word  Q1  # T6
        .word  Q11 # T7

Q10:	.word	RETURN
        .word  Q10  # T1
        .word  Q10  # T2
        .word  Q10  # T3
        .word  Q10  # T4
        .word  Q10  # T5
        .word  Q10  # T6
        .word  Q11  # T7

Q11:    .word  ERROR 
	.word  Q4  # T1
	.word  Q4  # T2
	.word  Q4  # T3
	.word  Q4  # T4
	.word  Q4  # T5
	.word  Q4  # T6
	.word  Q4  # T7
	
Tabchar: 	
	.word 	0x0a, 6		# LF
	.word 	' ', 5
 	.word 	'#', 6
	.word 	'$', 4
	.word 	'(', 4 
	.word 	')', 4 
	.word 	'*', 3 
	.word 	'+', 3 
	.word 	',', 4 
	.word 	'-', 3 
	.word 	'.', 4 
	.word 	'/', 3 

	.word 	'0', 1
	.word 	'1', 1 
	.word 	'2', 1 
	.word 	'3', 1 
	.word 	'4', 1 
	.word 	'5', 1 
	.word 	'6', 1 
	.word 	'7', 1 
	.word 	'8', 1 
	.word 	'9', 1 

	.word 	':', 4 

	.word 	'A', 2
	.word 	'B', 2 
	.word 	'C', 2 
	.word 	'D', 2 
	.word 	'E', 2 
	.word 	'F', 2 
	.word 	'G', 2 
	.word 	'H', 2 
	.word 	'I', 2 
	.word 	'J', 2 
	.word 	'K', 2
	.word 	'L', 2 
	.word 	'M', 2 
	.word 	'N', 2 
	.word 	'O', 2 
	.word 	'P', 2 
	.word 	'Q', 2 
	.word 	'R', 2 
	.word 	'S', 2 
	.word 	'T', 2 
	.word 	'U', 2
	.word 	'V', 2 
	.word 	'W', 2 
	.word 	'X', 2 
	.word 	'Y', 2
	.word 	'Z', 2

	.word 	'a', 2 
	.word 	'b', 2 
	.word 	'c', 2 
	.word 	'd', 2 
	.word 	'e', 2 
	.word 	'f', 2 
	.word 	'g', 2 
	.word 	'h', 2 
	.word 	'i', 2 
	.word 	'j', 2 
	.word 	'k', 2
	.word 	'l', 2 
	.word 	'm', 2 
	.word 	'n', 2 
	.word 	'o', 2 
	.word 	'p', 2 
	.word 	'q', 2 
	.word 	'r', 2 
	.word 	's', 2 
	.word 	't', 2 
	.word 	'u', 2
	.word 	'v', 2 
	.word 	'w', 2 
	.word 	'x', 2 
	.word 	'y', 2
	.word 	'z', 2

	.word	'\\', -1	# if you ‘\’ as the end-of-table symbol