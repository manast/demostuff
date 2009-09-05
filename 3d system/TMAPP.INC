;******************************************************************************
; 3D Engine by Sarwaz/Mistery
; Module: Texture Mapping Triangle Filler 
;******************************************************************************

x1 dd 100
y1 dd 20

x2 dd 250
y2 dd 100

x3 dd 20
y3 dd 180


nx1 dd 100
ny1 dd 20

nx2 dd 250
ny2 dd 100

nx3 dd 20
ny3 dd 180


left_adder     dd 0
right_adder    dd 0
left_nx_adder  dd 0
left_ny_adder  dd 0
right_nx_adder dd 0
right_ny_adder dd 0
inc_j          dd 0
inc_i          dd 0

left_x  dd 0
right_x dd 0

left_nx  dd 0
left_ny  dd 0
right_nx dd 0
right_ny dd 0


;In: ax (leftX), bx (RightX), cx (Y Line)
;In: ebp (i1), esi (j1), edx (i2) , edi (j2)
; Destroys ax,bx

Horiz_line MACRO 
	local @nohorizline,@@tmapp 
	inc bx
	
	push cx
	push edi
	xchg bx,cx
		
	shl bx,6
	lea ebx,[ebx*4+ebx] ;at bx the line offset in video mem

	sub cx,ax       ;at cx the length of the slope
			;at ax the X initial offset
	mov di,bx
	add di,ax       ;at di the offset of the first point
	pop ebx
	
	;Calculating Inc_i,Inc_j         
		
	mov eax,edx
	sub eax,ebp
	and ecx,65535
	or cx,cx
	jz @nohorizline

	cdq
	idiv ecx
	mov inc_i,eax
	mov eax,ebx
	sub eax,esi
	cdq
	idiv ecx
	mov inc_j,eax
	mov edx,inc_i

@@tmapp:
	mov ebx,esi
	shr ebx,8
	mov eax,ebp
	shr eax,16
	mov bl,al
	mov al,fs:[bx]
	stosb
	add ebp,edx
	add esi,inc_j
	dec cx
	jnz @@tmapp
@nohorizline:        
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
	
	;texture mapping Stuff
	mov ebp,left_nx_adder
	mov esi,left_ny_adder
	mov edx,right_nx_adder
	mov edi,right_ny_adder
	
	add left_nx,ebp
	add left_ny,esi
	add right_nx,edx
	add right_ny,edi
	
	mov ebp,left_nx
	mov esi,left_ny
	mov edx,right_nx
	mov edi,right_ny
	
	cmp ax,bx
	ja @nopaint
	Horiz_Line ;ax,bx,cx,ebp,edx
@nopaint:       
	ENDM


Texture_Triangle_Filler Proc

	Call sortpoints
	
	shl x1,16 ;Adjusting for Fixed point
	shl x2,16
	shl x3,16

	shl nx1,16
	shl ny1,16
	shl nx2,16
	shl ny2,16
	shl nx3,16
	shl ny3,16


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

	mov eax,nx1
	mov left_nx,eax
	mov right_nx,eax

	mov eax,ny1
	mov left_ny,eax
	mov right_ny,eax
	
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

	;Now Calc new Left_nx_adder
	mov eax,nx2
	sub eax,nx3

	or ebx,ebx
	jz @@nodivision2

	cdq
	idiv ebx
@@nodivision2:
	
	mov left_nx_adder,eax
	
	;Calc new left_ny_adder
	mov eax,ny2
	sub eax,ny3
	or ebx,ebx
	jz @@nodivision3
	cdq
	idiv ebx
@@nodivision3:

	mov left_ny_adder,eax

	mov cx,word ptr y2
	
@fillingtri:

	PaintKernel
	
	inc cx

	cmp cx,word ptr y3
	jb @fillingtri
	ret

@sub4:
	;Swap adders
	mov eax,left_adder
	mov ebx,right_adder
	mov left_adder,ebx
	mov right_adder,eax
	
	mov ebx,right_nx_adder
	mov eax,left_nx_adder
	mov right_nx_adder,eax
	mov left_nx_adder,ebx

	mov ebx,right_ny_adder
	mov eax,left_ny_adder
	mov right_ny_adder,eax
	mov left_ny_adder,ebx


	mov cx,word ptr y1

@sub4buc:

	PaintKernel
	inc cx
	cmp cx,word ptr y2
	jb @sub4buc

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

	;Now Calc new right_nx_adder
	mov eax,nx2
	sub eax,nx3

	or ebx,ebx
	jz @nodivision4

	cdq
	idiv ebx
@nodivision4:
	
	mov right_nx_adder,eax 
	;now calc new right_ny_adder
	mov eax,ny2
	sub eax,ny3
	or ebx,ebx
	jz @nodivision5
	cdq
	idiv ebx
@nodivision5:
	mov right_ny_adder,eax
	
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
	; Calculating Adders
	
	call CalcAdders
		;Fill Triangle
	mov eax,x1
	mov left_x,eax
	mov right_x,eax

	mov eax,nx1
	mov left_nx,eax
	mov right_nx,eax
	mov eax,ny1
	mov left_ny,eax
	mov right_ny,eax

	mov cx,word ptr y1
	
	mov eax,x3
	cmp eax,x2
	ja @Fillchopbott
	mov eax,left_adder
	mov ebx,right_adder
	
	mov left_adder,ebx
	mov right_adder,eax
	
	mov eax,left_nx_adder
	mov ebx,right_nx_adder
	
	mov left_nx_adder,ebx
	mov right_nx_adder,eax

	mov eax,left_ny_adder
	mov ebx,right_ny_adder
	
	mov left_ny_adder,ebx
	mov right_ny_adder,eax

	
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
	;Calculating Texture mapping Adders
		;Left_nx_adder
	mov eax,nx3
	sub eax,nx1
	or ebp,ebp
	jz @nodivide3

	cdq
	idiv ebp
@nodivide3:
	mov left_nx_adder,eax
		;left_ny_adder
	mov eax,ny3
	sub eax,ny1
	or ebp,ebp
	jz @nodivide4
	cdq
	idiv ebp
@nodivide4:
	mov left_ny_adder,eax

		;Right_nx_adder
	mov eax,nx3
	sub eax,nx2
	or ebx,ebx
	jz @nodivide5

	cdq
	idiv ebx
@nodivide5:
	mov right_nx_adder,eax
		;Right_ny_adder
	mov eax,ny3
	sub eax,ny2
	or ebx,ebx
	jz @nodivide6
	cdq
	idiv ebx
@nodivide6:
	mov right_ny_adder,eax

	;Filling triangle

	mov eax,x1
	mov left_x,eax
	mov ebx,x2
	mov right_x,ebx

	mov ecx,nx1
	mov left_nx,ecx
	mov edx,nx2
	mov right_nx,edx
	mov esi,ny1
	mov left_ny,esi
	mov edi,ny2
	mov right_ny,edi
     
	mov cx,word ptr y1

	cmp ebx,x1
	ja @Fill_buc
	mov left_x,ebx
	mov right_x,eax
	mov eax,left_adder
	mov ebx,right_adder
	mov left_adder,ebx
	mov right_adder,eax

	mov left_nx,edx
	mov right_nx,ecx
	mov left_ny,edi
	mov right_ny,esi

	mov eax,left_nx_adder
	mov ebx,right_nx_adder
	mov left_nx_adder,ebx
	mov right_nx_adder,eax

	mov eax,left_ny_adder
	mov ebx,right_ny_adder
	mov left_ny_adder,ebx
	mov right_ny_adder,eax

	       
@Fill_buc:
	
	PaintKernel

	inc cx
 
	cmp cx,word ptr y3
	jb @Fill_buc
 ;----------------------- Triangle chop at top -------------------------   
	ret
Texture_Triangle_Filler endp

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

	;tmapping normals Adders
	
		;Left normals Adders
		;left_nx_adder
	mov eax,nx2
	sub eax,nx1
	or ebp,ebp
	jz @nodiv3

	cdq
	idiv ebp
@nodiv3:
	mov left_nx_adder,eax
		;left_ny_adder
	mov eax,ny2
	sub eax,ny1
	or ebp,ebp
	jz @nodiv4

	cdq
	idiv ebp
@nodiv4:
	mov left_ny_adder,eax
		;Right normal adders
		;right_nx_adder
	mov eax,nx3
	sub eax,nx1
	or ebx,ebx
	jz @nodiv5
	
	cdq
	idiv ebx
@nodiv5:
	mov right_nx_adder,eax
		;right_ny_adder
	mov eax,ny3
	sub eax,ny1
	or ebx,ebx
	jz @nodiv6
	
	cdq
	idiv ebx
@nodiv6:
	mov right_ny_adder,eax
	
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
	mov ebp,nx1
	xchg ebp,nx2
	mov nx1,ebp
	
	mov ebp,ny1
	xchg ebp,ny2
	mov ny1,ebp
@noswap1:
	cmp eax,ecx
	jbe @noswap2
	xchg eax,ecx
	xchg edx,esi
	mov ebp,nx1
	xchg ebp,nx3
	mov nx1,ebp

	mov ebp,ny1
	xchg ebp,ny3
	mov ny1,ebp
@noswap2:
	cmp ebx,ecx
	jbe @noswap3
	xchg ebx,ecx
	xchg edi,esi
	mov ebp,nx2
	xchg ebp,nx3
	mov nx2,ebp

	mov ebp,ny2
	xchg ebp,ny3
	mov ny2,ebp
@noswap3:
	mov y1,eax
	mov y2,ebx
	mov y3,ecx

	mov x1,edx
	mov x2,edi
	mov x3,esi

	ret
sortpoints endp
    
    
