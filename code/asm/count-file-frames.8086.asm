; 8086 Assembly Program to Count Frames in an XTXT File for MS-DOS

.MODEL SMALL
.STACK 100H

.DATA
buffer DB 1024 DUP(?)        ; Buffer to load the .xtxt file
filename DB 'input.xtxt', 0  ; Filename of the XTXT file
fileHandle DW ?              ; File handle for the opened file
bytesRead DW ?               ; Number of bytes read
frameCount DW 0              ; Variable to store the number of frames

markerHigh DB 0FFH           ; High byte of the Next Frame Marker (NFM)
markerLow DB 0FDH            ; Low byte of the Next Frame Marker (NFM)

prompt DB 'Total frames: $'

.CODE
MAIN PROC
    MOV AX, @DATA            ; Load data segment into AX
    MOV DS, AX               ; Set DS to point to data segment
    MOV ES, AX               ; Set ES to point to data segment (used for buffer)

    ; Open the file
    MOV AH, 3DH              ; DOS Open File function
    LEA DX, filename         ; Load address of filename into DX
    MOV AL, 0                ; Open in read-only mode
    INT 21H                  ; DOS interrupt
    JC FILE_ERROR            ; Jump to error if the carry flag is set
    MOV fileHandle, AX       ; Store the file handle

    ; Read the file
    MOV AH, 3FH              ; DOS Read File function
    MOV BX, fileHandle       ; Load file handle
    LEA DX, buffer           ; Load address of buffer into DX
    MOV CX, 1024             ; Number of bytes to read
    INT 21H                  ; DOS interrupt
    JC FILE_ERROR            ; Jump to error if the carry flag is set
    MOV bytesRead, AX        ; Store the number of bytes read

    ; Close the file
    MOV AH, 3EH              ; DOS Close File function
    MOV BX, fileHandle       ; Load file handle
    INT 21H                  ; DOS interrupt

    ; Count frames in the buffer
    LEA SI, buffer           ; Load address of buffer into SI
    MOV CX, bytesRead        ; Load number of bytes read into CX
    XOR BX, BX               ; Clear BX to use as the frame counter

SEARCH_LOOP:
    CMP CX, 0                ; Check if all bytes have been processed
    JE PRINT_RESULT          ; If CX is zero, jump to print the result

    MOV AL, [SI]             ; Load the current byte into AL
    INC SI                   ; Increment SI to point to the next byte
    DEC CX                   ; Decrement CX (remaining bytes to process)

    CMP AL, markerHigh       ; Check if the byte matches the high byte of NFM
    JNE SEARCH_LOOP          ; If not, continue searching

    CMP CX, 0                ; Ensure there is another byte to check
    JE PRINT_RESULT          ; If not, jump to print the result

    MOV AL, [SI]             ; Load the next byte into AL
    INC SI                   ; Increment SI
    DEC CX                   ; Decrement CX
    CMP AL, markerLow        ; Check if it matches the low byte of NFM
    JNE SEARCH_LOOP          ; If not, continue searching

    INC BX                   ; Increment the frame counter
    JMP SEARCH_LOOP          ; Continue searching

PRINT_RESULT:
    MOV frameCount, BX       ; Store the frame count in memory

    ; Print the result
    MOV AH, 09H              ; DOS Print String function
    LEA DX, prompt           ; Load address of the prompt string
    INT 21H                  ; DOS interrupt

    MOV AX, frameCount       ; Load the frame count
    CALL PRINT_NUMBER        ; Print the frame count

    ; Exit program
    MOV AH, 4CH              ; DOS terminate program function
    INT 21H                  ; Exit to DOS

FILE_ERROR:
    ; Handle file errors (optional)
    MOV AH, 09H              ; DOS Print String function
    LEA DX, prompt           ; Load address of an error string (if defined)
    INT 21H                  ; DOS interrupt
    MOV AH, 4CH              ; DOS terminate program function
    INT 21H                  ; Exit to DOS

; Subroutine to print a number
PRINT_NUMBER PROC
    PUSH AX                  ; Save AX
    PUSH DX                  ; Save DX

    XOR CX, CX               ; Clear CX (digit count)
    MOV BX, 10               ; Divisor for decimal numbers

DIV_LOOP:
    XOR DX, DX               ; Clear DX for division
    DIV BX                   ; Divide AX by 10, remainder in DX
    PUSH DX                  ; Push remainder onto stack
    INC CX                   ; Increment digit count
    TEST AX, AX              ; Check if AX is zero
    JNZ DIV_LOOP             ; Repeat until AX is zero

PRINT_DIGITS:
    POP DX                   ; Pop digit from stack
    ADD DL, '0'              ; Convert to ASCII
    MOV AH, 02H              ; DOS Print Character function
    INT 21H                  ; Print the character
    LOOP PRINT_DIGITS        ; Loop until all digits are printed

    POP DX                   ; Restore DX
    POP AX                   ; Restore AX
    RET
PRINT_NUMBER ENDP

MAIN ENDP
END MAIN
