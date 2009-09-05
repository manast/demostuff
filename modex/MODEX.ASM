;************************************
;** ModeX- Coded by Sarwaz/MiSTERY **
;************************************

.286

;Constants 

          SEQC_ADRR equ 3c4h
          CRTC_ADRR equ 3d4h



STACK SEGMENT STACK
          db 100 dup (?)
STACK ENDS

DATA SEGMENT
          CORD_X dw 0
          CORD_Y dw 0
          COLOR  db 15
DATA ENDS

wvr MACRO
    LOCAL dwait,dwait2
          mov dx,3dah
dwait:    in al,dx
          test al,8
          jnz dwait
dwait2:    
          in al,dx
          test al,8
          jz dwait2
    ENDM

CODE SEGMENT 
 ASSUME CS:CODE,SS:STACK,DS:DATA
        

start: 
       mov ax,SEG DATA
       mov ds,ax
       call init_modex
       wvr
       mov bx,16000  ;Set another page
       mov dx,3d4h
       mov ah,bh
       mov al,0ch
       out dx,ax
       mov ah,bl
       mov al,0dh
       out dx,ax
       mov cx,199
@@@1:
       mov CORD_Y,cx
       mov ax,319
@@@2:

       mov CORD_X,ax
       mov COLOR,cl
       push ax
       push cx
       call putpixel
       pop cx
       pop ax
       dec ax
       jnz @@@2
       dec cx
       jnz @@@1
            ;Lets get the dib with a scroll ;)
       mov cx,15920
Scr1:
       wvr
       mov dx,3d4h
       mov ah,ch
       mov al,0Ch
       out dx,ax
       mov ah,cl
       mov al,0Dh
       out dx,ax
       sub cx,80
       jnz Scr1
       call wait_exit


init_modex PROC ;320x200x256 4 bit planes
       mov ax,13h ;First We initialize the 320x200x256 color mode
       int 10h
       mov dx,SEQC_ADRR
       mov ax,0604h
       out dx,ax  ;This disables CHAIN-4
       mov dx,CRTC_ADRR
       mov ax,0014h  ;Disables dword mode
       out dx,ax
       mov ax,0e317h
       out dx,ax  ;Sets the byte mode

                      ;Lets Clean the screen
       mov ax,0F02h ;This will enable the 4 bit planes (for more speed in 
       mov dx,SEQC_ADRR            
       out dx,ax    ;the cleaning operation)
       mov ax,0a000h
       mov es,ax
       xor di,di
       mov cx,8000h  ;In words, all the display memory
       xor ax,ax
       rep stosw
       ret
init_modex endp
                     
;******************************************       
;Procedure Put Pixel
;Inputs: CORD_X:word,CORD_Y:word,COLOR,byte
;Registers destroyed: ax,bx,cx,dx,es
;******************************************

PutPixel PROC
       mov dx,SEQC_ADRR ;First We have to select the plane
       mov ax,ds:CORD_X
       and al,3
       mov cl,al
       mov ah,1
       shl ah,cl
       mov al,2
       out dx,ax
       mov dx,0a000h
       mov es,dx
       mov ax,320/4
       mov bx,CORD_Y
       mul bx
       mov bx,CORD_X
       shr bx,2
       add bx,ax
       mov cl,ds:COLOR
       mov es:[bx],cl
       ret
PutPixel ENDP

wait_exit PROC
kwait: in al,60h
       cmp al,1
       jnz kwait
       mov ax,3h
       int 10h
       mov ax,4c00h
       int 21h
wait_exit endp 

CODE ENDS
END start


