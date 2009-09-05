;***************************************************************************
; 3d engine by Sarwaz / Mistery
; Module: Flat_triangle_filler
;***************************************************************************


color db 12

x1 dd 71
y1 dd 144

x2 dd 144
y2 dd 144

x3 dd 230
y3 dd 144


left_adder dd 0
right_adder dd 0

left_x dd 0
right_x dd 0

swaping db 0 ;0 = no swap, 255 = swaping

;In: ax (leftX), bx (RightX), cx (Y Line)
Horiz_line MACRO ;LeftX,RightX,Yline,color
	local @nostosb,@nostosw
	inc bx
	push cx
	xchg bx,cx
		
	shl bx,6
	lea ebx,[ebx*4+ebx] ;at bx the line offset in video mem

	sub cx,ax ;at cx the length of the slope
		  ;at ax the X initial offset
		 ;at es 0a000h
	mov di,bx
	add di,ax
	;color 
	mov al,color
	mov ah,al
	shl eax,16
	mov al,color
	mov ah,al
	shr cx,1
	jnc @nostosb
	stosb
@nostosb:        
	shr cx,1
	jnc @nostosw
	stosw
@nostosw:        
	rep stosd

	pop cx

	ENDM

PaintKernel MACRO
	local @nopaint
	mov eax,left_adder
	mov ebx,right_adder

	add left_x,eax
	add right_x,ebx
	
	mov eax,left_x
	shr eax,16
	mov ebx,right_x
	shr ebx,16

	cmp ax,bx
	ja @nopaint
	Horiz_Line ;ax,bx,cx,color
@nopaint:        
	ENDM

;At es the segment where the screen is
Flat_Triangle_Filler Proc

			;Make Lame-Clipping
	xor eax,eax
	cmp y1,eax
	jl @clip
	cmp y2,eax
	jl @clip
	cmp y3,eax
	jl @clip



	    
	mov swaping,0 ;Initializing swap variable

	Call sortpoints
	
	shl x1,16 ;Adjusting for Fixed point
	shl x2,16
	shl x3,16

	mov eax,y1        
	cmp eax,y2
	jz @choptop

	mov eax,y2
	cmp eax,y3
	jz @chopbottom
	
;------------------ P1<>P2<>P3 --------------------------------------------
	Call CalcAdders
		;fill
	mov eax,x1
	mov left_x,eax
	mov right_x,eax
	
	mov eax,left_adder
	cmp eax,right_adder
	jl @nochange
	mov ebx,right_adder
	mov left_adder,ebx
	mov right_adder,eax
	mov swaping,255
@nochange:      

	mov cx,word ptr y1
	
@fillbucle:

	PaintKernel

	inc cx
	cmp cx,word ptr y2
	jb @Fillbucle
	
	;Now drawing from P2 to P3        
	;First Calc New left_adder
	
	mov eax,x2
	sub eax,x3

	mov ebx,y2
	sub ebx,y3
	or ebx,ebx
	jz @nodivision

	cdq
	idiv ebx
@nodivision:
	
	inc swaping
	jz @Update_Right
	mov left_adder,eax
	jmp @Update_Left
@Update_Right:
	mov right_adder,eax
@Update_Left:
	
	mov cx,word ptr y2
	mov bp,word ptr y3          
@fillingtri:

	PaintKernel
	
	inc cx
	cmp cx,bp
	jb @fillingtri
	ret
;--------------------------------------------------------------------------

@chopbottom:
;------------------ Triangle Chop At Bottom -------------------------------        
	; Calculating Adders
	
	call CalcAdders
		;Fill Triangle
	mov eax,x1
	mov left_x,eax
	mov right_x,eax

	mov cx,word ptr y1
	
	mov eax,x3
	cmp eax,x2
	ja @fillchopbott
	mov eax,left_adder
	mov ebx,right_adder
	mov left_adder,ebx
	mov right_adder,eax
  
@Fillchopbott:
	
	PaintKernel

	inc cx
	cmp cx,word ptr y3
	jb @Fillchopbott
	ret
;------------------------- Triangle Chop at Bottom --------------------

@choptop:
 ;------------------------Triangle Chop at Top ---------------------
	; Calculating Left and Right Adders
	mov eax,x3 ;Left Adder
	sub eax,x1

	mov ebx,y3
	sub ebx,y1
		  ;Seems imposible that ebx=0 ;that means not a tri, but a line
	or ebx,ebx
	jz @nodivide
	cdq

	idiv ebx
@nodivide:
	mov left_adder,eax

	mov eax,x3 ;Right Adder
	sub eax,x2

	mov ebx,y3
	sub ebx,y2
	or ebx,ebx
	jz @nodivide2
	cdq

	idiv ebx
@nodivide2:
	mov right_adder,eax

	;Filling triangle

	mov eax,x1
	mov left_x,eax
	mov ebx,x2
	mov right_x,ebx
	
	mov cx,word ptr y1
	cmp ebx,x1
	jae @fill_buc
	mov left_x,ebx
	mov right_x,eax
	mov eax,left_adder
	mov ebx,right_adder
	mov left_adder,ebx
	mov right_adder,eax
	      
@Fill_buc:
	
	PaintKernel

	inc cx
	cmp cx,word ptr y3
	jb @Fill_buc
 ;----------------------- Triangle chop at top -------------------------   
@clip:  ret
Flat_Triangle_Filler endp

CalcAdders Proc        
	mov eax,x2 ;Left_Adder
	sub eax,x1

	mov ebx,y2
	sub ebx,y1

	or ebx,ebx
	jz @nodiv

	cdq
	idiv ebx
@nodiv:        
	mov left_adder,eax
		   ;Right Adder
	mov eax,x3
	sub eax,x1

	mov ebx,y3
	sub ebx,y1

	or ebx,ebx
	jz @nodiv2

	cdq
	idiv ebx
@nodiv2:
	mov right_adder,eax
	ret
calcAdders endp

sortpoints proc
	mov eax,y1
	mov ebx,y2
	mov ecx,y3

	mov edx,x1
	mov edi,x2
	mov esi,x3

	cmp eax,ebx
	jb @noswap1
	xchg eax,ebx
	xchg edx,edi
@noswap1:
	cmp eax,ecx
	jb @noswap2
	xchg eax,ecx
	xchg edx,esi
@noswap2:
	cmp ebx,ecx
	jb @noswap3
	xchg ebx,ecx
	xchg edi,esi
@noswap3:
	mov y1,eax
	mov y2,ebx
	mov y3,ecx

	mov x1,edx
	mov x2,edi
	mov x3,esi

	ret
sortpoints endp
