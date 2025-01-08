; Z80 Assembly Program to Count Frames and Streams in an XTXT File (ZX Spectrum +3)
;
; Constants and ROM Addresses
NFM_LOW  EQU $FD    ; Low byte of the Next Frame Marker (NFM)
NFM_HIGH EQU $FF    ; High byte of the Next Frame Marker (NFM)
NSM_LOW  EQU $FE    ; Low byte of the Next Stream Marker (NSM)
NSM_HIGH EQU $FF    ; High byte of the Next Stream Marker (NSM)

; ROM routines addresses (obtained from +3 ROM disassembly):
ROM_OPEN_FILE  EQU $4528    ; Opens a file from filename string
ROM_CLOSE_FILE EQU $4590    ; Closes a file given filehandle
ROM_READ_FILE  EQU $4557    ; Reads bytes from file to buffer
ROM_PRINT_CHAR EQU $1601    ; Prints a character in register A to the screen
ROM_NEW_LINE   EQU $165C    ; Prints a new line to the screen

; Memory locations
ORG $8000           ; Start of the program in memory for ZX Spectrum

JP START

; Data section
FILE_NAME:        DB "INPUT.XTX", 0    ; Null-terminated filename string
FILE_HANDLE:      DB 0                 ; Variable to store file handle
FRAME_COUNT:      DB 0                 ; Variable to store the number of frames
STREAM_COUNT:     DB 0                 ; Variable to store streams in current frame
TOTAL_STREAMS:    DW 0                 ; Total number of streams across all frames
MAX_STREAMS:      DB 0                 ; Maximum streams in any frame
FILE_BUFFER:      DS 512              ; Buffer to read file data (one disk sector)
LAST_BYTE:        DB 0                ; Store last byte from previous block

MSG_FRAMES:       DB "FRAMES: ", 0
MSG_TOT_STREAMS:  DB "TOTAL STREAMS: ", 0
MSG_MAX_STREAMS:  DB "MAX STREAMS/FRAME: ", 0
MSG_AVG_STREAMS:  DB "AVG STREAMS/FRAME: ", 0

; Subroutine: Selects the ROM bank by writing to the 0x7FFD port
; Input: A = ROM bank to select
SELECT_ROM_BANK:
    LD BC, $7FFD       ; Port for ROM banking
    OUT (C), A         ; Write the bank number to the port
    RET

; Macro for ROM call with explicit ROM bank switching
ROM_CALL MACRO rom_address, bank
    PUSH AF
    LD A, bank
    CALL SELECT_ROM_BANK ; Switch to the required ROM bank
    CALL rom_address     ; Call the ROM routine
    LD A, $00
    CALL SELECT_ROM_BANK ; Restore to BASIC ROM
    POP AF
ENDM

; Subroutine: Print a null-terminated string (HL points to string)
PRINT_STRING:
    PUSH HL
PRINT_STRING_LOOP:
    LD A, (HL)
    OR A
    JR Z, PRINT_STRING_END
    ROM_CALL ROM_PRINT_CHAR, $00 ; BASIC ROM bank
    INC HL
    JR PRINT_STRING_LOOP
PRINT_STRING_END:
    POP HL
    RET

; Subroutine: New Line Routine (prints a new line with ROM switching)
NEW_LINE_ROUTINE:
    ROM_CALL ROM_NEW_LINE, $00 ; BASIC ROM bank
    RET

; Subroutine: Print a number in HL
PRINT_NUMBER:
    PUSH AF
    LD BC, 10       ; Base for decimal conversion
    LD DE, STRING_BUFFER  ; Pointer to the string buffer

NUMBER_LOOP:
    XOR A     ; Clear A to hold remainder
    PUSH BC
    CALL DIV16
    POP BC
    ADD A, '0'   ; Convert remainder to ASCII character
    DEC DE
    LD (DE), A  ; Store the character in the buffer

    LD A, H
    OR L
    JR NZ, NUMBER_LOOP  ; if HL still not zero

    INC DE    ; move pointer to start of string

PRINT_STRING_LOOP_IN_NUMBER:
    LD A, (DE)
    OR A
    JR Z, PRINT_STRING_END_IN_NUMBER
    ROM_CALL ROM_PRINT_CHAR, $00 ; BASIC ROM bank
    INC DE
    JR PRINT_STRING_LOOP_IN_NUMBER

PRINT_STRING_END_IN_NUMBER:
    POP AF
    RET

; Subroutine: 16-bit unsigned division (HL / BC) - Quotient in HL, Remainder in A
DIV16:
    PUSH BC
    PUSH DE
    PUSH HL

    LD DE, 0        ; Initialize DE to 0 (remainder)
DIV16_LOOP:
    LD A, H     ; Get high byte of dividend
    RLA         ; Rotate left into carry
    LD H, A     ; Put the result in H

    LD A, L     ; Get low byte of dividend
    RLA         ; Rotate left into carry
    LD L, A     ; Put the result in L

    RLC E
    RLC D

    LD A, D         ; load high byte of remainder in A
    CP B            ; compare it with high byte of divisor
    JR NC, DIV16_NO_SUB

    LD A, D     ; load high byte of remainder
    SUB B      ; subtract high byte of divisor
    LD D, A     ; store high byte of remainder

    LD A, E      ; load low byte of remainder
    SBC A, C      ; subtract low byte of divisor, accounting for carry
    LD E, A      ; store low byte of remainder
DIV16_NO_SUB:
    LD A, H
    OR L
    JR NZ, DIV16_LOOP

    LD A, E ; Remainder in A
    POP HL
    POP DE
    POP BC
    RET

; Start of the program
START:
    ; Initialize counters and storage
    XOR A
    LD (LAST_BYTE), A
    LD (FRAME_COUNT), A
    LD (STREAM_COUNT), A
    LD (MAX_STREAMS), A
    LD HL, 0
    LD (TOTAL_STREAMS), HL

    ; Open the file
    LD HL, FILE_NAME     
    ROM_CALL ROM_OPEN_FILE, $01
    JR NC, FILE_OPENED   

    ; Failed to open file
    LD HL, FAILED_STRING
    CALL PRINT_STRING
    CALL NEW_LINE_ROUTINE
    RET

FILE_OPENED:
    ; Save the file handle
    LD A, L
    LD (FILE_HANDLE), A

FILE_READ_LOOP:
    ; Read file into memory buffer
    LD HL, FILE_BUFFER
    LD BC, 512           
    LD A, (FILE_HANDLE)  
    ROM_CALL ROM_READ_FILE, $01

    JP C, READ_ERROR
    OR A                
    JP Z, FILE_END_CHECK

    ; Initialize counters for this block
    LD B, 0              ; Frame counter for this block
    LD C, 0              ; Stream counter for current frame
    LD DE, 0             ; Offset counter

    ; Check for markers spanning previous block
    LD A, (LAST_BYTE)
    CP NFM_HIGH
    JR NZ, CHECK_STREAM_SPAN
    
    LD A, (FILE_BUFFER)  
    CP NFM_LOW
    JR NZ, CHECK_STREAM_SPAN
    
    ; Found frame marker spanning blocks
    INC B               
    CALL UPDATE_STREAM_STATS
    XOR A
    LD (STREAM_COUNT), A

CHECK_STREAM_SPAN:
    LD A, (LAST_BYTE)
    CP NSM_HIGH
    JR NZ, SEARCH_LOOP
    
    LD A, (FILE_BUFFER)
    CP NSM_LOW
    JR NZ, SEARCH_LOOP
    
    ; Found stream marker spanning blocks
    LD A, (STREAM_COUNT)
    INC A
    LD (STREAM_COUNT), A

SEARCH_LOOP:
    LD HL, FILE_BUFFER
    ADD HL, DE          ; Point to current position in buffer
    
    LD A, (HL)         ; Load the current byte into A
    INC HL             ; Point to next byte
    
    CP NFM_HIGH
    JR NZ, CHECK_STREAM
    
    LD A, (HL)
    CP NFM_LOW
    JR NZ, CHECK_LOOP_END
    
    ; Found frame marker
    INC B
    CALL UPDATE_STREAM_STATS
    XOR A
    LD (STREAM_COUNT), A
    JR CHECK_LOOP_END

CHECK_STREAM:
    CP NSM_HIGH
    JR NZ, CHECK_LOOP_END
    
    LD A, (HL)
    CP NSM_LOW
    JR NZ, CHECK_LOOP_END
    
    ; Found stream marker
    LD A, (STREAM_COUNT)
    INC A
    LD (STREAM_COUNT), A

CHECK_LOOP_END:
    INC DE
    LD A, D
    CP 2               ; Check if we've processed 512 bytes (high byte = 2)
    JR NC, BLOCK_DONE
    
    LD A, E
    CP 0               ; Check if we've processed 512 bytes (low byte = 0)
    JR NZ, SEARCH_LOOP

BLOCK_DONE:
    ; Save last byte of current block
    LD HL, FILE_BUFFER
    LD DE, 511        
    ADD HL, DE
    LD A, (HL)
    LD (LAST_BYTE), A

    ; Update frame count
    LD A, (FRAME_COUNT)
    ADD A, B
    LD (FRAME_COUNT), A

    JP FILE_READ_LOOP

; Update stream statistics
; Preserves: B, DE
UPDATE_STREAM_STATS:
    PUSH BC
    PUSH DE
    
    ; Update total streams
    LD A, (STREAM_COUNT)
    LD C, A
    LD B, 0
    LD HL, (TOTAL_STREAMS)
    ADD HL, BC
    LD (TOTAL_STREAMS), HL
    
    ; Update max streams if needed
    LD A, (MAX_STREAMS)
    CP C
    JR NC, UPDATE_DONE
    LD A, C
    LD (MAX_STREAMS), A
    
UPDATE_DONE:
    POP DE
    POP BC
    RET

FILE_END_CHECK:
    ; Print frame count
    LD HL, MSG_FRAMES
    CALL PRINT_STRING
    LD A, (FRAME_COUNT)
    LD L, A
    LD H, 0
    CALL PRINT_NUMBER
    CALL NEW_LINE_ROUTINE

    ; Print total streams
    LD HL, MSG_TOT_STREAMS
    CALL PRINT_STRING
    LD HL, (TOTAL_STREAMS)
    CALL PRINT_NUMBER
    CALL NEW_LINE_ROUTINE

    ; Print max streams per frame
    LD HL, MSG_MAX_STREAMS
    CALL PRINT_STRING
    LD A, (MAX_STREAMS)
    LD L, A
    LD H, 0
    CALL PRINT_NUMBER
    CALL NEW_LINE_ROUTINE

    ; Calculate and print average streams per frame
    LD HL, MSG_AVG_STREAMS
    CALL PRINT_STRING
    LD HL, (TOTAL_STREAMS)
    LD A, (FRAME_COUNT)
    LD C, A
    LD B, 0
    CALL DIV16
    CALL PRINT_NUMBER
    CALL NEW_LINE_ROUTINE

    ; Close the file
    LD A, (FILE_HANDLE)
    ROM_CALL ROM_CLOSE_FILE, $01
    RET

READ_ERROR:
    LD HL, READ_ERROR_STRING
    CALL PRINT_STRING
    CALL NEW_LINE_ROUTINE
    RET

; Data strings
STRING_BUFFER:      DS 10  ; Buffer for number conversion
FAILED_STRING:      DB "FAILED", 0
READ_ERROR_STRING:  DB "READ ERROR", 0
