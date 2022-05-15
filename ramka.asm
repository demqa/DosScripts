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
       add di, 160d - TABLELEN * 2
       sub si, 3
       endm

TABLEHEIGHT = 9d
TABLELEN    = 16d
X_START     = 2d
Y_START     = 3d
COLOR       = 5eh

ZERO        = 30h
ONE         = 31h
TWO         = 32h
LETTER_T    = 'T'
SLASH_N       = 0Dh

VIDEOSEG equ 0b800h                   ; VIDEOSEG textmode

start:

       mov si, 82h
       lodsb

       mov bx, si

       cmp al, ONE
       mov si, offset TOP_1
       je @@mid
       
       cmp al, TWO
       mov si, offset TOP_2
       je @@mid

       cmp al, ZERO
       jne @@invinp
       
       mov si, bx

       add si, 10d
       mov bx, si
       sub si, 9d

@@mid:
       push bx

       mov ax, VIDEOSEG     
       mov es, ax               ; es = VIDEOSEG

       mov DH, COLOR            ; BG = VIOLET, LETTER = YELLOW
       mov BH, X_START
       mov BL, Y_START
       call DrawTable

       pop si
@@txt:
       lodsw
       cmp ah, LETTER_T
       jne @@ret

       mov ah, COLOR
       mov di, ((Y_START + TABLEHEIGHT / 2) * 50h + X_START + 1) * 2

@@cycle:
       lodsb
       cmp al, SLASH_N
       je @@ret
       stosw
       jmp @@cycle

@@invinp:

       mov ax, offset InvInput 
       mov dh, 09h

       int 21h

@@ret:
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
       
       mov al, bl
       mov ah, 0h
       mov cx, 50h
       mov bl, dh        ; saving DH from mul
       mul cx            ; + Y_START * 80d
       mov cl, bh
       add ax, cx        ; + X_START
       mov cl, 2h
       mul cl

       mov di, ax        ; DI = (X_START + Y_START * 80) * 2

       mov ah, bl        ; AH = attribute
       mov cx, TABLELEN
       call DrawLine

       sub di, TABLELEN * 2h
       add di, 160d

       mov cx, TABLEHEIGHT
       sub cx, 2

@@mid:
       xchg cx, dx

       mov cx, TABLELEN
       call DrawLine
       .skip

       xchg cx, dx
       loop @@mid

       add si, 3
       add cx, TABLELEN
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

TOP_1 db 0C9h, 0CDh, 0BBh
      db 0BAh, 020h, 0BAh
      db 0C8h, 0CDh, 0BCh

TOP_2 db 02Bh, 02Dh, 02Bh
      db 07Ch, 02Eh, 07Ch
      db 02Bh, 02Dh, 02Bh

InvInput db 'Invalid Input$'

end start