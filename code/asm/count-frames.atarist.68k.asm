; Atari ST Assembly Program to Count Frames in an XTXT File

; Constants
NFM_HIGH    EQU $FF     ; High byte of the Next Frame Marker (NFM)
NFM_LOW     EQU $FD     ; Low byte of the Next Frame Marker (NFM)

bufferSize  EQU 1024    ; Buffer size

; GEMDOS function codes
Fopen       EQU $3D     ; Open a file
Fread       EQU $3F     ; Read a file
Fclose      EQU $3E     ; Close a file
Cconws      EQU $09     ; Write string to console
Cconout     EQU $02     ; Write character to console
Pterm0      EQU $4C     ; Terminate program

; Data section
    ORG $4000    ; Start of data segment, must be greater than program memory
buffer:   DS.B   bufferSize      ; Buffer to load .xtxt file
filename: DC.B   'INPUT.XTX',0    ; Filename of the XTXT file (null-terminated)
fileHandle:   DS.W   1       ; File handle for the opened file
bytesRead:   DS.W   1       ; Number of bytes read
frameCount:  DS.W   1       ; Variable to store the number of frames

markerHigh:  DC.B   NFM_HIGH      ; High byte of NFM
markerLow:  DC.B   NFM_LOW      ; Low byte of NFM

prompt:    DC.B   'Total frames: ',0 ; Prompt string (null-terminated)
errorMessage:  DC.B 'File error occurred!',0 ; Error message string

; Code section
    ORG $8000   ; Start of the code section
START:
    CLR.W   frameCount    ; Initialize frame counter

    ; Open the file
    MOVE.L  #filename,A1    ; Load address of filename into A1
    MOVE.W  #0,D0           ; Open in read-only mode
    MOVE.W  #Fopen,D1       ; GEMDOS Open File function
    TRAP    #1              ; TOS system call
    BMI     FILE_ERROR      ; Branch if result is negative (error)
    MOVE.W  D0,fileHandle   ; Store the file handle

READ_LOOP:
    ; Read the file
    MOVE.W  #Fread,D1       ; GEMDOS Read File function
    MOVE.W  fileHandle,D0   ; Load file handle
    MOVE.L  #buffer,A1      ; Load address of buffer
    MOVE.W  #bufferSize,D2  ; Number of bytes to read
    TRAP    #1              ; TOS system call
    BMI     FILE_ERROR      ; Branch if result is negative (error)
    MOVE.W  D0,bytesRead    ; Store the number of bytes read
    BEQ     EOF_REACHED     ; Exit loop if EOF (D0 == 0)

    ; Count frames in the buffer
    MOVE.L  #buffer,A0      ; Load address of buffer into A0
    MOVE.W  bytesRead,D0    ; Load number of bytes read into D0

SEARCH_LOOP:
    CMP.W   #0,D0           ; Check if all bytes have been processed
    BEQ     READ_LOOP       ; If D0 is zero, continue reading

    MOVE.B  (A0)+,D2        ; Load the current byte into D2
    SUB.W   #1,D0           ; Decrement D0 (remaining bytes to process)

    CMP.B   markerHigh,D2   ; Check if the byte matches the high byte of NFM
    BNE     SEARCH_LOOP     ; If not, continue searching

    CMP.W   #0,D0           ; Ensure there is at least one more byte to check
    BEQ     READ_LOOP       ; If D0 is zero, continue reading


    MOVE.B  (A0)+,D2        ; Load the next byte into D2
    SUB.W   #1,D0           ; Decrement D0
    CMP.B   markerLow,D2    ; Check if it matches the low byte of NFM
    BNE     SEARCH_LOOP     ; If not, continue searching

    ADDQ.W  #1,frameCount   ; Increment the frame counter
    BRA     SEARCH_LOOP     ; Continue searching

EOF_REACHED:
    ; Print the result
    MOVE.L  #prompt,A1      ; Load address of the prompt string
    MOVE.W  #Cconws,D1      ; GEMDOS Write string to console function
    TRAP    #1              ; TOS system call

    MOVE.W  frameCount,D0   ; Load the frame count
    JSR     PRINT_NUMBER    ; Call the PRINT_NUMBER subroutine

    ; Close the file
    MOVE.W  #Fclose,D1      ; GEMDOS Close File function
    MOVE.W  fileHandle,D0   ; Load file handle
    TRAP    #1              ; TOS system call

    ; Exit program
    MOVE.W  #Pterm0,D1      ; GEMDOS terminate program function
    TRAP    #1              ; TOS system call

FILE_ERROR:
    ; Handle file errors
    MOVE.L  #errorMessage,A1 ; Load address of error message string
    MOVE.W  #Cconws,D1       ; GEMDOS Write string to console function
    TRAP    #1               ; TOS system call

    MOVE.W  fileHandle,D0   ; Load file handle
    MOVE.W  #Fclose,D1      ; GEMDOS Close File function
    TRAP    #1              ; TOS system call

    MOVE.W  #Pterm0,D1       ; GEMDOS terminate program function
    TRAP    #1               ; Exit to TOS

; Subroutine to print a number
PRINT_NUMBER:
    MOVE.L  SP,-(A7)
    ;MOVE.W  D0,-(A7)         ; Save D0

    CLR.W   D2               ; Clear D2 (digit count)
    MOVE.W  #10,D3           ; Divisor for decimal numbers

DIV_LOOP:
    CLR.W   D1               ; Clear D1 for division
    DIVU.W  D3,D0            ; Divide D0 by 10, remainder in D1
    ;MOVE.W  D1,-(A7)         ; Push remainder onto stack
    ADDQ.W  #1,D2            ; Increment digit count
    TST.W   D0               ; Check if D0 is zero
    BNE     DIV_LOOP         ; Repeat until D0 is zero

PRINT_DIGITS:
    CLR.W   D1
    DIVU.W D3,D0
    ADD.W #$30,D1
    MOVE.W  #Cconout,D1      ; GEMDOS print character function
    TRAP    #1               ; Output to console
    DBRA    D2,PRINT_DIGITS  ; Loop until all digits are printed
    ;MOVE.W  (A7)+,D0         ; Restore D0
    MOVE.L  (A7)+,SP
    RTS

    END START