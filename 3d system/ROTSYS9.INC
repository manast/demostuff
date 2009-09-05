; 3D Engine by Sarwaz / MiSTERY
; Module: Rotation Procedures - 9 mults 


include sincos.inc                      ;15 bit fixed sin, cos table 

k0 dd ?
k1 dd ?
k2 dd ?
k3 dd ?
k4 dd ?
k5 dd ?
k6 dd ?
k7 dd ?
k8 dd ?

Xr dd ?
Yr dd ?
Zr dd ?

;----------------------------------------------------------------------------
; Precalculating Matrix Procedure
; Precalcs k0-k8  for 9 mults rotation formulas
; In: bp (pointer to angles structure)
; Out: k0-k8
; Destroys: eax,ebp,esi,edi,ebx
;----------------------------------------------------------------------------

Precalc_Matrix PROC
       push si
       push di
       push ecx
       mov si,ds:[bp.Xan]
       shl si,2
       mov di,ds:[bp.Yan]
       shl di,2
       mov bx,ds:[bp.Zan]
       shl bx,2
	;k0=cy*cz
	mov eax,cos[di];cy
	mov ebp,cos[bx];cz
	imul ebp
	shrd eax,edx,15
	mov k0,eax

	;k1=cx*sz-sx*sy*cz
	mov eax,cos[si];cx
	mov ebp,sin[bx];sz
	imul ebp
	shrd eax,edx,15
	mov ecx,eax
	mov eax,sin[si];sx
	mov ebp,sin[di];sy
	imul ebp
	shrd eax,edx,15
	mov ebp,cos[bx];cz
	imul ebp
	shrd eax,edx,15
	sub ecx,eax
	mov k1,ecx
	
	;k2=cx*sy*cz+sx*sz
	mov eax,cos[si];cx
	mov ebp,sin[di];sy
	imul ebp
	shrd eax,edx,15
	mov ebp,cos[bx];cz
	imul ebp
	shrd eax,edx,15
	mov ecx,eax
	mov eax,sin[si];sx
	mov ebp,sin[bx];sz
	imul ebp
	shrd eax,edx,15
	add eax,ecx
	mov k2,eax

	;k3=-cy*sz
	mov eax,cos[di];cy
	mov ebp,sin[bx];sz
	imul ebp
	shrd eax,edx,15
	neg eax
	mov k3,eax

	;k4=cx*cz+sx*sy*sz
	mov eax,cos[si];cx
	mov ebp,cos[bx];cz
	imul ebp
	shrd eax,edx,15
	mov ecx,eax
	mov eax,sin[si];sx
	mov ebp,sin[di];sy
	imul ebp
	shrd eax,edx,15
	mov ebp,sin[bx];sz
	imul ebp
	shrd eax,edx,15
	add eax,ecx
	mov k4,eax

	;k5=sx*cz-cx*sy*sz
	mov eax,sin[si];sx
	mov ebp,cos[bx];cz
	imul ebp
	shrd eax,edx,15
	mov ecx,eax
	mov eax,cos[si];cx
	mov ebp,sin[di];sy
	imul ebp
	shrd eax,edx,15
	mov ebp,sin[bx];sz
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
	pop ecx
	pop di
	pop si
	      
       ret
precalc_matrix endp


;---------------------------------------------------------------------------
; Rotate Points Procedure - 9 muls Version                                                                           
; In: x,y,z and k0..k8
; out: Xr,Yr,Zr
; Destroys: eax,ebx
;---------------------------------------------------------------------------

Rotate_Points MACRO
	;Xr=k0*x+k1*y+k2*z
	mov eax,x
	imul k0
	mov ebx,eax

	mov eax,y
	imul k1
	add ebx,eax

	mov eax,z
	imul k2
	add ebx,eax
	sar ebx,15
	mov Xr,ebx
	 
	;Yr=k3*x+k4*y+k5*z
	mov eax,x
	imul k3
	mov ebx,eax

	mov eax,y
	imul k4
	add ebx,eax

	mov eax,z
	imul k5
	add ebx,eax
	sar ebx,15
	mov Yr,ebx

	;Zr=k6*x+k7*y+k8*z
	mov eax,x
	imul k6
	mov ebx,eax

	mov eax,y
	imul k7
	add ebx,eax

	mov eax,z
	imul k8
	add ebx,eax
	sar ebx,15
	mov Zr,ebx
	ENDM
	 
;----------------------------------------------------------------------------        
; Rotation Engine Procedure
; Rotates all the points at vertices
; In: si (pointer to points/normals array to rotate),ecx (number of points)
;     di (pointer to points/normals array to place the rotated)
;     bp (pointer to angle structure)
; Out: di (pointer to rotated points/normals array)
; Destroys: si,di,eax,ebx,ecx
;----------------------------------------------------------------------------

RotateEngine Proc
	 call Precalc_Matrix
;        lea si,vertices
;        lea di,rotated_vertices
;        mov ecx,number_of_vertices
@@another_point:        
	mov eax,[si]
	mov x,eax
	mov eax,[si+4]
	mov y,eax
	mov eax,[si+8]
	mov z,eax
	add si,12
	
	rotate_points
	
	mov eax,Xr
	mov [di],eax
	mov eax,Yr
	mov [di+4],eax
	mov eax,Zr
	mov [di+8],eax
	add di,12
	
	dec cx
	jnz @@another_point
	ret
RotateEngine Endp

;------------------------------------------------------------------------------
; Procedure RotateFaceNormals - Assuming that the k0-k8 matrix is precalc.
; Rotates All the Face Normals
; Note: Rotates the Normals with Xan,Yan,Zan
; In: Number_of_faces,faces
; out: rotated_face_normals
;------------------------------------------------------------------------------

RotateFaceNormals Proc
	lea di,rotated_face_normals
	lea si,faces
	mov ecx,number_of_faces
@another_face:        
	mov eax,[si+12]
	mov x,eax
	mov eax,[si+16]
	mov y,eax
	mov eax,[si+20]
	mov z,eax
		
	rotate_points

	mov eax,Xr
	mov [di],eax
	mov eax,Yr
	mov [di+4],eax
	mov eax,Zr
	mov [di+8],eax
	add di,12
	add si,24
		
	dec cx
	jnz @another_face

	ret
RotateFaceNormals Endp

; --------------------------------------------------------------------------
; RotateCamera procedure
; Rotates the camera to the correct camera angles
; In: CameraAngle, Camera
; Out: Camera 
; --------------------------------------------------------------------------

RotateCamera Proc
	lea bp,CameraAngle
	call Precalc_Matrix
	mov cx,3
	lea si,camera
	
@rotcamera:
	mov eax,[si]   
	shl eax,16
	mov x,eax
	mov eax,[si+4] 
	shl eax,16
	mov y,eax      
	mov eax,[si+8] 
	shl eax,16
	mov z,eax

	rotate_points

	mov eax,Xr
	mov [si],eax
	mov eax,Yr
	mov [si+4],eax
	mov eax,Zr
	mov [si+8],eax

	add si,12
	dec cx
	jnz @rotcamera
	ret

RotateCamera endp
