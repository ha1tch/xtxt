; Atari 800XL Assembly Program to Count Frames in an XTXT File
; Using 6502 CIO (Central Input/Output) calls

    *= $2000          ; Start of program

; Constants
NFM_HIGH    = $FF      ; High byte of the Next Frame Marker (NFM)
NFM_LOW     = $FD      ; Low byte of the Next Frame Marker (NFM)

bufferSize  = 128      ; CIO supports up to 128 bytes per read

; Memory locations
buffer      = $0600    ; Buffer to load .xtxt file
filename    = $0700    ; Filename of the XTXT file (null-terminated)
frameCount  = $0800    ; Variable to store the number of frames

; CIO control block
iocb        = $3400    ; IOCB #0 control block
iocbCom     = iocb + $02 ; Command byte (open, read, close)
iocbFile    = iocb + $08 ; Address of the filename

; Strings
prompt      = 'Total frames: $00'
errorMsg    = 'File error!$00'

; Main program
START:
    LDX #0                ; Clear IOCB #0
    JSR CIO_CLOSE         ; Ensure it is closed

    ; Open the file
    LDA #$03              ; Command: Open for input
    STA iocbCom           ; Set IOCB command
    LDX #<filename        ; Low byte of filename address
    LDY #>filename        ; High byte of filename address
    STX iocbFile          ; Store filename address (low byte)
    STY iocbFile + 1      ; Store filename address (high byte)
    JSR CIO_CALL          ; Call CIO
    BCC READ_LOOP         ; Continue if no error

FILE_ERROR:
    LDX #<errorMsg        ; Low byte of error message
    LDY #>errorMsg        ; High byte of error message
    JSR PRINT_STRING      ; Print the error message
    JMP EXIT_PROGRAM      ; Exit the program

READ_LOOP:
    ; Read the file
    LDA #$07              ; Command: Read
    STA iocbCom           ; Set IOCB command
    LDX #<buffer          ; Low byte of buffer address
    LDY #>buffer          ; High byte of buffer address
    STX iocb + $0C        ; Store buffer address (low byte)
    STY iocb + $0D        ; Store buffer address (high byte)
    LDA #bufferSize       ; Max bytes to read
    STA iocb + $10        ; Set buffer size
    JSR CIO_CALL          ; Call CIO
    BCS EOF_REACHED       ; Branch if end of file
    LDA iocb + $10        ; Get bytes read
    BEQ EOF_REACHED       ; Exit if no bytes read

    ; Process the buffer
    LDX #0                ; Initialize index
PROCESS_BUFFER:
    LDA buffer, X         ; Load byte from buffer
    CMP #NFM_HIGH         ; Compare with high byte of NFM
    BNE SKIP_HIGH

    INX                   ; Increment to next byte
    CPX #bufferSize       ; Check for end of buffer
    BEQ SKIP_HIGH         ; Exit if buffer exhausted (High byte was last byte)

    LDA buffer, X         ; Load next byte
    CMP #NFM_LOW          ; Compare with low byte of NFM
    BNE SKIP_HIGH

    INC frameCount        ; Increment frame count
SKIP_HIGH:
    INX                   ; Increment to next byte
    CPX #bufferSize       ; Check for end of buffer
    BNE PROCESS_BUFFER    ; Repeat loop

    JMP READ_LOOP         ; Read more data

EOF_REACHED:
    ; Print the result
    LDX #<prompt          ; Low byte of prompt address
    LDY #>prompt          ; High byte of prompt address
    JSR PRINT_STRING      ; Print the prompt

    LDA frameCount        ; Load frame count
    JSR PRINT_NUMBER      ; Print the frame count

    ; Close the file and exit
    JSR CIO_CLOSE         ; Close IOCB
    JMP EXIT_PROGRAM

; Subroutine: CIO_CALL
CIO_CALL:
    LDA #0                ; Use IOCB #0
    JSR $E456             ; CIO system call
    RTS

; Subroutine: CIO_CLOSE
CIO_CLOSE:
    LDA #$0C              ; Command: Close
    STA iocbCom           ; Set IOCB command
    JSR CIO_CALL          ; Call CIO
    RTS

; Subroutine: PRINT_STRING
PRINT_STRING:
    LDA #$0F              ; Print string to screen
    JSR $E456             ; SIOV call
    RTS

; Subroutine: PRINT_NUMBER (Basic Implementation)
PRINT_NUMBER:
    PHA ; Save A
    TXA ; Transfer X to A
    PHA ; Save X (Which is used in PRINT_STRING)

    LDA frameCount

    LDX #10

    JSR PRINT_NUM_LOOP

    PLA
    TAX
    PLA
    RTS

PRINT_NUM_LOOP:
    ; Divide by 10, store digit on stack, recurse
    SEC
    LDY #0 ; Remainder

DIV_LOOP:
    CPX #0
    BEQ OUTPUT_LOOP

    
    SBC #1
    INY

    LDA frameCount
    SBC #0

    STA frameCount
    BCC DIV_LOOP
OUTPUT_LOOP:

    ; Push remainder
    TYA
    PHA


    LDA frameCount

    CPX #0
    BEQ OUTPUT_LOOP_END

    JSR PRINT_NUM_LOOP

OUTPUT_LOOP_END:
    PLA
    ORA #$30

    PHA

    LDX #<tmpBuf
    LDY #>tmpBuf
    JSR PRINT_STRING

    PLA
    RTS

tmpBuf: .BYTE $00,$00

EXIT_PROGRAM:
    JMP $E477             ; Exit to DOS

    *= $0700
filename: .BYTE 'D:INPUT.XTX',0 ; Null-terminated filename