;******************************************************************************
; 3D Engine By Sarwaz / Mistery
; Main Program
;******************************************************************************

code segment
assume cs:code,ds:code,ss:stack
.386

;Strucs

AngleStruc struc
	Xan dw ?
	Yan dw ?
	Zan dw ?
AngleStruc ends


;equ's Definitions

X_Center                equ 160
Y_Center                equ 100

Number_Of_Objects       equ 2


;Variables and objects

proyected_vertices dd 1000 DUP (0)

x               dd ?
y               dd ?
z               dd ?

ObjectAngle     AngleStruc <0,0,-256>
CameraAngle     AngleStruc <0,0,0>

Xv              dd ?
Yv              dd ?
Zv              dd ?

;Test Example for 2 objects

ObjectMatrix1    dd 0,0,0
ObjectMatrix2    dd 0,0,0

virtual_page    dw 0
texture         dw 0

palette         db 768 DUP (?)          ;For palette storing
palname         db 'flatpal.col',0


include d:\sarwaz\3dsystem\objects\sakk.inc               ; 3d Object
texture_filename db 'd:\data\phong4.sar',0                ; Texture
include d:\sarwaz\misc\misc.inc

include rotsys9.inc                     ; Rotation Engine, 9 muls
;include flatshad.inc                    ; Shading Engine Here
;include gourshad.inc
;include textmapp.inc
include envmapp.inc
include tranproy.inc                    ; Translation proyection Stuff
include camera.inc                      ; Camera Translation

start:
	push cs
	pop ds
					;we calc here the length of the proggy
	mov bx,ss  
	mov ax,es
	sub bx,ax
	mov ax,sp
	shr ax,4
	add bx,ax                       ;Bx=Number of parraphs of the program
	inc bx                          ;one more here
	mov ah,4ah
	int 21h
					;Reserving here 64k for virtual page
	mov ah,48h
	mov bx,4096 ;4096x16=64k
	int 21h
	mov virtual_page,ax

	mov ax,13h
	int 10h

	;Loading and setting palette
	mov ah,3dh ;open file
	lea dx,palname
	xor al,al ;read
	int 21h
	mov bx,ax

	mov ah,3fh
	mov cx,768
	lea dx,palette
	int 21h

	mov ah,3eh
	int 21h
	call set_palette
	
       
       call AllocTexture
       call LoadTexture


       call Wretrace
       call inittimer
	
 @bucle:
	;Angles to rotate the object
	mov cx,cs:framecounter
	shl cx,1
	add ObjectAngle.Xan,cx
	and ObjectAngle.Xan,1023
	add ObjectAngle.Yan,cx
	and ObjectAngle.Yan,1023
;        add ObjectAngle.Zan,cx
;        and ObjectAngle.Zan,1023
	mov cs:framecounter,0
;       inc dword ptr ObjectMatrix1
;       and dword ptr ObjectMatrix1,127
;       inc dword ptr ObjectMatrix1+8
;       inc dword ptr ObjectMatrix2+4
;       and dword ptr ObjectMatrix2+4,63
	
;        inc CameraAngle.Xan
;        and CameraAngle.Xan,255
;        inc CameraAngle.Yan
;        and CameraAngle.Yan,255
;        inc CameraAngle.Zan
;        and CameraAngle.Zan,255

	call clear
		
	
	lea si,vertices
	lea di,rotated_vertices
	lea bp,ObjectAngle
	mov ecx,number_of_vertices
	call RotateEngine
     
	lea si,normals
	lea di,rotated_normals
	mov ecx,number_of_vertices
	lea bp,ObjectAngle
	call RotateEngine

;        call RotateFaceNormals

;        lea si,camera
;        lea di,CameraRotated
;        mov ecx,3
;        lea bp,CameraAngle
;        call RotateEngine

;        call RotateCamera
	
	lea bx,ObjectMatrix1
	call translation
;        call setcamera
	call Proyection
;        call texturefill
;        call gouraudfill
;        call flatfill
	call EnvMappfill ;Shading Here
	
;       lea bx,ObjectMatrix2
;       call Proyection
;       call Flatfill


	call Wretrace
	call flip
	
	in al,60h
	dec al
	jnz @bucle
	
	xor ah,ah
	int 16h

	mov ax,3h
	int 10h
		;Free mem
	mov ah,49h
	mov es,virtual_page
	int 21h
		;Set old int 8
	call deinittimer

	mov ax,4c00h
	int 21h



Clear PROC
	mov es,virtual_page
	mov ecx,16000
	xor eax,eax
	xor di,di
	rep stosd
	ret
clear endp

Wretrace proc
	mov dx,3dah
@dwait:
	in al,dx
	test al,8
	jz @dwait
	ret
Wretrace endp

flip proc 
     push ds
     mov ds,virtual_page
     mov ax,0a000h
     mov es,ax
     xor di,di
     xor si,si
     mov ecx,16000
     rep movsd
     pop ds
     ret
flip endp

Set_Palette PROC
	push dx
	push ax
	push si
	push cx
	
	mov dx,3c8h ;PEL register
	xor al,al
	out dx,al
	inc dx      ;PEL Data
	lea si,palette
	mov cx,300h   ;300h =768 
	rep outsb
	pop cx
	pop si
	pop ax
	pop dx
	ret
Set_Palette Endp  

code ends

stack segment stack
	db 100h dup (0)
stack ends

end start
