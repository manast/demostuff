; 3D System by Sarwaz (A.k.a. Manuel Astudillo)
; Module: Camera Translator


; ---------------------------------------------------------------------------
; Camera Structure
; ---------------------------------------------------------------------------

CameraStruc struc

	Vx1 dd ?
	Vx2 dd ?
	Vx3 dd ?
    
	Vy1 dd ?
	Vy2 dd ?
	Vy3 dd ?

	Vz1 dd ?
	Vz2 dd ?
	Vz3 dd ?

	Xpos dd ?
	Ypos dd ?
	Zpos dd ?

CameraStruc ends

; tmp vars

	Xc dd ?
	Yc dd ?
	Zc dd ?

Camera          cameraStruc <1024,0,0,0,1024,0,0,0,1024,0,0,0>
CameraRotated   cameraStruc <5,0,0,0,5,0,0,0,5,0,0,0>

; ---------------------------------------------------------------------------
; Set Camera Procedure
; Translates Object to Camera
; In: camera,number_of_vertices,rotated_vertices
; ---------------------------------------------------------------------------

SetCamera proc

	mov ecx,number_of_vertices        
	lea si,CameraRotated
	lea di,rotated_vertices

@CameraOne:
				;Xc = Vx1*Px+Vx2*Py+Vx3*Pz
	mov eax,[si.Vx1]
	imul d [di]
	mov ebx,eax

	mov eax,[si.Vx2]
	imul d [di+4]
	add ebx,eax

	mov eax,[si.Vx3]
	imul d [di+8]
	add ebx,eax

	;sar ebx,16
	
;        add ebx,[si.Xpos]       ;Add X position of the camera
	mov Xc,ebx
				;Yc = Vy1*Px+Vy2*Py+Vy3*Pz

	mov eax,[si.Vy1]
	imul d [di]
	mov ebx,eax

	mov eax,[si.Vy2]
	imul d [di+4]
	add ebx,eax

	mov eax,[si.Vy3]
	imul d [di+8]
	add ebx,eax

	;sar ebx,16
	
;        add ebx,[si.Ypos]       ; add Y position of the camera
	mov Yc,ebx
	

				;Zc = Vz1*Px+Vz2*Py+Vz3*Pz

	mov eax,[si.Vz1]
	imul d [di]
	mov ebx,eax

	mov eax,[si.Vz2]
	imul d [di+4]
	add ebx,eax

	mov eax,[si.Vz3]
	imul d [di+8]
	add ebx,eax

	;sar ebx,16
	
	;mov Zc,ebx

;        add ebx,[si.Zpos]       ; Add Z position of the camera

	mov [di+8],ebx
	mov ebx,Xc
	mov [di],ebx
	mov ebx,Yc
	mov [di+4],ebx
		
	add di,12
	dec ecx
	jnz @CameraOne

	ret
SetCamera endp



