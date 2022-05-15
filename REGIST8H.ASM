.model tiny
.code
org 100h

locals @@

INT08H   = 08h
INT09H   = 09h
VIDEOSEG = 0b800h
COLOR    = 4eh
KEYB_PPI = 61h
KEYB_BUF = 60h
SIGN_BIT = 80h

LETTER_A = 'A'
ZERO     = '0'
F1       = 3Bh
F2       = 3Ch

END_OF_STRING = 0

start:
    jmp execute

execute:
;======Now Lets Change Interruption Vectors======

        mov ax, 3500h + INT08H                ; Get Interrupt Vector
        int 21h                               ; of Int08h

        mov word ptr OldInt8,     bx          ; There I Can Save Old Interruption
        mov ax, es                            ; It Will Be Nice When I Want To
        mov word ptr OldInt8 + 2, ax          ; Hide My Interception

        mov dx, offset Hack08                 ; Set Interrupt Vector
        mov ax, 2500h + INT08H                ; on My Own Function (ds:dx)
        int 21h                               ; I Don't Have To Do cli Before This Func


        mov ax, 3500h + INT09H                ; Get Interrupt Vector
        int 21h                               ; of Int09h

        mov word ptr OldInt9,     bx          ; There I Can Save Old Interruption
        mov ax, es                            ; It Will Be Nice When I Want To
        mov word ptr OldInt9 + 2, ax          ; Hide My Interception

        mov dx, offset Hack09                 ; Set Interrupt Vector
        mov ax, 2500h + INT09H                ; on My Own Function (ds:dx)
        int 21h                               ; I Don't Have To Do cli Before This Func


        mov ax, 3100h
        mov dx, offset meow + 0Fh
        shr dx, 4
        int 21h
;================================================

Hack08:
;======It Is Hacked Int08h=======================
        push es di ax
        
        mov ax, VIDEOSEG
        mov es, ax 

        mov di, 00h

        mov ah, COLOR
        mov al, cs:activated

        stosw

        pop ax di es

        cmp cs:activated, 0h
        jz @@exit

        push ax bx cx dx es di ds si
        pushf

        mov bx, ax

        mov ax, offset cs:buff
        mov di, ax
        mov ax, cs
        mov es, ax

        call Itoa16

        mov ax, VIDEOSEG
        mov es, ax   

        mov di, (80 * 10 + 40) * 2          ; 40 symb on 11th line

        mov ax, offset cs:buff
        mov si, ax
        mov ax, cs
        mov ds, ax

        mov ah, COLOR

        mov cx, 4h
        call PrintString

        popf
        pop si ds di es dx cx bx ax

@@exit:
        db 0EAh
OldInt8 dd 000h  
;================================================

;================================================
; Entry:
; ES - destination segment
; DI - destination index
; BX - input integer
; Destr: AX, DX, CX
;================================================
Itoa16 proc

        mov dx, di
        cld
        mov cx, 4h
       
@@proceed:
        mov ax, bx    ; ax = N

        and ax, 0Fh

        cmp ax, 9h
        jbe @@number

        add ax, LETTER_A - ZERO - 0Ah

@@number:
        add al, ZERO

        stosb

        shr bx, 4h
        loop @@proceed

        mov al, END_OF_STRING
        stosb

        mov bx, dx
        sub di, 2

@@reverse:                   ; 
        mov al, es:[di]      ;
        mov dl, es:[bx]      ;
        mov es:[di], dl      ;
        mov es:[bx], al      ; I CAN DO THIS FROM STACK
                             ; BUT IM STUPID ENOUGH
        inc bx               ; NOT TO DO IT AGAIN 
        dec di               ; ..................
                             ; ..................
        cmp bx, di           ; TILT
        jb @@reverse         ; 

        ret

        endp
;================================================

Hack09:
;======Int09h Activates & Deactivates Spying=====
        push ax

        in al, KEYB_BUF              ; Got Scan Code From 60h Port
        
        cmp al, F1                   ; If Pressed F1 activated
        je @@activate

        cmp al, F2                   ; If Pressed F2 unactivated
        jne @@exit_default
        mov byte ptr cs:activated, 00h
        jmp @@exit_intercept

@@activate:
        mov byte ptr cs:activated, 02h

@@exit_intercept:

;======Sending ACK===============================
        in  al, KEYB_PPI             ; Send ACK To
        or  al, SIGN_BIT             ; Keyboard
        out KEYB_PPI, al             
        xor al, SIGN_BIT
        out KEYB_PPI, al
;================================================

;======Sending EOI===============================
        mov al, 20h                  ; Send Signal
        out 20h, al                  ; End Of Interruption
;================================================

        pop ax

        iret

@@exit_default:
        pop ax

        db 0EAh
OldInt9 dd 000h       
;================================================

;================================================
; CX - number of symbols to print
; AH - COLOR
; ES - VIDEOSEG
; DI - start cell in VIDEOSEG
; DS - segment of reading
; SI - index of string
;================================================
PrintString proc
@@out:  lodsb
        stosw        
        loop @@out
        ret
            endp
;================================================

activated db 0          ; 0     if turned off
                        ; other if turned on

buff db 4 dup(0)

REG_AX db 'AX'
REG_BX db 'BX'
REG_CX db 'CX'
REG_DX db 'DX'
REG_DI db 'DI'
REG_SI db 'SI'
REG_SP db 'SP'
REG_BP db 'BP'

meow:
end start
