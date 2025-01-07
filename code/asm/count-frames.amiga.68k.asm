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
; Amiga DOS requires you to allocate the DOS string with length, and it's allocated on the stack, not the data segment.

; Libs for calls (offsets)
execBase    EQU 4
dosBase     EQU 400

; Offsets for FileHandle structure
fh_File      EQU 4
fh_BufPtr    EQU 8
fh_BufLen    EQU 12

; Offsets for DOS Request Structure
DR_Type      EQU 0
DR_Task      EQU 4
DR_Node      EQU 8
DR_Res1      EQU 12
DR_Res2      EQU 16
DR_Res3      EQU 20
DR_File      EQU 24
DR_Buffer    EQU 28
DR_Length    EQU 32
DR_Position  EQU 36

; Data section
    SECTION data,data_a  ; Amiga uses named sections
    ORG $1000  ; Starting address for data

buffer:   DS.B   bufferSize      ; Buffer to load .xtxt file
filename: DC.B   'INPUT.XTX',0    ; Filename of the XTXT file (null-terminated)
fileHandle:   DS.L   1        ; File handle for the opened file (pointer)
bytesRead:   DS.L   1        ; Number of bytes read (long)
frameCount:  DS.W   1       ; Variable to store the number of frames (word)

markerHigh:  DC.B   NFM_HIGH      ; High byte of NFM
markerLow:  DC.B   NFM_LOW      ; Low byte of NFM

prompt:    DC.B   'Total frames: ',0 ; Prompt string (null-terminated)
errorMessage:  DC.B 'File error occurred!',0 ; Error message string

    SECTION code,code_a  ; Amiga uses named sections
    ORG $2000 ; Start of code section

START:
    MOVE.L A4,A5; move exec library pointer into a general use register
    CLR.W   frameCount    ; Initialize frame counter

    ; Open the file (using direct exec calls)
    LEA     filename(PC),A0  ; Load address of filename into A0
    MOVE.L  #0,D0           ; Open in read-only mode (0)
    MOVE.L   #DO_OPEN,D0    ;Function Number to Open the File
    TRAP    #1              ; call exec
    MOVE.L  D0,fileHandle   ; Store the file handle
    BEQ     FILE_ERROR      ; Branch if result is 0 (error)

READ_LOOP:
    ; Read the file
    MOVE.L  fileHandle,A0   ; Load file handle into A0
	
	; Create a DOS request on the stack
	MOVE.L #40,D0; size of DOS request
	SUB.L D0,SP

	;Fill out the DOS request
	MOVE.L #0,DR_Type(SP)
	MOVE.L #0,DR_Task(SP)
	MOVE.L #0,DR_Node(SP)
	MOVE.L #0,DR_Res1(SP)
	MOVE.L #0,DR_Res2(SP)
	MOVE.L #0,DR_Res3(SP)
	MOVE.L A0,DR_File(SP)
	LEA  buffer(PC),A0
	MOVE.L A0,DR_Buffer(SP)
    MOVE.L #bufferSize,DR_Length(SP)
    MOVE.L #0,DR_Position(SP)

	; Call Read via DoIO
    MOVE.L #DO_READ,D0 ; function number to DO_READ
	LEA SP,A0; address of our request structure
    TRAP #1; DoIO
	MOVE.L SP,A0; get our request from the stack
    MOVE.L DR_Length(A0),D0; get the bytes read
    MOVE.L D0,bytesRead    ; Store number of bytes read
	BEQ EOF_REACHED; If D0 is 0, then we reached the EOF
    BMI FILE_ERROR; if the return was negative, it was a file error.
	; Count frames in the buffer
    LEA     buffer(PC),A0      ; Load address of buffer into A0
    MOVE.L  bytesRead,D0    ; Load number of bytes read into D0
	ADD.L #40,SP; clean up stack used for the DOS request
SEARCH_LOOP:
    CMP.L   #0,D0           ; Check if all bytes have been processed
    BEQ     READ_LOOP       ; If D0 is zero, continue reading

    MOVE.B  (A0)+,D2        ; Load the current byte into D2
    SUB.L   #1,D0           ; Decrement D0 (remaining bytes to process)

    CMP.B   markerHigh,D2   ; Check if the byte matches the high byte of NFM
    BNE     SEARCH_LOOP     ; If not, continue searching

    CMP.L   #1,D0           ; Ensure there is at least one more byte to check
    BEQ     READ_LOOP       ; If D0 is zero, continue reading

    MOVE.B  (A0)+,D2        ; Load the next byte into D2
    SUB.L   #1,D0           ; Decrement D0
    CMP.B   markerLow,D2    ; Check if it matches the low byte of NFM
    BNE     SEARCH_LOOP     ; If not, continue searching

    ADDQ.W  #1,frameCount   ; Increment the frame counter
    BRA     SEARCH_LOOP     ; Continue searching

EOF_REACHED:
    ; Print the result
	; Allocate stack space for the output buffer
	MOVE.L  #6,D0; length 5 + 1 null
	SUB.L D0,SP; Allocate the stack space
    LEA     prompt(PC),A0      ; Load address of the prompt string
    MOVE.L #DO_WRITE,D0 ; function number to write to console
	MOVE.L #0,D1 ; file handle zero = CON:
	MOVE.L A0,0(SP); put pointer to string in first slot
	MOVE.L #16,D0; push the length, which is always 16, as DO_WRITE requires it, this is because it copies it's own length
	MOVE.L D0,4(SP); Put the length in the next slot
	LEA (SP),A0 ; Point to the string output on the stack
    TRAP    #1              ; call exec
	ADD.L  #6,SP; remove allocated stack space.
   
    MOVE.W  frameCount,D0   ; Load the frame count
    JSR     PRINT_NUMBER    ; Call the PRINT_NUMBER subroutine

	; Close the file
	MOVE.L  fileHandle,A0   ; Load file handle
    MOVE.L #DO_CLOSE,D0 ; function number to close the file
    TRAP    #1              ; call exec

    ; Exit program
    MOVE.L  #0,D0 ; exit code 0 = no error
    TRAP #0; terminate process

FILE_ERROR:
    ; Handle file errors
    LEA     errorMessage(PC),A0 ; Load address of error message string
	; Allocate space on the stack to write the string
	MOVE.L  #20,D0; length 20 + 1 null
	SUB.L D0,SP; Allocate the stack space

    MOVE.L #DO_WRITE,D0 ; function number to write to console
	MOVE.L #0,D1 ; file handle zero = CON:
	MOVE.L A0,0(SP); put pointer to string in first slot
	MOVE.L #21,D0; push the length, which is always 21, as DO_WRITE requires it, this is because it copies it's own length
	MOVE.L D0,4(SP); Put the length in the next slot
	LEA (SP),A0 ; Point to the string output on the stack
    TRAP    #1              ; call exec

	ADD.L #20,SP; remove stack

    MOVE.L  #0,D0; exit code 0 = no error
    TRAP #0; terminate process

; Subroutine to print a number
PRINT_NUMBER:
    MOVE.W  D0,-(A7)         ; Save D0

    CLR.W   D2               ; Clear D2 (digit count)
    MOVE.W  #10,D3           ; Divisor for decimal numbers

DIV_LOOP:
    CLR.W   D1               ; Clear D1 for division
    DIVU.W  D3,D0            ; Divide D0 by 10, remainder in D1
    MOVE.W  D1,-(A7)         ; Push remainder onto stack
    ADDQ.W  #1,D2            ; Increment digit count
    TST.W   D0               ; Check if D0 is zero
    BNE     DIV_LOOP         ; Repeat until D0 is zero

PRINT_DIGITS:
    MOVE.W  (A7)+,D1         ; Pop digit from stack
    ADD.B   #'0',D1          ; Convert to ASCII
	
	; Allocate space for the output buffer on the stack
	MOVE.L  #6,D0; length 1
	SUB.L D0,SP; Allocate the stack space
	MOVE.L D1,0(SP); put the character in the string slot.
	MOVE.L #1,4(SP); Put the length in the next slot

	; Output single character to console via DO_WRITE
    MOVE.L #DO_WRITE,D0 ; function number to write to console
    MOVE.L #0,D1 ; file handle zero = CON:
	LEA (SP),A0; pointer to stack
	TRAP #1
    ADD.L #6,SP; remove the stack
    DBRA    D2,PRINT_DIGITS  ; Loop until all digits are printed

    MOVE.W  (A7)+,D0         ; Restore D0
    RTS