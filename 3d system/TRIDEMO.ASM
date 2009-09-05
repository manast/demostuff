;******************************************************************************
; 3D Engine by Sarwaz/Mistery
; Demo of triangle fillers 
;******************************************************************************

.model small
.stack  100h
code segment
	assume cs:code,ds:code

.386

wrandomseed dw 1110101011110101b

include gourtri.inc

start:
	push cs
	pop ds
	
	mov ax,13h
	int 10h
	mov ax,0a000h
	mov es,ax
@repeat:
	call setrandomcoords
	call Gouraud_Triangle_Filler

	in al,60h
	dec al
	jnz @repeat

	xor ah,ah
	int 16h

	mov ax,3h
	int 10h

	mov ax,4c00h
	int 21h

    
    
SetRandomCoords PRoc
;        call Randomize
	mov bx,320
	call random
	mov word ptr X1,ax
	call random
	mov word ptr X2,ax
	call random
	mov word ptr X3,ax
	mov bx,200
	call random
	mov word ptr y1,ax
	call random
	mov word ptr y2,ax
	call random
	mov word ptr y3,ax
	
	mov bx,255
	call random
	mov word ptr z1,ax
	call random
	mov word ptr z2,ax
	call random
	mov word ptr z3,ax
	ret
SetRandomCoords endp

Randomize PROC    
    ; Seed random number generator
    mov     ah,02Ch                 ;Get system time
    int     21h                     ;   Interrupt: DOS
    mov     wRandomSeed,dx          ;
    ret     
Randomize Endp

;Generate random number
;  Arguments: BX = Random maximum + 1
;  Returns  : AX = Random number
;  Destroys : DX DI
Random  PROC
	mov     ax,wRandomSeed
	mov     dx,25173
	mul     dx
	add     ax,13849
	mov     wRandomSeed,ax
	div     bx
	mov     ax,dx
	ret                             ;
Random ENDP
 

code ends

end start
