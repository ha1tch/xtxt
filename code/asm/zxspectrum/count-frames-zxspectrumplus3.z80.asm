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

; Variables for ROM and RAM tracking
CURRENT_ROM:      DB $FF              ; Initialize to an invalid value
CURRENT_RAM:      DB $00              ; Initialize to default RAM bank (Bank 0)

; System variables
PORT_7FFD_COPY:   EQU $5B5C           ; System variable for $7FFD state
PORT_1FFD_COPY:   EQU $5B67           ; System variable for $1FFD state

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
SELECT_RAM_BANK:
    PUSH AF
    LD HL, CURRENT_RAM     ; Load CURRENT_RAM address
    LD B, (HL)             ; Load current RAM from memory
    CP B                   ; Compare with desired RAM
    JR Z, SELECT_RAM_END   ; If already selected, return

    LD (HL), A             ; Update CURRENT_RAM

    ; Preserve ROM bank
    LD HL, CURRENT_ROM     ; Load current ROM bank
    LD B, (HL)             ; Store in B

    ; Prepare $7FFD value
    AND $07                ; Ensure only RAM bits are affected
    OR (B << 4)            ; Combine with current ROM bank
    LD (PORT_7FFD_COPY), A ; Update $7FFD system variable copy
    DI                     ; Disable interrupts
    OUT ($7FFD), A         ; Write to $7FFD
    EI                     ; Enable interrupts

SELECT_RAM_END:
    POP AF
    RET

; Subroutine: Print a null-terminated string (HL points to string)
PRINT_STRING:
    PUSH HL
PRINT_STRING_LOOP:
    LD A, (HL)
    OR A
    JR Z, PRINT_STRING_END
    CALL ROM_PRINT_CHAR
    INC HL
    JR PRINT_STRING_LOOP
PRINT_STRING_END:
    POP HL
    RET

; Subroutine: New Line Routine (prints a new line with ROM switching)
NEW_LINE_ROUTINE:
    CALL ROM_NEW_LINE
    RET

; Start of the program
START:
    ; Initialize memory state
    LD A, $30              ; Default ROM (Editor ROM) with RAM bank 0
    OUT ($7FFD), A
    LD (PORT_7FFD_COPY), A ; Initialize system variable copy
    LD (CURRENT_ROM), A
    LD (CURRENT_RAM), 0

    ; Initialize last byte to 0
    XOR A
    LD (LAST_BYTE), A

    ; Open the file
    LD HL, FILE_NAME       ; Load file name address into HL
    CALL ROM_OPEN_FILE     ; Open the file
    JR NC, FILE_OPENED     ; Jump if successful

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
    LD BC, 512             ; Read 512 bytes at a time (sector size)
    LD A, (FILE_HANDLE)    ; Load the file handle into register A
    CALL ROM_READ_FILE     ; Read the file

    JR C, READ_ERROR
    OR A                   ; Check if end of file reached
    JR Z, FILE_END_CHECK

    ; Frame counting logic (unchanged)
    ; Check for frame markers in FILE_BUFFER and update FRAME_COUNT
    LD DE, 0               ; Offset counter
    LD B, 0                ; Frame counter for this block
SEARCH_LOOP:
    LD HL, FILE_BUFFER
    ADD HL, DE             ; Point to current position in buffer
    LD A, (HL)             ; Load the current byte into A
    INC HL                 ; Increment HL to point to the next byte
    CP NFM_HIGH            ; Compare the byte with the high byte of NFM
    JR NZ, CHECK_LOOP_END
    LD A, (HL)             ; Load the next byte (low byte of NFM)
    CP NFM_LOW             ; Compare with the low byte of NFM
    JR NZ, CHECK_LOOP_END
    INC B                  ; Increment the frame count
CHECK_LOOP_END:
    INC DE                 ; Increment offset
    LD A, D
    CP 2                   ; Check if we've processed 512 bytes (high byte = 2)
    JR NC, BLOCK_DONE
    LD A, E
    CP 0                   ; Check if we've processed 512 bytes (low byte = 0)
    JR NZ, SEARCH_LOOP

BLOCK_DONE:
    ; Save last byte of current block for next iteration
    LD HL, FILE_BUFFER
    LD DE, 511             ; Point to last byte
    ADD HL, DE
    LD A, (HL)
    LD (LAST_BYTE), A

    ; Add current iteration count to total count
    LD A, (FRAME_COUNT)    ; Load total count
    ADD A, B               ; Add current count to total count
    LD (FRAME_COUNT), A    ; Store new total count

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
    CALL ROM_CLOSE_FILE
    RET

READ_ERROR:
    LD HL, READ_ERROR_STRING
    CALL PRINT_STRING
    CALL NEW_LINE_ROUTINE
    RET

; Data strings
FAILED_STRING:      DB "FAILED", 0
READ_ERROR_STRING:  DB "READ ERROR", 0
