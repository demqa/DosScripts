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
; ES - segment
; DI - index of first symbol of string ending with \0 (00h)
; Out:
; CX - length of text
; Destr: AL, Dest. flag
;------------------------------------------------
Strlen proc

       cld
       mov cx, -1

       mov al, END_OF_STRING
       repne scasb

       neg cx
       sub cx, 2

       ret

       endp
;------------------------------------------------

;------------------------------------------------
; Entry:
; Parameters Pushing that Way:
; First  - index   of string
; Second - segment of string
; Out: AX - length
;------------------------------------------------
StrlenC proc
       push bp
       mov bp, sp

       push es di  
       pushf

       mov es, [bp + 4]
       mov di, [bp + 6]
       
       call Strlen

       mov ax, cx
 
       popf
       pop di es

       pop bp

       ret 2*2
        endp
;------------------------------------------------

;------------------------------------------------
; Entry:
; ES - current segment
; DI - address of string ending with 00h
; AL - desired symbol
; Out:
; AX - address of found symbol
;------------------------------------------------
Strchr proc

       cld

       repne scasb

       dec di
       mov ax, di

       ret

       endp
;------------------------------------------------

;------------------------------------------------
; Entry:
; Parameters Pushing that Way:
; First  - index   of string
; Second - segment of string
; Out: AX - address
;------------------------------------------------
StrchrC proc
       push bp
       mov bp, sp

       push es di
       pushf

       mov es, [bp + 4]
       mov di, [bp + 6]
       mov al, [bp + 8]
       
       call Strchr

       popf
       pop di es

       pop bp

       ret 3*2
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
; Parameters Pushing that Way:
; First   - max. number of symbols that will copy
; Second  - destination index
; Third   - destination segment
; Fourth  - source index
; Fifth   - source segment
; Out: AX - 
;------------------------------------------------
StrncpyC proc
       push bp
       mov bp, sp

       push es di ds si
       pushf

       mov ds, [bp + 4]
       mov si, [bp + 6]
       
       call Strchr

       popf
       pop si ds di es

       pop bp

       ret 3*2
        endp
;------------------------------------------------


;------------------------------------------------
; Entry:
; DS - current segment
; SI - start index of string, containing [0-9] or -(+) in the beggining
; Out:
; AX - result integer (signed)
; Destr: BX, DX, CL
;------------------------------------------------
Atoi10 proc

       xor bx, bx
       xor ah, ah
       xor cl, cl

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

       jmp @@positive

@@negative:
       inc cl

@@positive:

       lodsb

       cmp al, END_OF_STRING
       je @@exit

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

@@exit:
       cmp cl, 0h
       jz @@ret

       neg bx

@@ret:
       mov ax, bx
       ret       

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
; Destr: AX, DX, CX
;------------------------------------------------
Itoa10 proc

       mov cx, TEN
       
       cmp bx, 0h
       push di
       jns @@proceed

       mov al, MINUS
       stosb

       pop dx
       push di

       neg bx

@@proceed:

       xor dx, dx

       mov ax, bx    ; ax = N
       idiv cx       ; ax = N / 10

       mov bx, ax    ; saving next integer

       mov ax, dx    ; ax = N % 10

       add al, ZERO

       stosb

       cmp bx, 0h
       jne @@proceed

       mov al, END_OF_STRING
       stosb

       pop bx
       sub di, 2

@@reverse:
       mov al, es:[di]
       mov dl, es:[bx]
       mov es:[di], dl
       mov es:[bx], al

       inc bx
       dec di

       cmp bx, di
       jb @@reverse

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
Itoa16 proc

       mov dx, di
       cld

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
       jnz @@proceed

       mov al, END_OF_STRING
       stosb

       mov bx, dx
       sub di, 2

@@reverse:                  ; 
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
;------------------------------------------------

;------------------------------------------------
; Entry:
; ES - destination segment
; DI - destination index
; BX - input integer
; Destr: AX, DX
;------------------------------------------------
Itoa8  proc

       mov dx, di
       cld

@@proceed:

       mov ax, bx    ; ax = N

       and ax, 07h

       add al, ZERO

       stosb

       shr bx, 3h
       jnz @@proceed

       mov al, END_OF_STRING
       stosb

       mov bx, dx
       sub di, 2

@@reverse:                  ; 
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
;------------------------------------------------

;------------------------------------------------
; Entry:
; ES - destination segment
; DI - destination index
; BX - input integer
; Destr: AX, DX
;------------------------------------------------
Itoa2  proc

       mov dx, di
       cld

@@proceed:

       mov ax, bx    ; ax = N

       and ax, 01h

       add al, ZERO

       stosb

       shr bx, 1h
       jnz @@proceed

       mov al, END_OF_STRING
       stosb

       mov bx, dx
       sub di, 2

@@reverse:                  ; 
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
;------------------------------------------------


main:
       mov ax, offset pupa
       push ax
       push ds
       call StrchrC

       mov di, offset output
       mov bx, ax
       call Itoa16

       mov ah, 09h
       mov dx, offset output
       int 21h

       ret

.data

pupa db '12345', END_OF_STRING

InvalidDN db 'There is not a decimal number in a string$'
InvalidBN db 'There is not a binary  number in a string$'
InvalidON db 'There is not an octal  number in a string$'
InvalidHN db 'There is not a hex     number in a string$'

output db 20 dup('$')

end start