; Z80 Assembly Program to Count Frames in an XTXT File (ZX Spectrum +3)
;
; Constants and ROM Addresses
NFM_LOW  EQU $FD    ; Low byte of the Next Frame Marker (NFM)
NFM_HIGH EQU $FF    ; High byte of the Next Frame Marker (NFM)

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
FILE_BUFFER:      DS 512              ; Buffer to read file data (one disk sector)
LAST_BYTE:        DB 0                ; Store last byte from previous block

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

; Subroutine: Print a number
PRINT_NUMBER:
    PUSH AF
    LD BC, 10       ; Base for decimal conversion
    LD DE, STRING_BUFFER  ; Pointer to the string buffer

NUMBER_LOOP:
    XOR A     ; Clear A to hold remainder
    PUSH BC
    ; divides HL by BC, remainder in A, quotient in HL
    CALL DIV16
    POP BC
    ADD A, '0'   ; Convert remainder to ASCII character
    DEC DE
    LD (DE), A  ; Store the character in the buffer

    LD A, H
    OR L
    JR NZ, NUMBER_LOOP  ; if HL still not zero

    INC DE    ; move pointer to start of string

; Print the string
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
    ; Initialize last byte to 0
    XOR A
    LD (LAST_BYTE), A

    ; Open the file
    LD HL, FILE_NAME     ; Load file name address into HL
    ROM_CALL ROM_OPEN_FILE, $01 ; 3DOS ROM bank
    JR NC, FILE_OPENED   ; Jump if the carry flag is not set (success)

    ; Failed to open file
    LD HL, FAILED_STRING
    CALL PRINT_STRING
    CALL NEW_LINE_ROUTINE
    RET

FILE_OPENED:
    ; Save the file handle
    LD A, L
    LD (FILE_HANDLE), A

    ; Reset the frame counter
    XOR A
    LD (FRAME_COUNT), A

    ; Loop through the file and count the number of frames
FILE_READ_LOOP:
    ; Read file into memory buffer
    LD HL, FILE_BUFFER
    LD BC, 512            ; Read 512 bytes at a time (sector size)
    LD A, (FILE_HANDLE)   ; Load the file handle into register A
    ROM_CALL ROM_READ_FILE, $01 ; 3DOS ROM bank

    JR C, READ_ERROR
    OR A                  ; A will be zero if the end of file is reached
    JR Z, FILE_END_CHECK

    ; Initialize frame counter and offset at this scope
    LD B, 0              ; Frame counter for this block
    LD DE, 0             ; Offset counter

    ; Check for frame marker spanning previous block
    LD A, (LAST_BYTE)
    CP NFM_HIGH
    JR NZ, SEARCH_LOOP
    
    LD A, (FILE_BUFFER)  ; Load first byte of new block
    CP NFM_LOW
    JR NZ, SEARCH_LOOP
    
    INC B               ; Found a frame marker spanning blocks

SEARCH_LOOP:
    LD HL, FILE_BUFFER
    ADD HL, DE          ; Point to current position in buffer
    
    LD A, (HL)         ; Load the current byte into A
    INC HL             ; Increment HL to point to the next byte
    CP NFM_HIGH        ; Compare the byte with the high byte of NFM
    JR NZ, CHECK_LOOP_END

    LD A, (HL)         ; Load the next byte (low byte of NFM)
    CP NFM_LOW         ; Compare with the low byte of NFM
    JR NZ, CHECK_LOOP_END

    INC B              ; Increment the frame count

CHECK_LOOP_END:
    INC DE
    LD A, D
    CP 2               ; Check if we've processed 512 bytes (high byte = 2)
    JR NC, BLOCK_DONE
    
    LD A, E
    CP 0               ; Check if we've processed 512 bytes (low byte = 0)
    JR NZ, SEARCH_LOOP

BLOCK_DONE:
    ; Save last byte of current block for next iteration
    LD HL, FILE_BUFFER
    LD DE, 511         ; Point to last byte
    ADD HL, DE
    LD A, (HL)
    LD (LAST_BYTE), A

    ; Add current iteration count to total count
    LD A, (FRAME_COUNT)  ; load total count
    ADD A, B             ; add current count to total count
    LD (FRAME_COUNT), A  ; store new total count

    ; Jump back to read more data
    JP FILE_READ_LOOP

FILE_END_CHECK:
    ; Output the frame count
    LD A, (FRAME_COUNT)
    LD L, A
    LD H, 0
    CALL PRINT_NUMBER

    CALL NEW_LINE_ROUTINE

    ; Close the file
    LD A, (FILE_HANDLE)
    ROM_CALL ROM_CLOSE_FILE, $01 ; 3DOS ROM bank
    RET

READ_ERROR:
    LD HL, READ_ERROR_STRING
    CALL PRINT_STRING
    CALL NEW_LINE_ROUTINE
    RET

; Data strings
STRING_BUFFER:      DS 10  ; Buffer to temporarily hold the string representation of the number
FAILED_STRING:      DB "FAILED", 0
READ_ERROR_STRING:  DB "READ ERROR", 0