.model tiny
.code
org 100h

INT09H   = 09h
VIDEOSEG = 0b800h
COLOR    = 5eh
KEYB_PPI = 61h
SIGN_BIT = 80h

start:
    jmp execute

execute:
;======Now Lets Rewrite Interruption Vector======
        cli

        xor bx, bx
        mov es, bx
        mov bx, INT09H * 4

; There I Can Save Old Interruption
; It Will Be Nice When I Want To
; Hide My Interception

        mov word ptr es:[bx], offset Hack09 ; I Catch An
        mov ax, cs                          ; Interruption
        mov word ptr es:[bx+2], ax          ; ............

        sti

        mov ax, 3100h
        mov dx, offset meow + 0Fh
        shr dx, 4
        int 21h
;================================================

Hack09:
;======It Is Hacked Int09h=======================
        push ax di es
        
        mov ax, VIDEOSEG
        mov es, ax   

        mov di, (80 * 10) * 2               ; 1 symb on 11th line
        mov ah, COLOR

        in al, 60h                          ; Got Scan Code From 60h Port
        stosw                               ; Write Scan Code as ASCII char
                                            ; Stop What??)))

        in  al, KEYB_PPI                    ; Send ACK To
        or  al, SIGN_BIT                    ; Keyboard
        out KEYB_PPI, al                    ; 
        xor al, SIGN_BIT
        out KEYB_PPI, al

        mov al, 20h                         ; Send Signal
        out 20h, al                         ; End Of Interruption

        pop es di ax

        iret
;================================================

Latent09:
;======It Is Hacked Int09h That Uses Origin09h===


        db 0EAh
OldInt  dd 000h       
;================================================


meow:
end start
