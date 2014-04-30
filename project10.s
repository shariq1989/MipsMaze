#==============================================================================
# maze.s
#
# by Patrick Kelley
#
# This program produces a maze in an 80 X 24 grid by recursively pathing 
# through the grid space.  It is an implementation of the following C++ code
# and is an example of equivalent coding.  As such, the complete code is given
# below and then repeated as comments in the assembly code.
#
# This code is intended to be built in the QTSPIM environment and run at a
# console command prompt with no parameters.  Each run should produce a unique
# maze.
#
# Last modified: 3/31/2014 by Patrick Kelley
#==============================================================================

#==============================================================================
# BEGIN IMPLEMENTATION
#==============================================================================

#==============================================================================
# SETUP:
#
# #include <iostream>
# using namespace std;
#==============================================================================
	# nothing to do here; standard for MIPS

#==============================================================================
# CONSTANTS:
#
# #define GRID_WIDTH 79			
# #define GRID_HEIGHT 23
# #define NORTH 0
# #define EAST 1
# #define SOUTH 2
# #define WEST 3
#==============================================================================
	.data
inputWIDTH: 	.asciiz 	"\n\nPlease enter maze width between 11 and 99: "
inputHEIGHT: 	.asciiz 	"\n\nPlease enter maze height between 11 and 99: "
GRID_WIDTH:	.word	80		# need to add 1 to print as string
GRID_HEIGHT:	.word	23
GRID_SIZE:	.word	1840		# because I can't precalculate it in
					# MIPS like I could in MASM
NORTH:		.word	0
EAST:		.word   1
SOUTH:		.word	2
WEST:		.word	3
RGEN:		.word	1073807359	# a sufficiently large prime for rand
POUND:		.byte	35		# the '#' character
SPACE:		.byte	32		# the ' ' character
NEWLINE:	.byte	10		# the newline character

#==============================================================================
# STRING VARIABLES
#
# Think of them as string constants for prompts and such
#==============================================================================

rsdPrompt:	.asciiz "Enter a seed number (1073741824 - 2147483646): "
smErr1:		.asciiz "That number is too small, try again: "
bgErr:		.asciiz "That number is too large, try again: "
newLine:	.asciiz "\n"

#==============================================================================
# GLOBAL VARIABLES
#
# char grid[GRID_WIDTH*GRID_HEIGHT];
#==============================================================================

grid:	.space	1841		# ((79 + 1) * 23) + 1 bytes reserved for grid
rSeed:	.word	0		# a seed for generating a random number

#==============================================================================
# FUNCTION PROTOTYPES:
#==============================================================================
# Only listed here because it is not necessary to forward-declare in assembly
# void ResetGrid();
# int XYToIndex( int x, int y );
# int IsInBounds( int x, int y );
# void Visit( int x, int y );
# void PrintGrid();
# int srand();                  # adding function to get random seed from user
# int rand(int min, int max);	# adding function to get a random from a range

#==============================================================================
# FUNCTIONS:
#==============================================================================
	.text
	.globl main
#==============================================================================
# int main()
# {
#   // Starting point and top-level control.
#   srand( time(0) ); // seed random number generator.
#   ResetGrid();
#   Visit(1,1);
#   PrintGrid();
#   return 0;
# }
#==============================================================================
main:
	sw	$ra, 0($sp)	# save the return address
	jal	handleWIDTH	# get width
	jal	handleHEIGHT	# get height
	jal	handleGRID_SIZE # calculate grid size
	jal	srand		# get a random seed
	jal	ResetGrid	# reset the grid to '#'s
	li	$t0, 1		# set up for start of generation at (1,1)
	sw	$t0, -4($sp)	# push first param
	sw	$t0, -8($sp) 	# push second param
#	jal	Visit		# start the recursive generation
	jal	PrintGrid	# display the grid
	lw	$ra, 0($sp)	# restore the return address
	jr	$ra		# exit the program

#==============================================================================
# void ResetGrid()
# {
#   // Fills the grid with walls ('#' characters).
#   for (int i=0; i<GRID_WIDTH*GRID_HEIGHT; ++i)
#   {
#     grid[i] = '#';
#   }
# }
#==============================================================================
ResetGrid:
	# It's a waste do do a stack frame when there are no parameters or
	# return values, so I'll optimize and simply push any register I use
	# onto the stack.  I need 7, a loop counter, a place to store the
	# loop bound for comparison, the base address of the grid, a register
	# to store the character value I will write, a register to store the
	# width of the grid, a register to store the newline character, and
	# finally, a register to hold calculation results.
	
	# save the registers
	sw	$s0, -4($sp)	# $s0 will be the loop counter
	sw	$s1, -8($sp)	# $s1 will hold the array bound
	sw	$s2, -12($sp)	# $s2 will be the grid base address
	sw	$s3, -16($sp)	# $s3 will hold the character
	sw	$s4, -20($sp)	# $s4 will hold the grid width
	sw      $s5, -24($sp)   # $s5 will hold the newline character
	sw	$s6, -28($sp)	# $s6 used for calculations
	# NOTICE THAT I DON'T BOTHER MOVING THE STACK POINTER
	
	# load the working values
	li	$s0, 1		# initialize the counter
	lw	$s1, GRID_SIZE	# initialize the array bound
	la	$s2, grid	# get the base address
	lb	$s3, POUND	# store the '#' ASCII code
	lw	$s4, GRID_WIDTH # store the grid width
	lb	$s5, NEWLINE	# store the newline ASCII code
  
ResetLoop:
	sb	$s3, 0($s2)	# put a '#' in the grid
	addi	$s0, $s0, 1	# increment the loop counter
	addi	$s2, $s2, 1	# point at next char position
	div	$s0, $s4	# divide the counter by grid width
	mfhi	$s6		# get remainder in calculation register
	bnez	$s6, NoNewLine	# keep going
	
	sb	$s5, 0($s2)     # put a newline in the grid
	addi	$s0, $s0, 1	# increment the loop counter
	addi	$s2, $s2, 1	# point at next char position
	
NoNewLine:
	blt	$s0, $s1, ResetLoop	# if less than end, loop again
	
	# when we fall out of the loop, restore the registers and return
	lw	$s0, -4($sp)	
	lw	$s1, -8($sp)	
	lw	$s2, -12($sp)	
	lw	$s3, -16($sp)	
	lw	$s4, -20($sp)	
	lw      $s5, -24($sp)   
	lw	$s6, -28($sp)
	# IN A LANGUAGE WITH PUSH/POP, YOU WOULD HAVE TO POP THEM
	# FROM THE STACK IN THE REVERSE ORDER YOU PUSHED THEM.
	
	jr	$ra		# return

#==============================================================================
# handleWIDTH()
#==============================================================================	
handleWIDTH:
	la	$a0, inputWIDTH #output message for width
	li	$v0, 4 
	syscall 	
	li	$v0, 5 #input width 
	syscall	
	sw	$v0, GRID_WIDTH #save register to memory
	li	$t0, 11 #must be greater than
	blt	$v0, $t0, handleWIDTH #error handling
	li	$t0, 99 #must be less than
	bgt	$v0, $t0, handleWIDTH #error handling
	addiu	$v0, $v0, 1	#add 1
	jr	$ra		# return

#==============================================================================
# handleHEIGHT()
#==============================================================================	
handleHEIGHT:
	la	$a0, inputHEIGHT #output message for height
	li	$v0, 4 
	syscall 	
	li	$v0, 5 #input height 
	syscall	
	sw	$v0, GRID_HEIGHT #save register to memory
	li	$t0, 11 #must be greater than
	blt	$v0, $t0, handleHEIGHT #error handling
	li	$t0, 99 #must be less than
	bgt	$v0, $t0, handleHEIGHT #error handling
	jr	$ra		# return

#==============================================================================
# handleGRID_SIZE()
#==============================================================================	
handleGRID_SIZE:
	lw	$t0, GRID_WIDTH	#load width
	lw	$t1, GRID_HEIGHT#load height
	multu	$t0, $t1	# grid size
	mflo	$t0		# lo result is new seed
	sw	$t0, GRID_SIZE	# store the seed in memory

	#testing
	#li  $v0, 1           # service 1 is print integer
   	#add $a0, $t0, $zero  # load desired value into argument register $a0, using pseudo-op
    	#syscall
    	
	jr	$ra		# return
#==============================================================================
# srand()
# 
# Unlike the C++ equivalent, this routine has to ask the user for a seed,
# because we don't have access to a time string. So I borrowed code from a
# linear congruence project to prompt for a large integer and save it as a
# seed for another function that does linear congruence.
#==============================================================================
srand:
	# For this function, we only need to preserve 3 registers.  We use
	# $a0 and $v0 for I/0, and we use $s0 as a scratch register.

	# save the registers
	sw	$v0, -4($sp)	# $v0 will be the service code
	sw	$a0, -8($sp)	# $a0 will point to the grid string
	sw	$s0, -12($sp)	# $s0 will hold the input for testing
	
	# prompt for a random seed and get the value
	la	$a0, rsdPrompt
	li	$v0, 4		# print_string
	syscall

input10:
	li	$v0, 5		# read_int
	syscall
	li	$s0, 1073741823		# put 2147483646 in t0 for comparison
	bgtu	$v0, $s0, input11	# input bigger than 1073741823?
	la	$a0, smErr1	# no, point to error and
	li	$v0, 4		# print_string
	syscall
	j	input10		# try again

input11:
	li	$s0, 2147483646	# upper bound in register t0 for comparison
	bleu	$v0, $s0, input12	# less than or equal 2147483646?
	la	$a0, bgErr	# no, point to error and
	li	$v0, 4		# print_string
	syscall
	j	input10		# try again

input12:	
	# number is good, save and move on
	sw	$v0, rSeed
	
	# restore the registers
	lw	$v0, -4($sp)	
	lw	$a0, -8($sp)	
	lw	$s0, -12($sp)

	jr	$ra		# return
	
#==============================================================================
# rand(int min, int max)
# 
# This code is stolen from the linear congruence project (relax, I wrote it).
# It uses the rSeed and RGEN values to create a new psuedo-random and a new 
# seed for the next time this routine is called.  It range-fits the psuedo-
# random to the range min-max and returns it.  It does not need to formalize a
# stack frame since it doesn't call any other routines, so we simply set the
# two params and the return into the stack before calling and it begins pushing
# registers onto the stack above -12($sp).  Min is expected to be at -8($sp)
# and max is expected at -12($sp) while the return is at -4($sp).
#==============================================================================
rand:
	# For this function, we only need to preserve 3 registers.  We use
	# $s0 - $s2 as scratch registers.

	# save the registers
	sw	$s0, -16($sp)	# $s0 random
	sw	$s1, -20($sp)	# $s1 will hold generator and min
	sw	$s2, -24($sp)	# $s2 will hold new seed and max
	
	# linear congruence
	lw	$s1, RGEN	# load the generator
	lw	$s2, rSeed	# last seed
	multu	$s1, $s2	# result goes in hi/lo registers
	mflo	$s2		# lo result is new seed
	mfhi	$s0		# hi result is new random
	sw	$s2, rSeed	# store the seed in memory

	# fit the random into the range
	lw	$s2, -12($sp)	# get the max
	lw	$s1, -8($sp)    # get the min
	sub	$s2, $s2, $s1	# s2 is now range (max - min)
	addiu	$s2, $s2, 1	# increment the range
	divu	$s0, $s2	# remainder is in hi register
	mfhi	$s0		# get it back
	addu	$s0, $s0, $s1	# add the minimum to put it in range
	sw	$s0, -4($sp)	# store the random in the return

	# restore the registers
	lw	$s0, -16($sp)	
	lw	$s1, -20($sp)	
	lw	$s2, -24($sp)

	jr	$ra		# return
	
#==============================================================================
# int XYToIndex( int x, int y )
# {
#   // Converts the two-dimensional index pair (x,y) into a
#   // single-dimensional index. The result is y * ROW_WIDTH + x.
#   return y * GRID_WIDTH + x;
# }
#
# Like rand, this uses the stack only for getting and returning values.  
# -4($sp) is the return, -8($sp) is x, and -12($sp) is y.
#==============================================================================
XYToIndex:
	# For this function, we only need to preserve 3 registers.  We use
	# $s0 - $s2 as scratch registers.
	
	# save the registers
	sw	$s0, -16($sp)	# $s0 will hold grid width
	sw	$s1, -20($sp)	# $s1 will hold x
	sw	$s2, -24($sp)	# $s2 will hold y
  
  	# get the values for our calculation
  	lw	$s0, GRID_WIDTH	# load the grid width
  	lw	$s1, -8($sp)	# load x
  	lw	$s2, -12($sp)	# load y
  	
  	# calculate and store in return
  	multu	$s0, $s2	# result goes in hi/lo registers
  	mflo	$s0		# hopefully only need LO
  	addu	$s0, $s0, $s1	# add x
  	sw	$s0, -4($sp)	# store result in return

  	# restore the registers
	lw	$s0, -16($sp)	
	lw	$s1, -20($sp)	
	lw	$s2, -24($sp)

	jr	$ra		# return


#================================================================================
# int IsInBounds( int x, int y )
# {
#   // Returns "true" if x and y are both in-bounds.
#   if (x < 0 || x >= GRID_WIDTH) return false;
#   if (y < 0 || y >= GRID_HEIGHT) return false;
#   return true;
# }
#
# Like rand, this uses the stack only for getting and returning values.  -4($sp)
# is the return, -8($sp) is x, and -12($sp) is y.  Note that because we use a
# width that has an extra character, our first test is actually:
# 	if (x < 0 || x > GRID_WIDTH) return false;
#================================================================================
IsInBounds:
	# For this function, we only need to preserve 3 registers.  We use
	# $s0 - $s2 as scratch registers.
	
	# save the registers
	sw	$s0, -16($sp)	# $s0 will hold bounds for testing and return
	sw	$s1, -20($sp)	# $s1 will hold x
	sw	$s2, -24($sp)	# $s2 will hold y
  
  	# get the values for our calculation
  	lw	$s1, -8($sp)	# load x
  	lw	$s2, -12($sp)	# load y
  	
  	# test width
  	lw	$s0, GRID_WIDTH		# load the grid width
  	bgtu	$s1, $s0, OutOfBounds	# catches both >= grid width and < 0
  	
  	# test height
  	lw	$s0, GRID_HEIGHT	# load the grid height
  	bgeu	$s2, $s0, OutOfBounds	# catches both >= grid height and < 0
  	
  	li	$s0, 1		# neither failed, so set true (1)
  	sw	$s0, -4($sp)
  	j	EndBounds
  	
OutOfBounds:
	li	$s0, 0		# something failed, so set false (0)
	sw	$s0, -4($sp)

EndBounds:
  	# restore the registers
	lw	$s0, -16($sp)	
	lw	$s1, -20($sp)	
	lw	$s2, -24($sp)

	jr	$ra		# return

#==============================================================================
# void Visit( int x, int y )
# {
#   // Starting at the given index, recursively visits every direction in a
#   // randomized order.
#   // Set my current location to be an empty passage.
#   grid[ XYToIndex(x,y) ] = ' ';
#   
#   // Create an local array containing the 4 directions and shuffle their
#   // order.
#   int dirs[4];
#   dirs[0] = NORTH;
#   dirs[1] = EAST;
#   dirs[2] = SOUTH;
#   dirs[3] = WEST;
#   
#   for (int i=0; i<4; ++i)
#   {
#     int r = rand() & 3;
#     int temp = dirs[r];
#     dirs[r] = dirs[i];
#     dirs[i] = temp;
#   }
#   
#   // Loop through every direction and attempt to Visit that direction.
#   for (int i=0; i<4; ++i)
#   {
#     // dx,dy are offsets from current location. Set them based
#     // on the next direction I wish to try.
#     int dx=0, dy=0;
#     switch (dirs[i])
#     {
#       case NORTH: dy = -1; break;
#       case SOUTH: dy = 1; break;
#       case EAST: dx = 1; break;
#       case WEST: dx = -1; break;
#     }
#     
#     // Find the (x,y) coordinates of the grid cell 2 spots
#     // away in the given direction.
#     int x2 = x + (dx<<1);
#     int y2 = y + (dy<<1);
# 
#     if (IsInBounds(x2,y2))
#     {
#       if (grid[ XYToIndex(x2,y2) ] == '#')
#       {
#         // (x2,y2) has not been visited yet... knock down the
#         // wall between my current position and that position
#         grid[ XYToIndex(x2-dx,y2-dy) ] = ' ';
#         
#         // Recursively Visit (x2,y2)
#         Visit(x2,y2);
#       }
#     }
#   }
# }
#
# Visit is the tough one.  Because it is recursive, you have to use a stack-
# frame to properly handle all the levels of recursion.  There is no return
# but x is at -4($sp) and y is at -8($sp).
#==============================================================================
Visit:

	# TO DO: Write the code.  Don't forget, it won't work if you don't
	#        use a stack frame to make it reentrant.
	
#	!!!!!!!
# 	Stubbed out: being rewritten
# 	!!!!!!!
#	# first, save the old frame pointer and return address on the stack 
#	# and point the frame pointer to the bottom of the frame 
# 	sw $fp, -12($sp) # save the old frame pointer 
#	sw $ra, -16($sp) # save the return address 
# 	move $fp, $sp # copy the stack pointer to the frame pointer 
# 
# 	# now we can save any registers we need. 
# 	sw $s0, -20($sp) # will hold current x or scratch 
#
#	#the sample code had "..." here.. why?
# 
# 	# and make space for any local variables 
# 	addiu $sp, $sp, -32 # space for 3 words (32  20 = 12 bytes) 
# 
# 	# and finally we can grab the input parameters we need for XYToIndex
# 	lw $s0, -4($fp) # load x into $s0
# 	lw $s1, -8($fp) # load y into $s1 
 
	# First, we need to set up the stack and frame pointers so that we can
	# use the frame pointer to reference variables that Visit was called
	# with and the stack pointer to reference other things we need. 
	# The only things Visit was called with are:
	# -8(sp): y
	# -4(sp): x
	# We'll make it so that we can call these at -8(fp) and -4(fp),
	# respectively, by moving the address pointed to by sp into fp. 
	# Before we do that, though, we need to store the return address and old
	# frame pointer address for this instance of Visit-- they're currently
	# floating around in registers and might get destroyed.
	sw $ra, -16($sp)
	sw $fp, -12($sp)
	# With the registers stored, we can safely move the frame pointer. 
	or $fp, $sp, 0

	# We'll also need space for our local variables:
	# The current x position : 1 word
	# The current y position : 1 word
	# The current xy position as a single value (y * width) + x : 1 word
	# Our randomly generated value : 1 word
	# An array to hold our positions to visit : 4 words
	# One more for certainty
	# Total: 9 words

	# We need to move sp up to -20sp for the things we already stored, and
	# add another 9 words for the things we'll need to store, totalling 32
	# words.
	addi $sp, $sp, -32

	# sp is now above our Visit's parameters, and we can use space above
	# sp (i.e.: in the negative direction) to store anything we need to
	# store.

 	####PROCEDURE###
 	
 	#   // Set my current location to be an empty passage.
 	#   grid[ XYToIndex(x,y) ] = ' ';	

	# Load parameters for XYToIndex.
	# x is at -4(fp), XYTI expects it at $s0
	lw $s0, -4($fp)
	# y is at -8(fp), XYTI '           ' $s1
	lw $s1, -8($fp)
	# Run XYToIndex, result stored at -4(sp)
	jal	XYToIndex 

	# Load the output of XYToIndex to $s2. 
  	lw	$s4, -4($sp)	
	la	$s2, grid	# get the base address	
	lb	$s3, SPACE	# store the ' ' ASCII code
	add	$s2, $s2, $s4 	# go to the index
	sb	$s3, 0($s2)	# put a ' ' in the grid location from XYToIndex

	# Load the output of XYToIndex to $s2
	lw $s2, -4($sp)
	# Get the address of the beginning of the grid
	la $s3, grid
	# Store the ASCII value for character ' '
	lb $s4, SPACE
	# Add together the original index of the grid and the index returned by
	# XYToIndex to get the absolute index of the space we want to change.
	# Store it in $s2.
	add $s2, $s2, $s3
	# Store the space value in the location we calculated, overwriting the #.
	sb $s3, 0($s2)

	# We'll store our current location in $s2 for the foreseeable future,
	# which leaves $s0 through $s2 occupied.
		
	#   // Create an local array containing the 4 directions and shuffle their
	#   // order.
	#   int dirs[4];
	#   dirs[0] = NORTH;
	#   dirs[1] = EAST;
	#   dirs[2] = SOUTH;
	#   dirs[3] = WEST;
	# First we make the array. We'll store it in registers temporarily.
	
	lw	$t0, NORTH
	lw	$t1, EAST
	lw	$t2, SOUTH
	lw	$t3, WEST

	# In order to reference a particular part of the array based on a
	# parameter (i.e.: our randomly generated value) we need to store it on
	# the stack rather than inside a set of registers. First we'll just push
	# all of these above the stack pointer.
	sw $t0,  28($sp) #NORTH
	sw $t1,  24($sp) #EAST
	sw $t2,  20($sp) #SOUTH
	sw $t3,  16($sp) #WEST

	# But we still need to keep track of where they are, and arithmetic will
	# be helped by having a pointer to the first word in the array. We'll
	# put it at $s3, the first register not already being used.
	sa $s3, 28($sp)
	
	# We'll need another pointer to select the x'th element from our array,
	# where x is the random number we generated.
	sa $s4, 28($sp)

	#   for (int i=0; i<4; ++i)
	#   {
	#     int r = rand() & 3;
	#     int temp = dirs[r];
	#     dirs[r] = dirs[i];
	#     dirs[i] = temp;
	#   }
Randomize:
	# How this procecure works:
	# [For i = 0 through 3]
	# 1) generate a random number 0-3
	# 2) Swap dirs[random] and dirs[i]
	# 3) Branch to beginning of for

	# For loop iterator. This needs to be saved across calls, so we should
	# put it in an s-register. $s5 is unoccupied. 
	li	$s5, 4		# initialize the counter (we'll count down)

RandomizeFor:
	# Ok. 1) generate a random number 0-3.
	# Load our min and max.
	li $t5, 0 	# min
	li $t6, 3 	# max

	# Now store our min at -8($sp) and our max at -12($sp).
	sw $t5, -8($sp)		# Store min	
	sw $t6, -12($sp)	# Store max

	# Call rand. It will leave the random inside -4($sp).
	jal rand
	# Retrieve our random value. $s6 is unoccupied, put it there.
	lw $s6, -4($sp)
	# 1) is done

	# 2) Find dirs[random] and dirs[i] and then swap them.
	# 2a) Find dirs[random] with pointer arithmetic
	# We have a pointer to dirs[0] stored already in $s4. And we know the
	# value of our random. If we multiply our random by 4 and add that
	# amount to $s4, we'll get a pointer to dirs[random].
	# Get 4
	li $t7, 4
	# Multiply random by 4, store back in the register that held random
	mul $s6, $s6, $t7
	# Add 4 * random to our pointer and store in its original register
	add $s4, $s4, $s6
	# 2a) is done [$s4 points to dirs[random] ]

	# 2b) find dirs[i] with pointer arithmetic
	# Same thing as before. Multiply i by 4 and add the result to the
	# pointer.
	# Multiply i by 4
	mul $s5, $s5, $t7
	# Add 4 * i to the pointer, store in its original register
	add $s3, $s3, $s5
	# 2b) is done [$s3 points to dirs[i] ]
	
	# 2c) swap them - easy
	lw $t8, 0($s3) 	# Load dirs[i] into t8
	lw $t9, 0($s4) 	# Load dirs[random] into t9
	sw $t9, 0($s3) 	# Load dirs[random] into dirs[i]
	sw $t8, 0($s4) 	# Load dirs[i] into dirs[random]

	# Decrement the iterator
	li $t0, 1
	sub $s5, $s5, $t0
	
	# If we haven't run this [4,3,2,1] = 4 times yet, branch back to
	# RandomizeFor
	bgtz $s5, RandomizeFor



# !!!!!!!
# Stubbed out: being rewritten
# !!!!!!!
#	# Here we go. 1) Generate random number
#	li,	$t7, 0		#min
#	li,	$t8, 3		#max
#	sw	$t7, -8($sp)	#store min
#	sw	$t8, -12($sp)	#store max
#	jal	rand		#run rand
#	lw	$t6, -4($sp)	#store random number
#	# 1) done
#
#	# We've got a random number, now we need to do some swapping. This
#	# requires that we put the array onto the stack. We'll say that we store
#	# the four directions at:
#	# dirs[0]: -8($sp)
#	# dirs[1]: -
#	# 2) Swap dirs[random] and dirs[i]
#	# Seems like the only way I can reference a register through a value
#	# from another register is by addressing it by number, not by name. So
#	# let's try adding to get where we ned to go.
#	# t0, t1, t2, t3, where the four directions are, are at registers 8-15,
#	# which means our lowest possible location is 8 - 0 = 8. So we add 8 to
#	# the random we generated.
#
#	addi $t4, $t4, 8
#
#	# Do the same for the random number.
#	
#	addi $t6, $t6, 8
#	
#	# Use $t9 as our temp. Copy dirs[ r ] into it. We address dirs[ r ] as
#	# the random number we generated plus eight, which should give us
#	# something between 8 and 11.
#	add $t9, 0($t6), $0
#
#	# We stored dirs[ r ] so we can set it equal to dirs[ i ] now
#	add 0($t6), 0($t4), $0
#
#	# Finally, load our temp back into dirs[ i ]
#	add 0($t4), $t9, $0
#	# 2) done
#
#	# We have to subtract 8 from $t4 to get our iterator back into the
#	# acceptable range. Since we don't need $t6 anymore we'll store the 8
#	# there
#	li $t6, 8
#
#	# Do subtraction
#	subu $t4, $t4, $t6
#
#	# Initialize the upper bound for the iterator
#	li	$t5, 4
#
#	# Increment the iterator and branch back to the top
#	addi $t4, $t4, 1
#	blt	$t4, $t5, RandomizeFor
#	

  
	#   // Loop through every direction and attempt to Visit that direction.
	#   for (int i=0; i<4; ++i)
	#   {
	#     // dx,dy are offsets from current location. Set them based
	#     // on the next direction I wish to try.
	#     int dx=0, dy=0;
	#     switch (dirs[i])
	#     {
	#       case NORTH: dy = -1; break;
	#       case SOUTH: dy = 1; break;
	#       case EAST: dx = 1; break;
	#       case WEST: dx = -1; break;
	#     }
	#     
	#     // Find the (x,y) coordinates of the grid cell 2 spots
	#     // away in the given direction.
	#     int x2 = x + (dx<<1);
	#     int y2 = y + (dy<<1);
	# 
	#     if (IsInBounds(x2,y2))
	#     {
	#       if (grid[ XYToIndex(x2,y2) ] == '#')
	#       {
	#         // (x2,y2) has not been visited yet... knock down the
	#         // wall between my current position and that position
	#         grid[ XYToIndex(x2-dx,y2-dy) ] = ' ';
	#         
	#         // Recursively Visit (x2,y2)
	#         Visit(x2,y2);
	#       }
	#     }
	#   }
	# }
	
	
 
 	# when done restore the registers 
 	lw $s0, -20($sp) # put old $s0 back 
 
 	# restore the stack pointer, frame pointer, and return address 
	move $sp, $fp # point to the beginning of the stack frame 
 	lw $fp, -12($sp) # restore the old frame pointer 
 	lw $ra, -16($sp) # restore the return address 
 
 	jr $ra # and return 

#==============================================================================
# void PrintGrid()
# {
#   // Displays the finished maze to the screen.
#   for (int y=0; y<GRID_HEIGHT; ++y)
#   {
#     for (int x=0; x<GRID_WIDTH; ++x)
#     {
#       cout << grid[XYToIndex(x,y)];
#     }
#     cout << endl;
#   }
# }
#==============================================================================
PrintGrid:

	# This is even easier than the C++ code because I've set the grid up as 
	# one long string so I can simply use a system service to print it to 
	# the console. Doing character by character printing in MASM was more 
	# complicated. We need to preserve 2 registers, $v0 and $a0 used for
	# this system service.

	# save the registers
	sw	$v0, -4($sp)	# $v0 will be the service code
	sw	$a0, -8($sp)	# $a0 will point to the grid string
	
	# load the values and print
	li	$v0, 4		# print service
	la	$a0, grid	# string to print
	syscall

	# restore the registers
	lw	$v0, -4($sp)	
	lw	$a0, -8($sp)	

	jr	$ra		# return
