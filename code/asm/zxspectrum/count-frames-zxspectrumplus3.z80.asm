; Z80 Assembly Program to Count Frames in an XTXT File (ZX Spectrum +3)
;
; Updated to include PRINT_NUMBER and handle memory banks effectively
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
STRING_BUFFER:    DS 10               ; Buffer for number conversion

MSG_FRAMES:       DB "FRAMES: ", 0
FAILED_STRING:    DB "FAILED", 0
READ_ERROR_STRING:DB "READ ERROR", 0

; Variables for ROM and RAM tracking
CURRENT_ROM:      DB $FF              ; Initialize to an invalid value
CURRENT_RAM:      DB $00              ; Initialize to default RAM bank (Bank 0)

; System variables
PORT_7FFD_COPY:   EQU $5B5C           ; System variable for $7FFD state
; PORT_1FFD_COPY:   EQU $5B67           ; System variable for $1FFD state

; Subroutine: Selects the ROM bank by writing to the 0x7FFD and 0x1FFD ports
; Input: A = ROM bank to select
; Updates: CURRENT_ROM variable, preserves RAM state
SELECT_ROM_BANK:
    PUSH AF
    LD HL, CURRENT_ROM     ; Load CURRENT_ROM address
    LD B, (HL)             ; Load current ROM from memory
    CP B                   ; Compare with desired ROM
    JR Z, SELECT_ROM_END   ; If already selected, return

    LD (HL), A             ; Update CURRENT_ROM

    ; Preserve RAM bank
    LD HL, CURRENT_RAM     ; Load current RAM bank
    LD B, (HL)             ; Store in B

    ; Prepare $7FFD value
    AND $30                ; Ensure only ROM bits are affected
    OR B                   ; Combine with current RAM bank
    LD (PORT_7FFD_COPY), A ; Update $7FFD system variable copy
    DI                     ; Disable interrupts
    OUT ($7FFD), A         ; Write to $7FFD
    EI                     ; Enable interrupts

SELECT_ROM_END:
    POP AF
    RET

; Subroutine: Selects the RAM bank by writing to the 0x7FFD port
; Input: A = RAM bank to select (0–7)
; Updates: CURRENT_RAM variable, preserves ROM state
;SELECT_RAM_BANK:
;    PUSH AF
;    LD HL, CURRENT_RAM     ; Load CURRENT_RAM address
;    LD B, (HL)             ; Load current RAM from memory
;    CP B                   ; Compare with desired RAM
;    JR Z, SELECT_RAM_END   ; If already selected, return
;
;    LD (HL), A             ; Update CURRENT_RAM
;
;    ; Preserve ROM bank
;    LD HL, CURRENT_ROM     ; Load current ROM bank
;    LD B, (HL)             ; Store in B
;
;    ; Prepare $7FFD value
;    AND $07                ; Ensure only RAM bits are affected
;    RLCA                   ; Shift B left by 4 bits
;RLCA
;RLCA
;RLCA
;OR A                  ; Combine with current ROM bank
;    LD (PORT_7FFD_COPY), A ; Update $7FFD system variable copy
;    DI                     ; Disable interrupts
;    OUT ($7FFD), A         ; Write to $7FFD
;    EI                     ; Enable interrupts
;
;SELECT_RAM_END:
;    POP AF
;    RET

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
    ; Initialize counters
    XOR A
    LD (LAST_BYTE), A
    LD (FRAME_COUNT), A

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

    ; Initialize frame counter for this block
    LD B, 0
    LD DE, 0

    ; Check for frame marker spanning previous block
    LD A, (LAST_BYTE)
    CP NFM_HIGH
    JR NZ, SEARCH_LOOP

    LD A, (FILE_BUFFER)
    CP NFM_LOW
    JR NZ, SEARCH_LOOP

    INC B

SEARCH_LOOP:
    LD HL, FILE_BUFFER
    ADD HL, DE          ; Point to current position in buffer
    
    LD A, (HL)         ; Load the current byte into A
    INC HL             ; Point to next byte
    
    CP NFM_HIGH
    JR NZ, CHECK_LOOP_END

    LD A, (HL)
    CP NFM_LOW
    JR NZ, CHECK_LOOP_END

    ; Found frame marker
    INC B

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

    ; Add current iteration count to total count
    LD A, (FRAME_COUNT)
    ADD A, B
    LD (FRAME_COUNT), A

    JP FILE_READ_LOOP

FILE_END_CHECK:
    ; Print frame count
    LD HL, MSG_FRAMES
    CALL PRINT_STRING
    LD A, (FRAME_COUNT)
    LD L, A
    LD H, 0
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
