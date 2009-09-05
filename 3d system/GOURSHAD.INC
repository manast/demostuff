; 3d system by Sarwaz (a.k.a. Manuel Astudillo)
; Module: Gouraud Shading


include gourtri.inc              ;Gouraud triangle filler


;----------------------------------------------------------------------------
; Gouraud Shading - 
; In: Proyected_Vertices,Faces,rotated_normals,number_of_faces
; Uses : x1,x2,x3,y1,y2,y3
; Out: /
;----------------------------------------------------------------------------

GouraudFill PROC
        lea bx,Proyected_vertices
        lea di,Faces
        lea bp,rotated_normals
        mov ecx,Number_of_Faces
        mov es,virtual_page
@Fill_all:
        mov esi,[di]
        shl si,3
        mov eax,[bx+si]
        mov x1,eax
        mov eax,[bx+si+4]
        mov y1,eax
        
        shr si,1  ;Getting the intensity of the vertices
        lea esi,[esi*2+esi]    ;esi=esi/2;esi=esi*4
        mov eax,[rotated_normals+si+8]  ;esi=esi*3, esi=esi*12
        shr eax,1
        cmp eax,0
        jge @color1_ok
        xor eax,eax
@color1_ok:
;        inc eax
        mov z1,eax

        mov esi,[di+4]
        shl si,3
        mov eax,[bx+si]
        mov x2,eax
        mov eax,[bx+si+4]
        mov y2,eax
        
        shr si,1            ;esi=esi/2;esi=esi*4
        lea esi,[esi*2+esi] ;esi=esi*3, esi=esi*12
        mov eax,[rotated_normals+si+8]
        shr eax,1
        cmp eax,0
        jge @color2_ok
        xor eax,eax
@color2_ok:
 ;       inc eax
        mov z2,eax
        
        mov esi,[di+8]
        shl si,3
        mov eax,[bx+si]
        mov x3,eax
        mov eax,[bx+si+4]
        mov y3,eax

        shr si,1
        lea esi,[esi*2+esi]
        mov eax,[rotated_normals+si+8]
        shr eax,1
        cmp eax,0
        jge @color3_ok
        xor eax,eax
@color3_ok:
  ;      inc eax
        mov z3,eax
        
        push di
        push cx
        push bx
        push bp

        ;Test if we have to show or to hide
        mov eax,x2
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
        
        call Gouraud_Triangle_Filler
@hide:
        pop bp
        pop bx
        pop cx
        pop di
        
        add di,24
        dec cx
        jnz @Fill_all
        ret
GouraudFill ENDP

