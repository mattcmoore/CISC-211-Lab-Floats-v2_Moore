/*** asmFmax.s   ***/
#include <xc.h>
.syntax unified

@ Declare the following to be in data memory
.data  
.align

@ Define the globals so that the C code can access them

/* create a string */
.global nameStr
.type nameStr,%gnu_unique_object
    
/*** STUDENTS: Change the next line to your name!  **/
nameStr: .asciz "Matt Moore"  
 
.align

/* initialize a global variable that C can access to print the nameStr */
.global nameStrPtr
.type nameStrPtr,%gnu_unique_object
nameStrPtr: .word nameStr   /* Assign the mem loc of nameStr to nameStrPtr */

.global f0,f1,fMax,signBitMax,storedExpMax,realExpMax,mantMax
.type f0,%gnu_unique_object
.type f1,%gnu_unique_object
.type fMax,%gnu_unique_object
.type sbMax,%gnu_unique_object
.type storedExpMax,%gnu_unique_object
.type realExpMax,%gnu_unique_object
.type mantMax,%gnu_unique_object

.global sb0,sb1,storedExp0,storedExp1,realExp0,realExp1,mant0,mant1
.type sb0,%gnu_unique_object
.type sb1,%gnu_unique_object
.type storedExp0,%gnu_unique_object
.type storedExp1,%gnu_unique_object
.type realExp0,%gnu_unique_object
.type realExp1,%gnu_unique_object
.type mant0,%gnu_unique_object
.type mant1,%gnu_unique_object
 
.align
@ use these locations to store f0 values
f0: .word 0
sb0: .word 0
storedExp0: .word 0  /* the unmodified 8b exp value extracted from the float */
realExp0: .word 0
mant0: .word 0
 
@ use these locations to store f1 values
f1: .word 0
sb1: .word 0
realExp1: .word 0
storedExp1: .word 0  /* the unmodified 8b exp value extracted from the float */
mant1: .word 0
 
@ use these locations to store fMax values
fMax: .word 0
sbMax: .word 0
storedExpMax: .word 0
realExpMax: .word 0
mantMax: .word 0

.global nanValue 
.type nanValue,%gnu_unique_object
nanValue: .word 0x7FFFFFFF            

@ Tell the assembler that what follows is in instruction memory    
.text
.align

/********************************************************************
 function name: initVariables
    input:  none
    output: initializes all f0*, f1*, and *Max varibales to 0
********************************************************************/
.global initVariables
 .type initVariables,%function
initVariables:
    /* YOUR initVariables CODE BELOW THIS LINE! Don't forget to push and pop! */
    
    PUSH {r4-r11, LR}
    /* Copy 0 to r12 to store into mem locations for initialization */
    MOV r11, 0
    
    /* Initialize f0, f1 and 'Max' variables to 0 */
    LDR r4, =f0
    STR r11, [r4]
    
    LDR r5, =f1
    STR r11, [r5]
    
    LDR r6, =fMax
    STR r11, [r6]
    
    LDR r7, =sbMax
    STR r11, [r7]
    
    LDR r8, =storedExpMax
    STR r11, [r8]
    
    LDR r9, =realExpMax
    STR r11, [r9]
    
    LDR r10, =mantMax
    STR r11, [r10]
    
    POP {r4-r11, LR} 
    /* Branch back to main at the instruction stored in the LR */
    BX LR
    /* YOUR initVariables CODE ABOVE THIS LINE! Don't forget to push and pop! */

    
/********************************************************************
 function name: getSignBit
    input:  r0: address of mem containing 32b float to be unpacked
            r1: address of mem to store sign bit (bit 31).
                Store a 1 if the sign bit is negative,
                Store a 0 if the sign bit is positive
                use sb0, sb1, or signBitMax for storage, as needed
    output: [r1]: mem location given by r1 contains the sign bit
********************************************************************/
.global getSignBit
.type getSignBit,%function
getSignBit:
    /* YOUR getSignBit CODE BELOW THIS LINE! Don't forget to push and pop! */
    
    PUSH {r4-r11, LR}
    /* Load signBit mem location from r0, shift the bit value to the LSB, e.g.
     isolating it and then store that value in the mem location in r1
    */
    LDR r11, [r0]
    LSR r11, r11, 31
    STR r11, [r1]
    
    /* FOR TESTING */
    MOV r11, 0
    LDR r11, [r1]
    
    POP {r4-r11, LR}
    /* Branch back to main at the instruction stored in the LR */
    BX LR
    
    /* YOUR getSignBit CODE ABOVE THIS LINE! Don't forget to push and pop! */
    

    
/********************************************************************
 function name: getExponent
    input:  r0: address of mem containing 32b float to be unpacked
      
    output: r0: contains the unpacked original STORED exponent bits,
                shifted into the lower 8b of the register. Range 0-255.
            r1: always contains the REAL exponent, equal to r0 - 127.
                It is a signed 32b value. This function doesn't
                check for +/-Inf or +/-0, so r1 always contains
                r0 - 127.
                
********************************************************************/
.global getExponent
.type getExponent,%function
getExponent:
    /* YOUR getExponent CODE BELOW THIS LINE! Don't forget to push and pop! */
    
    PUSH {r4-r11, LR}
    /* 
     Extract the exponent bits (bits 23-30) by shifting the masked off 8 bits to 
     the 8 LSB comparing them with a 'mask' with bits 0-22 set (0xFF)., e.g. 
     isolating the exponent in bits 23-30. Last, Copy value to r0.
    */
    
    LDR r0, [r0]
    LSR r0, r0, 23
    LDR r4, =0xFF
    AND r0, r0, r4 
    
    
    /* 
     Convert the stored exponent value in r0 to a real exponent by subtracting 
     the real exponent by the bias, which is 127. Copy real exponent value to r1
     NOTE: I'm using SUB instead of SUBS because I don't need to update flags
     for conditionals
    */
    
    SUB r1, r0, 127
    
    POP {r4-r11, LR}
    /* Branch back to main at the instruction stored in the LR */
    BX LR
    /* YOUR getExponent CODE ABOVE THIS LINE! Don't forget to push and pop! */
   
/********************************************************************
 function name: getMantissa
    input:  r0: address of mem containing 32b float to be unpacked
      
    output: r0: contains the mantissa WITHOUT the implied 1 bit added
                to bit 23. The upper bits must all be set to 0.
            r1: contains the mantissa WITH the implied 1 bit added
                to bit 23. Upper bits are set to 0. 
********************************************************************/
.global getMantissa
.type getMantissa,%function
getMantissa:
    /* YOUR getMantissa CODE BELOW THIS LINE! Don't forget to push and pop! */
    
    PUSH {r4-r11, LR}
    /* 
     Extract the mantissa bits (bits 0-22) by comparing them with a 'mask' 
     with bits 0-22 set (0x7FFFFF). These are the LSBs so once masked and added
     the value is effectively extracted
    */
    
    LDR r4, [r0]
    LDR r5, =0x007FFFFF
    AND r0, r4, r5
    
    
 
    
    /* 
     Sets bit 23 (where the implied '1' in the mantissa would go) in bit 23 by
     masking bit 23 with the value 0x0080000, which has bit 1 set and comparing 
     the mask with an ORR, so that no matter what, bit 23 will be set r2 (along 
     with whatever bits were set in the extracted mantissa).
    */
    
    ORR r1, r0, 0x00800000
    
    
    POP {r4-r11, LR}
    /* Branch back to main at the instruction stored in the LR */
    BX LR
    
    /* YOUR getMantissa CODE ABOVE THIS LINE! Don't forget to push and pop! */
   

/********************************************************************
 function name: asmIsZero
    input:  r0: address of mem containing 32b float to be checked
                for +/- 0
      
    output: r0:  0 if floating point value is NOT +/- 0
                 1 if floating point value is +0
                -1 if floating point value is -0
      
********************************************************************/
.global asmIsZero
.type asmIsZero,%function
asmIsZero:
    /* YOUR asmIsZero CODE BELOW THIS LINE! Don't forget to push and pop! */
    PUSH {r4-r11, LR}
/* 
     After copying value at mem location in r0, compare the value to zero, and 
     if the comparison doesn't set a Z flag (e.g. the value isn't +/- 0) copy
     '0' into r0 
*/     
    MOV r11, 0 /* first make a -1 for moving into a register */
    SUB r11, r11, 1
    LDR r12, [r0]
    CMP r12, 0
    BNE non_neg
    BEQ yes_neg

/* 
    Else, test the sign bit against a mask with MSB (sign bit) set. If the sign
    bit is set to 1, e.g. there's a -0, there will be a Z flag set, the EQ 
    condition will run which will subtract 0 from 1 into r0. 
    
    It's necessary to use a subtract instruction because MOV can't use negative 
    immediate values as operands since they take more than 8 bits for a given 
    level of precision
    
    If the sign bit is set to 0, e.g. there is a -0, there will no Z flag set 
    and the NE condition will run which will copy a 1 into r0. 
*/
    non_neg: 
    MOV r0, 0
    CMP r0, 0x80000000
    MOVEQ r0, r11
    POP {r4-r11, LR}
    BX LR
    
    yes_neg: 
    TST r0, 0x80000000
    MOVEQ r0, 1
    MOVNE r0, r11
    
    POP {r4-r11, LR}
    /* Branch back to main at the instruction stored in the LR */
    BX LR    
    /* YOUR asmIsZero CODE ABOVE THIS LINE! Don't forget to push and pop! */
   
/********************************************************************
 function name: asmIsInf
    input:  r0: address of mem containing 32b float to be checked
                for +/- infinity
      
    output: r0:  0 if floating point value is NOT +/- infinity
                 1 if floating point value is +infinity
                -1 if floating point value is -infinity
      
********************************************************************/
.global asmIsInf
.type asmIsInf,%function
asmIsInf:
    /* YOUR asmIsInf CODE BELOW THIS LINE! Don't forget to push and pop! */
    
    PUSH {r4-r11, LR}
    
    LDR r0, [r0]
    
/*
    Bitwise compare float in r0 with, 0x7FFFFFFF, so that the MSB is a 0 and all
    other bits are set to 1. 
     
    When the MSB == 0 and all other bits == 1  on the comparison (2nd) operand, 
    the value in the destination will have an MSB == 0 regardless of what the 
    sign bit/MSB in the float operand was and all subsequent bits will stay the 
    same. 
     
    Thus the sign bit of the float operand we're trying to classify as
    infinity or not-infinty will be set to zero, so we can make it negative if
    it's not already, and then compare to negative infinity.
     
    Then the resulting number gets compared to floating point negative infinity
    expressed as 0x7F800000. 
     
    If the comparison instruction fails to set a zero flag, e.g. the value in r1 
    != -inf than the original float did not equal +/- inf and r0, the output
    register is set to 0 as per the instructions
*/
    ANDS r1, r0, 0x7FFFFFFF   
    CMP r1, 0x7F800000        
    MOVNE r0, 0
    
/*
   Compares r0 to positive infinity, represented as 0x7F800000 (sign bit == 0,
   all ones in the exponent bits 23-30 and 0s in bits 1-22) then copies 1 into 
   r0 if CMP instructions sets Z flag (e.g. r0 == + inf)
*/
    CMP r0, 0x7F800000 
    MOVEQ r0, 1

/*
   Compares r0 to floating point negative infinity, which == 0x7F800000 (like 
   positive infinity but with the sign bit == 1 for negative) 
   
   Then it does r0 = 0 - 1 (like copying negative one but using the same 
   workaround used in asmIsZero) if CMP instructions sets Z flag (e.g. r0 == 
   -inf)
*/
   CMP r0, 0xFF800000
   MOV r12, 0
   SUBEQ r0, r12, 1
   
   /* Popping back r4-r11, and the originally LR (we're heading back to) */
    
    POP {r4-r11, LR}
/* Back to asmFmax */
    BX LR    
    /* YOUR asmIsInf CODE ABOVE THIS LINE! Don't forget to push and pop! */
    
/********************************************************************
function name: asmFmax
function description:
     max = asmFmax ( f0 , f1 )
     
where:
     f0, f1 are 32b floating point values passed in by the C caller
     max is the ADDRESS of fMax, where the greater of (f0,f1) must be stored
     
     if f0 equals f1, return either one
     notes:
        "greater than" means the most positive number.
        For example, -1 is greater than -200
     
     The function must also unpack the greater number and update the 
     following global variables prior to returning to the caller:
     
     signBitMax: 0 if the larger number is positive, otherwise 1
     realExpMax: The REAL exponent of the max value, adjusted for
                 (i.e. the STORED exponent - (127 o 126), see lab instructions)
                 The value must be a signed 32b number
     mantMax:    The lower 23b unpacked from the larger number.
                 If not +/-INF and not +/- 0, the mantissa MUST ALSO include
                 the implied "1" in bit 23! (So the student's code
                 must make sure to set that bit).
                 All bits above bit 23 must always be set to 0.     

********************************************************************/    
.global asmFmax
.type asmFmax,%function
asmFmax:   
    

    /* YOUR asmFmax CODE BELOW THIS LINE! VVVVVVVVVVVVVVVVVVVVV  */
    
    
         
    /* 
     Save free registers and LR because the sub routines might change them 
    */
    PUSH {r4 - r11, LR}
    BL initVariables
        
    /* Store f0 and f1 */
    LDR r11, =f0
    STR r0, [r11]
    
    LDR r11, =f1
    STR r1, [r11]
    
    
    /* Unpack sign bits */
    LDR r0, =f0
    LDR r1, =sb0
    BL getSignBit
    LDR r0, =f1
    LDR r1, =sb1
    BL getSignBit
   
    
    /* Unpack exponents */
    LDR r0, =f0
    BL getExponent
    LDR r3, =storedExp0
    STR r0, [r3]
    
    CMP r0, 0
    SUBEQ r2, r0, 126 /* Use 126 bias if exp == 0 */
    MOVNE r2, r1
    
    LDR r3, =realExp0
    STR r2, [r3] /* Then write the result to real exponent mem location */
    
    LDR r0, =f1
    BL getExponent
    LDR r3, =storedExp1
    STR r0, [r3]
    
    CMP r0, 0
    SUBEQ r2, r0, 126 /* Use 126 bias if exp == 0 */
    MOVNE r2, r1
    
    LDR r3, =realExp1
    STR r2, [r3] /* Then write the result to real exponent mem location */
    
    /* Unpack mantissas */
    /*
	Pass f0 or f1 into getMantissa. First write the 'hidden' bit mantissa
	returned from the subroutine to the mant0/mant1 mem location. If the
	stored exponent == 0 or 255 overwrite the mantissa with the version
	returned from the subroutine with the hidden bit added. 
	
	This is because an exponent of 0 could indicate a subnormal number 
	(exponent of 0) and to give a subnormal continuity from zero instead of
	1 (which wouldn't make sense because subnormal numbers are all 0. 
	something) the implied 1 bit in front of normal numbers is dropped.
	
    */
    LDR r0, =f0   
    BL getMantissa
    
    /* LDR r11, =mant0
    LDR r10, =storedExp0
    LDR r10, [r10]
    CMP r10, 0
    STRNE r0, [r11]
    STREQ r1, [r11]
    */
    
    LDR r11, =mant0
    STR r1, [r11]
    
    
    /* Same thing for f1 */
    LDR r0, =f1
    BL getMantissa
    
    /* LDR r11, =mant1
    LDR r10, =storedExp1
    LDR r10, [r10]
    CMP r10, 0
    STRNE r0, [r11]
    STREQ r1, [r11]
    */
    
    LDR r11, =mant1
    STR r1, [r11]
    
    /* Compare r0 and r1 to +inf. If == infinity copy to fMax */
    LDR r6, =fMax /* first right fMax address for writing the result */
    
    LDR r0, =f0
    /* Subroutine changes r0 depending on +/- infinity or not-infinity */
    BL asmIsInf
    /* Checks if r0 == 1, meaning == infinity and sets flags accordingly 
     then write rites r0 to fMax if == 1 e.g. == + inf or writes r1 to fmax if
     the opposite is true
    */
    CMP r0, 1
    BEQ f0_max
    CMP r0, -1
    BEQ f1_max
    
    /* Then do the same for the f1 value */
    LDR r0, =f1   
    BL asmIsInf  
    CMP r0, 1
    BEQ f1_max
    CMP r0, -1
    BEQ f0_max
    
    /* ELSE compare the sign bits */

    LDR r0, =sb0
    LDR r0, [r0]
    LDR r1, =sb1
    LDR r1, [r1]
    CMP r0, r1

    /* 
     Branch to f1_max if flags trigger LT conditional. This would mean r0 < r1
     
     Branch to f1_max if the opposite is true and e.g. the flags
     trigger the GT conditional
    */
    BLT f1_max
    BGT f0_max
    
    /* ElSE compare the real exponents 
     
     Copy the f0 and f1 exponents stored at realExp0, realExp1 mem locations
     to r10 and r11 so the can be used for comparison in the next set of 
     instructions
    */
    LDR r10, =realExp0
    LDR r10, [r10]
    LDR r11, =realExp1
    LDR r11, [r11]
    
    /* 
       Pull the sign bit for f0 out of it's memory location at sb0. If we've
       made it this far without branching, we know that f0 sign bit = f1 sign 
       bit.
       
       Compare the sign bit to 0, so we can branch to a different sub routine
       based on whether or not a great real exp is making the value more 
       positive or more negative.
    */
    
    LDR r12, =sb0
    LDR r12, [r12]
    CMP r12, 0
    CMPEQ r10, r11     /* Positive case */
    BGT f0_max                /* realExp0 > realExp1 */
    BLT f1_max                /* realExp0 < realExp1 >  */
    CMPNE r10, r11     /* Negative case */
    BGT f1_max                 /* realExp0 > realExp1 (more neg)  */
    BLT f0_max                 /* realExp1 > realExp0 (more neg) */
    
    
    /* ELSE compare the mantissas
     
     Copy the f0 and f1 exponents stored at mant0, mant1 mem locations
     to r10 and r11 so the can be used for comparison in the next set of 
     instructions
    */
    
    LDR r10, =mant0
    LDR r10, [r10]
    LDR r11, =mant1
    LDR r11, [r11]
    
    /* For testing */
    LDR r9, =f0
    
    /* Similar to what happened when the exponents were compared, compare the 
     sign bit to 0 first, so we can branch to f1_max or f0_max based on whether 
     or not a greater mantissa makes value more positive or more negative. 
    */
    
    /* Note to Matt: remember that the sign bit output is either 0 or 1 */
    
    LDR r12, =sb0
    LDR r12, [r12]
    CMP r12, 0
    CMPEQ r10, r11     /* Positive case */
    BGT f0_max                /* mant0 > mant1 */
    BLT f1_max                /* mant1 > mant0 */
    CMPNE r10, r11     /* Negative case */
    BGT f1_max                 /* mant0 > mant1 (more neg)  */
    BLT f0_max                 /* mant0 > mant1 (more neg) */
    
    /* 
     If the assembler gets this far without branching it means that f0 == f1.

     As per the instructions f0 will go in fMax in this case
    */
    
    
    /* Puts f0 in fMax, pops the registers and LR back and exits to caller */
    f0_max:
    
    LDR r0, =sb0
    LDR r0, [r0]
    LDR r7, =sbMax
    STR r0, [r7]
    
    LDR r0, =realExp0
    LDR r0, [r0]
    LDR r9, =realExpMax
    STR r0, [r9]
    
    /* For testing 
    MOV r11, 0
    LDR r11, [r9]
    
    This test passed, I'm not exacly sure why but I can write the value 
    from realExp0 into realExpMax and then copy into r11 here (after copying 0
    to r11 to make sure it didn't already contain the value). Yet main.c
    does not read the value in realExpMax. Also, when I run in debug mode it
    branches from asmFmax to the subroutines and then back appropriately 
    ending up in f0_max or f1_max. For whatever reason main. c is not reading
    the values stored in memory at the 'max' memory location.
    */
    
    LDR r0, =storedExp0
    LDR r0, [r0]
    LDR r8, =storedExpMax
    STR r0, [r8]
    
    LDR r0, =mant0
    LDR r0, [r0]
    LDR r10, =mantMax
    STR r0, [r10]
    
    LDR r0, =f0   /* Just the address for this one */
    
    LDR r3, [r0]
    
    LDR r6, =fMax
    STR r0, [r6]
    
    /* Don't forget to write the address of =fMax in r0 before returning */
    LDR r0, =fMax
    
    /* r0 is left as the mem address of the float written to fMax */
    
    POP {r4-r11, LR}
    MOV PC, LR   
    
    /* Puts f1 in fMax, pops the registers and LR back and exits to caller  */
    f1_max:
    
    LDR r0, =sb1
    LDR r0, [r0]
    LDR r7, =sbMax
    STR r0, [r7]
    
    LDR r0, =realExp1
    LDR r0, [r0]
    LDR r9, =realExpMax
    STR r0, [r9]
    
    LDR r0, =storedExp1
    LDR r0, [r0]
    LDR r8, =storedExpMax
    STR r0, [r8]
    
    LDR r0, =mant1
    LDR r0, [r0]
    LDR r10, =mantMax
    STR r0, [r10]
  
    /* Just the address for this one */

    LDR r0, =f1      
    LDR r6, =fMax
    STR r0, [r6]
    
    /* Don't forget to write the address of =fMax in r0 before returning */
    LDR r0, =fMax
    
    POP {r4-r11, LR}
    MOV PC, LR
    /* YOUR asmFmax CODE ABOVE THIS LINE! ^^^^^^^^^^^^^^^^^^^^^  */

   

/**********************************************************************/   
.end  /* The assembler will not process anything after this directive!!! */
           



