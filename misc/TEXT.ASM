;***************************************************************************
;********************* Text Routines ***************************************
;***************************************************************************
;********************* by Sarwaz/mistery ***********************************
;***************************************************************************
.model large
DATA SEGMENT 
   IMAGE DB 64800 DUP (?)
   block db 12760 dup (?)
   filenam  db 'dib1.raw',0
   handle1 dw 0
   merror db 'ERROR opening archive!!$'
   merror2 db 'ERROR reading archive!!$'
   mes1 db 'SARWAZ$'
   mes2 db 'ROCKS$'
   mes3 db 'FOREVER$'
   
   MesX dw ?
   MesY dw ?
   LetX dw ?       
   LetY dw ?
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
  mov MesX,50
  mov MesY,50
  lea bx,mes1
  call putmessage
  mov MesX,80
  mov MesY,90
  lea bx,mes2
  call putmessage
  mov MesX,60
  mov MesY,130
  lea bx,mes3
  call putmessage
  call waitkey
  call msdos
main endp

msdos proc
       mov ax,3
       int 10h
       mov ax,4C00h
       int 21h
       ret
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

waitkey proc
kwait:  in al,60h
        cmp al,1
        jnz kwait
waitkey endp

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

writeletter proc  ; In LetX,LetY the Position of the letter. and Letter the
                 ; obviusly character
        push ax 
        push bx 
        push cx 
        push di 
        push si
        mov di,Letter
        shl di,1   ;We have to multiply by 2 because LettPos are Words
        mov ax,0a000h
        mov es,ax
        mov bx,LetY
        mov ax,320
        mul bx
        add ax,LetX
        mov bx,ax
        mov si,LettPos[di]
        mov ax,si
        mov ch,40 ;Number of lines of the letter
@@1:
        mov cl,32 ;Number of Rows of the letter
@@2:
        push cx
        mov cl,ds:[image+800+si]
        mov es:[bx],cl
        inc si
        inc bx
        pop cx
        dec cl
        jnz @@2
        add bx,288
        add ax,320
        mov si,ax
        dec ch
        jnz @@1
        pop si
        pop di
        pop cx
        pop bx
        pop ax
        ret
writeletter endp

putmessage proc  ;In MesX,MesY the coords of the text
                 ;In Bx the Offset OF the Message
        xor si,si
        xor cx,cx
        mov dx,MesX
        mov LetX,dx
        mov dx,MesY
        mov LetY,dx
@@@1:     
        mov cl,ds:[bx+si]
        sub cl,65
        mov letter,cx
        call writeletter
        add LetX,32
        inc si
        cmp byte PTR ds:[bx+si],36
        jnz @@@1
        ret
putmessage endp

CODE ENDS       
     END main

