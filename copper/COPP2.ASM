;******** COPPER BARS II ********
;******** By Sarwaz/MRY  ********
;********************************

NCOLORS   equ 23
DEFCOLOR  equ 0
DEFPOS    equ 199

STACK SEGMENT STACK
          db 100 DUP (?)
STACK ENDS
DATA SEGMENT
barcolor db 0,0,0,10,0,0,15,0,0,20,0,0,25,0,0,30,0,0,35,0,0,40,0,0
         db 45,0,0,50,0,0,55,0,0,60,0,0,55,0,0,50,0,0,45,0,0,40,0,0
         db 35,0,0,30,0,0,25,0,0,20,0,0,15,0,0,10,0,0,0,0,0

sinuwave db   164,164,164,164,164,164,164,164,163,163,163,163,163,162,162,162
         db   162,161,161,161,160,160,159,159,159,158,158,157,157,156,156,155
         db   155,154,153,153,152,152,151,150,150,149,148,148,147,146,146,145
         db   144,144,143,142,141,141,140,139,138,137,137,136,135,134,134,133
         db   132,131,130,130,129,128,127,127,126,125,124,123,123,122,121,120
         db   120,119,118,118,117,116,116,115,114,114,113,112,112,111,111,110 
         db   109,109,108,108,107,107,106,106,105,105,105,104,104,103,103,103 
         db   102,102,102,102,101,101,101,101,101,100,100,100,100,100,100,100 
         db   100,100,100,100,100,100,100,100,101,101,101,101,101,102,102,102 
         db   102,103,103,103,104,104,105,105,105,106,106,107,107,108,108,109 
         db   109,110,111,111,112,112,113,114,114,115,116,116,117,118,118,119
         db   120,120,121,122,123,123,124,125,126,127,127,128,129,130,130,131
         db   132,133,134,134,135,136,137,137,138,139,140,141,141,142,143,144
         db   144,145,146,146,147,148,148,149,150,150,151,152,152,153,153,154
         db   155,155,156,156,157,157,158,158,159,159,159,160,160,161,161,161
         db   162,162,162,162,163,163,163,163,163,164,164,164,164,164,164,164
         db   164
DATA ENDS

CODE SEGMENT
ASSUME CS:CODE,SS:STACK,DS:DATA
WRITELN MACRO _string
local _afterstring
          call _afterstring
          db _string,13,10,'$'
_afterstring:
          mov ah,9
          pop dx
          int 21h
          ENDM
wvr MACRO             
local dwv,dwv2          
           mov dx,3dah
dwv:       in al,dx
           test al,8
           jnz dwv
dwv2:      in al,dx        
           test al,8      ;lets look in bit 3
           jz dwv2         ;ok, if retrace isnt on the top...  wait it!
           ENDM

whr MACRO          
local dwh,dwh2          
          mov dx,3dah
dwh:      in al,dx
          test al,1
          jnz dwh
dwh2:     in al,dx      
          test al,1
          jz dwh2
          ENDM



MAIN PROC
          mov ax,3h
          int 10h
          mov ax,SEG CODE
          mov ds,ax
          writeln 'Sarwaz Proudly Presents: COPPER BARS II'
          writeln 'Example Effect for MiSTERY'
          writeln '************ PRESS ESPACE *************'
keypres:  in al,60h
          cmp al,1
          jnz keypres
          mov ax,13h ;Lets start 320x200x256
          int 10h
          writeln 'THE REAL RASTER COPPER USING THE METHOD:           LOOK FIRST DO THEN'
          writeln '----------------------------------------'
          writeln '     M     M     RRRRRR     Y     Y          MMMMMMM     R    R      YYYYY           M MMM M     R R R          Y            M  M  M     R    R      YYY'
          mov bx,offset sinuwave
          mov si,256
start:    dec si
          dec si
          dec si
          dec si
          jz adjust
@@1:      mov cl,200
          wvr
lookline: cmp cl,[bx][si]
          jz drawbar
          whr
          dec cl
          jnz lookline
          in al,60h
          cmp al,1
          jnz start
          jmp finish
adjust:   mov si,256
          jmp @@1
drawbar:  
          push bx
          push si
          mov ax,SEG DATA
          mov ds,ax
          mov bx,offset barcolor          
          xor si,si
copline:  mov dx,3c8h
          mov al,0
          out dx,al
          inc dx                    
          mov al,[bx]
          out dx,al
          inc bx
          mov al,[bx]
          out dx,al
          inc bx
          mov al,[bx]
          out dx,al
          inc bx
          dec cx
          inc si
          whr
          cmp si,23
          jnz copline
          pop si
          pop bx
          jmp lookline
finish:             
          include exit.asm

MAIN ENDP

CODE ENDS

END MAIN

