;****************************************************************
;*** Gradual Fade, Only for one colour **************************
;**************************************************************************
;*** For use in text modes, usefull for change from a text mode to another*
;*** or something like that ***********************************************
;**************************************************************************
;** By Sarwaz Of MiSTERY **************************************************
;**************************** Octuber 1995 ********************************
;**************************************************************************

COLOUR equ 7



STACK SEGMENT STACK
          db 100h DUP (?)
STACK ENDS

CODE SEGMENT 
          ASSUME CS:CODE,SS:STACK,ds:code
Fadepal db 64*3 DUP (63)
RGB db 3 DUP (?)
RGBTMP db 3 DUP (?)
wvr MACRO
          local dw,dw2
          mov dx,3dah
dw:       in al,dx
          test al,8
          jnz dw
dw2:      in al,dx
          test al,8
          jz dw2
          ENDM

whr MACRO
          local dw,dw2
          mov dx,3dah
dw:       in al,dx
          test al,1
          jnz dw
dw2:      in al,dx
          test al,1
          jz dw2
          ENDM



start:
      ;First we have to calculate the fade colours of the current colour
      mov dx,3c7h
      mov al,COLOUR
      out dx,al
      mov dx,3c9h
      in al,dx
      mov Byte Ptr cs:[RGB],al
      mov Byte Ptr cs:[RGBTMP],al
      in al,dx
      mov Byte Ptr cs:[RGB+1],al
      mov Byte Ptr cs:[RGBTMP+1],al
      in al,dx
      mov Byte Ptr cs:[RGB+2],al
      mov Byte Ptr cs:[RGBTMP+2],al
      mov cx,64
      xor si,si
      lea bx,FadePal
@@1: 
      mov al,cs:[RGB]
      cmp al,1
      jz nomod
      dec al
      mov cs:[RGB],al
nomod:      
      mov byte ptr cs:[bx+si],al
      mov al,cs:[RGB+1]
      cmp al,1
      jz nomod2
      dec al
      mov cs:[RGB+1],al
nomod2:      
      mov byte ptr cs:[bx+si+1],al
      mov al,cs:[RGB+2]
      cmp al,1
      jz nomod3
      dec al
      mov cs:[RGB+2],al
nomod3:
      mov byte ptr cs:[bx+si+2],al
      add si,3
      dec cx
      jnz @@1

      ;Now we begin with the fade itself.
      ;What we do is generate a coper bar with those colours above defined,
      ;And we move that copper from the bottom of the screen upwards
      
      
      
      mov di,198 ;400 frames? yeah 400/70=5,7seg

frame:
      cli
      wvr
      mov dx,3c8h
      mov al,COLOUR
      out dx,al
      inc dx
      mov al,cs:[RGBTMP]
      out dx,al
      mov al,cs:[RGBTMP+1]
      out dx,al
      mov al,cs:[RGBTMP+2]
      out dx,al
      sti
      
      mov bp,di
fade:
      cli
      whr
      whr
      sti
      dec bp
      cmp bp,2
      jnz fade
      mov bp,200
      sub bp,di
      mov cx,64
      xor si,si
copbar:
      cli
      mov dx,3c8h
      mov al,COLOUR
      out dx,al
      inc dx
      mov al,cs:[bx+si]
      out dx,al
      mov al,cs:[bx+si+1]
      out dx,al
      mov al,cs:[bx+si+2]
      out dx,al
      add si,3
      dec cx
      jz endd
      whr
      whr
      sti
      dec bp
      jnz copbar
endd:
      dec di
      cmp di,3
      jz endish
      jmp frame
endish:
      mov ax,3h
      int 10h
      mov ax,4c00h
      int 21h

CODE ENDS
END start
