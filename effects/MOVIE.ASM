;**************************************************************************
;****** Scroll UPWARDS (modex) by Sarwaz/MiSTERY **************************
;**************************************************************************

;Directives
.286



;CONSTANTS
	SEQC_ADRR equ 3c4h
	CRTC_ADRR equ 3d4h
	ENDCODE   equ 0    ;The code of the end of text
	TENDCODE  equ 1    ;The code of the end of all text
	FNTADRS   equ 800  ;The offset of the picture in Freemem
	FNTHEIGTH equ 20
	FNTWIDTH  equ 16
	FNTLINE   equ 320-FNTWIDTH
	SCRLINE   equ 80-(FNTWIDTH/4)
	SPLITSCR  equ 00FFh
	LOGOFFSET equ (320*60)+800

STACK SEGMENT STACK
	db 200h DUP (0)
STACK ENDS

CODE SEGMENT 
	ASSUME CS:CODE,DS:CODE,SS:STACK
;Includes-
include inc.inc  ;Rutines from Unreal/S!P and from me (of coz!!) :)


;Variables
OKY       db 0
text label byte     
include text.inc

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

;copper db 0,0,0,1,1,1,2,2,2,3,3,3,4,4,4,5,5,5,6,6,6,7,7,7,8,8

Screen_Off dw 0
Let_Off    dw 0
Scr_Plane  db 0
Scr_tmp    dw 0
Start_adress dw ((SPLITSCR+1)/2)*80  ;The same valour of split screen
Fnt_Point  dw 0
Fnt_Point_tmp dw 0
Adress_Count db 0
tmp1      dw 0

;Macros
PutLogo MACRO
	local @@logo
	;mov si,OFFSET freemem+LOGOFFSET
	
	mov ah,1 ;First the plane 1
	xor bx,bx
	mov dx,SEQC_ADRR
	mov al,02h

np:       
	xor di,di ;Screen Offset 0, because we are writting on a split scr.
	mov si,OFFSET freemem+LOGOFFSET
	add si,bx
	out dx,ax
	mov cx,5120
@@logo:          
	movsb          
	add si,3
	dec cx
	jnz @@logo
	shl ah,1
	inc bl
	cmp bl,4
	jnz np
	ENDM


SetStartAdress MACRO St_adr ;Sets the start Adress of the 320x200 window
	mov dx,CRTC_ADRR
	mov cx,St_adr
	mov ah,ch
		;byte ptr [St_adr]
	mov al,0ch
	out dx,ax
	mov ah,cl
		;byte ptr [St_adr+1]
	mov al,0dh
	out dx,ax
	ENDM

WaitVRet  MACRO
	local dwait,dwait2
	mov dx,3dah
dwait:    in al,dx
	test al,8
	jnz dwait
dwait2:   in  al,dx
	test al,8
	jz dwait2
	ENDM

GetSOff MACRO   x,y,whereoff,plane ;Gets the offset on the Vram of X,Y.
      mov cx,x                       ;And the plane which shuld be active
      and cl,3
      mov plane,cl
      mov ax,y
      mov bx,y
      shl ax,6             ;y*64
      shl bx,4             ;y*16
      add bx,ax            ;y*64+y*16=80*y
      mov ax,x
      shr ax,2
      add bx,ax            ;y*80+x/4
      mov whereoff,bx
      ENDM

SelPlane MACRO NumPlane  ;selects a plane (only one plane at the time)
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
      LOCAL err,endie,cont,ini,adj,err2
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
      and PlaneInOut,3
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

WriteTextLine MACRO NumLine,Scr_Off,WhereText,adder
	local @@1,cont,endtext
	mov dx,Scr_Off
	xor si,si
@@1:      
	xor ax,ax
	lea bx,WhereText
	add bx,adder
	mov al,[bx+si]
	push si
	push dx
	GetLetOff al,Let_Off,OKY 
	dec OKY
	jnz cont
	jmp endtext
cont:
	WriteLine dx,Let_Off,0,Numline
	pop dx
	add dx,FNTWIDTH/4
	pop si
	inc si
	jmp @@1
endtext:
	ENDM



WriteLine MACRO ScrOffset,LetOffset,@plane@,line ;Writes a line of text
	xor bx,bx
	mov di,ScrOffset
	mov bl,line
	mov ax,320
	mul bx
	mov bx,ax
	mov si,LetOffset
	add si,bx
	mov bl,@plane@
	
	REPT FNTWIDTH
	SelPlane bl
	mov al,ds:[freemem+FNTADRS+si]
	mov es:[di],al
	inc si
	NextPlane bl,di
	ENDM
	ENDM
whr1 MACRO 
	local dw
	mov dx,3dah
dw:       
	in al,dx
	test al,1
	jnz dw
	ENDM

whr2 MACRO
	local dw2
	mov dx,3dah
dw2:      
	in al,dx
	test al,1
	jz dw2
     ENDM

start:              ;Ok, Lets begin
	SetSegs 
	init_modex                    ; First we set the video mode
				 
			;Now we sets the Line compare to 128
	mov dx,CRTC_ADRR
	mov al,18h
	mov ah,SPLITSCR
	out dx,ax
			;And the ninth and tenth bits to 0
	mov al,07h         ;bit 4 of the overflow put to 0
	mov ah,0Fh
	out dx,ax

	mov al,09h    ;bit 6 of the Max scan Line put to 0
	mov ah,1      ;here, 0=400 pixels 1=200 pixels
	out dx,ax

	;mov dx,CRTC_ADRR  ;This little code gets 400 pixel heigh screen
	;mov ax,4009h
	;out dx,ax


	OpenF cs,fntname,handle        ;Open the file
	REadF 64800,ds,freemem,handle ;We read it and put it on the freemem
	CloseF handle                 ;And we have to close
	
	SetPalette cs,Freemem+32      ;Ok, now we set the fnt palette
	SetStartAdress Start_Adress
	putlogo
	
	mov Word Ptr Fnt_Point,0
make_scr:
	mov dx,3dah
dw1:      
	in al,dx
	test al,8
	jnz dw1
	;WaitVRet   ;After this begins the scroll, but here you can put too
		 ;Other effects which will execute with the scrolly
	SetStartAdress Start_Adress
	cmp BYTE PTR Adress_Count,20 ;and fgsds,15
	jge cont@1
	jmp cont@3
adj@@1:
	mov WORD PTR Fnt_Point,0
	jmp cont@3

cont@1:          
	mov BYTE PTR Adress_Count,0
	add Fnt_Point,21
	cmp Fnt_Point,TOTALINE*21
	jge adj@@1
cont@3:          
	mov ax,((SPLITSCR+1)/2)*80 ;The end of the Visible window
	add ax,Start_Adress
	WriteTextLine Adress_Count,ax,text,Fnt_Point
	cmp WORD PTR Start_Adress,FNTHEIGTH*80
	jge cont@2
	jmp nowrite
cont@2:          
	mov ax,Start_Adress
	sub ax,FNTHEIGTH*80
	add bx,80*FNTHEIGTH
	WriteTextLine Adress_Count,ax,text,Fnt_Point   ;Fnt_Point
	;sub Fnt_Point_tmp,si
nowrite:          
	cmp WORD PTR Start_Adress,(FNTHEIGTH+SPLITSCR)*80
	jnz increment
	mov Start_Adress,(((SPLITSCR+1)/2)-1)*80
increment:
	add Start_Adress,80
	inc Adress_Count
	in al,60h
	dec al
	jnz dummie   ;Here we puts the copperlist
	jmp endd
dummie:
	cli
	mov dx,3dah
dw2:
	in al,dx
	test al,8
	jz dw2
	mov ch,2
	mov cl,0
mak_cop:  whr1
	mov dx,3c8h
	mov al,0
	out dx,al
	inc dx
	push dx
	whr2
	pop dx
	mov al,cl
	out dx,al
	;xor al,al
	out dx,al
	out dx,al
	whr1
	whr2
	inc cl
	cmp cl,64
	jnz mak_cop
	dec cl
mak_cop2: whr1 
	mov dx,3c8h
	mov al,0
	out dx,al
	inc dx
	push dx
	whr2
	pop dx
	mov al,cl
	out dx,al
	;xor al,al
	out dx,al
	out dx,al
	whr1
	whr2
	sti
	dec cl
	jnz mak_cop2

	mov dx,3c8h
	mov al,0
	out dx,al
	inc dx
	mov al,0
	out dx,al
	out dx,al
	out dx,al
	jmp make_scr
endd:
	SetMode 3h
	mov ax,4C00h
	int 21h

Freemem label byte  ;Here begins the free memory

CODE ENDS
END start
