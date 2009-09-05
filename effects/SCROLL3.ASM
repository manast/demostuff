;***************************************************************************
;********************* Scroll V0.3 *****************************************
;***************************************************************************
;********************* by Sarwaz/mistery ***********************************
;***************************************************************************
;        --/\/\-------- Do you Want Contact with me?  --------/\/\--
;        --/\/\-------- Manuel Astudillo              --------/\/\--
;        --/\/\-------- Calle Buganvillas. Casa Calma --------/\/\--
;        --/\/\-------- San Pedro Alcantara. ESPA¥A   --------/\/\--
;***************************************************************************
; ATENTION! This is a MiSTERY Internal FILE - Delete it if you are'nt member
;***************************************************************************
;Finished the 1 of Octuber 1995
          YSCROLL EQU 199-40
          Npixel  equ 4  ;This will be in short, the speed of the scrolly

DATA SEGMENT
   IMAGE DB 64800 DUP (?)
   filenam  db 'dib1.raw',0
   handle1 dw 0
   merror db 'ERROR opening archive!!$'
   merror2 db 'ERROR reading archive!!$'
   message db 'HEY[[YOU[ARE[WATCHING[A[SCROLL[CODED[BY[SARWAZ[[[[['
           DB 'LETS[BEGIN[WITH[SOMETHING[BORING[[[[THE[GREETINGS[['
           DB '[[[ATLANT[WALLY[DARKROSE[FLY[BARRA[[[AND[TO[ALL[MISTERY['
           DB 'CREW[[[[[[[[[THE[FEAR[[[[HERE[YOU[HAVE[A[NICE[SCROLLY[[['
           DB 'HOPE[YOU[LIKE[IT[[[[[[[[[[$'
   
   Letter dw 0
          ;Litte Table With the position of each letter
   LettPos dw 00000,00032,00064,00096,00128,00160,00192,00224,00256,00288
           dw 12800,12832,12864,12896,12928,12960,12992,13024,13056,13088
           dw 25600,25632,25664,25696,25728,25760,25792,25824,25856,25888
           dw 38400,38432,38464,38496,38528,38560,38592,38624,38656,38688
           dw 51200,51232,51264,51296,51328,51360,51392,51424,51456,51488

DATA ENDS

STACK SEGMENT STACK
      DB 128 DUP (?)
STACK ENDS

CODE SEGMENT
  ASSUME CS:CODE,DS:DATA,SS:STACK
main PROC
  call load
  call setmode19
  call putpal
  call scroll
  call msdos
main endp

msdos proc
       mov ax,3
       int 10h
       mov ax,4C00h
       int 21h
msdos endp


load PROC
         
         mov ah,3dh
         mov al,00           ;read mode
         mov dx,DATA
         mov ds,dx
         lea dx,filenam      ;we get the offset of the file to read
         int 21h             ;eh!
         jc error            ;mmh!, bad filename!
         
         xchg ax,bx          ;lets put file handle in bx
         mov ah,3fh
         mov cx,64800        ;yep, 64000 bytes (320x200x256)
         lea dx,image        ;image offset. aha!
         int 21h             ;reading!! in ax number of read bytes
         jc error2
         jmp fin            ;OK!

error:   mov ax,3
         int 10h
         mov dx,OFFSET merror;nothing yet
         mov ah,9
         int 21h
         call msdos

error2:  mov ax,3
         int 10h
         mov dx,OFFSET merror2 ;nothing yet
         mov ah,3eh
         int 21h ;Close archive
         mov ah,9
         int 21h
         call msdos

fin:         ;correctly loaded!
         mov ah,3eh
         int 21h ;close archive
         ret

load endp

setmode19 proc
        mov ax,13h
        int 10h      ;do you know what is this? :)
        ret
setmode19 endp

putpal proc
        mov ax,SEG DATA
        mov ds,ax
        xor ax,ax
        mov dx,3c8h
        out dx,al
        inc dx
        lea bx,[image+32]
        xor si,si
@@pal:
        mov al,ds:[bx+si]
        out dx,al
        mov al,ds:[bx+si+1]
        out dx,al
        mov al,ds:[bx+si+2]
        out dx,al
        add si,3
        cmp si,768
        jnz @@pal
        ret
putpal endp

scroll proc
          JMP INIT
forcexit:           
                     ;First lets put the stack in order, hehe!
          pop dx
          pop si
          ret

INIT:     mov ax,0a000h
          mov es,ax
          xor si,si
          xor ax,ax
@@1:      
          mov al,ds:message[si]
          cmp al,36
          jz INIT
cont:     sub al,65
          mov bp,ax
          shl bp,1
          push si
          xor dx,dx
oneletter:                
          push dx
          in al,60h
          cmp al,1
          jz forcexit
          ;Now we move the "block" of the scroll to the left N pixels
          push ds
          mov dx,0a000h
          mov ds,dx
          mov es,dx
          mov si,YSCROLL*320+Npixel
          mov di,YSCROLL*320
          mov dx,3dah

dwait:    in  al,dx  ;here we must wait the retrace
          test al,8
          jnz dwait
dwait2:   in al,dx
          test al,8
          jz dwait2
          
          mov al,40
@@@1:
          mov cx,(320-Npixel)/2
          REP MOVSW ;Yeah, Here is the key!
          add si,Npixel
          add di,Npixel
          dec al
          jnz @@@1
          
          pop ds
          pop dx
          mov ch,40
          mov bx,YSCROLL*320+316
          mov si,ds:Lettpos[bp]
          add si,dx
writecol:          
          mov ax,WORD PTR ds:image[800+si]
          mov es:[bx],ax
          mov ax,WORD PTR ds:image[800+si+2]
          mov es:[bx+2],ax
          add bx,320
          add si,320
          dec ch
          jnz writecol
          add dl,4
          cmp dl,32
          jz endbucle
          jmp oneletter
endbucle:          
          pop si
          inc si
          jmp @@1
endscroll:          
          ret
scroll endp


CODE ENDS       
     END main

