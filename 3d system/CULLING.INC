;---------------------------------------------------------------------------
; BackFaceCulling
; Removes hiden faces, make Z clipping and creates FacePointerArray
; In: rotated_vertices,proyected_vertices,faces,number_of_Faces
; Out: FacePointerArray
;---------------------------------------------------------------------------

ZClippingDist   equ -1500
Ztmp            dw  0

BackFaceCulling Proc
    ;    lea si,proyected_vertices
    ;    lea bx,Faces
    ;    lea di,FacePointerArray

	lea bx,Proyected_vertices
	;lea bp,FacePointerList
	lea di,Faces
	mov ecx,Number_of_Faces
	
@Cull_all:
	    
			;Make Z Clipping
	mov esi,[di]
	shl si,2
	lea esi,[esi*2+esi] ;esi=esi*12
	mov eax,[rotated_vertices+si+8]
	cmp eax,Zclippingdist
	jl @RemoveFace
	mov esi,[di+4]
	shl si,2
	lea esi,[esi*2+esi] ;esi=esi*12
	mov edx,[rotated_vertices+si+8]
	cmp edx,Zclippingdist
	jl @RemoveFace
	add edx,eax
	mov esi,[di+8]
	shl si,2
	lea esi,[esi*2+esi] ;esi=esi*12
	mov eax,[rotated_vertices+si+8]
	cmp eax,Zclippingdist
	jl @RemoveFace
	add edx,eax
	mov Ztmp,dx     ;Face Z*3
	      
			;Get Faces Coordinates
	mov esi,[di]
	shl si,3
	mov eax,[bx+si]
	mov x1,eax
	mov eax,[bx+si+4]
	mov y1,eax

	mov esi,[di+4]
	shl si,3
	mov eax,[bx+si]
	mov x2,eax
	mov eax,[bx+si+4]
	mov y2,eax
	
	mov esi,[di+8]
	shl si,3
	mov eax,[bx+si]
	mov x3,eax
	mov eax,[bx+si+4]
	mov y3,eax
  
	
	;Test if we have to show or to hide
	mov eax,x2 ; (x2-x1)*(y3-y1) >= (x3-x1)*y2-y1)
	sub eax,x1
	mov ebx,y3
	sub ebx,y1
	imul ebx
	mov ebx,eax
	mov eax,x3
	sub eax,x1
	mov edx,y2
	sub edx,y1
	imul edx
	cmp ebx,eax
	jl @RemoveFace

	mov dx,[FacePointer]
	mov ds:[FacePointerArray][bp],dx
	mov dx,[Ztmp]
	mov ds:[FacePointerArray][bp+2],dx
	add bp,4

@RemoveFace:
	add FacePointer,4*6
	dec ecx
	jnz @CullAll

	ret
BackFaceCulling Endp

