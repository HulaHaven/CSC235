; 
; Load a list of olympians into an array of structs
; print them out, calculating the olympian's total medals
;
; Name: Skyler Romanuski
; 

include Irvine32.inc

; define some constants
FSIZE = 150							; max file name size
CR = 0Dh							; c/r
LF = 0Ah							; line feed
ASTERISK = 2Ah						; asterisk for new entry
NULL = 00h							; null character
SPACE = 20h							; space character
STRSIZE = 32						; string sizes in struct
NUMTESTS = 3						; number of olympian medals
ROUND = 1							; cutoff for rounding

olympian STRUCT
	sname BYTE STRSIZE DUP('n')		; 32 bytes	
	country BYTE STRSIZE DUP('c')	; 32
	medals DWORD NUMTESTS DUP(0)	; NUMTESTS x 32
olympian ENDS						; 76 total

.data
filename BYTE FSIZE DUP(?)			; array to hold the file name
fileptr DWORD 0						; the file pointer
prompt1 BYTE "Enter the number of olympians: ",0	; prompt for a string
prompt2 BYTE "Enter a filename: ",0	; prompt for a string
ferror BYTE "Invalid input...",0	; error message

maxnum DWORD 0						; max number of olympians
slistptr DWORD 0					; pointer to olympian list
numread	DWORD 0						; number of olympians loaded

; for output listing (these can be used as globals)
outname  BYTE "Olympian: ",0
outcountry BYTE "Country: ",0
outmedals  BYTE "Medals: ",0

.code
main PROC
    mov edx, OFFSET prompt1						; prompt for the number of olympians 
	call WriteString
	call ReadInt
	mov maxnum, eax								; mov inputed value to 'maxnum'

	push maxnum									; push maxnum to use in allocOlympians
	call allocOlympians							; call to allocate memory in the heap
	jc FILE_ERROR								; jump if carry flag is set
	mov slistptr, eax							; move location of allocated memory to 'slistptr'

    mov edx, OFFSET prompt2						; prompt for the file name
	call WriteString

	mov edx, OFFSET filename					; point to the beginning of 'filename' 
	mov ecx, FSIZE								; max size of the file
	call ReadString					

	mov edx, OFFSET filename					; point to the beginning of the file
	call OpenInputFile							; open the file
	mov fileptr, eax							; Store the file pointer

	cmp eax, INVALID_HANDLE_VALUE				; compare the file handle to the invalid handle
	je FILE_ERROR								; jump if hanlde is invalid

	push slistptr								; pass slistptr into loadAllOlympians
	push fileptr								; pass fileptr into loadAllOlympians
	push maxnum									; pass maxnum into loadAllOlympians
	call loadAllOlympians						; load all the olympains into the array of structs
	mov numread, eax							; mov number of olympians read into numread

	push slistptr								; pass slistptr into OutputAllOlympians	
	push numread								; pass numread into OutputAllOlympians
	call OutputAllOlympians						; output the number of olympians specified in numread to the terminal
	jmp DONE

FILE_ERROR:
	mov edx, OFFSET ferror						; load the error message
	call WriteString							; print the message
	call Crlf									; new line

DONE:
	mov eax, fileptr							; move fileptr to eax
	call CloseFile								; close the file
	call WaitMsg								; halt execution so output can be viewed
	invoke ExitProcess, 0						; bye
main ENDP

; read a character from a file
; receives:
;	[ebp+8]  = file pointer
; returns:
;	eax = character read, or system error code if carry flag is set
readFileChar PROC
	push ebp									; save the base pointer
	mov ebp,esp									; base of the stack frame
	sub esp,4									; create a local variable for the return value
	push edx									; save the registers
	push ecx

	mov eax,[ebp+8]								; file pointer
	lea edx,[ebp-4]								; pointer to value read
	mov ecx,1									; number of chars to read
	call ReadFromFile							; gets file handle from eax (loaded above)
	jc DONE										; if CF is set, leave the error code in eax
	mov eax,[ebp-4]								; otherwise, copy the char read from local variable

DONE:
	pop ecx										; restore the registers
	pop edx
	mov esp,ebp									; remove local var from stack 
	pop ebp
	ret 4
readFileChar ENDP

; allocates memory in the heap based on the number of olympians entered
; receives:
;	[ebp+8]  = number of olympians
; returns:
;	eax = pointer to allocated array
;	cf = set cary flag on error
allocOlympians PROC
	ENTER 0, 0									; enter the stack frame

	push edx									; save the registers
	push ebx									; save the registers

    mov edx, SIZEOF olympian					; move the size of olympian struct to edx
    imul edx, [ebp + 8]							; Multiply by the number of olympians
	call getProcessHeap							; get the heap handle
	mov ebx, eax								; store the handle

	push edx									; push the size you want the heap to be
	push HEAP_ZERO_MEMORY						; set to all zeros
	push ebx									; push the handle
	call HeapAlloc
	
	cmp eax, 0									; check if successful
	jne OK										; jump if successful
	stc											; set the carry flag
	jmp DONE									; jump to DONE

OK:
	clc											; clear the carry flag

DONE:
	pop ebx										; restore the registers
	pop edx										; restore the registers
	LEAVE										; leave the stack frame
	ret 4										; return the 4 bytes passed in
allocOlympians ENDP

; reads a line from the file
; receives:
;	[ebp + 8] = size of the string
;	[ebp + 12] = pointer to output BYTE array
;	[ebp + 16] = pointer to open file
; returns:
;	eax = numbers of characters read and stored in the target array
;	cf = set cary flag on error
readFileLine PROC
    ENTER 0, 0									; enter the stack frame
	push esi									; save the registers
	push ecx									; save the registers
	push ebx									; save the registers

	mov ecx, [ebp + 8]							; size of string
	mov esi, [ebp + 12]							; pointer to byte array
    mov ebx, 0									; 0 for counting

L1:
    push [ebp + 16]								; push the file pointer
    call readFileChar							; read a character
	jc ERROR									; jump if carry flag is set
    cmp al, CR									; check if the character is the carrige return
    je SKIP										; if character is the carrige return, jump to SKIP		
    cmp al, LF									; check if the character is the line feed
    je NULLCHAR									; if character is line feed, jump to NULLCHAR
    mov BYTE PTR [esi], al						; move the character into the BYTE array
	inc esi										; increment esi to point to the next position

SKIP:
	inc ebx										; increment the counter
    jmp L1										; Continue reading until a newline is encountered

ERROR:
	stc											; set the carry flag
	jmp POPALL									; jump to POPALL

NULLCHAR:
	mov BYTE PTR [esi], NULL					; add a null character 
	inc esi										; increment esi to the next position

DONE:
	clc											; clear the carry flag

POPALL:
	mov eax, ebx								; Number of characters read
	pop ebx										; restore the registers
	pop ecx										; restore the registers
	pop esi										; restore the registers
	LEAVE										; leave the stack frame
    ret 12										; return 12 bytes 
readFileLine ENDP

; loads an olympian into the olympian struct
; receives:
;	[ebp + 8] = pointer to open file
;	[ebp + 12] = pointer to the beginning of the struct
; returns:
;	eax = updated file pointer
;	cf = set cary flag on error
loadOlympian PROC
LOCAL array[STRSIZE]: BYTE						;declare a local byte array

	push ebx									; save the registers
	push edx									; save the registers
	push ecx									; save the registers
	push esi									; save the registers

	lea esi, array								; move effective address to the array
	push [ebp + 8]								; push the file pointer
	push esi									; push esi
	push STRSIZE								; push STRSIZE
	call readFileLine							; read a line
	jc ERROR									; jump if carry flag is set
	cmp byte ptr [array], ASTERISK				; compare line with an asterisk
	jne ERROR									; jump if it isn't an asterisk

NAMEOF:
	mov esi, [ebp + 12]							; move the pointer to the struct to esi
	lea ebx, (olympian PTR [esi]).sname			; mov the pointer to the struct into ebx
	push [ebp + 8]								; push the file pointer
	push ebx									; push the struct pointer
	push STRSIZE								; push the max string size
	call readFileLine							; read a line
	jc ERROR									; jump if carry flag is set

COUNTRY:
	mov esi, [ebp + 12]							; move the pointer to the struct to esi
	lea ebx, (olympian PTR [esi]).country		; mov the pointer to the struct into ebx
	push [ebp + 8]								; push the file pointer
	push ebx									; push the struct pointer
	push STRSIZE								; push the max string size
	call readFileLine							; read a line
	jc ERROR									; jump if carry flag is set

	mov ecx, NUMTESTS							; set ecx to the number of medals
	mov ebx, [ebp+12]							; move the pointer to the struct to ebx
	lea esi, (olympian PTR [ebx]).medals		; mov the pointer to the struct into esi
MEDALS:
	lea edx, array								; make edx load the effective address of the array
	mov ebx, [ebp + 12]							; move the pointer to the struct to ebx
	push [ebp + 8]								; push the file pointer
	push edx									; push the pointer to the BYTE array
	push STRSIZE								; push the max string size
	call readFileLine							; read a line
	jc ERROR									; jump if carry flag is set

PARSE:
	push ecx									; push ecx to save the loop counter
	mov ecx, eax								; move the number of characters read into ecx
	call PARSEINTEGER32							; convert string to integer
	mov [esi], eax								; mov the integer into the struct
	add esi, SIZE DWORD							; increment the struct to the loction of the next medal
	pop ecx										; restore the loop counter
	loop MEDALS									; loop til there are no more medals
	jmp DONE									; jump to DONE

ERROR:
	stc											; set the carry flag
	jmp POPALL									; jump to POPALL

DONE:
	mov eax, esi								; move the updated struct pointer to eax
 	clc											; clear the carry flag

POPALL:
	pop esi										; restore the registers
	pop ecx										; restore the registers
	pop edx										; restore the registers
	pop ebx										; restore the registers
	ret 8										; return 8 bytes
loadOlympian ENDP

; makes successive calls to loadOlympian
; receives:
;	[ebp + 8] = maximum number of olympians to read
;	[ebp + 12] = file pointer
;	[ebp + 16] = pointer to the beginning of the struct array
; returns:
;	eax = numbers of Olympians read
loadAllOlympians PROC
	ENTER 0, 0									; enter the stack frame

	push ebx									; save the registers
	push esi									; save the registers
	push edi									; save the registers
	push ecx									; save the registers

	mov ebx, 0									; 0 the counter to count the number of olympians loaded into the struct
	mov esi, [ebp + 16]							; move the struct pointer to esi

L1:
	push esi									; push the struck pointer
	push [ebp + 12]								; push the file pointer
	call loadOlympian							; load an olympian into the struct
	mov esi, eax								; move the updated struct pointer ot esi
	jc ERROR									; jump if carry flag was set | will set when file runs out of olympians
	
	inc ebx										; increment the counter
	cmp ebx, [ebp + 8]							; compare ebx to the max number of olympians
	je DONE										; jump if ebx = the max number of olympians
	loop L1										; loop L1
	jmp DONE									; jump to DONE

ERROR:
	stc											; set the carry flag
	jmp POPALL									; jump to POPALL

DONE:
 	clc											; clear the carry flag

POPALL:
	mov eax, ebx								; move number of olympians loaded into eax
	pop ecx										; restore the registers
	pop edi										; restore the registers
	pop esi										; restore the registers
	pop ebx										; restore the registers
	LEAVE										; leave the stack frame
	ret 12										; return 12 bytes

loadAllOlympians ENDP

; reads a line from the file
; receives:
;	[ebp + 8] = pointer to the beginning of the struct object
; returns:
;	There is no return value
OutputOlympian PROC
	ENTER 0, 0									; enter the stack frame

	push edx									; save the registers
	push ecx									; save the registers
	push eax									; save the registers

OUTPUTNAME:
	call Crlf									; new line
	mov edx, OFFSET outname						; prompt of olympian output
	call WriteString							; write to termial
	mov edx, [ebp + 8]							; point to the struct
	add edx, OFFSET olympian.sname				; add the offset of the olympian name
	call WriteString							; write the name to terminal

OUTPUTCOUNTRY:
	call Crlf									; new line
	mov edx, OFFSET outcountry					; prompt of country output
	call WriteString							; write to termial
	mov edx, [ebp + 8]							; point to the struct
	add edx, OFFSET olympian.country			; add the offset of the olympian country
	call WriteString							; write the country to terminal

OUTPUTMEDALS:
	call Crlf									; new line
	mov edx, OFFSET outmedals					; prompt of medals output
	call WriteString							; write to termial
	mov edx, [ebp + 8]							; point to the struct
	add edx, OFFSET olympian.medals				; add the offset of the olympian medals
	mov eax, 0									; 0	eax to count total number of medals
	mov ecx, NUMTESTS							; make ecx the number of medals

COUNTMEDALS:
	add eax, [edx]								; add the number of medals from edx to eax
	add edx, TYPE DWORD							; increment to the next medal									
	loop COUNTMEDALS							; loop all the medals

FINISHMEDALS:
	mov edx, eax								; move the total medal count to edx
	call WriteDec								; write the total medal count to terminal
	call Crlf									; new line

DONE:
	pop eax										; restore the registers
	pop ecx										; restore the registers
	pop edx										; restore the registers
	LEAVE										; leave the stack frame
	ret 4										; return 4 bytes
	
OutputOlympian ENDP

; Outputs the entire array of Olympains by successively calling outputOlympian
; receives:
;	[ebp + 8] = Number of Olympians to output
;	[ebp + 12] = pointer to the first Olympian struct
; returns:
;	There is no return value
OutputAllOlympians PROC
	ENTER 0, 0									; enter the stack frame

	push esi									; save the registers
	push ecx									; save the registers
			
	mov esi, [ebp + 12]							; move struct pointer to esi
	mov ecx, [ebp + 8]							; move number of olympians to output to ecx
L1:
	push ecx									; push number olympains to output
	push esi									; push the struct pointer
	call OutputOlympian							; output an olympian
		
	add esi, SIZEOF Olympian					; increment to the second struct
	pop ecx										; restore the loop counter
	loop L1										; loop L1

POPALL:
	pop ecx										; restore the registers
	pop esi										; restore the registers
	LEAVE										; leave the stack frame
	ret 8										; return 8 bytes

OutputAllOlympians ENDP

END main