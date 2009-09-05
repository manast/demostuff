; GUS raw sample player by Sarwaz of Mistery

sample_frec equ 8000

code segment
assume cs:code,ds:code,ss:pila
.386

include gus.inc
include ..\misc\misc.inc

filename db 'sound2.raw',0
current_sample_offset dw 0
sample_segment dw 0
sample_offset dw 0

start:
	push    cs
	pop     ds
	SetProgramSize
	lea     dx,filename
	mov     cx,65535
	call    LoadFile
	jc      nogus
	mov     sample_segment,dx
	mov     current_sample_offset,dx

;        push ds
;        mov ds,Sample_Segment
;        xor si,si
;        mov cx,65535
;        call ConvertDelta2Data
;        pop ds


	call    ResetGus
	jc      noGus
	
	push    ds        
	mov     ds,cs:sample_segment
	xor     ebx,ebx
	mov     cx,60000
	call    mem2Gus
	pop     ds
		
	mov     al,2
	call    GusSetVoice
	mov     cl,60
	call    GusSetVolume
	mov     cl,7
	call    GusSetPanning
	mov     ax,22000
	mov     cx,42
	xor     dx,dx
	div     cx
	mov     cx,ax
	call    GusSetFreq
;        mov     ebp,0
;        mov     esi,25000
;        mov     edi,60000
;        call    GusSetInstrument
	mov     bl,0
	mov     ebp,1000
	call    GussetVCurr

	xor     ax,ax
	int     16h
	mov     bl,1
	call    GusSetVCurr
	

noGus:

	mov ax,4c00h
	int 21h

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

;cx,Number of Bytes
;ds:[0000] - Mem Adress (Source)
;Ebx, Gus Mem Initial Position  (Destination)
;returns EBX, with next Free Position

Mem2Gus proc
	push    si
	push    ax
	xor     si,si
@@@Copy:
	mov     al,ds:[si]            
	call    GusWrite
	inc     ebx
	inc     si
	dec     cx
	jnz     @@@Copy
	pop     ax
	pop     si
	ret
Mem2Gus endp


code ends

pila segment stack
	db 100h DUP (?)
pila ends

end start
