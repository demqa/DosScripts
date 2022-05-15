.model tiny
.code
org 100h
locals @@

.term  macro
       mov ax, 4c00h
       int 21h
       endm

.getch macro
       xor ah, ah
       int 16h
       endm

.skip  macro
       sub DI, TABLELEN * 2
       add DI, 160d
       sub SI, 3
       endm

TABLEHEIGHT = 9d
TABLELEN    = 16d
X           = 2d
Y           = 3d

VIDEOSEG equ 0b800h                   ; VIDEOSEG textmode

start:
       mov ax, 0106h
       jmp ax                         ; JUMP after $
       
       db '$'

       mov ah, 09h
       mov dx, 82h
       int 21h

       mov si, 82h
       lodsb
       
       mov ah, 02h 
       int 21h

       mov ax, VIDEOSEG     
       mov es, ax                     ;  es = VIDEOSEG

       mov bx, (80d * 1d + 40d) * 2

       mov ah, 5eh                    ;  BG = VIOLET, LETTER = YELLOW

       mov byte ptr es:[bx],   'A'    ;  UL corner = A
       mov byte ptr es:[bx+1],  ah    

       .getch

       mov SI, offset TOP
       mov DH, 5eh
       mov BH, X
       mov BL, Y

       call DrawTable
	
       .getch

       .term

;------------------------------------------------
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
;------------------------------------------------
DrawTable proc
       
       mov AL, BL
       mov AH, 0h
       mov CX, 50h
       mov BL, DH        ; saving DH from mul
       mul CX            ; + Y * 80d
       mov CL, BH
       add AX, CX        ; + X
       mov CL, 2h
       mul CX

       mov DI, AX        ; DI = (X + Y * 80) * 2

       mov AH, BL        ; AH = attribute
       mov CX, TABLELEN
       call DrawLine

       sub DI, TABLELEN * 2h
       add DI, 160d

       mov CX, TABLEHEIGHT
       sub CX, 2
@@mid: 
       xchg CX, DX

       mov CX, TABLELEN
       call DrawLine
       .skip

       xchg CX, DX
       loop @@mid

       add SI, 3
       add CX, TABLELEN
       call DrawLine

       ret
          endp
;------------------------------------------------


;------------------------------------------------
; Entry:
; DS - current segment
; SI - index of 3 symbol string, LEFT ELEM, MID ELEMs, RIGHT ELEM
; CX - string length
; DI - index of line start
; AH - symbol attribute
; ES - VIDEOSEG (0b800h)
; Destr: AX
;------------------------------------------------
DrawLine  proc

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
;------------------------------------------------

.data

TOP db 0C9h, 0CDh, 0BBh
    db 0BAh, 020h, 0BAh
    db 0C8h, 0CDh, 0BCh

end start