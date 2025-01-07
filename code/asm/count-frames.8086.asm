; 8086 Assembly Program to Count Frames in an XTXT File for MS-DOS

.MODEL SMALL
.STACK 100H

.DATA
XTXT_DATA DB 'Hello, world!', 0FFH, 0FDH, 'Goodbye, world!', 0FFH, 0FDH
XTXT_END LABEL BYTE

frameCount DW 0              ; Variable to store the number of frames

.CODE
MAIN PROC
    MOV AX, @DATA            ; Load data segment into AX
    MOV DS, AX               ; Set DS to point to data segment

    LEA SI, XTXT_DATA        ; Load address of XTXT data into SI
    LEA DI, XTXT_END         ; Load address of end of data into DI

    XOR BX, BX               ; Clear BX to use as the frame counter

SEARCH_LOOP:
    MOV AL, [SI]             ; Load the current byte into AL
    INC SI                   ; Increment SI to point to the next byte

    CMP AL, 0FFH             ; Check if the byte matches the high byte of NFM
    JNE CHECK_END            ; If not, skip to the end check

    MOV AL, [SI]             ; Load the next byte into AL
    INC SI                   ; Increment SI
    CMP AL, 0FDH             ; Check if it matches the low byte of NFM
    JNE CHECK_END            ; If not, skip to the end check

    INC BX                   ; Increment the frame counter

CHECK_END:
    LEA AX, XTXT_END         ; Load the end address into AX
    CMP SI, AX               ; Compare current position with the end
    JB SEARCH_LOOP           ; If not at the end, continue the loop

STORE_RESULT:
    MOV frameCount, BX       ; Store the frame count in memory

EXIT:
    MOV AH, 4CH              ; DOS terminate program function
    INT 21H                  ; Exit to DOS

MAIN ENDP
END MAIN
