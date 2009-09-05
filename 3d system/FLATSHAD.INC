;Sarwaz 3d Engine
;Module: Flat Shading Procedure


include flattri.inc                    ;Flat Triangle Filler 

;----------------------------------------------------------------------------
; Flat Shading - 
; Shades the object with Flat shading
; In: Proyected_Vertices,Faces,rotated_face_normals
; Uses : x1,x2,x3,y1,y2,y3
; Out: /
;----------------------------------------------------------------------------

FlatFill PROC
	lea bx,Proyected_vertices
	lea bp,rotated_face_normals
	lea di,Faces
	mov ecx,Number_of_Faces
	mov es,virtual_page
@Fill_all:
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
	
		
	push bp
	push di
	push cx
	push bx

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
	jl @hide

	;Flat Light Shading here, we pick the color from normal_z of the face
	mov eax,ds:[bp+8]
	shr eax,2
	cmp al,0
	jg @colorOK
	xor al,al
@colorOk:
	shl al,2
	mov [color],al


	call Flat_Triangle_Filler
@hide:
	pop bx
	pop cx
	pop di
	pop bp
	
	add bp,12
	add di,24
	dec cx
	jnz @Fill_all
	ret
FlatFill ENDP


;FlatFill2 Proc
;        lea di,Rotated_Face_normals
;        lea bx,Proyected_Vertices
;        lea bp,FacePointerArray
;        lea ecx,Number_Of_Visible_Faces
;@Render:
;        mov si,ds:[bp]
;        
;        mov esi,[si]
;        shl si,3
;        mov eax,[bx+si]
;        mov x1,eax
;        mov eax,[bx+si+4]
;        mov y1,eax
;        
;        mov si,ds:[bp]
;
;        mov esi,[si+4]
;        shl si,3
;        mov eax,[bx+si]
;        mov x2,eax
;        mov eax,[bx+si+4]
;        mov y2,eax
;        
;        mov si,ds:[bp]
;
;        mov esi,[si+8]
;        shl si,3
;        mov eax,[bx+si]
;        mov x3,eax
;        mov eax,[bx+si+4]
;        mov y3,eax
	
	;Flat Light Shading here, we pick the color from normal_z of the face
;        mov eax,[di+8]
;        shr eax,1
	
;        cmp al,0
;        jg @colorOK
;        xor al,al
;@colorOk:
;        ;shl al,1
;        mov [color],al
;        
;        call Flat_Triangle_Filler
;        
;        add bp,4
;        add di,12
;        dec cx
;        jnz @Fill_all
;        
;        ret
;FlatFill2 Endp

