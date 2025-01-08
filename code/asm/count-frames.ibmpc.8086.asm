; 8086 Assembly Program to Count Frames in an XTXT File for MS-DOS

.MODEL SMALL
.STACK 100H

.DATA
buffer DB 1024 DUP(?)        ; Buffer to load the .xtxt file
filename DB 'INPUT.XTX', 0  ; Filename of the XTXT file
fileHandle DW ?              ; File handle for the opened file
bytesRead DW ?               ; Number of bytes read
frameCount DW 0              ; Variable to store the number of frames

markerHigh DB 0FFH           ; High byte of the Next Frame Marker (NFM)
markerLow DB 0FDH            ; Low byte of the Next Frame Marker (NFM)

prompt DB 'Total frames: $'
errorMsg DB 'Error: Could not open/read file.', 0dh, 0ah, '$'

.CODE
MAIN PROC
    MOV AX, @DATA            ; Load data segment into AX
    MOV DS, AX               ; Set DS to point to data segment
   ; MOV ES, AX               ; Not needed

    ; Open the file
    MOV AH, 3DH              ; DOS Open File function
    LEA DX, filename         ; Load address of filename into DX
    MOV AL, 0                ; Open in read-only mode
    INT 21H                  ; DOS interrupt
    JC FILE_ERROR            ; Jump to error if the carry flag is set
    MOV fileHandle, AX       ; Store the file handle

FILE_READ_LOOP:
    ; Read the file
    MOV AH, 3FH              ; DOS Read File function
    MOV BX, fileHandle       ; Load file handle
    LEA DX, buffer           ; Load address of buffer into DX
    MOV CX, 1024             ; Number of bytes to read
    INT 21H                  ; DOS interrupt
    JC FILE_ERROR            ; Jump to error if the carry flag is set
    MOV bytesRead, AX        ; Store the number of bytes read

    ; Check if we reached the end of the file
    CMP AX, 0
    JE FILE_READ_END         ; If bytesRead is zero, we reached the end

    ; Count frames in the buffer
    LEA SI, buffer           ; Load address of buffer into SI
    MOV CX, bytesRead        ; Load number of bytes read into CX
    XOR BX, BX               ; Clear BX to use as the frame counter

SEARCH_LOOP:
    CMP CX, 0                ; Check if all bytes have been processed
    JE NEXT_READ             ; If CX is zero, jump to next read

    MOV AL, [SI]             ; Load the current byte into AL
    INC SI                   ; Increment SI to point to the next byte
    DEC CX                   ; Decrement CX (remaining bytes to process)

    CMP AL, markerHigh       ; Check if the byte matches the high byte of NFM
    JNE SEARCH_LOOP          ; If not, continue searching

    CMP CX, 0                ; Ensure there is another byte to check
    JE NEXT_READ          ; If not, jump to next read

    MOV AL, [SI]             ; Load the next byte into AL
    INC SI                   ; Increment SI
    DEC CX                   ; Decrement CX
    CMP AL, markerLow        ; Check if it matches the low byte of NFM
    JNE SEARCH_LOOP          ; If not, continue searching

    INC BX                   ; Increment the frame counter
    JMP SEARCH_LOOP          ; Continue searching

NEXT_READ:
     ADD frameCount, BX       ; Add accumulated frames
     JMP FILE_READ_LOOP       ; Loop and read more data


FILE_READ_END:


    ; Close the file
    MOV AH, 3EH              ; DOS Close File function
    MOV BX, fileHandle       ; Load file handle
    INT 21H                  ; DOS interrupt

    ; Print the result
    MOV AX, frameCount      ; move the accumulated frame count into AX
    MOV AH, 09H              ; DOS Print String function
    LEA DX, prompt           ; Load address of the prompt string
    INT 21H                  ; DOS interrupt

    ; Print the frame count
    CALL PRINT_NUMBER        ; Print the frame count

    ; Exit program
    MOV AH, 4CH              ; DOS terminate program function
    INT 21H                  ; Exit to DOS

FILE_ERROR:
    ; Handle file errors
    MOV AH, 09H              ; DOS Print String function
    LEA DX, errorMsg         ; Load address of an error string
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