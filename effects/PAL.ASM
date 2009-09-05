STACK SEGMENT STACK
      db 128 dup (?)
STACK ENDS

DATA SEGMENT
     pal db 63,0,0
DATA ENDS

CODE SEGMENT
assume cs:CODE,ds:DATA
.286C
SetColors:
          mov dx,seg DATA
          mov ds,dx
          mov       si,offset pal
          cli                         ; It's quite good 2 disable int. here
          mov       ax,0
          mov       dx,3c8h 
          out       dx,al 
          mov       cx,3              ; 3 times [palette size]
          inc       dx 
          
CSET:     mov       al,[si]           
          out       dx,al 
          inc       si
          dec       cx
          jnz       CSET
          sti

mov ax,4c00h
int 21h

CODE ENDS
     end setcolors
