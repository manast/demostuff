; 3D Engine by Sarwaz / MiSTERY
; Module: Rotation Procedures - 7 muls + 15 adds 
; Note: a little more faster that 9 muls version. %15 faster on 386 at least.


k0 dd ?
k1 dd ?
k2 dd ?
k3 dd ?
k4 dd ?
k5 dd ?
k6 dd ?
k7 dd ?
k8 dd ?
k9 dd ?
k10 dd ?
k11 dd ?

sxsz dd ?
sxcz dd ?
cxsz dd ?
cxcz dd ?

xy dd ?

Xr dd ?
Yr dd ?
Zr dd ?


; Precalc_Matrix
; Precalcs k0-k8  for 9 mults rotation formulas
; IN: Xan,Yan,Zan
; Out: k0-k8

Precalc_Matrix PROC
       push eax
       push ebp
       push esi ;Xan
       push edi ;Yan
       push ebx ;Zan
       mov si,Xan
       shl si,2
       mov di,Yan
       shl di,2
       mov bx,Zan
       shl bx,2

	;sxsz=sx*sz
	mov eax,sin[si];sx
	mov ebp,sin[bx];sz
	imul ebp
	shrd eax,edx,15
	mov sxsz,eax

	;sxcz=sx*cz
	mov eax,sin[si];sx
	mov ebp,cos[bx];cz
	imul ebp
	shrd eax,edx,15
	mov sxcz,eax

	;cxsz=cx*cz
	mov eax,cos[si];cx
	mov ebp,sin[bx];sz
	imul ebp
	shrd eax,edx,15
	mov cxsz,eax

	;cxcz=cx*cz
	mov eax,cos[si];cx
	mov ebp,cos[bx];cz
	imul ebp
	shrd eax,edx,15
	mov cxcz,eax

	;k0=cy*cz
	mov eax,cos[di];cy
	mov ebp,cos[bx];cz
	imul ebp
	shrd eax,edx,15
	mov k0,eax

	;k1=cxsz-sy*sxcz
	mov ecx,cxsz
	
	mov eax,sxcz
	mov ebp,sin[di];sy
	imul ebp
	shrd eax,edx,15
	
	sub ecx,eax
	mov k1,ecx
	
	;k2=sy*cxcz+sxsz
	mov eax,cxcz
	mov ebp,sin[di];sy
	imul ebp
	shrd eax,edx,15
	
	mov ecx,sxsz
	
	add eax,ecx
	mov k2,eax

	;k3=-cy*sz
	mov eax,cos[di];cy
	mov ebp,sin[bx];sz
	imul ebp
	shrd eax,edx,15
	neg eax
	mov k3,eax

	;k4=cxcz+sy*sxsz
	mov ecx,cxcz
	
	mov eax,sxsz
	mov ebp,sin[di];sy
	imul ebp
	shrd eax,edx,15
	
	add eax,ecx
	mov k4,eax

	;k5=sxcz-sy*cxsz
	mov ecx,sxcz
	
	mov eax,cxsz
	mov ebp,sin[di];sy
	imul ebp
	shrd eax,edx,15
	
	sub ecx,eax
	mov k5,ecx


	;k6=-sy
	mov eax,sin[di];sy
	neg eax
	mov k6,eax

	;k7=-sx*cy
	mov eax,sin[si];sx
	mov ebp,cos[di];cy
	imul ebp
	shrd eax,edx,15
	neg eax
	mov k7,eax
	
	;k8=cx*cy
	mov eax,cos[si];cx
	mov ebp,cos[di];cy
	imul ebp
	shrd eax,edx,15
	mov k8,eax
	
	;k9=k0*k1
	mov eax,k0
	mov ebp,k1
	imul ebp
	shrd eax,edx,15
	mov k9,eax

	;k10=k3*k4
	mov eax,k3
	mov ebp,k4
	imul ebp
	shrd eax,edx,15
	mov k10,eax

	;k11=k6*k7
	mov eax,k6
	mov ebp,k7
	imul ebp
	shrd eax,edx,15
	mov k11,eax

      
       pop ebx
       pop edi
       pop esi
       pop ebp
       pop eax
       ret
precalc_matrix endp

;In: x,y,z
;out: Xr,Yr,Zr

rotate_points proc
	;Make Fixed x,y,z - 15 bits fixed like the sincos Table
	shl x,15
	shl y,15
	shl z,15

	;xy=x*y        
	mov eax,x
	imul y
	shrd eax,edx,15
	mov xy,eax
	
      
	;Xr=(k0+y)*(k1+x) - k9 - xy + k2*z
	mov eax,k0
	add eax,y
	mov ebp,k1
	add ebp,x
	imul ebp
	shrd eax,edx,15
	mov ecx,eax

	sub ecx,k9
	sub ecx,xy

	mov eax,k2
	imul z
	shrd eax,edx,15
	add ecx,eax

	sar ecx,15 ;get integer
	mov Xr,ecx

	;Yr=(k3+y)*(k4+x) - k10 - xy + k5*z
	mov eax,k3
	add eax,y
	mov ebp,k4
	add ebp,x
	imul ebp
	shrd eax,edx,15
	mov ecx,eax

	sub ecx,k10
	sub ecx,xy

	mov eax,k5
	imul z
	shrd eax,edx,15
	add ecx,eax

	sar ecx,15 ;get integer
	mov Yr,ecx

	;Zr=(k6+y)*(k7+x) - k11 - xy + k8*z

	mov eax,k6
	add eax,y
	mov ebp,k7
	add ebp,x
	imul ebp
	shrd eax,edx,15
	mov ecx,eax

	sub ecx,k11
	sub ecx,xy

	mov eax,k8
	imul z
	shrd eax,edx,15
	add ecx,eax

	sar ecx,15
	mov Zr,ecx

	ret
rotate_points endp
	 

