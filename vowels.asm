; 
; Count matching vowels in a string
; 
; Name: Skyler Romanuski
;
include Irvine32.inc

.DATA
MAX_STRING_LENGTH = 100                                 ; Symbolic constant for the maximum string length.
MAX_VOWELS = 5                                          ; Symbolic constant for the maximum number of vowels.

userString  BYTE MAX_STRING_LENGTH + 1 DUP(0)           ; An array to store user input + 1 for null terminator
vowelCounts DWORD MAX_VOWELS DUP(0)                     ; An array to store vowel counts
vowels      BYTE "aeiou", 0                             ; A string containing vowels
prompt      BYTE "Enter string: ", 0                    ; Input prompt message
found       BYTE "Vowels found: ", 0                    ; Output prompt messgage
stringTotal DWORD 0                                     ; A variable to store the total number of characters in the user's input

.CODE
main PROC
    mov edx, OFFSET prompt                              ; Make EDX point to 'prompt'
    call WriteString                                    ; Display the prompt message
    mov edx, OFFSET userString                          ; Make EDX point to the user string
    mov ecx, MAX_STRING_LENGTH + 1                      ; Move the max input size into ECX, + 1 for null termintor
    call ReadString                                     ; Read the inputted string
    mov stringTotal, eax                                ; Store the length of the input in 'stringTotal'
    mov esi, OFFSET userString                          ; Set esi to point to the inputted string

    mov edi, 0                                          ; Initialize edi to 0 for vowel index
    mov ecx, MAX_VOWELS                                 ; Set ECX to 5, for number of vowels

LoopCountChars:
    mov bl, [vowels + edi]                              ; Load the current vowel from the 'vowels' string
    push ecx                                            ; Push ECX to stack
    call CountChars                                     ; Call 'CountChars' to count the occurrences of the current vowel
    pop ecx                                             ; Pop ECX from stack
    mov [vowelCounts + edi * TYPE vowelCounts], edx     ; Store the count in the 'vowelCounts' array.
    inc edi                                             ; Increment edi by 1 to access the next vowel in 'vowels' and the next spot in 'vowelCounts'
    loop LoopCountChars                                 ; Continue the loop

    mov edx, OFFSET found                               ; Make EDX point to 'found'
    call WriteString                                    ; Display the 'found' message
    call Crlf                                           ; New line
    mov ecx, MAX_VOWELS                                 ; Set ecx to the maximum number of vowels
    mov edi, 0                                          ; Reset edi to 0 for vowel index
    lea esi, [vowelCounts]                              ; Set esi to point to the 'vowelCounts' array

print_loop:
    mov al, [vowels + edi]                              ; Load the current vowel character
    call WriteChar                                      ; Display the character
    mov al, " "                                         ; Move a space into al
    call WriteChar                                      ; Display a space
    mov eax, [esi]                                      ; Load the current vowel count from the 'vowelCounts' array into eax
    call WriteDec                                       ; Display the vowel count
    call Crlf                                           ; New line
    add edi, 1                                          ; Increment edi to access the next vowel
    add esi, TYPE vowelCounts                           ; Move to the next element in the 'vowelCounts' array
    loop print_loop                                     ; Continue the loop

    call WaitMsg                                        ; Display a message to wait for user input
    Invoke ExitProcess, 0                               ; Bye

main ENDP                                               ; End of main PROC

;----------------------------------------------------------------------
; CountChars
;
; Calculates and returns the amount of times a vowel occurs in a string
; Recieves: ESI - Points to user input
;           BL  - Current Vowel
;
;Returns: EDX - Amount of times the vowel was found
;----------------------------------------------------------------------

CountChars PROC
    mov ecx, stringTotal                                ; Set ECX to 'stringTotal'
    mov eax, 0                                          ; Initialize EAX to 0
L1: movzx ax, BYTE PTR [esi]                            ; Load a character from the user's input
    push ax                                             ; Push the character onto the stack
    inc esi                                             ; Move to the next character
    loop L1                                             ; Loop until the end of the string

    mov edx, 0                                          ; Initialize edx to 0 to count vowels
    mov ecx, stringTotal                                ; Set ECX to 'stringTotal'

L2: pop ax                                              ; Pop a character from the stack
    cmp al, bl                                          ; Compare the character to the current vowel
    je L3                                               ; If they match, jump to L3
    loop L2                                             ; Continue the loop

    mov esi, OFFSET userString                          ; Reset esi to point to the user's input
    ret                                                 ; Return

L3:
    add edx, 1                                          ; Increment EDX by 1 to count the number of vowels
    loop L2                                             ; Continue the loop to check for more vowels

    mov esi, OFFSET userString                          ; Reset esi to point to the user's input
    ret                                                 ; Return

CountChars ENDP                                         ; End of CountChars PROC

END main                                                ; End of the main program