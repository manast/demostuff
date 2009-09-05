;***************************************************************************
;********************* Raw loader V.1.0 ************************************
;***************************************************************************
;********************* by Sarwaz/mistery ***********************************
;***************************************************************************

DATA SEGMENT
   IMAGE DB 64000 DUP (?)
   filenam  db 'dib1.raw',0
   handle1 dw 0
   merror db 'ERROR opening archive!!$'
   merror2 db 'ERROR reading archive!!$'
   good    db 'Archive loaded correctly!!$'
DATA ENDS

STACK SEGMENT STACK
      DB 128 DUP (?)
STACK ENDS

CODE SEGMENT
  ASSUME CS:CODE,DS:DATA,SS:STACK

main PROC
  call load
  call setmode19
  call putimage
  call waitkey
  call msdos
main endp

msdos proc
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
         mov cx,64000        ;yep, 64000 bytes (320x200x256)
         lea dx,image        ;image offset. aha!
         int 21h             ;reading!! in ax number of read bytes
         jc error2
         jmp fin             ;OK!

error:   mov ax,3
         int 10h
         mov dx,OFFSET merror;nothing yet
         mov ah,9
         int 21h
         call msdos

error2:  mov ax,3
         int 10h
         mov dx,OFFSET merror2 ;nothing yet
         mov ah,9
         int 21h
         call msdos

fin:         ;correctly loaded!
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

putimage proc
        mov cx,64000          ;bytes to copy!!
        lea si,image          ;effective adress on si
        mov dx,0a000h
        mov es,dx             ;In es, video segment
        xor di,di             
        rep movsb   
        ret
putimage endp



CODE ENDS       
     END main

