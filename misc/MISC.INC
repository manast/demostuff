;****************************************************************************
; Miscelaneous rutines. by Sarwaz / Mistery (at least most of them)
;****************************************************************************

;Usefull Constants

B       equ byte ptr
W       equ word ptr
D       equ dword ptr
O       equ offset

;------------------------
; File Stuff            |
;------------------------


;----------------------------------------------------------------------------
; Procedure LoadFile
; Description: Load a file which name was pointed by ds:dx and cx bytes
; In: ds:dx pointer to filename
;     cx    number of bytes to read
; Out: dx  segment where the data of the file was loaded
; errors: Carry flag set to 1 and error code at dx
; error codes: 0 = no enough memory
;              1 = Bad Filename
;----------------------------------------------------------------------------

LoadFile proc
	push ax
	push bx
	mov ah,48h
	mov bx,cx
	shr bx,4
	inc bx
	int 21h
	jc @noEnoughMem
	mov bx,ax
	
	mov ah,3dh ;open file
	xor al,al ;read
	int 21h   ;in ds:dx pointer to filename
	jc @badfilename
	
	push ds
	mov ds,bx  ;Save segment in ds
	mov bx,ax
	
	xor dx,dx
	mov ah,3fh
	int 21h  ;In cx number of bytes to read
		
	mov dx,ds
	pop ds
	
	mov ah,3eh  ;Close File
	int 21h
	pop bx                
	pop ax
	clc
	ret
@noenoughmem:
	pop bx
	pop ax
	xor dx,dx
	stc
	ret
@badfilename:
	pop bx
	pop ax
	mov dx,1
	stc
	ret
LoadFile endp

;----------------------------------------------------------------------------
; LoadFile2 Procedure
; Loads cx bytes from Asciiz file pointed by ds:dx and returns dx with seg
; and bx with file Handle
; But without closing the file. and File pointer points to end of reading.
; NOTE: Same errors Management that LoadFile
;----------------------------------------------------------------------------

loadFile2Handle dw 0

LoadFile2 proc
	push ax
	mov ah,48h
	mov bx,cx
	shr bx,4
	inc bx
	int 21h
	jc @noEnoughMem2
	mov bx,ax
	
	mov ah,3dh ;open file
	xor al,al ;read
	int 21h   ;in ds:dx pointer to filename
	jc @badfilename2
	
	push ds
	mov ds,bx  ;Save segment in ds
	mov cs:[LoadFile2Handle],ax
	mov bx,ax
	
	xor dx,dx
	mov ah,3fh
	int 21h  ;In cx number of bytes to read
		
	mov dx,ds
	pop ds
	
	
	mov bx,cs:[LoadFile2Handle]                
	pop ax
	clc
	ret
@noenoughmem2:
	pop ax
	xor dx,dx
	stc
	ret
@badfilename2:
	pop ax
	mov dx,1
	stc
	ret

	ret
LoadFile2 endp


;----------------------------------------------------------------------------
; ReadFile Macro
; read cx bytes from file bx and put them at ds:dx
;----------------------------------------------------------------------------

ReadFile Macro
	push ax
	mov ah,3fh
	int 21h  ;In cx number of bytes to read
	pop ax
	Endm

;----------------------------------------------------------------------------
; CloseFile Macro
; Close Bx file
;----------------------------------------------------------------------------

CloseFile MACRO
	push ax
	mov ax,3eh
	int 21h
	pop ax
	endm

Location MACRO
	push cx
	mov ah,42h
	mov al,01h
	xor dx,dx
	xor cx,cx
	int 21h
	pop cx
	endm



;-------------------
; Memory Stuff     | 
;-------------------


;---------------------------------------------------------------------------
; Macro SetProgramSize
; Description: Sets the current program correct size
; Note: ES must Point to PSP, and th stack must be at the end part, otherwise
;       the system will hung up
;---------------------------------------------------------------------------

SetProgramSize MACRO
	push bx
	push ax
	mov bx,ss  
	mov ax,es
	sub bx,ax
	mov ax,sp
	shr ax,4
	add bx,ax ;Bx=Number of parraphs of the program
	inc bx      ;one more here
	mov ah,4ah
	int 21h
	pop ax
	pop bx
	ENDM

;---------------------------------------------------------------------------
; Macro AllocMem
; Allocates ax bytes of memory
; Return dx with segment, or c set if not enough memory
;---------------------------------------------------------------------------

AllocMem macro
	push ax
	push bx
	mov bx,ax
	shr bx,4
	inc bx
	mov ah,48h
	int 21h
	mov dx,ax
	pop bx
	pop ax
	endm

;---------------------------------------------------------------------------
; Macro FreeMem
; Frees the segment pointed by dx
;---------------------------------------------------------------------------

FreeMem macro
	push ax
	push es
	mov es,dx
	mov ah,49h
	int 21h
	pop es
	pop ax
	endm

;--------------------------
;Input output stuff       |
;--------------------------

WriteLN MACRO text
	local outtext,writenow
	push ax
	push dx
	push ds
	call writenow
outtext db text,10,13,36
	
writenow:
	pop dx
	push cs
	pop ds
	mov ah,9h
	int 21h
	pop ds
	pop dx
	pop ax
	endm

;---------------------------------------------------------------------------
; Others Authors Misc stuff
;---------------------------------------------------------------------------


;北北北北北北北北 setborder 北北北北北北北北
;descr: debug/change border color , Credits for this is Psi / FC
setborder MACRO col
	IF BORDERS
	push    ax
	push    dx
	mov     dx,3dah
	in      al,dx
	mov     dx,3c0h
	mov     al,11h+32
	out     dx,al
	mov     al,col
	out     dx,al
	pop     dx
	pop     ax
	ENDIF
	ENDM

oldint8 dd 0

;北北北北北北北北 timer 北北北北北北北北
inittimer PROC NEAR
	push ds
	xor ax,ax        
	mov     ds,ax
	mov     eax,ds:[8*4]
	mov     cs:oldint8,eax
	mov     ax,cs
	shl     eax,16
	mov     ax,OFFSET intti8
	mov     dx,17042 ;70hz , 1193/70 frecuency divisor
	jmp     @@1
deinittimer:                            
	push ds
	mov     eax,cs:oldint8
	xor     dx,dx
	mov     ds,dx
@@1:    cli
	mov     ds:[8*4],eax
	mov     al,036h
	out     43h,al
	mov     al,dl
	out     40h,al
	mov     al,dh
	out     40h,al
	sti
	pop ds
	ret
inittimer ENDP

framecounter dw 0

intti8  PROC FAR ;timer interrupt
	push    ax
	mov     al,20h
	out     20h,al
	inc     cs:framecounter
	pop     ax
	iret
intti8  ENDP

;北北北北北北北北 setborder 北北北北北北北北
; Change Border Color
setborder MACRO col
	push    ax
	push    dx
	mov     dx,3dah
	in      al,dx
	mov     dx,3c0h
	mov     al,11h+32
	out     dx,al
	mov     al,col
	out     dx,al
	pop     dx
	pop     ax
	ENDM

; -----------------------------------------------------------------------------
; Fast sqrt procedure by Mika tuomi (aka Trug/fc)
; input:  AX = number to calc sqrt
; modif:  AX, BP, DX
; output: AX=sqrt value of number in input sqrt; BP=orig. number
; -----------------------------------------------------------------------------

sqrt     PROC
	 push    bx 
	 push    cx
	 mov     bp,ax      ; store original number to BP
	 mov     cx,7       ; number of rounds to calc sqrt
	 mov     bx,00ffh   ; BL = guess (algorithm needs in first round)
sqrtl:   mov     ax,bp      ; get original number from BP
	 xor     dx,dx      ; zero DX register for dividing
	 div     bx         ; AX = AX / BX
	 add     ax,bx      ; AX = AX + BX
	 shr     ax,1       ; AX = AX / 2
	 mov     bx,ax      ; put new guess value to BX
	 dec     cx
	 jnz     sqrtl
	 pop     cx 
	 pop     bx
	 ret
sqrt     endp
