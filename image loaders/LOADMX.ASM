;***************************************************************************
;********************* Raw loader V.2.0 (in mode X) ************************
;***************************************************************************
;********************* by Sarwaz/mistery ***********************************
;***************************************************************************

          SEQC_ADRR equ 3c4h
          CRTC_ADRR equ 3d4h



DATA SEGMENT
   IMAGE DB 64800 DUP (?)
   filenam  db 'dib1.raw',0
   palname db 'dib1.pal',0
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
  call init_modex
  call putimage
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

waitkey proc
kwait:  in al,60h
        cmp al,1
        jnz kwait
waitkey endp

putimage proc
        mov ax,SEG DATA
        mov ds,ax
        xor ax,ax
        mov dx,3c8h   ;First We have to set the Palette
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
        jnz @@pal                     ;Now we have to copy from mem to scr
        
        lea si,[image+800]  ;In DS:SI the image - In ES:DI the scr
        mov bx,si      ;We use Bx like a tmp register ;-)
        mov ax,0a000h
        mov es,ax
        xor di,di
        mov dx,3c4h
        mov ax,0102h
        out dx,ax
        mov ch,4     ;Four times, because we have four planes
$$1:  
        movsb
        ;mov cl,DS:[SI]
        ;mov ES:[DI],cl
        ;inc di
        add si,3
        cmp di,16000
        jnz $$1

        shl ah,1
        cmp ah,16
        jz finish
        out dx,ax
        xor di,di
        inc bx
        mov si,bx
        dec ch
        jnz $$1
finish: ret
putimage endp

init_modex PROC ;320x200x256 4 bit planes
;       mov ax,13h ;First We initialize the 320x200x256 color mode
;       int 10h
;       mov dx,SEQC_ADRR
;       mov ax,0604h
;       out dx,ax  ;This disables CHAIN-4
;       mov dx,CRTC_ADRR
;       mov ax,0014h  ;Disables dword mode
;       out dx,ax
;       mov ax,0e317h
;       out dx,ax  ;Sets the byte mode

                      ;Lets Clean the screen
;       mov ax,0F02h ;This will enable the 4 bit planes (for more speed in 
;       mov dx,SEQC_ADRR            
;       out dx,ax    ;the cleaning operation)
;       mov ax,0a000h
;       mov es,ax
;       xor bx,bx
;       xor ax,ax
;       mov cx,64000 ;All the segment ;)
;@@1:
;       mov es:[bx],al
;       inc bx
;       loop @@1
;       ret

mov dx,3d4h
mov al,11h
out dx,al
mov dx,3d5h
in al,dx
and al,7fh
out dx,ax
 
mov dx,3c2h
mov al,0e3h
out dx,ax

mov dx,3d4h
mov ax,5f00h
out dx,ax
mov ax,4f01h
out dx,ax
mov ax,5002h
out dx,ax
mov ax,8203h
out dx,ax
mov ax,5404h
out dx,ax
mov ax,8005h
out dx,ax
mov ax,0d06h
out dx,ax
mov ax,3e07h
out dx,ax
mov ax,0008h
out dx,ax
mov ax,4109h
out dx,ax
mov ax,0ea10h
out dx,ax
mov ax,0ac11h
out dx,ax
mov ax,0df12h
out dx,ax
mov ax,2813h
out dx,ax
mov ax,0014h
out dx,ax
mov ax,0e715h
out dx,ax
mov ax,0616h
out dx,ax
mov ax,0e317h
out dx,ax

mov dx,3c4h
mov ax,0101h
out dx,ax
mov ax,0604h
out dx,ax

mov dx,3ceh
mov ax,4005h
out dx,ax
mov ax,0506h
out dx,ax
mov ax,0506h
out dx,ax
ret
init_modex endp



CODE ENDS       
     END main

