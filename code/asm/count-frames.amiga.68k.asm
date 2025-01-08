; Commodore Amiga Assembly Program to Count Frames in an XTXT File

; Constants
NFM_HIGH    EQU $FF     ; High byte of the Next Frame Marker (NFM)
NFM_LOW     EQU $FD     ; Low byte of the Next Frame Marker (NFM)

bufferSize  EQU 1024    ; Buffer size

; AmigaDOS function codes (using direct exec calls)
DO_OPEN     EQU -30     ; Open a file (exec.library)
DO_READ     EQU -36     ; Read a file (exec.library)
DO_CLOSE    EQU -42     ; Close a file (exec.library)
DO_WRITE    EQU -48     ; Write to console (exec.library)

; Data section
    SECTION data,data_a
    ORG $1000

buffer:      DS.B  bufferSize      ; Buffer to load .xtxt file
filename:    DC.B  'INPUT.XTX',0   ; Null-terminated filename string
fileHandle:  DS.L  1               ; File handle
bytesRead:   DS.L  1               ; Number of bytes read
frameCount:  DS.W  1               ; Frame count
lastByte:    DS.B  1               ; Last byte of previous buffer

prompt:      DC.B  'Total frames: ',0 ; Prompt string
errorMsg:    DC.B  'File error occurred!',0

; Code section
    SECTION code,code_a
    ORG $2000

START:
    MOVE.L A4,A5                    ; Initialize exec.library pointer
    CLR.W   frameCount              ; Reset frame counter
    CLR.B   lastByte                ; Reset last byte tracker

    ; Open the file
    LEA     filename(PC),A0
    MOVE.L  #0,D0
    MOVE.L  #DO_OPEN,D0
    TRAP    #1
    MOVE.L  D0,fileHandle
    BEQ     FILE_ERROR

READ_LOOP:
    ; Read the file
    MOVE.L  fileHandle,A0
    LEA     buffer(PC),A1
    MOVE.L  #bufferSize,D1
    MOVE.L  #DO_READ,D0
    TRAP    #1
    MOVE.L  D0,bytesRead
    BEQ     EOF_REACHED
    BMI     FILE_ERROR

    ; Process the buffer
    LEA     buffer(PC),A0
    MOVE.L  bytesRead,D0

    ; Check for boundary-spanning marker
    CMP.B   lastByte,NFM_HIGH
    BNE     NORMAL_SEARCH
    CMP.B   (A0),NFM_LOW
    BNE     NORMAL_SEARCH
    ADDQ.W  #1,frameCount

NORMAL_SEARCH:
SEARCH_LOOP:
    CMP.L   #0,D0                   ; Check if all bytes processed
    BEQ     END_BLOCK_PROCESSING

    MOVE.B  (A0)+,D2                ; Load current byte
    SUBQ.L  #1,D0                   ; Decrement remaining bytes

    CMP.B   D2,NFM_HIGH             ; Compare with high marker
    BNE     SEARCH_LOOP

    CMP.L   #0,D0                   ; Check for additional byte
    BEQ     END_BLOCK_PROCESSING

    MOVE.B  (A0)+,D2                ; Load next byte
    SUBQ.L  #1,D0
    CMP.B   D2,NFM_LOW              ; Compare with low marker
    BNE     SEARCH_LOOP

    ADDQ.W  #1,frameCount           ; Increment frame count
    BRA     SEARCH_LOOP

END_BLOCK_PROCESSING:
    ; Save last byte for boundary check
    LEA     buffer(PC),A0
    ADD.L   bytesRead,D0
    SUBQ.L  #1,D0                   ; Point to last byte of buffer
    MOVE.B  (A0,D0),lastByte

    BRA     READ_LOOP

EOF_REACHED:
    ; Output frame count
    LEA     prompt(PC),A0
    MOVE.L  #DO_WRITE,D0
    TRAP    #1

    MOVE.W  frameCount,D0
    JSR     PRINT_NUMBER

    ; Close the file
    MOVE.L  fileHandle,A0
    MOVE.L  #DO_CLOSE,D0
    TRAP    #1

    ; Exit program
    MOVE.L  #0,D0
    TRAP    #0

FILE_ERROR:
    ; Handle errors
    LEA     errorMsg(PC),A0
    MOVE.L  #DO_WRITE,D0
    TRAP    #1

    MOVE.L  #0,D0
    TRAP    #0

; Subroutine to print a number
PRINT_NUMBER:
    ; Implementation unchanged
    RTS
