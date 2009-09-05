;**************************************************************************
;------------------- Copper Bars by Sarwaz of Mistery ---------------------
;**************************************************************************

;We begin with some constants and definitions

NCOLORS   equ 27
MINYCORD  equ 100
MAXYCORD  equ 160
BARCOLOR  equ 0

STACK SEGMENT STACK
      db 128 dup (?)
STACK ENDS

DATA SEGMENT
       
       
  
copperbar1   db   0, 0, 0, 5, 0, 0,10, 0, 0,15, 0, 0,20, 0, 0,25, 0, 0
             db  30, 0, 0,35, 0, 0,40, 0, 0,45, 0, 0,50, 0, 0,55, 0, 0  
             db  60, 0, 0,63, 0, 0,60, 0, 0,55, 0, 0,50, 0, 0,45, 0, 0
             db  40, 0, 0,35, 0, 0,30, 0, 0,25, 0, 0,20, 0, 0,15, 0, 0
             db  10, 0, 0, 5, 0, 0, 0, 0, 0
copperbar2   db   0, 0, 0, 0, 5, 0, 0,10, 0, 0,15, 0, 0,20, 0, 0,25, 0 
             db   0,30, 0, 0,35, 0, 0,40, 0, 0,45, 0, 0,50, 0, 0,55, 0  
             db   0,60, 0, 0,63, 0, 0,60, 0, 0,55, 0, 0,50, 0, 0,45, 0
             db   0,40, 0, 0,35, 0, 0,30, 0, 0,25, 0, 0,20, 0, 0,15, 0
             db   0,10, 0, 0, 5, 0, 0, 0, 0
     
       pos   dw  MINYCORD
       pos2  dw  MAXYCORD-MINYCORD+120
  incrdecr   db  0



DATA ENDS

CODE SEGMENT
     ASSUME CS:CODE,DS:DATA

main proc
      mov dx,seg DATA
      mov ds,dx
wesc: mov cx,NCOLORS    ;number of colors of the copperlist
      mov si,offset copperbar1 ;load in si palette offset!! :)
      call wvr        ;wait for vertical retrace  (on the top of screen)!!
      call intercam   ;OK! this checks if the bar is going up or down, eh!
      mov bx,pos
      call anima      ;he! here we set the y coord of the bar!
      call bar
      mov cx,NCOLORS
      mov si,offset copperbar2
      mov bx,pos2
      call anima
      call bar
      in al,60h       ;Hey!, ESC key!
      cmp al,1
      jnz wesc
      call msdos      ;bye!

main endp     

wvr proc             ;wait for horizontal retrace
      mov dx,3dah       
dwv:  in al,dx        
      test al,8      ;lets look in bit 3
      jz dwv         ;ok, if retrace isnt on the top...  wait it!
      ret
wvr endp

whr proc            ;wait for vertical!
      mov dx,3dah
dwh:  in al,dx
      test al,1
      jnz dwh
dwh2: in al,dx      
      test al,1
      jz dwh2
      ret
whr endp


msdos proc
      mov ax,4c00h    ;mhh, not need explanation
      int 21h
msdos endp

intercam proc ;procedure which increments/decrements pos
       cmp incrdecr,0     ;0=incrementing, 1=decrementing
       jz incre           ;okey, we are increm.
decre: sub pos,4          ;okey, we are decrem. 4 pixels each time
       add pos2,8
       cmp pos,MINYCORD         ;we decrement until pos 50
       jz tog1            ; lets toggle
       ret
incre: add pos,4
       sub pos2,8
       cmp pos,MAXYCORD
       jz tog2
       ret
tog1:  mov incrdecr,0
       ret
tog2:  mov incrdecr,1
       ret
intercam endp

anima proc ;in BX the number of lines
                     ; we wait until the desired y coord!
bucl:  call whr
       dec bx
       jnz bucl
       ret
anima endp

bar PROC  ;in SI the bar colors, and in CX number of colors
copp:     call whr    ;yes i know, this is unnecesary but...!
                          ; aha! here is the Trick!
          cli                         ; It's quite good 2 disable int. here
          mov       ax,0
          mov       dx,3c8h           ;PEL Adress register 
          out       dx,al             ;we put color 0
          inc       dx                ;ú3d9h - PEL Color register
          
          mov       al,[si]           ;We put the R,G and B
          out       dx,al 
          inc       si
          mov       al,[si]
          out       dx,al
          inc       si
          mov       al,[si]
          out       dx,al
          inc       si
          sti
     
      dec cx          ; lets put the next color
      jnz copp          
      ret
bar ENDP      

CODE ENDS
     END main

