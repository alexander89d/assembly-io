TITLE Writing & Testing Simple I/O Procedures     (assembly-io.asm)

; Author: Alexander Densmore
; Last Modified: 11/29/18
; OSU email address: densmora@oregonstate.edu
; Course number/section: CS 271-400
; Project Number: 6A                Due Date: 12/2/18
; Description:	This program implements and tests low-level I/O procedures (and macros to assist those procedures).
;				Input is converted from ASCII values to numeric forms.
;				Output is converted from numeric forms to ASCII values for printing.
;				This short test program tests these procedures by asking the user to enter 10 integers.
;				It stores the integers in an array and prints the integers, their sum, and their average.

INCLUDE Irvine32.inc

; Integer Constants

FALSE			= 0					; used for boolean flag variables
TRUE			= 1					; used for boolean flag variables
MAX_DIGITS		= 10				; maximum number of digits long a 32-bit unsigned int can be
ARRAY_LENGTH	= 10				; length of the array to store 32-bit integers

; Macros

; ***************************************************************
; Macro that reads in keyboard input as a string
; and stores it in a specified memory location.
; receives: the address of a prompt for user input; the address
;			of a string where the input will be stored.
; returns:	the user-inputted string stored in the specified
;			memory location.
; preconditions: a null-terminated string begins at promptAddr
; registers changed: none
; ***************************************************************
getString		MACRO		promptAddr, destinationAddr
	
	; Save registers used by Irvine's ReadString procedure
	push	eax
	push	ecx
	push	edx

	; Display the prompt for the user's input starting at promptAddr
	mov		edx,			promptAddr
	call	WriteString

	; Read in the user's input
	mov		edx,			destinationAddr
	mov		ecx,			(MAX_DIGITS+1)
	call	ReadString

	; restore registers used by macro
	pop		edx
	pop		ecx
	pop		eax

ENDM


; ***************************************************************
; Macro that displays the string which begins at promptAddr.
; receives: the starting address of a string
; returns: nothing
; preconditions: a null-terminated string begins at promptAddr
; registers changed: none
; ***************************************************************
displayString	MACRO		promptAddr
	; Save register used in macro
	push	edx							
	
	; Display the string starting at promptAddr
	mov		edx,			promptAddr
	call	WriteString

	; Restore the used register
	pop		edx

ENDM

.data

; variables used to process user input
inputValString	BYTE	(MAX_DIGITS+1) DUP(0)	; stores string read in by getString macro
unsignedInts	DWORD	(ARRAY_LENGTH) DUP(?)	; array to store 32-bit unsigned integers converted from strings
outputValString	BYTE	(MAX_DIGITS+1) DUP(0)	; stores string converted from unsigned int in writeVal procedure

; introduction strings
programTitle	BYTE	9,9,"Writing and Testing Low-Level I/O Procedures",0
programmerName	BYTE	9,9,"by Alexander Densmore",10,10,13,0
ecPrompt		BYTE	"**EC: READVAL AND WRITEVAL PROCEDURES ARE RECURSIVE.",10,10,13,0
intro1			BYTE	"This program tests low-level I/O procedures.",10,13,0
intro2			BYTE	"You will be prompted to enter 10 unsigned 32-bit integers.",10,13,0
intro3			BYTE	"The program will then print those integers, their sum, and their average.",10,10,13,0
intro4			BYTE	"Note that only 10 characters of input will be read in each time you are prompted ",10,13,0
intro5			BYTE	"to enter an unsigned integer (based on the max size of a 32-bit unsigned integer).",10,13,0
intro6			BYTE	"All characters after the 10th character in a line of input will be ignored.",10,10,13,0

; input prompts
inputPrompt		BYTE	"Please enter an unsigned 32-bit integer: ",0
errorMessage	BYTE	"Error: Either the number you entered is larger than 32 bits or contains non-digits.",10,13,0

; results prompts
resultsPrompt1	BYTE	10,13,"Here are the numbers you entered:",10,13,0
commaSpace		BYTE	", ",0
resultsPrompt2	BYTE	10,10,13,"The sum of the numbers you entered is: ",0
resultsPrompt3	BYTE	10,13,"The average of those numbers is: ",0

.code
main PROC

	; pass intro prompts to introduction procedure by address
	push	OFFSET programTitle
	push	OFFSET programmerName
	push	OFFSET ecPrompt
	push	OFFSET intro1
	push	OFFSET intro2
	push	OFFSET intro3
	push	OFFSET intro4
	push	OFFSET intro5
	push	OFFSET intro6
	call	introduction

	push	OFFSET inputPrompt		; pass input prompt by reference
	push	OFFSET errorMessage		; pass error message by reference
	push	OFFSET inputValString	; pass starting address of input string
	push	OFFSET unsignedInts		; pass reference to array's starting address
	push	ARRAY_LENGTH			; pass value of array's length
	call	fillArray

	push	OFFSET resultsPrompt1	; pass prompt by reference
	push	OFFSET commaSpace		; pass string containing a comma and space by reference
	push	OFFSET resultsPrompt2	; pass prompt by reference
	push	OFFSET resultsPrompt3	; pass prompt by reference
	push	OFFSET unsignedInts		; pass starting address of array
	push	ARRAY_LENGTH			; pass length of array by value
	push	OFFSET outputValString	; pass starting address of output string
	call	showResults

	exit	; exit to operating system
main ENDP


; ***************************************************************
; Procedure that invokes displayString macro within a counted
; loop to print the strings passed as parameters
; receives: 9 null-terminated strings containing introductory
;			information about this program.
; returns:	nothing
; preconditions: none
; registers changed: none
; ***************************************************************
introduction	PROC
	; save registers and set up stack frame
	push	ecx
	push	esi
	push	ebp
	mov		ebp,			esp

	; Set esi to the address of the higest index of the stack frame.
	; The loop below will output each string stored in the stack frame.
	; Set ecx as loop counter to the number of prompts to print.
	mov		esi,			ebp
	add		esi,			48		; esi = ebp+48 (address of highest index of stack frame)
	mov		ecx,			9

	; ecx-counted loop to print intro prompts
	printIntros:
		displayString			[esi]		; print the prompt at address stored in esi
		sub		esi,			4			; esi now points to next parameter in stack frame
		loop	printIntros

	; Restore registers and return to calling procedure
	pop		ebp
	pop		esi
	pop		ecx
	ret		36
introduction	ENDP


; ***************************************************************
; Procedure that fills array with 10 validated unsigned integers
; entered by the user. Calls readVal subprocedure to read
; in and validate each value entered.
; receives: address of input prompt; address of error message;
;			starting address of string to store user input;
;			starting address of array; length of array
; returns:	array beginning at address is filled with 10 
;			32-bit unsigned integers
; preconditions: none
; registers changed: none
; ***************************************************************
fillArray		PROC
	; save 32-bit registers and set up stack frame
	pushad
	mov		ebp,			esp
	
	; Create space for local variables:
	; [ebp-4] a local int to store value received from readVal procedure
	; [ebp-8] a local bool flag set to "false" by readVal if invalid value entered
	; [ebp-12] a local bool flag set to default of "false" until readVal has read in a string.
	sub		esp,			12		

	; Set edi to the starting address of the array and ebx to 0 as accumulator for within loop.
	mov		edi,			[ebp+40]
	mov		ebx,			0

	; Use post-test loop to read in valid values from the user. 
	; If the user does not enter a valid value, display an error message.
	enterValidVals:

		; Set local int variable at [ebp-4] to 0. This will be used
		; as accumulator within readVal to store string converted to int.
		mov		eax,			0
		mov		[ebp-4],		eax
		
		; Set local flag variable at [ebp-8] to true.
		; It is assumed that value returned by readVal procedure
		; is valid unless readVal procedure sets flag to false.
		mov		eax,			TRUE
		mov		[ebp-8],		eax

		; Set local flag variable at [ebp-12] to false. readVal will use this flag
		; to track if a string has been read in by readVal
		mov		eax,			FALSE
		mov		[ebp-12],		eax
		
		; Prepare to call readVal procedure
		; Use edx to store stack addresses of local variables and
		; pass to readVal procedure (readVal is recursive, so it will
		; repeatedly pass these stack addresses to itself to keep track of
		; where locals in fillArray are located).
		mov		edx,			ebp
		sub		edx,			4
		push	edx						; pass stack address to store int returned by readVal
		sub		edx,			4
		push	edx						; pass stack address to store validVal flag returned by readVal
		sub		edx,			4		
		push	edx						; pass stack address of flag to track if string has been read in by readVal
		push	[ebp+52]				; pass address of inputPrompt to readVal
		push	[ebp+44]				; pass address of inputValString to readVal
		call	readVal
		
		; Determine if a valid value has been entered (local var [ebp-8] set to false by
		; readVal subprocedure if a valid value was not received)
		mov		eax,			[ebp-8]	
		cmp		eax,			TRUE
		je		validVal

		; If a valid value has not been entered, display an error message
		; and loop again without incrementing the count of valid values entered.
		displayString			[ebp+48]
		jmp		enterValidVals

		; Otherwise, store the value received in the array.
		validVal:

		mov		eax,			[ebp-4]		; eax = value received from readVal
		mov		[edi],			eax			; value stored in array
		add		edi,			4			; edi points to next array element
	
		; Increment the number of integers stored in the array and determine whether to iterate again.
		inc		ebx							; ebx = number of values stored in array
		mov		eax,			[ebp+36]	; eax = max number of elements array can hold
		cmp		ebx,			eax

		; If 10 values have been entered, stop iterating.
		je		allValuesReceived

		; Otherwise, loop again.
		jmp		enterValidVals

	; Once the array has been filled, exit loop and return to calling procedure
	allValuesReceived:
	
	; remove local variables, restore registers, and return to calling procedure
	mov		esp,			ebp
	popad
	ret		20
fillArray		ENDP


; ********************************************************************
; Recursive subprocedure called by fillArray. When called 
; directly from fillArray (i.e. before recursion starts), this
; subprocedure invokes the getString macro to prompt the user
; to enter a 32-bit integer. This subprocedure then processes the
; input string byte-by-byte to convert it to its numeric equivalent.
; receives: stack address in which to store string converted to
;			int; stack address of valid value bool flag; 
;			stack address of string read bool flag; address of
;			input prompt; address to store string input.
; returns:	input string converted to valid 32-bit unsigned int 
;			stored in reference parameter (reset to default value
;			of 0 if an error occurs); bool validValue flag
;			(left set to default of true if valid value was
;			entered; set to false if either an invalid
;			(non-digit) character was entered by the user
;			or the string converted to an unsigned int would be
;			too large to fit in a 32-bit register.
; preconditions:	Before fillArray calls this subprocedure,
;					reference parameter for storing int should
;					be set to 0; valid value flag should be set
;					to default value of true; string entered flag
;					should be set to default value of false.
; registers changed: none
; ********************************************************************
readVal			PROC
	; save registers and set up stack frame
	push	eax
	push	ebx
	push	ecx
	push	esi
	push	ebp
	mov		ebp,			esp

	; Check to see if a string has been read in by this procedure already
	; using the getString macro in this series of function calls.
	; Since this procedure is recursive, it should only read in a string
	; when called by an outside function and should not do so
	; when called by itself.
	mov		ebx,			[ebp+32]
	mov		eax,			[ebx]
	cmp		eax,			TRUE
	je		getByte

	; If a string has not yet been read in by this procedure, invoke the getString
	; macro, and then set up the procedure to process the string.
	initialStringSetup:
		
		; pass getString macro the addresses of input prompt and input string
		getString	[ebp+28],	[ebp+24]

		; set stringRead flag to true
		mov			ebx,		[ebp+32]
		mov			eax,		TRUE
		mov			[ebx],		eax

		; clear the direction flag to traverse the string moving forward
		cld
	
	getByte:

	; put the address of the next byte of the string to be processed in esi, and get that byte
	mov		esi,			[ebp+24]
	lodsb

	; If the byte read into al is a null character, the string is done being processed.
	; Return to the calling procedure.
	cmp		al,				0
	je		done

	; Otherwise, if al < 48 or al > 57, it is a non-digit ASCII character. Signal that an error has occurred.
	cmp		al,				48
	jl		error
	cmp		al,				57
	jg		error

	; If the character has been determined to be valid, convert the ASCII digit to numeric form,
	; add the digit in a new digit's place in tempVal, and recursively call readVal to process next byte of string.
	validVal:
		; move ascii value in al to ebx for processing and zero-extend
		movzx	ebx,			al

		; convert the ascii value to the digit it represents by subtracting 48 (the ascii value of 0)
		sub		ebx,			48

		; move tempVal to eax (this digit will be appended to current value of tempVal)
		mov		ecx,			[ebp+40]
		mov		eax,			[ecx]

		; multiply tempVal by 10 to add additional place value for digit stored in ebx
		mov		ecx,			10
		mul		ecx

		; If carry flag is set, tempVal is too large to fit in a 32-bit register. Indicate an error.
		jc		error

		; Add digit stored in ebx to tempval in eax
		add		eax,			ebx

		; If carry flag is set, tempVal is too large to fit in a 32-bit register. Indicate an error.
		jc		error

		; Otherwise, if the new digit has been appended to tempVal successfully, update value of tempVal parameter.
		mov		ecx,			[ebp+40]
		mov		[ecx],			eax

		; Prepare to recursively call procedure to process next digit of input string.
		push	[ebp+40]		; pass address of tempVal
		push	[ebp+36]		; pass address of validVal flag
		push	[ebp+32]		; pass address of stringRead flag
		push	[ebp+28]		; pass address of inputPrompt
		push	esi				; pass address of next byte of string to be processed
		call	readVal

		; After returning from recursive procedure call, prepare to return from this procedure call.
		jmp		done

	; if an error has occurred due to an invalid character or too large a number for a 32-bit register being entered,
	; reset tempVal to 0 and set validVal flag to false
	error:
		; reset tempVal to 0 since a user-entered val was not processed successfully
		mov		ebx,			[ebp+40]
		mov		eax,			0
		mov		[ebx],			eax

		; set validVal flag to false to indicate to calling procedure that user entered an invalid value.
		mov		ebx,			[ebp+36]
		mov		eax,			FALSE
		mov		[ebx],			eax

	; restore registers and return to calling function
	done:
	pop		ebp
	pop		esi
	pop		ecx
	pop		ebx
	pop		eax
	ret		20
readVal			ENDP


; ********************************************************************
; Procedure that prints the 10 values stored in the array, the sum
; of the 10 elements, and the average of those elements. Calls
; writeVal procedure to convert all integers to string form and print
; them.
; receives: addresses of 4 strings containing output messages;
;			the starting address of the array of 32-bit unsigned
;			integers; the array's length passed by value;
;			the starting address of a string in which to store numbers
;			converted to string form
; returns:	nothing
; preconditions: array has been filed with validated 32-bit integers.
; registers changed: none
; ********************************************************************
showResults		PROC
	; save registers and set up stack frame
	pushad
	mov		ebp,			esp

	; create space on stack for local variable to be passed to writeVal 
	; to count how many digits have been stored in output string
	sub		esp,			4

	; prepare for loop to display the contents of the array using writeVal procedure
	displayString			[ebp+60]	; "Here are the numbers you entered:"
	mov		ecx,			[ebp+40]	; loop counter (size of array)
	mov		esi,			[ebp+44]	; esi = starting address of array
	mov		eax,			0			; eax = accumulator to sum elements of array

	; loop to process and print each array element
	printArray:
		
		; set local variable that will be passed to writeVal and keeps track
		; of how many digits have been stored in the output string to 0.
		mov		ebx,			0
		mov		[ebp-4],		ebx			; digitsStored local var = 0

		; prepare to call writeVal procedure
		mov		edx,			ebp
		sub		edx,			4
		push	edx				; pass stack address of digitsStored
		push	TRUE			; pass value of true for originalCall flag (indicating non-recursive call)
		push	[esi]			; pass value at current array index
		push	[ebp+36]		; pass starting address of output string
		call	writeVal

		; See if this is the last number in the array (ecx not yet decremented by loop instruction)
		cmp		ecx,			1
		je		next

		; If this is not the last iteration, print a comma and a space after the number just printed.
			displayString			[ebp+56]

		; Add the number at the current array index to accumulator, make esi point to next
		; array index, and loop again (if applicable).
		next:
		add		eax,			[esi]	; eax += val at current array index
		add		esi,			4		; esi points to next array element
		loop	printArray
	
	; prepare to call writeVal to display sum of array elements
	printSum:

	displayString			[ebp+52]	; "The sum of the numbers you entered is: "

	; set local variable that will be passed to writeVal and keeps track
	; of how many digits have been stored in the output string to 0.
	mov		ebx,			0
	mov		[ebp-4],		ebx			; digitsStored local var = 0

	; prepare to call writeVal procedure
	mov		edx,			ebp
	sub		edx,			4
	push	edx				; pass stack address of digitsStored
	push	TRUE			; pass value of true for originalCall flag (indicating non-recursive call)
	push	eax				; pass value of accumulator (sum of array elements)
	push	[ebp+36]		; pass starting address of output string
	call	writeVal
	
	; calculate average of array elements (rounded down to nearest integer)
	printAverage:
	mov		ebx,			[ebp+40]	; ebx = arrayLength
	mov		edx,			0			; clear edx register to store remainder
	div		ebx							; eax = average
	
	; prepare to call writeVal to display average of array elements
	displayString			[ebp+48]	; "The average of those numbers is: "

	; set local variable that will be passed to writeVal and keeps track
	; of how many digits have been stored in the output string to 0.
	mov		ebx,			0
	mov		[ebp-4],		ebx			; digitsStored local var = 0

	; prepare to call writeVal procedure
	mov		edx,			ebp
	sub		edx,			4
	push	edx				; pass stack address of digitsStored
	push	TRUE			; pass value of true for originalCall flag (indicating non-recursive call)
	push	eax				; pass value of average
	push	[ebp+36]		; pass starting address of output string
	call	writeVal
	call	CrLf
	call	CrLf

	; remove local variable from stack, restore registers,
	; and return to calling procedure.
	mov		esp,			ebp
	popad
	ret		28
showResults		ENDP


; ***************************************************************
; Recursive subprocedure that converts an unsigned 32-bit integer 
; to a null-terminated string containing the ascii representations 
; of each of its digits and invokes displayString macro to print
; the string.
; receives: the stack address of a local variable declared in 
;			showResults indicating the number of digits
;			that have already been added to the output string
;			by this procedure; a bool flag to indicate whether
;			or not this is the original procedure call;
;			the unsigned 32-bit integer's value to be converted
;			to a string; the starting address of the
;			output string
; returns:	nothing
; preconditions: Before showResults calls this procedure,
;				 it sets digitsStored to 0 and passes value of
;				 true for originalCall parameter.
; registers changed: none
; ***************************************************************
writeVal		PROC
	; save registers and set up stack frame
	push	eax
	push	ebx
	push	edx
	push	edi
	push	ebp
	mov		ebp,			esp

	; Remove the number in the 1's place from val
	mov		eax,			[ebp+28]	; eax = val
	mov		edx,			0			; clear edx register to store remainder
	mov		ebx,			10			; will divide val by 10 to obtain digit in 1's place
	div		ebx							; eax = val with 1's place removed; edx = digit removed from val

	; Determine if val has any more digits to remove. If not, process the digit just removed and return
	; from this procedure call (this is the base case of the recursion).
	cmp		eax,			0
	je		addDigit		; if eax = 0, there are no more digits to remove from val

	; Otherwise, prepare to recursively call writeVal to get next digit from val.
	push	[ebp+36]		; pass address of digitsStored
	push	FALSE			; pass value of false to indicate that this is a recursive procedure call
	push	eax				; pass new value of val after the division above
	push	[ebp+24]		; pass starting address of outputString
	call	writeVal

	; Add the digit removed from val and stored in edx to the output string.
	addDigit:
		; set edi to position of next character to be stored in the output string.
		mov		eax,			[ebp+36]
		mov		ebx,			[eax]		; ebx = digitsStored
		mov		edi,			[ebp+24]	; edi = starting address of output string
		add		edi,			ebx			; edi = position in output string at which to store this digit

		; convert the digit to its ascii representation and store in the output string
		mov		eax,			edx			; al = digit (in numeric form) to store in string
		add		al,				48			; al = digit (in ascii form) to store in string
		stosb

		; increment digitsStored
		inc		ebx
		mov		eax,			[ebp+36]
		mov		[eax],			ebx

		; Check to see if this is the original procedure call. If it is not, prepare
		; to return from this procedure call.
		mov		eax,			[ebp+32]	; eax = value of originalCall flag
		cmp		eax,			FALSE
		je		done

		; If this is the original procedure call (as opposed to a recursive call),
		; null-terminate the output string and invoke displayString macro to output the string.
			mov				eax,			0
			stosb							; outputString has been null-terminated
			displayString	[ebp+24]

	; Restore registers and return to calling procedure
	done:
	pop		ebp
	pop		edi
	pop		edx
	pop		ebx
	pop		eax
	ret		16
writeVal		ENDP


END main
