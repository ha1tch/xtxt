; Z80 Routine to Switch ROM
; Inputs:
;   A - ROM number to page in (0, 1, 2, or 3)
;
; Updates:
;   CURRENT_ROM - memory location holding the currently paged ROM number

; Memory location for CURRENT_ROM
CURRENT_ROM:  DEFW 0

; Port addresses
PORT_7FFD:    EQU 0x7FFD ; Primary paging port
PORT_1FFD:    EQU 0x1FFD ; Extended paging port

; Routine start
SWITCH_ROM:
    LD HL, CURRENT_ROM     ; Point HL to CURRENT_ROM
    LD (HL), A             ; Store the ROM number in CURRENT_ROM

    AND 0x03               ; Ensure A contains only the lowest 2 bits (ROM 0-3)
    LD B, A                ; Save ROM number in B for later

    ; Calculate bit values for 7FFD and 1FFD
    RLC A                  ; Move bit 0 of ROM number to bit 1
    RLC A                  ; Move bit 1 of ROM number to bit 2 (for vertical switching)
    LD C, A                ; Store A in C for PORT_1FFD value

    LD A, B                ; Restore ROM number to A
    RLC A                  ; Move bit 0 of ROM number to bit 4 (for horizontal switching)
    AND 0x10               ; Mask out everything except bit 4
    LD D, A                ; Store A in D for PORT_7FFD value

    ; Write to 1FFD for vertical ROM switching
    LD A, C                ; Load value for 1FFD
    OUT (PORT_1FFD), A     ; Set vertical ROM selection

    ; Write to 7FFD for horizontal ROM switching
    LD A, D                ; Load value for 7FFD
    OUT (PORT_7FFD), A     ; Set horizontal ROM selection

    RET                    ; Return from routine

; Example Usage
;   LD A, 2                ; Select ROM 2
;   CALL SWITCH_ROM
