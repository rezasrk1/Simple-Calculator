.MODEL SMALL
  
org 100h 

.STACK 100H
 

PUTC    MACRO   char
        PUSH    AX
        MOV     AL, char     ;new line
        MOV     AH, 0Eh
        INT     10h     
        POP     AX
ENDM

jmp start


; define variables:

msg0 db "note: calculator works with integer values only.",0Dh,0Ah,'$'
msg1 db 0Dh,0Ah, 0Dh,0Ah, 'enter first number: $'
msg2 db "enter the operator:    +  -  *  /  ^  ! %  p r  : $"

msg3 db "enter second number: $"
msg4 db  0dh,0ah , 'the approximate result of my calculations is : $' 
msg5 db  0dh,0ah ,'thank you for using the calculator! press any key... ', 0Dh,0Ah, '$'
err1 db  "wrong operator!", 0Dh,0Ah , '$'
smth db  " and something.... $"
msg8 db  " and something.... $"           
err_divide_by_zero db  " and something yee.err_divide_by_zero... $"  
permutation_array dw 10 dup(?)

; operator can be: '+','-','*','/' or 'q' to exit in the middle.
opr db '?'

; first and second number:
num1 dw ?
num2 dw ?


start:
;mov dx, offset msg0  

lea dx, msg0
mov ah, 9
int 21h


lea dx, msg1
mov ah, 09h    ; output string at ds:dx
int 21h  


call scan_num

; store first number:
mov num1, cx 



; new line:
putc 0Dh
putc 0Ah




lea dx, msg2
mov ah, 09h     ; output string at ds:dx
int 21h  


; get operator:
mov ah, 1   ; single char input to AL.
int 21h
mov opr, al



; new line:
putc 0Dh
putc 0Ah


cmp opr, 'q'      ; q - exit in the middle.
je exit



cmp opr, '!'
jb wrong_opr
je factorial     

cmp opr, 'p'
je do_permutation

lea dx, msg3
mov ah, 09h
int 21h  


call scan_num


; store second number:
mov num2, cx 




lea dx, msg4
mov ah, 09h      ; output string at ds:dx
int 21h  




cmp opr, '/'
je do_div


 
cmp opr, '!'
je factorial

cmp opr, 'q'
je exit

wrong_opr:
lea dx, err1
mov ah, 09h
int 21h


exit:
; output of a string at ds:dx
lea dx, msg5
mov ah, 09h
int 21h  


; wait for any key...
mov ah, 0
int 16h


ret  ; return back to os.

factorial:
lea dx, msg8
mov ah, 09h
int 21h

mov ax, num1  ; copy the number to ax for multiplication
mov bx, ax    ; copy the number to bx for the loop counter
dec bx        ; decrement bx as we don't want to multiply the number by itself in the first iteration

fact_loop:
mul bx        ; multiply ax with bx, result is in ax (as num1 is small we don't need to worry about dx)
dec bx        ; decrement the counter
cmp bx, 0     ; compare bx with 0
jne fact_loop ; if bx is not 0, keep looping

; at this point, ax contains the factorial of num1
call print_num ; print ax value.

ret  ; return to the main calculation loop



do_permutation:
    ; Prompt for both numbers
    lea dx, msg1
    mov ah, 09h
    int 21h

    call scan_num
    mov num1, cx

    putc 0Dh
    putc 0Ah

    lea dx, msg3
    mov ah, 09h
    int 21h

    call scan_num
    mov num2, cx

    ; Print msg8 before performing the permutation calculation
    lea dx, msg8
    mov ah, 09h
    int 21h

    ; Perform the permutation calculation
    ; Initialize variables
    mov ax, num1   ; Number of elements (n)
    mov bx, num2   ; Size of each permutation (k)

    ; Calculate n! (factorial of num1)
    mov dx, 1       ; Initialize the factorial value
    mov cx, ax      ; Copy of num1 to use as loop counter
factorial_loop:
    mul cx          ; Multiply dx:ax by cx
    dec cx          ; Decrement cx
    jnz factorial_loop  ; Loop until cx becomes zero

    ; Calculate (n-k)!
    sub ax, bx      ; Calculate (n-k)
    mov cx, ax      ; Copy of (n-k) to use as loop counter
    mov di, 1       ; Initialize the factorial value
factorial_loop2:
    mul cx          ; Multiply di:ax by cx
    dec cx          ; Decrement cx
    jnz factorial_loop2 ; Loop until cx becomes zero

    ; Divide n! by (n-k)! to get the result
    div di          ; Divide dx:ax by di
    ; Now, ax contains the result, which is the number of permutations

    ; Print a newline character before printing the result
    putc 0Dh
    putc 0Ah

    ; Print the result
    call print_num  ; Print the calculated permutation count

    ret




























do_div:
; dx is ignored (calc works with tiny integer numbers only).
mov dx, 0
mov ax, num1
idiv num2  ; ax = (dx ax) / num2.
cmp dx, 0
jnz approx
call print_num    ; print ax value.
jmp exit
approx:
call print_num    ; print ax value.
lea dx, smth
mov ah, 09h    ; output string at ds:dx
int 21h  
jmp exit

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; library emu8086.inc ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


; gets the multi-digit SIGNED number from the keyboard,
; and stores the result in CX register:
SCAN_NUM        PROC    NEAR
        PUSH    DX
        PUSH    AX
        PUSH    SI
        
        MOV     CX, 0

        ; reset flag:
        MOV     CS:make_minus, 0

next_digit:

        ; get char from keyboard
        ; into AL:
        MOV     AH, 00h
        INT     16h
        ; and print it:
        MOV     AH, 0Eh
        INT     10h

        ; check for MINUS:
        CMP     AL, '-'
        JE      set_minus

        ; check for ENTER key:
        CMP     AL, 0Dh  ; carriage return?
        JNE     not_cr
        JMP     stop_input
not_cr:


        CMP     AL, 8                   ; 'BACKSPACE' pressed?
        JNE     backspace_checked
        MOV     DX, 0                   ; remove last digit by
        MOV     AX, CX                  ; division:
        DIV     CS:ten                  ; AX = DX:AX / 10 (DX-rem).
        MOV     CX, AX
        PUTC    ' '                     ; clear position.
        PUTC    8                       ; backspace again.
        JMP     next_digit
backspace_checked:


        ; allow only digits:
        CMP     AL, '0'
        JAE     ok_AE_0
        JMP     remove_not_digit
ok_AE_0:        
        CMP     AL, '9'
        JBE     ok_digit
remove_not_digit:       
        PUTC    8       ; backspace.
        PUTC    ' '     ; clear last entered not digit.
        PUTC    8       ; backspace again.        
        JMP     next_digit ; wait for next input.       
ok_digit:


        ; multiply CX by 10 (first time the result is zero)
        PUSH    AX
        MOV     AX, CX
        MUL     CS:ten                  ; DX:AX = AX*10
        MOV     CX, AX
        POP     AX

        ; check if the number is too big
        ; (result should be 16 bits)
        CMP     DX, 0
        JNE     too_big

        ; convert from ASCII code:
        SUB     AL, 30h

        ; add AL to CX:
        MOV     AH, 0
        MOV     DX, CX      ; backup, in case the result will be too big.
        ADD     CX, AX
        JC      too_big2    ; jump if the number is too big.

        JMP     next_digit

set_minus:
        MOV     CS:make_minus, 1
        JMP     next_digit

too_big2:
        MOV     CX, DX      ; restore the backuped value before add.
        MOV     DX, 0       ; DX was zero before backup!
too_big:
        MOV     AX, CX
        DIV     CS:ten  ; reverse last DX:AX = AX*10, make AX = DX:AX / 10
        MOV     CX, AX
        PUTC    8       ; backspace.
        PUTC    ' '     ; clear last entered digit.
        PUTC    8       ; backspace again.        
        JMP     next_digit ; wait for Enter/Backspace.
        
        
stop_input:
        ; check flag:
        CMP     CS:make_minus, 0
        JE      not_minus
        NEG     CX
not_minus:

        POP     SI
        POP     AX
        POP     DX
        RET




make_minus      DB      ?       ; used as a flag.
SCAN_NUM        ENDP





; this procedure prints number in AX,
; used with PRINT_NUM_UNS to print signed numbers:
PRINT_NUM       PROC    NEAR
        PUSH    DX
        PUSH    AX

        CMP     AX, 0
        JNZ     not_zero

        PUTC    '0'
        JMP     printed

not_zero:
        ; the check SIGN of AX,
        ; make absolute if it's negative:
        CMP     AX, 0
        JNS     positive
        NEG     AX

        PUTC    '-'

positive:
        CALL    PRINT_NUM_UNS
printed:
        POP     AX
        POP     DX
        RET
PRINT_NUM       ENDP



; this procedure prints out an unsigned
; number in AX (not just a single digit)
; allowed values are from 0 to 65535 (FFFF)
PRINT_NUM_UNS   PROC    NEAR
        PUSH    AX
        PUSH    BX
        PUSH    CX
        PUSH    DX

        ; flag to prevent printing zeros before number:
        MOV     CX, 1

        ; (result of "/ 10000" is always less or equal to 9).
        MOV     BX, 10000       ; 2710h - divider.

        ; AX is zero?
        CMP     AX, 0
        JZ      print_zero

begin_print:

        ; check divider (if zero go to end_print):
        CMP     BX,0
        JZ      end_print

        ; avoid printing zeros before number:
        CMP     CX, 0
        JE      calc
        ; if AX<BX then result of DIV will be zero:
        CMP     AX, BX
        JB      skip
calc:
        MOV     CX, 0   ; set flag.

        MOV     DX, 0
        DIV     BX      ; AX = DX:AX / BX   (DX=remainder).

        ; print last digit
        ; AH is always ZERO, so it's ignored
        ADD     AL, 30h    ; convert to ASCII code.
        PUTC    AL


        MOV     AX, DX  ; get remainder from last div.

skip:
        ; calculate BX=BX/10
        PUSH    AX
        MOV     DX, 0
        MOV     AX, BX
        DIV     CS:ten  ; AX = DX:AX / 10   (DX=remainder).
        MOV     BX, AX
        POP     AX

        JMP     begin_print
        
print_zero:
        PUTC    '0'
        
end_print:

        POP     DX
        POP     CX
        POP     BX
        POP     AX
        RET
PRINT_NUM_UNS   ENDP



ten             DW      10      ; used as multiplier/divider by SCAN_NUM & PRINT_NUM_UNS.







GET_STRING      PROC    NEAR
PUSH    AX
PUSH    CX
PUSH    DI
PUSH    DX

MOV     CX, 0                   ; char counter.

CMP     DX, 1                   ; buffer too small?
JBE     empty_buffer            ;

DEC     DX                      ; reserve space for last zero.


;============================
; Eternal loop to get
; and processes key presses:

wait_for_key:

MOV     AH, 0                   ; get pressed key.
INT     16h

CMP     AL, 0Dh                  ; 'RETURN' pressed?
JZ      exit_GET_STRING


CMP     AL, 8                   ; 'BACKSPACE' pressed?
JNE     add_to_buffer
JCXZ    wait_for_key            ; nothing to remove!
DEC     CX
DEC     DI
PUTC    8                       ; backspace.
PUTC    ' '                     ; clear position.
PUTC    8                       ; backspace again.
JMP     wait_for_key

add_to_buffer:

        CMP     CX, DX          ; buffer is full?
        JAE     wait_for_key    ; if so wait for 'BACKSPACE' or 'RETURN'...

        MOV     [DI], AL
        INC     DI
        INC     CX
        
        ; print the key:
        MOV     AH, 0Eh
        INT     10h

JMP     wait_for_key
;============================

exit_GET_STRING:

; terminate by null:
MOV     [DI], 0

empty_buffer:

POP     DX
POP     DI
POP     CX
POP     AX
RET
GET_STRING ENDP

;just add here permutation term
