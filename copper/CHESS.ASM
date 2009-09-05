;**********************************
;***** ChessBoard Effect V0.1 *****
;*****   By Sarwaz / Mistery  *****
;**********************************


;Constants

        R1 equ 40
        G1 equ 20
        B1 equ 0

        R2 equ 0
        G2 equ 15
        B2 equ 35


STACK SEGMENT STACK
        db 100h DUP (?)
STACK ENDS


CODE SEGMENT
        ASSUME cs:code,ds:code,ss:stack

Xmov    db 1
Xzoomer1 db 25
Yzoomer1 db 25
Xzoomer2 db 0
Yzoomer2 db 0
color1   db 1

wvr MACRO
        local dw1,dw2
        mov dx,3dah
dw1:
        in al,dx
        test al,8
        jnz dw1
dw2:
        in al,dx
        test al,8
        jz dw2
ENDM

whr MACRO
        local dw1,dw2
        mov dx,3dah
dw1:
        in al,dx
        test al,1
        jnz dw1
dw2:
        in al,dx
        test al,1
        jz dw2
ENDM





Initialize Proc  ;Set video mode, palette and other stuff
        mov ax,13h
        int 10h
        mov dx,3d4h
        mov ax,0013h  ;Set the modulo=0 
        out dx,ax   
        mov ax,SEG CODE
        mov ds,ax
        mov ax,0a000h
        mov es,ax
        xor di,di      ;Video range for effect: es:di=0a000:0000-0a000:0140
        ret
Initialize endp


Chess Proc
        xor di,di      ;FIRST THE X stretcher
        mov ch,color1

        mov cl,Xzoomer1
        cmp cl,Xmov
        jl @@mov
        sub cl,Xmov
        
@@mov:
        mov es:[di],ch
        inc di
        dec cl
        jnz @@mov

@@out:        
        not ch
        mov cl,Xzoomer1 ;First we write the chess upper line
@@in:    
        mov es:[di],ch
        inc di
        dec cl
        jnz @@in
        cmp di,320
        jl @@out      
                        

                        
                        
                        ;Lets Do now the Y stretcher
        
        mov ah,1
        xor bx,bx
@@out2:
        cli
        mov dx,3c8h    ;we have to interchange the color 0 with th 255
        mov al,ah
        out dx,al
        inc dx
        mov al,R1
        out dx,al
        mov al,G1
        out dx,al
        mov al,B1
        out dx,al
        not ah
        dec dx
        mov al,ah
        out dx,al
        inc dx
        mov al,R2
        out dx,al
        mov al,G2
        out dx,al
        mov al,B2
        out dx,al
        sti

        mov ch,Yzoomer1
@@in2:
        whr
        inc bx
        cmp bx,399
        jz fin
        dec ch
        jnz @@in2
        cmp bx,400
        jl @@out2
fin:        
        ret
Chess Endp

start: 
        
        call initialize
doframe:   
        wvr
        call chess
        
        in al,60h
        dec al
        jz exitt
        
        dec Yzoomer1
        dec Xzoomer1
        inc Xzoomer2
        cmp Xzoomer1,5
        jnz doframe
        
doframe2:        
        wvr
        call chess
        inc Yzoomer1
        inc Xzoomer1
        dec Xzoomer2
        cmp Xzoomer1,150
        jnz doframe2
        jmp doframe

exitt:  mov ax,3h
        int 10h
        mov ax,4c00h
        int 21h

CODE ENDS

END start

