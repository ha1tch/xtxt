; Z80 Assembly Program to Count Frames in an XTXT File

; Define constants for XTXT markers
NFM_LOW  EQU $FD    ; Low byte of the Next Frame Marker (NFM)
NFM_HIGH EQU $FF    ; High byte of the Next Frame Marker (NFM)

; Memory locations
ORG $8000           ; Start of the program in memory for ZX Spectrum

JP START
; Data section
XTXT_DATA:          ; Pointer to XTXT data
    DB  'Hello, world!', $FF, $FD, 'Goodbye, world!', $FF, $FD
XTXT_END:           ; End marker for the XTXT data

; Variables
frameCount:         ; Variable to store the number of frames
    DB  0

; Start of the program
START:
    LD HL, XTXT_DATA    ; Load the starting address of the XTXT data into HL
    LD DE, XTXT_END     ; Load the end address of the XTXT data into DE
    LD B, 0             ; Initialize frame count in register B

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
    LD A, L             ; Check if we've reached the end of data
    CP E                ; Compare with the end address low byte
    LD A, H             ; Check the high byte of HL
    SBC A, D            ; Compare with the high byte of DE
    JR NZ, SEARCH_LOOP  ; Loop until the end is reached

; STORE_RESULT:
    LD A, B             ; Load the frame count into A
    LD (frameCount), A  ; Store the frame count in memory
    PUSH AF

    RET


END START
