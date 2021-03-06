;***************************
;** Sarwaz Stile Copper   **
;***************************
;**   By Sarwaz / Mry     **
;***************************

;Constants
        speed1 equ 3
        speed2 equ 2
        long1  equ 2
        long2  equ 3
        modu   equ 63


;Palette Constants , lame, but fast!

        R1  equ 5
        G1  equ 0
        B1  equ 5
        R2  equ 10
        G2  equ 0
        B2  equ 10
        R3  equ 15
        G3  equ 0
        B3  equ 15
        R4  equ 20
        G4  equ 0
        B4  equ 20
        R5  equ 15
        G5  equ 0
        B5  equ 15
        R6  equ 10
        G6  equ 0
        B6  equ 10
        R7  equ 5
        G7  equ 0
        B7  equ 5
        R8  equ 0
        G8  equ 0
        B8  equ 0


STACK SEGMENT STACK
        db 100h DUP(?)
STACK ENDS

CODE SEGMENT
        ASSUME cs:code,ds:code,ss:stack
.286
;Vars
sinus label byte
include sarcop2.inc

ind1 dw 0
ind2 dw 0

start:
        call initialize
        xor si,si
        call filine
doefect:        
        call frame
        in al,60h
        dec al
        jnz doefect
        mov ax,3h
        int 10h
        mov ax,4c00h
        int 21h

wvr MACRO        
        local dw,dw2
        mov dx,3dah
dw:     in al,dx
        test al,8
        jnz dw
dw2:    in al,dx
        test al,8
        jz dw2
ENDM

whr1 MACRO
        local dw
        mov dx,3dah
dw:     in al,dx
        test al,1
        jnz dw
ENDM
whr2 MACRO
        local dw2
        mov dx,3dah
dw2:    in al,dx
        test al,1
        jz dw2
ENDM

copline MACRO
        cli
        mov dx,3c8h
        ;mov cl,cs:value ;Here we put the rotating value
        and cl,modu
        inc cl
        mov al,cl        ;Color 1
        out dx,al
        inc dx
        mov al,R1
        out dx,al
        mov al,G1
        out dx,al
        mov al,B1
        out dx,al
        dec dx
        
        and cl,modu
        inc cl
            
        mov al,cl        ;Color 2
        out dx,al
        inc dx
        mov al,R2
        out dx,al
        mov al,G2
        out dx,al
        mov al,B2
        out dx,al
        dec dx
        
        and cl,modu
        inc cl

        mov al,cl        ;Color 3
        out dx,al
        inc dx
        mov al,R3
        out dx,al
        mov al,G3
        out dx,al
        mov al,B3
        out dx,al
        dec dx
        
        and cl,modu
        inc cl

        mov al,cl        ;color 4
        out dx,al
        inc dx
        mov al,R4
        out dx,al
        mov al,G4
        out dx,al
        mov al,B4
        out dx,al
        dec dx
        
        and cl,modu
        inc cl

        mov al,cl       ;color 5 
        out dx,al
        inc dx
        mov al,R5
        out dx,al
        mov al,G5
        out dx,al
        mov al,B5
        out dx,al
        dec dx
        
        and cl,modu
        inc cl
        
        mov al,cl       ;color 6 
        out dx,al
        inc dx
        mov al,R6
        out dx,al
        mov al,G6
        out dx,al
        mov al,B6
        out dx,al
        dec dx
        
        and cl,modu
        inc cl

        
        mov al,cl        ;Color 7
        out dx,al
        inc dx
        mov al,R7
        out dx,al
        mov al,G7
        out dx,al
        mov al,B7
        out dx,al
        dec dx
        
        and cl,modu
        inc cl

        mov al,cl           ;Color 8
        out dx,al
        inc dx
        mov al,R8
        out dx,al
        mov al,G8
        out dx,al
        mov al,B8
        out dx,al
        
        sti
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

frame proc
        wvr
        mov di,cs:ind2
        mov si,cs:ind1
        add cs:ind2,Speed2
        add cs:ind1,Speed1
        and cs:ind2,511
        and cs:ind1,511
        mov bp,199
        mov bx,offset sinus
lin:
        mov cl,[bx+si]
        add cl,[bx+di]
        shr cl,1
        add di,long2
        and di,511
        add si,long1
        and si,511
        
        
        whr2
        copline
        whr1
        dec bp
        jz fini
        jmp lin
fini:
        ret
frame endp


filine proc
        
        mov ch,1
@@11:
        mov cl,4
@@21:        
        mov es:[di],ch
        inc di
        dec cl
        jnz @@21
        inc ch
        cmp ch,32
        jnz @@11
        mov ch,32
@@12:
        mov cl,4
@@22:
        mov es:[di],ch
        inc di
        dec cl
        jnz @@22
        dec ch
        cmp ch,0
        jnz @@12
        
        mov ch,1
@@13:
        mov cl,4
@@23:        
        mov es:[di],ch
        inc di
        dec cl
        jnz @@23
        inc ch
        cmp ch,32
        jnz @@13
        
        ret
filine endp



CODE ENDS
END start
