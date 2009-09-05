;*******************************************
;** Palette Routines by Sarwaz of Mistery **
;*******************************************

;***************************************************************************
;Routines: ReadPal (R,G,B,colour : 8 bits), SetPal (R,G,B,colour : 8 bits)
;          FadeOut (), FadeIn (palette pointed by DS:SI)
;          SetAllPal (palette pointed by DS:BX)
;
;
;***************************************************************************

NumOfRegisters equ 255

PILA SEGMENT STACK
          db 100 DUP (?)
PILA ENDS

DATA SEGMENT 

message1   db  'HI EVERYONE!!!, LETS SEE A GOOD FADE EFFECT - PRESS ESC$'
RGB db 3 DUP (0)
R db 0
G db 0
B db 0
colour db 0




DATA ENDS


CODE SEGMENT
          ASSUME cs:code,ds:DATA
WaitVertRetrace MACRO
local dwait          
          mov dx,3dah
dwait:    in al,dx
          test al,8
          jz dwait
          ENDM



init:      
          mov ax,SEG DATA
          mov ds,ax
          xor ax,ax
          mov ah,9
          mov dx,OFFSET message1
          int 21h
kwait:    in al,60h
          dec al
          jnz kwait
          call FadeOut
          mov ax,4c00h
          int 21h

;--------------------------------------------------------------------------
;    SetPal - Set an individual Color - Work with: R-G-B-Colour Variables
;
;--------------------------------------------------------------------------



SetPal proc ;R-G-B-Colour
          push ax
          push dx
          mov dx,3c8h
          mov al,colour
          out dx,al
          inc dx
          mov al,R
          out dx,al
          mov al,G
          out dx,al
          mov al,B
          out dx,al
          pop dx
          pop ax
          ret
SetPal endp

;--------------------------------------------------------------------------
;   ReadPal - Read an Individual color and puts result on R-G-B - 
;   Works with Colour Variable
;--------------------------------------------------------------------------


ReadPal proc ;Param: Colour - Returns: R-G-B
          push ax
          push dx
          mov dx,3c7h
          mov al,colour
          out dx,al
          mov dx,3c9h
          in al,dx
          mov R,al
          in al,dx
          mov G,al
          in al,dx
          mov B,al
          pop dx
          pop ax
          ret
ReadPal endp

;--------------------------------------------------------------------------
; FadeOut - Fades From current Palette to 0 - Needs RGB temporary Variable 
; with 3 bytes
;--------------------------------------------------------------------------


FadeOut PROC;From current palette To 0,0,0
          push ax
          push bx
          push cx
          push dx
          mov bx,OFFSET RGB
          mov ch,63
@@1:          
          WaitVertRetrace
          mov cl,NumOfRegisters
@@2:          
          mov dx,3c7h
          mov al,cl
          out dx,al
          mov dx,3c9h
          in al,dx
          mov ds:[bx],al
          in al,dx
          mov ds:[bx+1],al
          in al,dx
          mov ds:[bx+2],al
          cmp byte PTR ds:[bx],0
          jz col1
          dec byte PTR ds:[bx]
col1:     
          cmp byte PTR ds:[bx+1],0
          jz col2
          dec byte PTR ds:[bx+1]
col2:
          cmp byte PTR ds:[bx+2],0
          jz col3
          dec byte PTR ds:[bx+2]
col3:
          mov dx,3c8h
          mov al,cl
          out dx,al
          inc dx
          mov al,ds:[bx]
          out dx,al
          mov al,ds:[bx+1]
          out dx,al
          mov al,ds:[bx+2]
          out dx,al
          dec cl          
          jnz @@2
          dec ch
          jnz @@1
          pop dx
          pop cx
          pop bx
          pop ax
          ret
FadeOut ENDP

;---------------------------------------------------------------------------
; FadeIn - Fades From 0,0,0 to desired palette - Needs a pointer to the
; Palette in ds:si
;---------------------------------------------------------------------------


FadeIn proc ;In DS:SI the pointer to the desired palette to fade to
            ;The Current palette should be 0,0,0 for each color register
          push ax
          push bx
          push cx
          push dx
          mov ch,63
@@@1:     
          WaitVertRetrace
          mov cl,NumOfRegisters
          xor bx,bx
@@@2:     
          mov dx,3c7h
          mov al,cl
          out dx,al
          mov dx,3c9h
          in al,dx
          mov R,al
          in al,dx
          mov G,al
          in al,dx
          mov B,al
          mov ah,R
          cmp byte PTR ds:[bx+si],ah
          jz @col12
          inc R
@col12:
          inc bx
          mov ah,G
          cmp byte PTR ds:[bx+si],ah
          jz @col22
          inc G
@col22:
          inc bx
          mov ah,B
          cmp byte PTR ds:[bx+si],ah
          jz @col32
          inc B
@col32:
          mov dx,3c8h
          mov al,cl
          out dx,al
          inc dx
          mov al,R
          out dx,al
          mov al,G
          out dx,al
          mov al,B
          out dx,al
          inc bx
          dec cl
          jnz @@@2
          dec ch
          jnz @@@1
          pop dx
          pop cx
          pop bx
          pop ax
          ret
FadeIn endp

;---------------------------------------------------------------------------
; SetAllPal - Sets All the palette - Needs a pointer in ds:[bx] pointing to
; the desired palette
;---------------------------------------------------------------------------

SetAllPal proc          
          push ax
          push dx
          push si
          xor si,si
          xor ax,ax    
          mov dx,3c8h
          out dx,al
          inc dx
pal:      
          mov al,ds:[bx+si]
          out dx,al
          mov al,ds:[bx+si+1]
          out dx,al
          mov al,ds:[bx+si+2]
          out dx,al
          add si,3
          cmp si,767
          jnz pal
          pop si
          pop dx
          pop ax
          ret
SetAllPal ENDP

;--------------------------------------------------------------------------
; GetAllPal - Reads all palette and put it on ds:bx -
;
;--------------------------------------------------------------------------

GetAllPal PROC
          push ax
          push dx
          push si
          xor ax,ax
          xor si,si
gett:     mov dx,3c7h
          out dx,al
          mov dx,3c9h
          in al,dx
          mov ds:[bx+si],al
          in al,dx
          inc si
          mov ds:[bx+si],al
          in al,dx
          inc si
          mov ds:[bx+si],al
          inc si
          cmp al,255
          jz @@pal1
          inc al
          jmp gett
@@pal1:   pop si
          pop dx
          pop ax
          ret
GetAllPal ENDP

;-----------------------------------------------------------------------
; FadeOutRange - Fades a range from curret palette to 0,0,0 - 
; needs: HighRange and Lowrange - HighRange is the highest color of
; the range, and the Lowrange is the lowest color + 1 of the range
;-----------------------------------------------------------------------


FadeOutRange proc ;Fades a range
          push ax
          push bx
          push cx
          push dx
          mov bx,OFFSET RGB
          mov ch,63
@@13:          
          WaitVertRetrace
          mov cl,HighRange
@@23:          
          mov dx,3c7h
          mov al,cl
          out dx,al
          mov dx,3c9h
          in al,dx
          mov ds:[bx],al
          in al,dx
          mov ds:[bx+1],al
          in al,dx
          mov ds:[bx+2],al
          cmp byte PTR ds:[bx],0
          jz col13
          dec byte PTR ds:[bx]
col13:     
          cmp byte PTR ds:[bx+1],0
          jz col23
          dec byte PTR ds:[bx+1]
col23:
          cmp byte PTR ds:[bx+2],0
          jz col33
          dec byte PTR ds:[bx+2]
col33:
          mov dx,3c8h
          mov al,cl
          out dx,al
          inc dx
          mov al,ds:[bx]
          out dx,al
          mov al,ds:[bx+1]
          out dx,al
          mov al,ds:[bx+2]
          out dx,al
          cmp cl,LowRange          
          jnz @@23
          dec ch
          jnz @@13
          pop dx
          pop cx
          pop bx
          pop ax
          ret
FadeOutRange ENDP

;-----------------------------------------------------------------------
; FadeInRange - Fades a range from 0,0,0 to a palette in ds:si 
; needs: HighRange and Lowrange - HighRange is the highest color of
; the range, and the Lowrange is the lowest color + 1 of the range
;-----------------------------------------------------------------------

FadeInRange proc
          push ax
          push bx
          push cx
          push dx
          mov ch,63
@@@@1:     
          WaitVertRetrace
          mov cl,HighRange
          xor bx,bx
@@@@2:     
          mov dx,3c7h
          mov al,cl
          out dx,al
          mov dx,3c9h
          in al,dx
          mov R,al
          in al,dx
          mov G,al
          in al,dx
          mov B,al
          mov ah,R
          cmp byte PTR ds:[bx+si],ah
          jz @@col12
          inc R
@@col12:
          inc bx
          mov ah,G
          cmp byte PTR ds:[bx+si],ah
          jz @@col22
          inc G
@@col22:
          inc bx
          mov ah,B
          cmp byte PTR ds:[bx+si],ah
          jz @@col32
          inc B
@@col32:
          mov dx,3c8h
          mov al,cl
          out dx,al
          inc dx
          mov al,R
          out dx,al
          mov al,G
          out dx,al
          mov al,B
          out dx,al
          inc bx
          cmp cl,LowRange
          jnz @@@@2
          dec ch
          jnz @@@@1
          pop dx
          pop cx
          pop bx
          pop ax
          ret
FadeInRange ENDP

Cycle proc
          
          xor ax,ax
          mov dx,3c7h
          out dx,al
          mov dx,3c9h
          in al,dx
          mov R,al
          in al,dx
          mov G,al
          in al,dx
          mov R,al
          in al,dx
          mov R1,al
          in al,dx
          mov G1,al
          in al,dx
          mov B1,al
          inc al
          mov dx,3c8h
          out dx,al
          inc dx
          mov al,R
          out dx,al
          mov al,G
          out dx,al
          mov al,B
          out dx,al





CODE ENDS

END init
