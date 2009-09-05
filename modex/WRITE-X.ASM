;**************************************************************************
;****** WriteText (modex) by Sarwaz/MiSTERY *******************************
;**************************************************************************

;Directives
.286



;CONSTANTS
          SEQC_ADRR equ 3c4h
          CRTC_ADRR equ 3d4h
          ENDCODE   equ 0    ;The code of the end of text
          FNTADRS   equ 800  ;The offset of the picture in Freemem
          FNTHEIGTH equ 20
          FNTWIDTH  equ 16
          FNTLINE   equ 320-FNTWIDTH
          SCRLINE   equ 80-(FNTWIDTH/4)


STACK SEGMENT STACK
          db 200h DUP (0)
STACK ENDS

CODE SEGMENT 
          ASSUME CS:CODE,DS:CODE,SS:STACK
;Includes-
include inc.inc  ;Rutines from Unreal/S!P and from me (of coz!!) :)


;Variables
OKY       db 0
text      db 'FAST WRITER RUTINES?',0
text2     db 'IN MODEX?',0
text3     db 'YEAH @<<<<<<',0
text4     db 'BY SARWAZ OF COURSE@',0
handle    dw 0
fntname   db '16x20fnt.raw',0
FntOffset dw 0000h,0010h,0020h,0030h,0040h,0050h,0060h,0070h,0080h,0090h
          dw 00a0h,00b0h,00c0h,00d0h,00e0h,00f0h,0100h,0110h,0120h,0130h
          dw 1900h,1910h,1920h,1930h,1940h,1950h,1960h,1970h,1980h,1990h
          dw 19a0h,19b0h,19c0h,19d0h,19e0h,19f0h,1a00h,1a10h,1a20h,1a30h
          dw 3200h,3210h,3220h,3230h,3240h,3250h,3260h,3270h,3280h,3290h
          dw 32a0h,32b0h,32c0h,32d0h,32e0h,32f0h,3300h,3310h,3320h,3330h
          dw 4b00h,4b10h,4b20h,4b30h,4b40h,4b50h,4b60h,4b70h,4b80h,4b90h
          dw 4ba0h,4bb0h,4bc0h,4bd0h,4be0h,4bf0h,4c00h,4c10h,4c20h,4c30h

Screen_Off dw 0
Let_Off    dw 0
Scr_Plane  db 0
Scr_tmp    dw 0


;Macros

GetSOff MACRO   x,y,whereoff,plane ;Gets the offset on the Vram of X,Y.
      mov cx,x                       ;And the plane which shuld be active
      and cl,3
      mov plane,cl
      mov ax,y
      mov bx,y
      shl ax,6             ;y*64
      shl bx,4             ;y*16
      add bx,ax            ;y*64+y*16=80 
      mov ax,x
      shr ax,2
      add bx,ax            ;y*80+x/4
      mov whereoff,bx
      ENDM

SelPlane MACRO NumPlane  ;selects a plane (only one plane)
          push cx
          mov cl,Numplane
          mov ah,1
          shl ah,cl
          mov al,02h
          mov dx,SEQC_ADRR
          out dx,ax
          pop cx
          ENDM

GetLetOff MACRO letter,letOffset,OK  ;The ascii code of a letter
      LOCAL err,endie,cont,ini,adj
      jmp ini
adj:  
      mov al,91
      jmp cont
ini:  mov OK,0
      mov al,letter
      cmp al,ENDCODE    
      jz err
      cmp al,32 ;SPACE CODE
      jz adj
cont: sub al,48         ;Because our font begins at ascii code 48
      shl al,1          ;the table with fnt offset are in words
      mov si,ax
      mov bx,word ptr cs:[FntOffset+si]
      mov letOffset,bx
      jmp endie
err:  
      mov OK,1
endie:
      ENDM

NextPlane MACRO  PlaneInOut,SOFF ;Increments the plane and the ScrOffset if necesary
      local endie
      inc planeInOut
      and PlaneInOut,3  ;Other posibly: rol al,1 (al=00010001b) and adc dl,0
      ;dec SOFF
      jnz endie
      inc SOFF
endie:
      ENDM

SetSegs MACRO  ;Little Macro with sets the segs correctly
      mov ax,0a000h
      mov es,ax
      mov ax,cs
      mov ds,ax
      ENDM
WriteText MACRO x,y,WhereText ;Writes a text from WhereText to x,y scr. coord.
          local @@1,endtext,cont
          GetSOff x,y,Screen_Off,Scr_Plane
          xor si,si
@@1:
          xor ax,ax
          mov al,[WhereText+si]
          push si
          GetLetOff al,Let_Off,OKY
          dec OKY
          jnz cont
          jmp endtext
cont:
          ;mov Let_Off,16
          WriteLet Screen_Off,Let_Off,Scr_Plane
          add Screen_Off,FNTWIDTH/4 ;div by four because each pos is 4 pix
          pop si
          inc si
          jmp @@1
endtext:
          ENDM


WriteLet MACRO ScrOffset,LetOffset,@Plane@ ;This Writes a letter
      local @@1,@@2,cont
      mov bl,@Plane@
      mov si,LetOffset
      add si,OFFSET freemem+FNTADRS
      mov di,ScrOffset
      mov ch,FNTHEIGTH
@@2:       
      ;mov cl,FNTWIDTH
      ; @@1:
      REPT FNTWIDTH
      SelPlane bl
      mov al,byte ptr ds:[si]
      mov byte PTR es:[di],al
      inc si
      ;movsb
      NextPlane bl,di
      
      ENDM
      ;dec cl
      ;jnz @@1
      add si,FNTLINE
      add di,SCRLINE    ;80-76=4, 4*4Planes=16 Pixels=FntWidth
      mov bl,@plane@
      dec ch
      jz cont
      jmp @@2
cont:
      ENDM

start:              ;Ok, Lets begin
          SetSegs 
          init_modex                    ; First we set the video mode
          mov dx,CRTC_ADRR
          mov ax,4009h
          out dx,ax
          OpenF cs,fntname,handle        ;Open the file
          REadF 64800,ds,freemem,handle ;We read it and put it on the freemem
          CloseF handle                 ;And we have to close
          
          SetPalette cs,Freemem+32      ;Ok, now we set the fnt palette
          WriteText 0,0,text       ;Great Macro, isnt it?
          WriteText 0,30,text2
          WriteText 0,60,text3
          WriteText 0,90,text4
          Call Wait4Esc
          SetMode 3h
          mov ax,4C00h
          int 21h

Freemem label byte  ;Here begins the free memory

CODE ENDS
END start

