.model tiny
.code
org 100h

locals @@

END_OF_STRING = 00h

MINUS         = '-'
PLUS          = '+'
ZERO          = '0'
ONE           = '1'
SEVEN         = '7'
NINE          = '9'
LETTER_A      = 'A'
LETTER_F      = 'F'

TEN           = 10d

start:

       jmp main

;------------------------------------------------
; Entry:
; DS - current segment
; SI - index of first symbol of string ending with \0 (00h)
; Out:
; AX - length of text
; Destr: AX, CX
;------------------------------------------------
Strlen proc

       xor cx, cx

@@proceed:
       lodsb
       cmp al, END_OF_STRING
       je @@ret

       inc cx
       jmp @@proceed

@@ret:
       mov ax, cx
       ret

       endp
;------------------------------------------------


;------------------------------------------------
; Entry:
; DS - current segment
; SI - address of string ending with 00h
; AH - desired symbol
; Out:
; AX - address of found symbol
; AX = 00h if there is no such symbol
;------------------------------------------------
Strchr proc

@@proceed:
       lodsb
       cmp al, END_OF_STRING
       je @@eof
       
       cmp al, ah
       jne @@proceed

       dec si
       mov ax, si

@@ret:
       ret

@@eof:
       mov ax, 00h
       ret

       endp
;------------------------------------------------

;------------------------------------------------
; Entry:
; DS - source segment
; SI - source index
; ES - destination segment
; DI - destination index
; CX - max. number of symbols that will copy
;------------------------------------------------
Strncpy proc

@@proceed:
       lodsb
       stosb

       cmp al, END_OF_STRING
       je @@ret
       
       loop @@proceed

@@ret:
       ret

        endp
;------------------------------------------------

;------------------------------------------------
; Entry:
; DS - current segment
; SI - start index of string, containing [0-9] or -(+) in the beggining
; Out:
; AX - result integer (signed)
; Destr: BX, DX
;------------------------------------------------
Atoi10 proc

       xor bx, bx
       xor ah, ah

       lodsb

       cmp al, MINUS
       je @@negative

       cmp al, PLUS
       je @@positive
       
       cmp al, END_OF_STRING
       je @@ret

       cmp al, ZERO ; '0'
       jb @@err
       cmp al, NINE ; '9'
       ja @@err

       sub al, ZERO
       xchg bl, al

@@positive:

       lodsb

       cmp al, END_OF_STRING
       je @@ret

       cmp al, ZERO
       jb @@err
       cmp al, NINE
       ja @@err

       sub al, ZERO

       mov dx, bx           ; MULTIPLYING
                            ; BY 10
       sal bx, 2            ; 
       add bx, dx           ; 
       sal bx, 1            ; 

       add bx, ax

       jmp @@positive

;-----------------------; I wanted to do this,
;---- jo @@overflow ----; but it will cause
;-----------------------; speed reduction

@@ret:
       mov ax, bx
       ret

@@negative:

       lodsb

       cmp al, END_OF_STRING
       je @@ret

       cmp al, ZERO
       jb @@err
       cmp al, NINE
       ja @@err

       sub al, ZERO

       mov dx, bx           ; MULTIPLYING
                            ; BY 10
       sal bx, 2            ; 
       add bx, dx           ; 
       sal bx, 1            ; 

       sub bx, ax

       jmp @@negative

@@err:
       mov dx, offset InvalidDN
       mov ah, 09h
       int 21h
       ret

       endp
;------------------------------------------------

;------------------------------------------------
; Entry:
; DS - current segment
; SI - start index of string ending with 00h, 
;      containing 0 or 1
; Out:
; AX - result integer
; Destr: BX
;------------------------------------------------
Atoi2  proc

       xor bx, bx
       xor ah, ah

@@proceed:

       lodsb

       cmp al, END_OF_STRING
       je @@ret

       cmp al, ZERO
       jb @@err
       cmp al, ONE
       ja @@err

       sub al, ZERO

       sal bx, 1

       add bx, ax

       jmp @@proceed

;-----------------------; I wanted to do this,
;---- jo @@overflow ----; but it will cause
;-----------------------; speed reduction

@@ret:
       mov ax, bx
       ret

@@err:
       mov dx, offset InvalidBN
       mov ah, 09h
       int 21h
       ret

       endp
;------------------------------------------------


;------------------------------------------------
; Entry:
; DS - current segment
; SI - start index of string ending with 00h, 
;      containing [0-7]
; Out:
; AX - result integer
; Destr: BX
;------------------------------------------------
Atoi8  proc

       xor bx, bx
       xor ah, ah

@@proceed:

       lodsb

       cmp al, END_OF_STRING
       je @@ret

       cmp al, ZERO
       jb @@err
       cmp al, SEVEN
       ja @@err

       sub al, ZERO

       sal bx, 3

       add bx, ax

       jmp @@proceed

;-----------------------; I wanted to do this,
;---- jo @@overflow ----; but it will cause
;-----------------------; speed reduction

@@ret:
       mov ax, bx
       ret

@@err:
       mov dx, offset InvalidON
       mov ah, 09h
       int 21h
       ret

       endp
;------------------------------------------------


;------------------------------------------------
; Entry:
; DS - current segment
; SI - start index of string ending with 00h, 
;      containing [0-9A-F]
; Out:
; AX - result integer
; Destr: BX
;------------------------------------------------
Atoi16 proc

       xor bx, bx
       xor ah, ah

@@proceed:

       lodsb

       cmp al, END_OF_STRING
       je @@ret

       cmp al, ZERO
       jb @@err
       cmp al, NINE
       jbe @@number

       cmp al, LETTER_A
       jb @@err
       cmp al, LETTER_F
       ja @@err

       add al, ZERO + 10d - LETTER_A   ; this constant used there
                                       ; because I dont want to
                                       ; divide this cases

@@number:
       sub al, ZERO

       sal bx, 4

       add bx, ax

       jmp @@proceed

;-----------------------; I wanted to do this,
;---- jo @@overflow ----; but it will cause
;-----------------------; speed reduction

@@ret:
       mov ax, bx
       ret

@@err:
       mov dx, offset InvalidHN
       mov ah, 09h
       int 21h
       ret

       endp
;------------------------------------------------


;------------------------------------------------
; Entry:
; ES - destination segment
; DI - destination index
; BX - input integer
; Destr: AX, DX
;------------------------------------------------
Itoa10 proc

       mov cx, TEN
       
       cmp bx, 0h
       jns @@proceed

       mov al, MINUS
       stosb

@@proceed:

       xor dx, dx
       
       mov ax, bx    ; ax = N
       idiv cx        ; ax = N / 10

       mov bx, ax    ; saving next integer

       mov ax, dx    ; ax = N % 10

;------------------------------------------------
; FIX SOMEHOW PROBLEM WITH SIGNED & reverse number
;------------------------------------------------

@@abs: neg ax
       js @@abs

       add al, ZERO

       stosb

       cmp bx, 0h
       jne @@proceed

       mov al, END_OF_STRING
       stosb

       ret

       endp
;------------------------------------------------

main:
       mov si, offset pupa
       call Atoi8

       mov di, offset output
       mov bx, -10
       call Itoa10

       mov ah, 09h
       mov dx, offset output
       int 21h

       ret

.data

pupa db '477', END_OF_STRING

InvalidDN db 'There is not a decimal number in a string$'
InvalidBN db 'There is not a binary  number in a string$'
InvalidON db 'There is not an octal  number in a string$'
InvalidHN db 'There is not a hex     number in a string$'

output db 20 dup('$')

end start