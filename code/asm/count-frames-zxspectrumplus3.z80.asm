; Z80 Assembly Program to Count Frames in an XTXT File (ZX Spectrum +3)
;
; Constants and ROM Addresses
NFM_LOW  EQU $FD    ; Low byte of the Next Frame Marker (NFM)
NFM_HIGH EQU $FF    ; High byte of the Next Frame Marker (NFM)

; ROM routines addresses (obtained from +3 ROM disassembly):
ROM_OPEN_FILE  EQU $4528    ; Opens a file from filename string
ROM_CLOSE_FILE EQU $4590    ; Closes a file given filehandle
ROM_READ_FILE  EQU $4557    ; Reads bytes from file to buffer
ROM_PRINT_CHAR EQU $1601   ; Prints a character in register A to the screen
ROM_NEW_LINE   EQU $165C  ; Prints a new line to the screen

; Memory locations
ORG $8000           ; Start of the program in memory for ZX Spectrum

JP START
; Data section
FILE_NAME:        DB "INPUT.XTX", 0    ; Null-terminated filename string
FILE_HANDLE:      DB 0                ; Variable to store file handle
FRAME_COUNT:      DB 0                ; Variable to store the number of frames
FILE_BUFFER:      DS 4096             ; Buffer to read file data

; Variables

; Macro for ROM call (used by subroutines)
ROM_CALL MACRO rom_address
    PUSH IY           ; Save current IY value (ROM state)
    LD IY, $C000      ; Set IY for 3DOS ROM
    CALL rom_address   ; Call the ROM routine
    POP IY            ; Restore IY value
ENDM


; Subroutine: Print a null-terminated string (HL points to string)
PRINT_STRING:
    PUSH HL
    PRINT_STRING_LOOP:
        LD A, (HL)
        OR A
        JR Z, PRINT_STRING_END
        PUSH HL
        ROM_CALL ROM_PRINT_CHAR
        POP HL
        INC HL
        JR PRINT_STRING_LOOP
    PRINT_STRING_END:
    POP HL
    RET

; Subroutine: Calls a 3DOS file handling routine (A: file handle,  rom_address specified by macro)
DOS_FILE_CALL MACRO rom_address
    PUSH AF ; save file handle
    ROM_CALL rom_address ; call specified rom address
    POP AF ; restore file handle
ENDM

; Start of the program
START:
    ; Open the file
    LD HL, FILE_NAME     ; Load file name address into HL
    PUSH HL             ; Put the name address on the stack for ROM to read from
    LD A, 0 ; file handle not needed for open
    DOS_FILE_CALL ROM_OPEN_FILE  ; Open the file
    POP HL              ; Clear the name address from the stack
    
    JR NC, FILE_OPENED ; Jump if the carry flag is not set (success)

    ; Failed to open file
    LD HL, FAILED_STRING : CALL PRINT_STRING
    CALL NEW_LINE_ROUTINE
    RET

FILE_OPENED:
    ; Save the file handle
    LD A, L
    LD (FILE_HANDLE), A

    ; Reset the frame counter
    LD (FRAME_COUNT), 0
    
    ; Loop through the file and count the number of frames
FILE_READ_LOOP:
    ; Read file into memory buffer
    LD HL, FILE_BUFFER
    LD BC, 4096           ; Read 4096 bytes at a time
    LD A, (FILE_HANDLE)  ; Load the file handle into register A
    PUSH AF              ; push the file handle for ROM to read
    DOS_FILE_CALL ROM_READ_FILE ; Read data from the file
    POP AF
    
    LD DE, BC           ; Store the count of bytes read into DE for checking

    ; Check if end of file or error
    OR A                ; A will be zero if the end of file is reached or there was an error
    JR Z, FILE_END_CHECK    ; if we've reached end of file jump to check

    
    ; Initialize frame counter at this scope
    LD B, 0
    LD DE, 0    ; <--- Initialize offset DE counter for SEARCH_LOOP
    ; Start search loop
SEARCH_LOOP:
    LD A, (HL)          ; Load the current byte into A
    INC HL              ; Increment HL to point to the next byte

    CP NFM_HIGH         ; Compare the byte with the high byte of NFM
    JR NZ, CHECK_END    ; If not equal, check for the end

    LD A, (HL)          ; Load the next byte (low byte of NFM)
    INC HL              ; Increment HL
    CP NFM_LOW          ; Compare with the low byte of NFM
    JR NZ, CHECK_END    ; If not equal, check for the end

    INC B               ; Increment the frame count
    
CHECK_END:
    ; Check if we've processed all the bytes we read from file in this iteration
    INC DE ; <--- increment DE
    LD A, D
    OR E
    JR Z, CHECK_LOW_OFFSET ; if high and low byte of DE are both 0 we must be at an offset of 0 or have wrapped around
    ;compare DE against bytes read BC to see if we have read through the whole block of data
    LD A, D
    CP B
    JR NC, SEARCH_LOOP
    LD A, E
    CP C
    JR C, SEARCH_LOOP
    JR FILE_END_OF_BLOCK

CHECK_LOW_OFFSET:
    LD A, E
    CP C
    JR C, SEARCH_LOOP
    
    

FILE_END_OF_BLOCK:
    ; Add current iteration count to total count
    LD A, (FRAME_COUNT)  ; load total count
    ADD A, B             ; add current count to total count
    LD (FRAME_COUNT), A  ; store new total count
    
    ; jump back to read more data
    JR FILE_READ_LOOP

FILE_END_CHECK: ; check for end of file or error
    
    OR A ; Set Zero flag if an error has occurred (in which case A would be 0)
    JR Z, OUTPUT_FRAMES ; if zero flag is set jump to output routine
    
    LD HL, READ_ERROR_STRING : CALL PRINT_STRING
    CALL NEW_LINE_ROUTINE
    RET

OUTPUT_FRAMES:
    ; Display the frame count
    LD HL, FRAME_COUNT
    LD A, (HL)          ; Load frame count into A
    CALL PRINT_NUMBER   ; Convert number to string and print
    
    CALL NEW_LINE_ROUTINE

    ; Close the file
    LD A, (FILE_HANDLE)
    DOS_FILE_CALL ROM_CLOSE_FILE

PROGRAM_END:
    RET

; Subroutine: Print a number
PRINT_NUMBER:
    PUSH HL
    PUSH BC
    PUSH DE
    ; PUSH AF REMOVED
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
    PUSH DE
    ROM_CALL ROM_PRINT_CHAR
    POP DE
    INC DE
    JR PRINT_STRING_LOOP_IN_NUMBER

PRINT_STRING_END_IN_NUMBER:
    ; POP AF REMOVED
    POP DE
    POP BC
    POP HL
    RET
; Subroutine: New Line Routine (prints a new line with ROM switching)
NEW_LINE_ROUTINE:
    ROM_CALL ROM_NEW_LINE
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
        CP B        ; compare it with high byte of divisor
        JR NC, DIV16_NO_SUB     ; if bigger or equal, no subtraction
        
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

STRING_BUFFER:      DS 10 ; Buffer to temporarily hold the string representation of the number
FAILED_STRING: DB "FAILED", 0
READ_ERROR_STRING: DB "READ ERROR", 0