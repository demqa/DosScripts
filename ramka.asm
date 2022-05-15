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
       xchg DX, DI
       sub DX, TABLELEN
       add DX, 160d
       xchg DX, DI
       sub SI, 3
       endm

HEIGHT = 10d * 2
TABLELEN  = 20d * 2

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

       mov di, (80d * 5d + 20d) * 2
       mov cx, TABLELEN
       mov si, offset TOP
       mov ah, 5eh
       call DrawLine
	
       .getch

       .term

;------------------------------------------------
; Entry:
; DS - current segment
; SI - index of 9 symbol string TL corner, TM elem, TR corner
;                               ML   elem, MM elem, MR   elem
;                               BL corner, BM elem, BR corner
; macro TABLELEN  = length
; macro HEIGHT = height  
; BL - number of first line   (numeration from 0)
; BH - number of first symbol (numeration from 0)
; ES - VIDEOSEG (0b800h)
; Destr: DI, CX, AX, DX
;------------------------------------------------
DrawTable proc

       mov DH, 0
       mov DL, BL
       mul DX, 50h
       mov BL, BH
       mov BH, 0
       add DX, BX
       mul DX, 2       ; change to shift left 1

       mov BL, TABLELEN   ; store length to register for speed

       mov DI, DX

       mov CX, TABLELEN
       call DrawLine
       xchg DX, DI
       sub DX, BL
       add DX, 160d
       xchg DX, DI

       mov CX, TABLELEN / 2
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
MID db 0BAh, 020h, 0BAh
BOT db 0C8h, 0CDh, 0BCh

end start