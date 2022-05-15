.model tiny
.code
org 100h
locals @@

TABLEHEIGHT = 10d
TABLELEN    = 40d
X_START     = 5d
Y_START     = 5d
COLOR       = 5eh

ZERO        = 30h
ONE         = 31h
TWO         = 32h
LETTER_T    = 'T'
SLASH_N     = 0Dh
SPACE       = ' '

VIDEOSEG equ 0b800h                   ; VIDEOSEG textmode

CMD_LINE equ 00082h                   ; First symbol in cmd params

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

start:

       mov si, CMD_LINE
       lodsb

       mov bx, si

       cmp al, ONE
       mov si, offset SYMB_SET_1
       je @@proceed
       
       cmp al, TWO
       mov si, offset SYMB_SET_2
       je @@proceed

       cmp al, ZERO
       jne @@err
       
       mov si, bx

       add si, 10d
       mov bx, si
       sub si, 9d

@@proceed:
       push bx

       mov ax, VIDEOSEG     
       mov es, ax               ; es = VIDEOSEG

       mov bx, si
       mov ax, [bx+4]

       mov bx, offset BGSYM
       mov [bx], ax

       mov DH, COLOR            ; BG = VIOLET, LETTER = YELLOW
       mov BH, X_START
       mov BL, Y_START
       call DrawTable

       pop si

       mov CX, TABLELEN - 3

       call WriteText
       jmp @@ret

@@err:

       mov ah, 09h
       mov dx, offset InvInput

       int 21h

@@ret:
       .term


;------------------------------------------------
; Entry:
; CX       - max length of text
; at BGSYM - flooding symbol
; DS:SI    - start of text, that ends with \n (0DH)
; ES       - VIDEOSEG (0b800h)
; Destr: AX, DI
;------------------------------------------------
WriteText proc

       lodsw
       cmp ah, LETTER_T
       jne @@ret

       mov ah, COLOR
       mov di, ((Y_START + TABLEHEIGHT / 2) * 50h + X_START + 1) * 2

@@cycle:
       lodsb
       cmp al, SLASH_N
       je  @@ret
       cmp al, SPACE
       jne @@proceed
       mov al, BGSYM

@@proceed:
       stosw

       loop @@cycle

@@ret:
       ret

          endp
;------------------------------------------------




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

SYMB_SET_1 db 0C9h, 0CDh, 0BBh
           db 0BAh, 020h, 0BAh
           db 0C8h, 0CDh, 0BCh

SYMB_SET_2 db 02Bh, 02Dh, 02Bh
           db 07Ch, 02Eh, 07Ch
           db 02Bh, 02Dh, 02Bh

InvInput   db 'Invalid Input$'

BGSYM      db 0FFh, 0FFh, 0FFh

end start