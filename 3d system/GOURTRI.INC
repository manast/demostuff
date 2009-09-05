;******************************************************************************
; 3D Engine by Sarwaz/Mistery
; Module: Gouraud Triangle Filler 
; Version 2.0: Optimized Divs. 3-4 divs per triangle. 0 divs per scanline
;******************************************************************************

;Variables

x1 dd 80
y1 dd 10

x2 dd 70
y2 dd 100

x3 dd 100
y3 dd 190
	  
z1 dd 20
z2 dd 150
z3 dd 80


left_adder   dd 0
right_adder  dd 0
left_cadder  dd 0
right_cadder dd 0
H_ColorInc   dd 0

left_x  dd 0
right_x dd 0

left_cx  dd 0
right_cx dd 0

swaping db 0 ;0 = no swap, 255 = swaping

;-------- MACROS ----------------------------------------------------------

;In: ax (leftX), bx (RightX), cx (Y Line)
;In: H_ColorInc
; Destroys ax,bx
Scanline MACRO 
	local @gouraud_line,@no_gouraud_line,@end_horiz
	push cx
	xchg bx,cx
		
	shl bx,6
	lea ebx,[ebx*4+ebx] ;at bx the line offset in video mem

	sub cx,ax ;at cx the length of the slope
	mov di,bx
	add di,ax ;at di the offset of the first point
	
	mov ebp,H_Colorinc
	or ebp,ebp
	jz @no_gouraud_line
	mov edx,Left_cx
	mov eax,edx 
	
@gouraud_line:
	shr eax,16
	stosb
	add edx,ebp
	mov eax,edx
	dec cx
	jnz @gouraud_line       
	
	jmp @end_horiz

@no_gouraud_line:
	mov eax,Left_cx
	shr eax,16
	mov ah,al
	shr cx,1
	rep stosw
	adc cx,cx
	rep stosb
	
@end_horiz:
	pop cx
	ENDM

PaintKernel MACRO
	local @nopaint
	
	mov eax,left_x
	shr eax,16
	mov ebx,right_x
	shr ebx,16
	inc bx
	
	cmp ax,bx
	ja @nopaint
	ScanLine
@nopaint:       
	mov eax,left_adder
	mov ebx,right_adder

	add left_x,eax
	add right_x,ebx

	mov ebp,left_cadder
	
	add left_cx,ebp
	
	ENDM

; ------------ PROCEDURES --------------------------------------------------

Gouraud_Triangle_Filler Proc

	Call sortpoints
	
	shl x1,16 ;Adjusting for Fixed point
	shl x2,16
	shl x3,16

;        and z1,255
;        and z2,255
;        and z3,255
	shl z1,16
	shl z2,16
	shl z3,16

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

	mov eax,z1
	mov left_cx,eax
	       
	mov eax,y2 ;eax=(y2-y1)/(y3-y1)
	sub eax,y1
	sal eax,16 ;Make fixed 16.16
	mov ebx,y3
	sub ebx,y1
	or ebx,ebx
	jz @ebxzero
	cdq
	idiv ebx
@ebxzero:
	mov ebx,eax  

	mov eax,x3 ;eax=(x3-x1) * ebx
	sub eax,x1
	sar eax,16 ;Get Integer Part
	imul ebx
	
	add eax,x1
	mov ecx,eax ;ecx=(x3-x1) * (y2-y1)/(y3-y1) + x1 -> endx
	sub ecx,x2  ;ecx=endx-startx
	sar ecx,16  ;Get integer Part

	mov eax,z3 ;eax=(z3-z1) * ebx
	sub eax,z1
	sar eax,16 ;Get integer part
	imul ebx

	add eax,z1  ;eax=(z3-z1) * (y2-y1)/(y3-y1) + z1 -> endc
	mov ebp,z2  ;ebp=z2 -> startc

	call CalcColorIncHorz

	mov eax,left_adder
	cmp eax,right_adder
	jg  @sub4
	
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
	mov left_adder,eax

	;Now Calc new Left_cadder
	mov eax,z2
	sub eax,z3

	or ebx,ebx
	jz @nodivision2

	cdq
	idiv ebx
@nodivision2:
	
	mov left_cadder,eax
	
	mov cx,word ptr y2
	
@fillingtri:

	PaintKernel
	
	inc cx

	cmp cx,word ptr y3
	jb @fillingtri
	ret

@sub4:
	mov eax,left_adder
	mov ebx,right_adder
	mov left_adder,ebx
	mov right_adder,eax
	
	mov ebx,right_cadder
      ;  mov eax,left_cadder
      ;  mov right_cadder,eax
	mov left_cadder,ebx

	mov cx,word ptr y1

@sub4buc:

	PaintKernel
	inc cx
	cmp cx,word ptr y2
	jb @sub4buc
			;New right adder
	mov eax,x2
	sub eax,x3

	mov ebx,y2
	sub ebx,y3
	or ebx,ebx
	jz @nodivision3

	cdq
	idiv ebx
@nodivision3:
	mov right_adder,eax
	
	mov cx,word ptr y2
	 
	
@fillingtri2:

	PaintKernel
	
	inc cx
	cmp cx,word ptr y3
	jb @fillingtri2
	ret





;--------------------------------------------------------------------------

@chopbottom:
;------------------ Triangle Chop At Bottom -------------------------------        
	
	mov eax,x3
	cmp eax,x2
	jae @OrderOk1
	mov ebx,x2
	mov x2,eax
	mov x3,ebx
	mov eax,y2
	mov ebx,y3
	mov y2,ebx
	mov y3,eax
	mov eax,z2
	mov ebx,z3
	mov z2,ebx
	mov z3,eax
@OrderOk1:        

	; Calculating Adders
	
	call CalcAdders
		;Fill Triangle
	mov eax,x1
	mov left_x,eax
	mov right_x,eax

	mov eax,z1
	mov left_cx,eax
       
	mov ecx,x3
	sub ecx,x2
	sar ecx,16
	mov ebp,z2
	mov eax,z3
	call CalcColorIncHorz

	mov cx,word ptr y1
	
@Fillchopbott:
	
	PaintKernel

	inc cx
	cmp cx,word ptr y3
	jb @Fillchopbott
	ret
;------------------------- Triangle Chop at Bottom --------------------

@choptop:
 
;------------------------Triangle Chop at Top ---------------------
	mov eax,x2
	cmp eax,x1
	jae @OrderOk2
	mov ebx,x1
	mov x1,eax
	mov x2,ebx
	mov eax,y1
	mov ebx,y2
	mov y1,ebx
	mov y2,eax
	mov eax,z1
	mov ebx,z2
	mov z1,ebx
	mov z2,eax
@OrderOk2:        
	
	; Calculating Left and Right Adders
	mov eax,x3 ;Left Adder
	sub eax,x1

	mov ebx,y3
	sub ebx,y1
			
	or ebx,ebx
	jz @nodivide
	cdq

	idiv ebx
@nodivide:
	mov left_adder,eax
	mov ebp,ebx

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
	;Calculating Gouraud Adders
		;Left Cadder
	mov eax,z3
	sub eax,z1
	or ebp,ebp
	jz @nodivide3

	cdq
	idiv ebp
@nodivide3:
	mov left_cadder,eax
	
	;Filling triangle

	mov eax,x1
	mov left_x,eax
	mov ebx,x2
	mov right_x,ebx

	mov ebp,z1
	mov left_cx,ebp
	
	mov ecx,x2        
	sub ecx,x1
	sar ecx,16
	mov eax,z2
	call CalcColorIncHorz
	
	mov cx,word ptr y1

@Fill_buc:
	
	PaintKernel

	inc cx
 
	cmp cx,word ptr y3
	jb @Fill_buc
 ;----------------------- Triangle chop at top -------------------------   
	ret
Gouraud_Triangle_Filler endp


;Calculate the Scanline Gouraud color increment
; in: ecx (Slope Length), ebp leftcolor, eax rightcolor

CalcColorIncHorz proc
	sub eax,ebp
	jz @increment0 ;the two intensities are the same
	or ecx,ecx
	jz @nonono
	cdq
	
	idiv ecx
@nonono:        
	mov H_ColorInc,eax
	ret
@increment0:
	mov H_ColorInc,0
	ret
CalcColorIncHorz endp

CalcAdders Proc        
	;Standard adders for painting triangle
	mov eax,x2 ;Left_Adder
	sub eax,x1

	mov ebx,y2
	sub ebx,y1
	mov ebp,ebx ;ebp=y2-y1

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
		    ;ebx=y3-y1

	or ebx,ebx
	jz @nodiv2

	cdq
	idiv ebx
@nodiv2:
	mov right_adder,eax

	;Gouraud Color Adders
		;Left Color Adder
	mov eax,z2
	sub eax,z1
	or ebp,ebp
	jz @nodiv3

	cdq
	idiv ebp
@nodiv3:
	mov left_cadder,eax
		;Right Color Adder
	mov eax,z3
	sub eax,z1
	or ebx,ebx
	jz @nodiv4

	cdq
	idiv ebx
@nodiv4:
	mov right_cadder,eax

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
	jbe @noswap1
	xchg eax,ebx
	xchg edx,edi
	mov ebp,z1
	xchg ebp,z2
	mov z1,ebp
@noswap1:
	cmp eax,ecx
	jbe @noswap2
	xchg eax,ecx
	xchg edx,esi
	mov ebp,z1
	xchg ebp,z3
	mov z1,ebp
@noswap2:
	cmp ebx,ecx
	jbe @noswap3
	xchg ebx,ecx
	xchg edi,esi
	mov ebp,z2
	xchg ebp,z3
	mov z2,ebp
@noswap3:
	mov y1,eax
	mov y2,ebx
	mov y3,ecx

	mov x1,edx
	mov x2,edi
	mov x3,esi

	ret
sortpoints endp
    
    
