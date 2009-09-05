; Sb raw sample player by Sarwaz of Mistery
; V0.1 Using Direct mode (just Sounds like shit)

sample_frec equ 8000

code segment
assume cs:code,ds:code,ss:pila
.386

include sb.inc
include ..\misc\misc.inc

filename db 'sound.raw',0
current_sample_offset dw 0
sample_segment dw 0
sample_offset dw 0

start:
	push    cs
	pop     ds
	SetProgramSize
	lea dx,filename
	mov cx,65535
	call LoadFile
	jc nosb
	mov sample_segment,dx
	mov current_sample_offset,dx

;        push ds
;        mov ds,Sample_Segment
;        xor si,si
;        mov cx,65535
;        call ConvertDelta2Data
;        pop ds
	
	call ResetDSP
	jc noSB

	call GetVersion

	mov al,0d1h      ;Turn on the speaker
	call WriteDSP

			 ;Hook Int8
	push ds
	xor ax,ax        
	mov     ds,ax
	mov     eax,ds:[8*4]
	mov     cs:oldint8,eax
	mov     ax,cs
	shl     eax,16
	mov     ax,OFFSET Sb_Int
	mov     dx,1193000/Sample_frec ; frecuency divisor
	cli
	mov     ds:[8*4],eax
	mov     al,036h
	out     43h,al
	mov     al,dl
	out     40h,al
	mov     al,dh
	out     40h,al
	sti
	pop ds

	xor ax,ax
	int 16h

	push ds
	mov     eax,cs:oldint8
	xor     dx,dx
	mov     ds,dx
	cli
	mov     ds:[8*4],eax
	mov     al,036h
	out     43h,al
	mov     al,dl
	out     40h,al
	mov     al,dh
	out     40h,al
	sti
	pop ds

nosb:

	mov ax,4c00h
	int 21h



; ----------------------------------------------------------------------------
; Sb interrupt
; ----------------------------------------------------------------------------

Sb_Int proc far
	push    dx
	push    si
	push    ds
	push    ax
	mov     si,cs:current_sample_offset
	mov     ds,cs:sample_segment
	
	
	mov     dx,cs:SB_BASE_ADRESS
	add     dx,0ch              ;2xCh
	
@NotReady1:
	in      al,dx
	and     al,80h              ;test bit 7
	jnz     @NotReady1
	
	mov     al,10h              ;Write Mode
	out     dx,al               ;Write the Byte
	
				
@NotReady2:
	in      al,dx
	and     al,80h              ;test bit 7
	jnz     @NotReady2
	
	lodsb

	out     dx,al               ;Write the Byte


	inc     cs:current_sample_offset
	mov     al,20h
	out     20h,al
	pop     ax
	pop     ds
	pop     si
	pop     dx
	iret
Sb_Int endp

;In ds:si with the sample data cx=data length
;Out sample at ds:si converted

ConvertDelta2Data proc
	xor ax,ax       ;OldByte = 0

@convert:
	add ds:[si],ax
	mov ax,ds:[si]
	inc si
	dec cx
	jnz @convert

	ret
ConvertDelta2Data endp


code ends

pila segment stack
	db 100h DUP (?)
pila ends

end start
