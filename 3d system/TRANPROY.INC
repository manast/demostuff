;Sarwaz 3d Engine
;Module: Translation and proyection stuff

;----------------------------------------------------------------------------
; Procedure Translation
; Translates all the objects to World Position
; In:  Rotated_Vertices,ObjectMatrix
; Out: Rotated_Vertices
;----------------------------------------------------------------------------

Translation proc
	lea si,rotated_vertices
;        lea bx,ObjectMatrix
	xor di,di
@TranslateAll:
	mov eax,[bx+di]                
	mov edx,[bx+di+4]
	mov ebp,[bx+di+8]
	mov ecx,Number_of_vertices
@@TranslateOne:
	add [si],eax
	add [si+4],edx
	add [si+8],ebp
	add si,12
	dec ecx        
	jnz @@TranslateOne
      
	ret
Translation Endp


;-------------------------------------------------------------------------------
; Procedure Proyection  
; Proyects the vertices, Translates to World and to Camera
; In: Rotated_vertices
; Out: Proyected_vertices
;-------------------------------------------------------------------------------

Proyection PROC
	lea si,rotated_vertices
	lea di,Proyected_vertices
;        lea bx,ObjectMatrix       ;Coords of the object in world space
	mov ecx,Number_of_vertices
@Proyect_all:   
	mov eax,[si]
      ;  add eax,[bx]    ;Translate X local coord to world
	
	shl eax,8
	neg eax
	mov ebp,[si+8]
      ;  add ebp,[bx+8]  ;Translate Z local coord to world
	
	sub ebp,255
	or ebp,ebp
	jz @zero

	cdq
	idiv ebp
@zero:
	add eax,X_center ;Translate to the center (2d)
	mov [di],eax

	mov eax,[si+4]   ;Translate Y local coord to world coord
     ;   add eax,[bx+4]
	
	shl eax,8
	neg eax
	or ebp,ebp
	jz @zero_2
	cdq
	idiv ebp
@zero_2:
	add eax,Y_center ;Translate to the center  (2d)
	mov [di+4],eax
	add di,8
	add si,12
	dec cx
	jnz @Proyect_all
	
	ret
Proyection Endp

