.model tiny
.code
org 100h

locals @@

END_OF_STRING = 0Dh

start:

       jmp main

;------------------------------------------------
; Entry:
; DS - current segment
; SI - index of first symbol of string ending with \n (0Dh)
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
; SI - address of string
; AH - desired symbol
; Out:
; AX - address of found symbol
;------------------------------------------------
Strchr proc

@@proceed:
       lodsb
       cmp al, ah
       jne @@proceed

       dec si
       mov ax, si

       ret

       endp
;------------------------------------------------

strncpy:
atoi:
itoa:

main:
       mov ah, '4'
       mov si, offset pupa
       call Strchr

       ret

.data

pupa db '12345', 0Dh

end start