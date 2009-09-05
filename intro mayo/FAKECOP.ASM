;Fake Copper Effect By Sarwaz / Mistery
;It needs to be called in 320x200

        heigth equ 200

extrn exit:far,fadeframef:far

public fakecopper

code segment public
                  assume cs:code,ds:code,ss:stack
.386
parmtab db 15,10,10
        db 5,5,3
        db 249,5,7
        db 1,2,3
        db 249,7,14
        db 5,4,3
        db 5,1,4
        db 7,9,8
        db 0

sinind1 db 0
sinind2 db 80
sinind3 db 135 
counter db 0
curpal dw 0
sintable label byte 
include fakecop.cos

palette label byte 
include fakecop.col

SetPalette PROC
        push ds
        mov     ds,ax
        mov     dx,3c8h
        mov     al,0
        out     dx,al
        inc     dx
        mov     cx,300h
        rep     outsb
        pop ds
        ret
Setpalette Endp

paintline MACRO initpos
        local @@1,@@2,@end,@@3,@@4
        push cx
        push si
        mov cl,initpos
        mov si,di
        add si,319

@@1:
        mov es:[di],cl
        mov es:[si],cl
        dec si
        inc di
        inc cl
        cmp cl,160
        jnz @@1
        xor cl,cl
        cmp cl,initpos
        jz @end
        
@@2:
        mov es:[di],cl
        mov es:[si],cl
        dec si
        inc di
        inc cl
        cmp cl,initpos
        jb @@2
@end:
        pop si
        pop cx
        ENDM

setborder MACRO color
        push    ax
        push    dx
        cli
        mov     dx,3dah
        in      al,dx
        mov     dx,3c0h
        mov     al,11h+32
        out     dx,al
        mov     al,color
        out     dx,al
        sti
        pop     dx
        pop     ax
        ENDM


fakecopper PROC  
        mov ax,13h
        int 10h
        
        lea si,palette
        mov ax,cs
        Call setpalette 
        mov cs:curpal,768
        setborder 200
        mov ax,0a000h
        mov es,ax
        lea bx,sintable        
        xor bp,bp
frame:
        mov dx,3dah
wait_ret:        
        in al,dx
        test al,8
        jz wait_ret
        xor di,di
        xor ah,ah
        xor dh,dh
        
        mov cl,cs:sinind3
        mov ch,cs:[parmtab+bp]
        add cs:sinind3,ch
        mov dl,cs:sinind2
        mov ch,cs:[parmtab+bp+1]
        add cs:sinind2,ch
        mov al,cs:sinind1
        mov si,ax
        mov ch,cs:[parmtab+bp+2]
        add cs:sinind1,ch
        
@buc1:
        push cx
        xor cx,cx
        mov al,cs:[bx][si] 
        mov cl,cs:[parmtab+bp+3]
        add si,cx
        and si,255
        xchg dx,si
        add al,cs:[bx][si]
        mov cl,cs:[parmtab+bp+4]
        add si,cx
        and si,255
        xchg dx,si
        pop cx
        xor ch,ch
        xchg cx,si
        push dx
        add al,cs:[bx][si]
        mov dl,cs:[parmtab+bp+5]
        add si,dx
        and si,255
        pop dx
        xchg cx,si
        paintline al
        add di,160
        cmp di,heigth*320;64000
        jb @buc1
        in al,60h
        dec al
        jnz @5am
        jmp exit
@5am:
        inc cs:counter
        cmp cs:counter,129
        jb nofade
        pusha
        Call FadeFramef
        popa
nofade:
        cmp cs:counter,170
        jnz frame
        add bp,6
        cmp cs:[parmtab+bp],0
        jz @end
        mov cs:counter,0
        lea cx,palette
        add cx,cs:curpal
        add cs:curpal,768
        mov si,cx
        mov ax,cs
        call setpalette 
        
        jmp frame
@end:        
        retf
fakecopper endp

code ends

stack Segment stack
        db 100h DUP (0)
Stack Ends

end fakecopper
