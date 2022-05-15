.model tiny
.code
org 100h

.386

locals @@

INT08H        = 08h
INT09H        = 09h
VIDEOSEG      = 0b800h
COLOR         = 4eh
KEYB_PPI      = 61h
KEYB_BUF      = 60h
SIGN_BIT      = 80h

LETTER_A      = 'A'
ZERO          = '0'
F2            = 3Ch
F1            = 3Bh

TABLELEN      = 11d
TABLEHEIGHT   = 12d
X_START       = 80d - TABLELEN
Y_START       = 1d

DIFFERENCE    = (80d - TABLELEN) * 2
VIDEOSEG_SIZE = 80d * 25d * 2d

VIDEOSEG_0    = (Y_START * 80d + X_START) * 2d
VIDEOSEG_1    = VIDEOSEG_0 + VIDEOSEG_SIZE
VIDEOSEG_2    = VIDEOSEG_1 + VIDEOSEG_SIZE

END_OF_STRING = 0

.skip  macro
       add di, 160d - TABLELEN * 2
       sub si, 3
       endm

start:

        jmp execute

execute:
;======Now Lets Change Interruption Vectors======

        mov ax, 3500h or INT08H                ; Get Interrupt Vector
        int 21h                               ; of Int08h

        mov word ptr OldInt8,     bx          ; There I Can Save Old Interruption
        mov ax, es                            ; It Will Be Nice When I Want To
        mov word ptr OldInt8 + 2, ax          ; Hide My Interception

        mov dx, offset Hack08                 ; Set Interrupt Vector
        mov ax, 2500h or INT08H                ; on My Own Function (ds:dx)
        int 21h                               ; I Don't Have To Do cli Before This Func


        mov ax, 3500h or INT09H                ; Get Interrupt Vector
        int 21h                               ; of Int09h

        mov word ptr OldInt9,     bx          ; There I Can Save Old Interruption
        mov ax, es                            ; It Will Be Nice When I Want To
        mov word ptr OldInt9 + 2, ax          ; Hide My Interception

        mov dx, offset Hack09                 ; Set Interrupt Vector
        mov ax, 2500h or INT09H                ; on My Own Function (ds:dx)
        int 21h                               ; I Don't Have To Do cli Before This Func


        mov ax, 3100h                         ; Terminate
        mov dx, offset meow + 0Fh             ; &
        shr dx, 4                             ; Stay Resident
        int 21h
;================================================

Hack08:
;======It Is Hacked Int08h=======================

;======Checking Mode in top left corner==========
 ;        push es di ax
        
 ;        mov ax, VIDEOSEG
 ;        mov es, ax 
 
 ;        mov di, 00h

 ;        mov ah, COLOR
 ;        mov al, cs:activated

 ;        stosw

 ;        pop ax di es
;================================================

        cmp cs:activated, 0h
        jz @@exit

;======Saving Registers==========================
        push di es si ds dx cx bx ax
        pushf
;================================================

;======Saving Registers to Print=================
        push di es si ds dx cx bx ax
;================================================

;======Here I have to save changes===============
        call GetChanges
;================================================

;======Here I have to Draw Frame with Registers==
        mov ax, cs
        mov ds, ax

        mov si, offset cs:SYMBOLS

        mov dh, COLOR

        mov bl, Y_START
        mov bh, X_START

        mov ax, VIDEOSEG
        mov es, ax

        call DrawFrame
;================================================

;======Here I have to Save Frame==================
        mov  si, VIDEOSEG_0
        mov  di, VIDEOSEG_2

        call SaveArea
;================================================

;======Recovering Registers======================
        popf
        pop  ax bx cx dx ds si es di
;================================================

@@exit:
        db 0EAh
OldInt8 dd 000h  
;================================================

Hack09:
        push ax

;======Int09h Activates & Deactivates Spying=====
        in al, KEYB_BUF              ; Got Scan Code From 60h Port
        
        cmp al, F1                   ; If Pressed F1 activated
        je @@activate

        cmp al, F2                   ; If Pressed F2 unactivated
        jne @@exit_default

@@unactivate:

        cmp cs:activated, 00h
        je @@exit_intercept

        mov byte ptr cs:activated, 00h

;======Here I have to recover area===============
        push cx es di si
        pushf

        mov  ax, VIDEOSEG
        mov  es, ax

        mov  si, VIDEOSEG_1
        mov  di, VIDEOSEG_0

        call SaveArea

        popf
        pop  si di es cx
;================================================

        jmp @@exit_intercept

@@activate:

        cmp cs:activated, 02d
        je @@exit_intercept

        pop ax
        push ax

;======Saving Registers==========================
        push di es si ds dx cx bx ax
        pushf
;================================================

;======Saving Registers To Print=================
        push di es si ds dx cx bx ax
;================================================

;======Here I have to Save Area==================
        mov  ax, VIDEOSEG
        mov  es, ax

        mov  si, VIDEOSEG_0
        mov  di, VIDEOSEG_1

        call SaveArea
;================================================

;======Here I have to Draw Frame with Regs=======
        mov ax, cs
        mov ds, ax

        mov si, offset cs:SYMBOLS
        mov dh, COLOR
        
        mov bl, Y_START
        mov bh, X_START

        call DrawFrame
;================================================

;======Here I want to Save Copy of Frame=========
        mov  si, VIDEOSEG_0
        mov  di, VIDEOSEG_2

        call SaveArea
;================================================

;======Recovering Registers======================
        popf
        pop  ax bx cx dx ds si es di
;================================================

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
; ES - VIDEOSEG
; macro TABLELEN    = length
; macro TABLEHEIGHT = height
; SI - index of original
; DI - index of destination
; Destr: CX, AX
;================================================
SaveArea proc

        mov cx, TABLEHEIGHT

@@save_area:
        xchg cx, ax

        mov cx, TABLELEN

@@save_line:
        movs word ptr es:[di], es:[si]
        loop @@save_line

        add di, DIFFERENCE
        add si, DIFFERENCE

        xchg cx, ax
        loop @@save_area

@@ret:
        ret
         endp
;================================================

;================================================
; Destr:
; DS, SI, ES, DI, AX, CX
;================================================
GetChanges proc

        mov ax, VIDEOSEG
        mov es, ax
        mov ds, ax

        mov si, VIDEOSEG_0 
        mov di, VIDEOSEG_2

        mov cx, TABLEHEIGHT

@@check_table:

        xchg cx, dx

        mov cx, TABLELEN

@@check_line:
        cmpsw
        je @@next_symbol

        mov ax, es:[si-2]
        mov es:[si-2+VIDEOSEG_1-VIDEOSEG_0], ax

@@next_symbol:
        loop @@check_line

        add si, DIFFERENCE
        add di, DIFFERENCE

        xchg cx, dx
        loop @@check_table

@@ret:
        ret
           endp
;================================================

;================================================
; Entry:
; DS - current segment
; SI - index of 9 symbol string TL corner, TM elem, TR corner
;                               ML   elem, MM elem, MR   elem
;                               BL corner, BM elem, BR corner
; macro TABLELEN    = length
; macro TABLEHEIGHT = height
; DH - symbol attribute
; BL - number of first line   (numeration from 0)
; BH - number of first symbol (numeration from 0)
; ES - VIDEOSEG (0b800h)
; Stack:
;                                                   AX 1234
; ELEMS from TOP: ax bx cx dx ds si es di           ^
; That would be printed in that format ------------ ^
; Destr: DI, CX, AX, DX
;================================================
DrawFrame proc

        call DrawTable

        mov di, VIDEOSEG_0 + (2 * 80d + 2) * 2

        push di

        mov ax, cs
        mov ds, ax

        mov si, offset cs:REGS
        mov ah, COLOR

        mov cx, 8h
@@printing_names:
        xchg cx, dx

        mov  cx, 2h
        call PrintString
        add  di, (80d - 2d) * 2d

        xchg cx, dx
        loop @@printing_names

@@numbers:
        pop  di
        add  di, 3d * 2

        mov cx, 8h
@@printing_numbers:
        xchg cx, dx

        pop  ax            ; return code
        pop  bx            ; number to print
        push ax            ; return code

        push di

        mov si, cs         ; for now I have to
        mov es, si         ; print it in buff
        
        mov di, offset cs:buff

        call Itoa16     

        mov si, cs
        mov ds, si

        mov si, VIDEOSEG
        mov es, si

        mov si, offset cs:buff

        pop di

        mov ah, COLOR

        mov cx, 4h
        call PrintString

        add  di, (80d - 4d) * 2d
        
        xchg cx, dx
        loop @@printing_numbers

          endp
;================================================


;================================================
; Entry:
; DS - current segment
; SI - index of 9 symbol string TL corner, TM elem, TR corner
;                               ML   elem, MM elem, MR   elem
;                               BL corner, BM elem, BR corner
; macro TABLELEN    = length
; macro TABLEHEIGHT = height
; DH - symbol attribute
; BL - number of first line   (numeration from 0)
; BH - number of first symbol (numeration from 0)
; ES - VIDEOSEG (0b800h)
; Destr: DI, CX, AX, DX
;================================================
DrawTable proc
       
        mov al, bl
        mov ah, 0h
        mov cx, 50h
        mov bl, dh        ; saving DH from mul
        mul cx            ; + Y_START * 80d
        mov cl, bh
        add ax, cx        ; + X_START
        mov cx, 2h
        mul cx

        mov di, ax        ; DI = (X_START + Y_START * 80) * 2

        mov ah, bl        ; AH = attribute
        mov cx, TABLELEN
        call DrawLine

        add di, 160d - TABLELEN * 2d

        mov cx, TABLEHEIGHT
        sub cx, 2

@@cycle:
        xchg cx, dx

        mov cx, TABLELEN
        call DrawLine
        .skip

        xchg cx, dx
        loop @@cycle

@@last:
        add si, 3
        add cx, TABLELEN
        call DrawLine

        ret

          endp
;================================================


;================================================
; Entry:
; DS - current segment
; SI - index of 3 symbol string, LEFT ELEM, MID ELEMs, RIGHT ELEM
; CX - string length
; DI - index of line start
; AH - symbol attribute
; ES - VIDEOSEG (0b800h)
; Destr: AX, CX
;================================================
DrawLine proc

        cld

        lodsb
        stosw

        sub cx, 2
        lodsb
        rep stosw

        lodsb
        stosw

        ret

         endp
;================================================


;================================================
; Entry:
; CX - number of symbols to print
; AH - COLOR
; ES - VIDEOSEG
; DI - start cell in VIDEOSEG
; DS - segment of reading
; SI - index of string
; Destr: AX, CX
;================================================
PrintString      proc
@@out:  lodsb
        stosw        
        loop @@out
        ret
            endp
;================================================

;================================================
; Entry:
; ES - destination segment
; DI - destination index
; BX - input integer
; Destr: AX, DX, CX
;================================================
Itoa16 proc

        push ax cx dx

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

@@reverse:
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

        pop dx cx ax

@@ret:
        ret

        endp
;================================================

activated db 0          ; 0     if turned off
                        ; other if turned on

buff db 5 dup(0)

SYMBOLS db 3 dup(3)
        db 3, ' ', 3
        db 3 dup(3)

REGS:
REG_AX db 'AX'
REG_BX db 'BX'
REG_CX db 'CX'
REG_DX db 'DX'
REG_DS db 'DS'
REG_SI db 'SI'
REG_ES db 'ES'
REG_DI db 'DI'

meow:
end start
