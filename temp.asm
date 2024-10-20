.model small
.stack 100h
.data
    buffer1 db 101 dup('$')  ; Buffer to store the first input string
    buffer2 db 21 dup('$')   ; Buffer to store the second input string
    reversedBuffer db 101 dup('$') ; Buffer to store the reversed string
    msg1 db 'Enter a string (max 100 chars):$'
    msg2 db 0Dh, 0Ah, 'Enter another string (max 20 chars):$'
    newLine db 0Dh, 0Ah, '$'
    msgFound db 'Second string found in the first string.$'
    msgNotFound db 'Second string not found in the first string.$'
    msgReverse db 0Dh, 0Ah, 'Reversed first string:$'
    msgCount db 0Dh, 0Ah, 'Number of occurrences: $'
    msgOccurrences db 0Dh, 0Ah, 'Occurrences at indices:$'
    indices dw 50 dup(0)     ; Buffer to store the starting indices (word array)
    indexCount db 0          ; Count of starting indices found
    msgOriginal db 0Dh, 0Ah, 'Original string:$'
    msgSubstring db 0Dh, 0Ah, 'Substring:$'

.code
main proc
    mov ax, @data
    mov ds, ax
    mov es, ax

    ; Display the first prompt message
    lea dx, msg1
    mov ah, 09h
    int 21h

    ; Read the first string from keyboard
    lea di, buffer1  ; Load the address of buffer1 into DI
    mov cx, 100      ; Set maximum characters to read for the first string
    call ReadString

    ; Display new line
    lea dx, newLine
    mov ah, 09h
    int 21h

    ; Display "Original string:" message
    lea dx, msgOriginal
    mov ah, 09h
    int 21h

    ; Display the entered first string
    lea dx, buffer1
    mov ah, 09h
    int 21h

    ; Display new line before the second prompt message
    lea dx, newLine
    mov ah, 09h
    int 21h

    ; Display the second prompt message
    lea dx, msg2
    mov ah, 09h
    int 21h

    ; Read the second string from keyboard
    lea di, buffer2  ; Load the address of buffer2 into DI
    mov cx, 20       ; Set maximum characters to read for the second string
    call ReadString

    ; Display new line
    lea dx, newLine
    mov ah, 09h
    int 21h

    ; Display "Substring:" message
    lea dx, msgSubstring
    mov ah, 09h
    int 21h

    ; Display the entered second string
    lea dx, buffer2
    mov ah, 09h
    int 21h

    ; Display new line after the entered second string
    lea dx, newLine
    mov ah, 09h
    int 21h

    ; Display "Original string:" message again
    lea dx, msgOriginal
    mov ah, 09h
    int 21h

    ; Display the entered first string again
    lea dx, buffer1
    mov ah, 09h
    int 21h

    ; Display new line
    lea dx, newLine
    mov ah, 09h
    int 21h

    ; Display "Substring:" message again
    lea dx, msgSubstring
    mov ah, 09h
    int 21h

    ; Display the entered second string again
    lea dx, buffer2
    mov ah, 09h
    int 21h

    ; Display new line
    lea dx, newLine
    mov ah, 09h
    int 21h

    ; Find the second string in the first string
    call FindSubstring

    ; Display the number of occurrences
    lea dx, msgCount
    mov ah, 09h
    int 21h

    ; Convert indexCount to 16-bit for printing
    xor ax, ax
    mov al, indexCount
    call PrintNumber

    ; Display new line
    lea dx, newLine
    mov ah, 09h
    int 21h

    ; Display the "Occurrences at indices:" message
    lea dx, msgOccurrences
    mov ah, 09h
    int 21h

    ; Display the result
    cmp byte ptr indexCount, 0
    je NotFound

    ; Display the indices
    lea si, indices
    mov cl, indexCount   ; Use the lower byte of CX for the loop counter

DisplayIndices:
    ; Check if we have displayed all indices
    cmp cl, 0
    je DoneDisplaying

    ; Display the current index
    lodsw
    call PrintNumber

    ; Display a space
    mov dl, ' '
    mov ah, 02h
    int 21h

    dec cl
    jmp DisplayIndices

DoneDisplaying:
    lea dx, newLine
    mov ah, 09h
    int 21h

    ; Print the reversed first string
    lea dx, msgReverse
    mov ah, 09h
    int 21h

    call ReverseString

    ; Exit program
    mov ax, 4C00h
    int 21h

NotFound:
    lea dx, msgNotFound
    mov ah, 09h
    int 21h
    jmp DoneDisplaying

main endp

ReadString proc
    ; Initialize registers
    xor bx, bx    ; BX will count the characters read

ReadChar:
    ; Read a character from keyboard using BIOS interrupt
    mov ah, 00h
    int 16h
    ; Check for Enter key (ASCII 13)
    cmp al, 0Dh
    je DoneReading

    ; Store the character in buffer if there is space
    cmp bx, cx    ; Compare character count with buffer size
    jae DoneReading  ; If buffer is full, stop reading
    stosb
    inc bx

    ; Continue reading characters
    jmp ReadChar

DoneReading:
    ; Null-terminate the string
    mov al, '$'
    stosb
    ret
ReadString endp

FindSubstring proc
    push si
    push di
    push cx
    push dx

    lea si, buffer1      ; Point SI to the start of the first string

NextChar:
    ; Check if we have reached the end of the first string
    cmp byte ptr [si], '$'
    je DoneFindSubstring

    ; Compare the current substring in buffer1 with buffer2
    lea di, buffer2
    call CompareStrings
    cmp ax, 0
    je StoreIndex

    inc si               ; Move to the next character in buffer1
    jmp NextChar

StoreIndex:
    ; Store the starting index of the match
    lea di, indices
    xor bx, bx
    mov bl, indexCount
    shl bx, 1            ; Multiply indexCount by 2 to get the word offset
    add di, bx
    mov bx, si
    sub bx, offset buffer1 ; Calculate the index
    mov [di], bx
    inc byte ptr indexCount

    inc si               ; Move to the next character in buffer1
    jmp NextChar

DoneFindSubstring:
    pop dx
    pop cx
    pop di
    pop si
    ret
FindSubstring endp

CompareStrings proc
    ; Compare the strings at SI and DI
    ; Returns 0 in AX if they match, non-zero otherwise
    push si
    push di

CompareLoop:
    mov al, [di]       ; Load byte from DI into AL
    cmp al, '$'        ; Check for end of the second string
    je Equal

    cmp al, [si]       ; Compare AL with byte at SI
    jne NotEqual

    inc si
    inc di
    jmp CompareLoop

Equal:
    xor ax, ax
    jmp CompareEnd

NotEqual:
    mov ax, 1

CompareEnd:
    pop di
    pop si
    ret
CompareStrings endp

PrintNumber proc
    ; Print a number in AX
    push ax
    push bx
    push cx
    push dx

    mov cx, 0          ; Digit count
    mov bx, 10         ; Divisor

PrintLoop:
    xor dx, dx
    div bx             ; AX = AX / 10, DX = AX % 10
    push dx            ; Push remainder (next digit)
    inc cx
    test ax, ax        ; Check if AX is 0
    jnz PrintLoop

PrintDigits:
    pop dx
    add dl, '0'        ; Convert digit to ASCII
    mov ah, 02h
    int 21h
    loop PrintDigits

    pop dx
    pop cx
    pop bx
    pop ax
    ret
PrintNumber endp

ReverseString proc
    push si
    push di
    push cx
    push bx

    lea si, buffer1      ; Point SI to the start of the first string
    lea di, reversedBuffer ; Point DI to the start of the reversed string buffer

    ; Find the end of the string
    mov cx, 0
    FindEnd:
        mov bx, cx
        mov al, [si+bx]
        cmp al, '$'
        je FoundEnd
        inc cx
        jmp FindEnd
    FoundEnd:
    dec cx   ; Move CX to the last character of the string

    ; Move SI to the last character
    lea si, buffer1
    add si, cx

    ; Reverse the string into reversedBuffer
    ReverseLoop:
        mov al, [si]
        mov [di], al
        inc di
        dec si
        test cx, cx
        jz EndReverseLoop
        dec cx
        jmp ReverseLoop

EndReverseLoop:
    ; Null-terminate the reversed string
    mov al, '$'
    mov [di], al

    ; Display the reversed string
    lea dx, reversedBuffer
    mov ah, 09h
    int 21h

    pop bx
    pop cx
    pop di
    pop si
    ret
ReverseString endp

end main
