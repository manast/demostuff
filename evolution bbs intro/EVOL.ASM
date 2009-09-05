;**************************************************************************
;***** Evolution BBS intro - Coded by Sarwaz / MiSTERY ********************
;**************************************************************************
;NOTE:Embarrashingshittyfukinunderstandablelamecode



;Constants
	DelayConst      equ 255 ;For Constant delay (not default choice)
	OnlyUpOff       equ 110
	estabilizeFactor equ 281
	mojon           equ 134*320
	FiasCo          equ 48 ;48 is 0's ascii code
	MaskColor       equ 0
	YLogoLines      equ 80
	XLogoLines      equ 160
	Logo            equ XLogoLines*YLogoLines
	MaxSinuGrade    equ 50
	wobspeed        equ 3
	Logo1PosY       equ 50
	Logo1Off        equ 15*320 ;Offset on Video Ram
	Logo2Off        equ 264 ;Offset on Picture and VRAM
	Logo2width      equ 56
	Xcentre         equ 160
	Ycentre         equ 100
	Nstars          equ 160
	TopText         equ 140 ;The highest Y cord of text
	FntHeigth       equ 20

stack segment stack
	db 100h DUP (?)
stack ends



code SEGMENT PARA
	ASSUME CS:CODE,DS:CODE,SS:STACK
.386

include inc.inc
;Lets Define a couple of variables

LogoSinus label byte
include sintabl1

StarSinus label byte
include sintabl2

;We have 3 stars Bank - 160 stars each - so each bank is 160*3 bytes from the other

Stars label byte  
include stars.inc

FntOffset label word
include fntOff.inc

text label byte
include evoltext.inc

TextSinus Label Byte
include sintabl3

TextCleanSin Label Word
include sintabl4

LogBuffSeg dw 0
LogSeggy  dw 0
SinIndex   db 0
SinIndex2  db 0
handle1    dw 0
Logo1Fil   db 'evol.log',0
counter      db 0
CLogoXpos  dw 318
ScrOffset  dw Logo1off+(320-(XlogoLines+Maxsinugrade))-2
LineNumber dw 0
sitmp       dw 0
ClearBuff   dw 0 ;A buffer with the old stars positions
CordX       dw 0
CordY       dw 0
TextBuff    dw 0  ;Pointer to TextBuff Piccy Segment
Clear       db 0 ;Clear Yes=1, No=0
TextPointer dw 0 ;Offset into Text
TextSinusIndex dw 0
Delay db 0 ;Delay for Text
TextCleanLine db 0
EndTextVar dw 0
LoadText db 1
display db 0


text2Buff MACRO
	  local endd,@@1,endd0,endd1,endd2
	  
	  mov si,cs:TextPointer
	  mov es,cs:TextBuff
	  mov ds,cs:LogSeggy
	  
	  xor di,di
	  jmp @@2
adj@1:
	  mov al,"["
	  jmp rett
@@2:
	  xor ax,ax
	  mov bx,Offset Text
	  mov al,cs:[bx+si]  ;Get Ascii code of a letter
	  cmp al,0 ;End of Text
	  jz endd0 
	  cmp al,1 ;Init of Paragraph
	  jz endd1
	  cmp al,2  ;Is an Alone Sentence
	  jz endd2
	  cmp al,32
	  jz adj@1

rett:
	  sub al,FiasCo ;First Ascii code (nice Constant hehehe ;)
	  mov bx,offset fntoffset
	  shl ax,1
	  push si
	  mov si,ax
	  mov bp,cs:[bx+si] ;Here we get the font offset
	  mov si,bp
	  add si,800  ;Skip the palette stuff
	  mov dl,20
	  push di
@@1:
	  mov cx,5
	  REP MOVSD
	  add si,320-20
	  add di,320-20
	  dec dl
	  jnz @@1
	  pop di
	  pop si
	  add di,20
	  inc si
	  jmp @@2
endd0:     
	  
	  xor si,si
	  jmp tatatan
endd1:
	  mov cs:TextCleanLine,128  ;Ok we have to clean after this
	  inc si
	  ;mov cs:delay,DelayConst ;Two ways, interactive or constant
	  mov al,cs:[bx+si]
	  mov cs:delay,al
	  inc si
tatatan:  
	  mov cs:TextPointer,si
	  mov cs:TextSinusIndex,0
	  mov cs:EndTextVar,142
	  
	  jmp endofend
endd2: 
	  inc si
	  mov cs:TextPointer,si
	  mov cs:TextSinusIndex,OnlyUpOff
	  sub cs:EndTextVar,11
	  
endofend:          

ENDM

Buff2Screen MACRO  ;We suposse screen offset on di
	local endd
	add di,mojon ;Shitt
	mov ax,0a000h
	mov es,ax
	mov ds,cs:TextBuff
	xor si,si
	REPT FNTHEIGTH
	cmp di,64000
	jg endd
	mov cx,260/4
	rep movsd
	add di,60
	add si,60
	ENDM
endd:

ENDM

ClearText MACRO
	local @@1
	
	
	mov bx,offset TextCleanSin
	xor ah,ah
	mov al,cs:TextCleanLine
	mov di,ax
	xchg ah,al
	shl di,6
	add ax,di
	
	

	mov cx,264
@@1:
	mov di,ax
	add di,cs:[bx+si]
	add di,cx
	mov byte PTR es:[di],0
	add si,2
	and si,63
	dec cx
	jnz @@1
ENDM


Writer PROC
	cmp cs:display,1
	jz @display
	cmp cs:loadtext,1
	jnz noload
	
	FILLDD cs:TextBuff,0,(320*20)/2,0
	Text2Buff ;we calculate the TextBuff
	mov cs:loadtext,0
	ret 

noload:
	cmp cs:TextCleanLine,200
	jge ClearedOk
	ClearText  ;First we have to clear old text
	inc cs:TextCleanLine
	ret  
	
       
ClearedOk:
	mov cs:display,1

@display:
	mov bx,Offset TextSinus
	add bx,cs:TextSinusIndex
	xor dh,dh
	mov dl,cs:[bx]
	mov di,dx
	xchg dh,dl
	shl di,6
	add di,dx
	Buff2Screen
	mov cx,cs:EndTextVar
	inc cs:TextSinusIndex
	cmp cs:TextSinusIndex,cx
	jz corr
	ret
corr:
	mov cs:display,0
	mov cs:LoadText,1
	ret

Writer ENDP


CreateMorphTab MACRO
	local @@1
	xor bx,bx
	mov cl,NumMorphFrames
	mov si,offset stars
	mov di,offset stars+3*Nstars
	mov bp,160
@@1:
	xor ah,ah
	mov al,cs:[si]
	mov dl,cs:[di]
	sub al,dl
	Xchg ah,al
	Idiv cx
	mov cs:[morph+bx+1],ax

	xor ah,ah
	mov al,cs:[si+1]
	mov dl,cs:[di+1]
	sub al,dl
	Xchg ah,al
	Idiv cx
	mov cs:[morph+bx+1],ax

	xor ah,ah
	mov al,cs:[si+2]
	mov dl,cs:[di+2]
	sub al,dl
	Xchg ah,al
	Idiv cx
	mov cs:[morph+bx+2],ax
	dec bp
	jnz @@1

ENDM


ClearStarField MACRO
	local @@1
	xor si,si
	mov cl,Nstars ;because we have Nstars
	mov ds,cs:ClearBuff
@@1:
	mov bx,ds:[si]
	mov byte PTR es:[bx],0
	add si,2
	dec cl
	jnz @@1
ENDM

StarField PROC
	;local @@1,nowrite
	mov ax,0a000h
	mov es,ax
	ClearStarField
	mov si,offset stars
	xor di,di
	mov bp,Nstars
	
@@@1:
	
	mov ax,cs:[si]     ;ax=X
	movsx edx,ax
	shr edx,16
	mov cx,cs:[si+4]   ;cx=Z
	
	Idiv cx 
	add ax,Xcentre
	xor bh,bh
	mov bl,cs:SinIndex2
	mov dl,0;cs:StarSinus[bx]
	movsx dx,dl
	add ax,dx
	mov cs:CordX,ax
	
	mov ax,cs:[si+2]   ;ax=Y
	movsx edx,ax
	shr edx,16
	Idiv cx
	add ax,Ycentre
	
	
				;Here we put a little sinus to the stars
		  
	mov dl,0;cs:StarSinus[bx]
	movsx dx,dl
	add ax,dx
	mov cs:CordY,ax
	
	
	mov bx,ax
	shl ax,8
	shl bx,6
	add ax,bx
	add ax,cs:CordX
	
	push cx
	dec cx
	cmp cx,3
	jl adj
retu:   mov WORD PTR cs:[si+4],cx
	pop cx      
	
	mov bx,ax
	mov al,es:[bx]
	mov WORD PTR ds:[di],0 ;0 offset is the acumulator point (the asshole, ;))
	cmp al,0
	jnz @nowrite
	cmp cs:CordX,320
	ja  @nowrite
	cmp cs:CordY,200
	ja  @nowrite
	
	shr cx,2
	not cl
	and cl,31
	add cl,48
	mov byte PTR es:[bx],cl
	mov ds:[di],bx
@nowrite:
	add si,6
	add di,2
	dec bp
	jnz @@@1
	inc cs:SinIndex2
	ret
adj:
	mov cx,127
	jmp retu


StarField ENDP



wvr1 MACRO
	local dw
	mov dx,3dah
dw:     in al,dx
	test al,8
	jnz dw
ENDM

wvr2 MACRO
	local dw
	mov dx,3dah
dw:     in al,dx
	test al,8
	jz dw
ENDM

;**********************************************************************
;WobleX this macro Wobles In X and put result graphik on LogBuffSeg:0
;Needs: 
; - SinIndex , with the current sinus offset value
; - LogSeggy , with the Evolution Logo
;**********************************************************************

wobleX MACRO  
	local @@1,@@2,endd,@put
	mov es,cs:LogBuffSeg
	mov ds,cs:LogSeggy
	
	xor bx,bx
@@1:
	mov si,800 ;Becasue Piccy begins at this offset
	xor di,di
	mov dl,YLogoLines
	mov bl,Byte PTR cs:SinIndex
@@2:
	and bx,255
	push di
	xor ah,ah
	mov al,Byte PTR cs:LogoSinus[bx]
	add di,ax
	mov cx,XLogoLines/4
	REP MOVSD
	pop di
	add di,XLogolines+MaxSinuGrade
	add si,320-XLogolines
	inc bx
	dec dl
	jnz @@2
		       ;Lets Put the LogoBuffer onto the screen
	
	add cs:SinIndex,wobspeed
	and cs:SinIndex,255

ENDM

estabilize MACRO  ;Sets the sinutable to 0 
       local @@1,endd
       mov si,255
       mov bx,258
@@1:
       xor dx,dx
       xor ah,ah
       mov al,Byte Ptr cs:LogoSinus[si]
       xchg al,ah
       div bx
       mov Byte Ptr cs:LogoSinus[si],al
       dec si
       jnz @@1
endd:   
       
ENDM


WobScr MACRO ;Scrolls the picture in LogBuffSeg from right to center
	local @@1,@@2
	mov cx,320
	mov di,cs:CLogoXpos
	sub cx,di
	add di,Logo1Off
	
	mov ax,0a000h
	mov es,ax
	mov ds,cs:LogBuffSeg
	xor si,si                  
	mov bx,cx    ;We copy to Bx here to save a shr later
	shr cx,1                  
	mov bp,Xlogolines+MaxSinuGrade
			  ;In cx number on iterations (cols. to copy to scr)
			  ;In di screen offset where begin to copy
	
	mov dl,YLogoLines
@@1:    
	push cx
	
	shr cx,1   ;Look at this... Its just ART!
	rep movsd
	adc cx,cx
	rep movsw
	
	push bp
	sub bp,bx
	add si,bp
	mov bp,320
	sub bp,bx
	add di,bp
	pop bp
	pop cx
	dec dl
	jnz @@1
	sub cs:CLogoXpos,2

ENDM

WriteLogo MACRO ;Rutine to be used exactly after WobleX. In di=ScrOffset
	local @put
	mov ax,0a000h
	mov es,ax
	mov ds,cs:LogBuffSeg
	xor si,si
	mov dl,YLogoLines
@put:        
	
	mov cx,(XLogolines+MaxSinuGrade)/4
	rep MOVSD
	inc cx
	rep movsw
	add di,320-XLogoLines-MaxSinuGrade
	dec dl
	jnz @put
ENDM

;*********+
;Requires: sitmp: the correct offset on LogSeggy
Scrolldown MACRO ;This macro scrolls down the second Logo ("Mistery")
	local @@1
	mov ax,0a000h
	mov es,ax
	mov ds,cs:Logseggy
	mov di,Logo2Off
	mov si,cs:sitmp
	;mov si,64000-logo2width+800 ;800, because 800 bytes is for palette
	mov cx,logo2width/4
	mov dx,cs:LineNumber
@@1:
	push cx
	REP MOVSD
	pop cx
	add si,320-Logo2width
	add di,320-Logo2width
	dec dx
	jnz @@1
	inc cs:LineNumber
	sub cs:sitmp,320
ENDM



start:
		 ;First we Set the proggy correct size
	
	
	;mov bx,Offset Freemem
	;shr bx,4
	;inc bx
	setblock 64000/16
	;mov ax,cs
	;mov ds,ax
	Alloc (64800/16)+1,cs:LogSeggy
	Alloc ((((XLogoLines+MaxSinuGrade)*YLogoLines))/16)+1,cs:LogBuffSeg
	Alloc (160*3)/16,cs:ClearBuff
	Alloc (320*20)/16,cs:TextBuff
	FILLDD cs:TextBuff,0,(320*20)/2,0
	FILLDD cs:ClearBuff,0,(160*3)/2,0
	FILLDD cs:LogBuffSeg,0,((XLogoLines+MaxSinuGrade)*YLogoLines)/2,0
	OpenF cs,Logo1fil,cs:handle1
	REadF 64800,cs:LogSeggy,0,cs:handle1
	CloseF cs:handle1
	mov ax,13h
	int 10h
	SetPalette cs:Logseggy,32
	mov cs:SinIndex,0 ;Initialize variables
	mov cs:counter,(XlogoLines+MaxSinuGrade)/2
	mov cs:LineNumber,1
	mov word Ptr cs:TextPointer,0
buc:
	wvr1
	WobleX
	wvr2
	WobScr
	dec cs:counter
	jz t1
	jmp buc
t1:
	mov cs:counter,30
	mov di,cs:ScrOffset
	mov cs:sitmp,64800-logo2width
buc2:   
	mov bp,di
	WobleX
	wvr2
	mov di,bp
	WriteLogo
	Scrolldown
	mov di,bp
	sub di,2
	dec cs:counter
	jz t2
	jmp buc2
t2:     mov bp,di
		
	mov cs:counter,170
buc3:
	wvr1
	WobleX
	wvr2
	mov di,bp
	push bp
	Writelogo
	cmp cs:counter,0
	jz doit
	ScrollDown
	dec cs:counter
	jmp bubba
doit:        
	;estabilize
	cmp cs:delay,0
	jnz delaying
	Call Writer
	jmp contin
delaying:        
	dec cs:delay
Contin:
	Call StarField
bubba:  pop bp
	waitESC buc3


enddd:        
	waitESC enddd

	mov ax,03h
	int 10h
	mov ax,4c00h
	int 21h

Freemem label byte


code ENDS
end start
