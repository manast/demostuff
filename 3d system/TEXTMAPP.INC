
include mapptri.inc

;----------------------------------------------------------------------------
; Texture Mapping - Linear non distorsion
; In: Proyected_Vertices,Faces,normals,number_of_faces
; Uses : x1,x2,x3,y1,y2,y3
; Out: /
;----------------------------------------------------------------------------

TextureFill PROC
        lea bx,Proyected_vertices
        lea di,Faces
        lea bp,normals
        mov ecx,Number_of_Faces
        mov es,virtual_page
@Fill_all:
                        ;X1,Y1,NX1,NY1
        mov esi,[di]
        shl si,3
        mov eax,[bx+si]
        mov x1,eax
        mov eax,[bx+si+4]
        mov y1,eax
        
        shr si,1  ;Getting the intensity of the vertices
        lea esi,[esi*2+esi]    ;esi=esi/2;esi=esi*4
        mov eax,[normals+si]  ;esi=esi*3, esi=esi*12
       ; sar eax,2
        sub eax,100
        neg eax
        mov nx1,eax
        mov eax,[normals+si+4]
       ; sar eax,2
        sub eax,100
        neg eax
        mov ny1,eax

                        ;X2 Y2 NX2 NY2
        mov esi,[di+4]
        shl si,3
        mov eax,[bx+si]
        mov x2,eax
        mov eax,[bx+si+4]
        mov y2,eax
        
        shr si,1            ;esi=esi/2;esi=esi*4
        lea esi,[esi*2+esi] ;esi=esi*3, esi=esi*12
        mov eax,[normals+si]
       ; sar eax,2        
        sub eax,100
        neg eax
        mov nx2,eax
        mov eax,[normals+si+4]
      ;  sar eax,2
        sub eax,100
        neg eax
        mov ny2,eax

                        
                        ;X3 Y3 NX3 NY3
        
        mov esi,[di+8]
        shl si,3
        mov eax,[bx+si]
        mov x3,eax
        mov eax,[bx+si+4]
        mov y3,eax

        shr si,1
        lea esi,[esi*2+esi]
        mov eax,[normals+si]
       ; sar eax,2
        sub eax,100
        neg eax
        mov nx3,eax
        mov eax,[normals+si+4]
       ; sar eax,2
        sub eax,100
        neg eax
        mov ny3,eax
        
        push bx
        
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
        
        push di
        push cx
        push bp

        call Texture_Triangle_Filler

        pop bp
        pop cx
        pop di

@hide:
        pop bx
        
        
        add di,24
        dec cx
        jnz @Fill_all
        ret
TextureFill ENDP
