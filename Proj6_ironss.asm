TITLE User Input to SDWORD - Hard Version   (Proj6_ironss.asm)

; Author: Scott Irons
; Last Modified: 3/7/2022
; OSU email address: ironss@oregonstate.edu
; Course number/section:   CS271 Section 402
; Project Number:   6              Due Date: 3/13/2022 (pi day minus 1)
; Description: 

INCLUDE Irvine32.inc

mGetString	MACRO	prompt, storage, maxLength, bytesRead
	push	eax
	push	ecx
	push	edx

	; prompt user to enter input
	mov		edx, prompt					; OFFSET
	call	WriteString

	mov		edx, storage				; address of buffer
	mov		ecx, maxLength				; buffer size + 1 (if user enters this many, it's too big)
	call	ReadString
	mov		bytesRead, eax

	pop		edx
	pop		ecx
	pop		eax
ENDM

mDisplayString MACRO stringOffset
	push	edx

	mov		edx, stringOffset
	call	WriteString

	pop		edx
ENDM

.data

intro1		BYTE	"Assignment 6: User Input to SDWORD - Hard Version by Scott Irons",13,10,0
intro2		BYTE	"Please enter 10 signed decimal integers (use + or - to indicate sign, if you want).",13,10,0
intro3		BYTE	"Your numbers must be within the range [-2,147,483,648, +2,147,483,647].",13,10,0
intro4		BYTE	"After you've entered 10 valid numbers, I'll display them as integers and show both their sum and average.",13,10,0

prompt1		BYTE	"Please enter a signed number: ",0
error1		BYTE	"ERROR: You entered something other than a signed number or your number was outside of the range...",0
retry		BYTE	"Please try again: ",0

userInput	BYTE	500 DUP(?),0	; in case the user enters a very large amount of character
inputSize	DWORD	?				; number of digits the user entered

toAscii		BYTE	11 DUP(?),0		; 11 is max length

testArray	SDWORD	10 DUP(?)		; store each result in here

totalSum	SDWORD	?
totalMean	SDWORD	?

displayTest	BYTE	"You entered the following numbers:",13,10,0
commaSpace	BYTE	", ",0
displaySum	BYTE	"The sum of these numbers is: ",0
displayMean	BYTE	"The truncated average is: ",0

toodles		BYTE	"So long, and thanks for all the fish!",0

.code

main PROC

	push	OFFSET intro1
	push	OFFSET intro2
	push	OFFSET intro3
	push	OFFSET intro4
	call	introduction
	call	CrLf

	mov		edi, OFFSET testArray
	mov		ecx, 10

_GetVals:
	push	LENGTHOF userInput
	push	edi
	push	OFFSET prompt1
	push	OFFSET error1
	push	OFFSET retry
	push	OFFSET userInput
	push	inputSize
	call	ReadVal
	add		edi, 4				; go to next element in the array
	loop	_GetVals

	call	CrLf
	mov		edx, OFFSET displayTest
	call	WriteString
	
	mov		ecx, 10
	mov		esi, OFFSET testArray

_PrintVals:
	push	OFFSET toAscii
	push	[esi]
	call	WriteVal
	cmp		ecx, 1
	je		_AllDonePrinting
	mov		edx, OFFSET commaSpace
	call	WriteString
	add		esi, 4
	loop	_PrintVals

_AllDonePrinting:
	call	CrLf
	call	CrLf

	; add up all the values
	mov		ecx, 10
	mov		edi, OFFSET testArray
_AddVals:
	mov		eax, [edi]
	add		totalSum, eax
	add		edi, 4
	loop	_AddVals

	; print sum
	mov		edx, OFFSET displaySum
	call	WriteString

	push	OFFSET toAscii
	push	totalSum
	call	WriteVal
	call	CrLf

	; calculate truncated average
	mov		eax, totalSum
	mov		ebx, 10
	cdq
	idiv	ebx
	mov		totalMean, eax

	; print rounded average
	mov		edx, OFFSET displayMean
	call	WriteString

	push	OFFSET toAscii
	push	totalMean
	call	WriteVal
	call	CrLf

	; say goodbye
	push	OFFSET toodles
	call	farewell

	Invoke ExitProcess,0	; exit to operating system
main ENDP

; ---------------------------------------------------------------------------------
; Name: introduction
;
; Introduces the program and the programmer and explains the instructions to the user.
;
; Preconditions: all input strings are declared in the .data section
;
; Postconditions: none
;
; Receives:
;		[ebp + 20]	=	OFFSET intro1
;		[ebp + 16]	=	OFFSET intro2
;		[ebp + 12]	=	OFFSET intro3
;		[ebp + 8]	=	OFFSET intro4
;
; returns: none, but prints the intros to the screen
; 
; registers modified: edx
; ---------------------------------------------------------------------------------
introduction PROC
	push	ebp
	mov		ebp, esp
	push	edx

	mov		edx, [ebp + 20]
	call	WriteString
	call	CrLf

	mov		edx, [ebp + 16]
	call	WriteString

	mov		edx, [ebp + 12]
	call	WriteString

	mov		edx, [ebp + 8]
	call	WriteString

	pop		edx
	pop		ebp
	ret		20
introduction ENDP

; ---------------------------------------------------------------------------------
; Name: ReadVal
;
; Invokes the mGetString macro to get a user input string (which should be a signed integer).
; Converts the string of ascii digits to an SDWORD, validating the user input is valid. Then
; stores this value in 
;
; Preconditions: all variables declared in .data
;
; Postconditions: the converted userInput is a valid SDWORD
;
; Receives:
;		[ebp + 32]	=	LENGTHOF userInput (500 bytes)
;		[ebp + 28]	=	testNum	(stored output value)
;		[ebp + 24]	=	OFFSET prompt1
;		[ebp + 20]	=	OFFSET error1
;		[ebp + 16]	=	OFFSET retry
;		[ebp + 12]	=	OFFSET userInput
;		[ebp + 8]	=	inputSize	(number of digits the user enters)
;
; returns: testNum contains the validated SDWORD
;
; registers changed: edi, eax, ecx, edx
; ---------------------------------------------------------------------------------
ReadVal PROC
	push	ebp
	mov		ebp, esp
	push	eax
	push	ecx
	push	edx
	push	edi

	mov		edi, [ebp + 28]

	; prompt, storage, maxLength, bytesRead
	mGetString [ebp + 24], [ebp + 12], [ebp + 32], [ebp + 8]

	; check if user entered 1 byte
	mov		eax, [ebp + 8]
	cmp		eax, 1
	je		_CheckSingleDigit
	cmp		eax, 11
	jge		_CheckMaxSign
	jl		_CheckNormalSign

_Invalid:
	mov		edx, [ebp + 20]
	call	WriteString
	call	CrLf

	; clear the value in testNum. I found you you stinkin' bug!!
	mov		eax, 0
	mov		[edi], eax

	mGetString [ebp + 16], [ebp + 12], [ebp + 32], [ebp + 8]
	mov		eax, [ebp + 8]
	cmp		eax, 1
	je		_CheckSingleDigit
	cmp		eax, 11
	jge		_CheckMaxSign
	jl		_CheckNormalSign


; if the user enters only one digit, it must be an integer
_CheckSingleDigit:
	mov		esi, [ebp + 12]
	lodsb
	cmp		al, 48
	jl		_Invalid
	cmp		al, 57
	jg		_Invalid

	; subtract 48 from the ascii value. This result is the single digit
	sub		al, 48
	movzx	eax, al
	add		[edi], eax
	jmp		_Finished


; if the user enters 11 digits, the first one must be a sign
_CheckMaxSign:
	mov		ecx, [ebp + 8]
	dec		ecx				; we've already looked at the first value
	mov		esi, [ebp + 12]
	lodsb
	cmp		al, '+'
	je		_LeadingZeros
	cmp		al, '-'			; it's like a face '-'
	je		_LeadingZeros
	cmp		al, '0'
	je		_LeadingZeros	
	jmp		_Invalid		; if the first value is not + or -

; user entered submaximal number of digits so we don't need a sign first
_CheckNormalSign:
	mov		ecx, [ebp + 8]
	mov		esi, [ebp + 12]
	lodsb
	cmp		al, '+'
	je		_DecECX
	cmp		al, '-'			; it's like a face '-'
	je		_DecECX
	cmp		al, '0'
	jne		_NormalCheck


; if the current digit is sign or a leading zero
_DecECX:
	dec		ecx
	cmp		ecx, 0
	je		_IsItZero

; check if the user entered a bunch of leading zeros to mess with me
_LeadingZeros:
	lodsb
	cmp		al, '0'
	je		_DecECX
	cmp		al, 48
	jl		_Invalid
	cmp		al, 57
	jg		_Invalid

; -------------------------
; The normal checking/converting method works as follows:
;	1. For each individual byte, if it's not a digit (ascii between 48 and 57), it is invalid.
;	2. Given the byte is a valid integer digit, eax = [10^(ecx-1)*value]. Add eax to [edi]
;		a. 10 ^ (ecx - 1) is the place value of the digit
;	3. Continue this process until we reach the final digit (ones place)
;   4. Then, re-check if there is a sign in the first digit of the user input string and NEG if necessary.
; -------------------------
_NormalCheck:
	; we've checked for any leading zeros/sign. If there are still more than 10 digits to check, it's invalid
	cmp		ecx, 10
	jg		_Invalid
	; if it's below 0 or above 9 in ascii, it's invalid
	cmp		al, 48
	jl		_Invalid
	cmp		al, 57
	jg		_Invalid

	; subtract 48 from the ascii value to find the digit value
	sub		al, 48
	movzx	eax, al

	; preserve eax (the digit value) and ecx (counter)
	push	eax
	push	ecx

	; 10^ (ecx - 1) is the place value. If ecx-1 = 0, we're at the ones place
	dec		ecx
	cmp		ecx, 0
	je		_OnesPlace

	; 10 ^ (ecx - 1) to get the place value. ecx originates in the outer loop
	mov			eax, 1
	_PlaceValue:
		mov		ebx, 10
		mul		ebx
		loop	_PlaceValue

	pop		ecx
	pop		ebx			; digit value now stored in EBX. EAX holds the place value (e.g. 100)

	; ebx * eax is the value to add
	mul		ebx
	; the resulting multiplication is bigger than the operand size
	jc		_Invalid
	add		[edi], eax
	; the resulting value is signed (too big for SDWORD)
	js		_Invalid
	jmp		_Loop

_PreserveAndInvalid:
	pop		ecx
	pop		eax
	jmp		_Invalid
; -------------------------
; Once the string primitive execution has reached the final user-entered digit, the following will take place:
;	1. Double check if the data has a positive/negative sign. If it is negative, NEG the value.
;	2. If it is positive, add the final digit, and conditionally jump to _Invalid if it's too big.
;   3. If it is negative, subtract the final digit, and conditionally jump to _Invalid if it's too smol.
; -------------------------
_OnesPlace:
	push	eax						; preserve eax value (holds the ones digit value)
	mov		esi, [ebp + 12]			; reset esi to look at first value again
	lodsb
	cmp		al, '-'
	jne		_Positive				; if the first value is not '-', it is positive

_Negative:
	pop		eax
	mov		ebx, [edi]
	neg		ebx
	mov		[edi], ebx
	sub		[edi], eax
	jns		_PreserveAndInvalid		; it's not signed = it's too small for SDWORD
	pop		ecx
	pop		ebx
	jmp		_Finished

_Positive:
	pop		eax
	add		[edi], eax
	js		_PreserveAndInvalid		; it's too big for SDWORD
	pop		ecx
	pop		ebx
	jmp		_Finished

_Loop:
	lodsb
	cmp		ecx, 0
	je		_Finished
	loop	_NormalCheck
	
	
; -------------------------
; If we've been removing leading zeros or a sign value and ecx is 0 (no more values to check),
; the final value in AL from LODSB needs to be '0', or else it's an invalid number.
; -------------------------
_IsItZero:
	cmp		al, '0'
	jne		_Invalid
	mov		eax, 0
	mov		[edi], eax

_Finished:
	pop		edi
	pop		edx
	pop		ecx
	pop		eax
	pop		ebp
	ret		28
ReadVal	ENDP


; ---------------------------------------------------------------------------------
; Name: WriteVal
;
; Converts a numeric SDWORD input into a string of ascii digits and uses the macro mDisplayString to 
; print the ascii representations of the SDWORD.
;
; Preconditions: The validated user input has been converted to an SDWORD wich this procedure receives as a parameter.
;
; Postconditions: The number is printed to the screen using the mDisplayString macro.
;
; Receives:
;		[ebp + 12]	=	OFFSET	toAscii (string for result)
;		[ebp + 8]	=	SDWORD input
;
; returns: none, but prints the ascii characters for each digit in the SDWORD
;
; registers modified: eax, ebx, ecx, edx, edi
; ---------------------------------------------------------------------------------
WriteVal PROC
	push	ebp
	mov		ebp, esp
	push	eax
	push	ebx
	push	ecx
	push	edx
	push	edi
	mov		ecx, 0				; clear counter :-]

	mov		edi, [ebp + 12]		; offset of output string
	add		edi, 10				; go to the final index in the string
	std							; will add values backward

	mov		eax, [ebp + 8]		; dividend
	cmp		eax, 0
	jge		_RepeatedDiv

	; the SDWORD is negative
	mov		ecx, 1				; use this as an indicator to add a '-' at the front of the string
	neg		eax

; the SDWORD is positive, jump right to here
_RepeatedDiv:
	mov		edx, 0
	mov		ebx, 10
	div		ebx
	push	eax

	; move the remainder to al, add 48 (0 in ascii) and store this in the output string
	mov		al, dl
	add		al, 48
	stosb

	; preserve eax
	pop		eax
	cmp		eax, 0
	jg		_RepeatedDiv

	; if I marked it negative, add '-' to the front
	cmp		ecx, 1
	jne		_PrintResult


_Negative:
	mov		al, '-'				; wee little face '-'
	stosb

_PrintResult:
	cld
	inc		edi
	mDisplayString edi

	pop		edi
	pop		edx
	pop		ecx
	pop		ebx
	pop		eax
	pop		ebp
	ret		8
WriteVal ENDP


; ---------------------------------------------------------------------------------
; Name: farewell
; 
; Say goodbye
;
; Receives:
;		[ebp + 8]	=	OFFSET toodles (goodbye string)
;
; Thank you, kind TA, for all your hard work this quarter :-]
; ---------------------------------------------------------------------------------
farewell PROC
	push	ebp
	mov		ebp, esp

	call	CrLF
	mov		edx, [ebp + 8]
	call	WriteString
	call	CrLF

	pop		ebp
	ret		4
farewell ENDP

END main
