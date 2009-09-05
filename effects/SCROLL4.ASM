;***************************************************************
;** Scroll Up-Down in Modex 320x200 - Coded by Sarwaz/MiSTERY **
;***************************************************************

.286

;Constants 

          SEQC_ADRR equ 3c4h
          CRTC_ADRR equ 3d4h



STACK SEGMENT STACK
          db 100 dup (?)
STACK ENDS

DATA SEGMENT
          merror db 'Error Open Archive!!'
          merror2 db 'Error Reading Archive!!'
          filenam db 'dib1.raw',0
          image   db 64800
          CORD_X dw 0
          CORD_Y dw 0
          COLOR  db 15
          ;Litte Table With the position of each letter
   LettPos dw 00000,00032,00064,00096,00128,00160,00192,00224,00256,00288
           dw 12800,12832,12864,12896,12928,12960,12992,13024,13056,13088
           dw 25600,25632,25664,25696,25728,25760,25792,25824,25856,25888
           dw 38400,38432,38464,38496,38528,38560,38592,38624,38656,38688
           dw 51200,51232,51264,51296,51328,51360,51392,51424,51456,51488

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
       call load
       call putpal
       
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
       xor bx,bx
       xor ax,ax
       mov cx,64000 ;All the segment ;)
@@1:
       mov es:[bx],al
       inc bx
       loop @@1
       ret
init_modex endp
                     
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

writeletter proc  ; In LetX,LetY the Position of the letter. and Letter the
                 ; obviusly character
        push ax 
        push bx 
        push cx 
        push di 
        push si
        mov di,Letter
        shl di,1       ;We have to multiply by 2 because LettPos are Words
        mov ax,0a000h
        mov es,ax
        
        mov ax,320/4   ;Here we calculate the offset of the screen pos
        mov bx,LetY
        mul bx         ;80*y+x/4
        mov bx,LetX
        shr bx,2
        add bx,ax
        
        mov si,LettPos[di]
        mov ax,si
        push ax
        mov ch,40 ;Number of lines of the letter
@@1:
        mov cl,32 ;Number of Rows of the letter
@@2:
        push cx
        mov cl,ds:[image+800+si]
                              ;Now we have to select the correct bitplane
       mov dx,SEQC_ADRR
       mov ax,ds:CORD_X
       and al,3
       mov cl,al
       mov ah,1
       shl ah,cl
       mov al,2
       out dx,ax
       mov es:[bx],cl     ;After the plane selection we can put the pixel
        
       inc si
       inc bx
       pop cx
       dec cl
       jnz @@2
       add bx,288
       pop ax
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


