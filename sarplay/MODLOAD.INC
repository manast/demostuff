;+---------------------------------------------------------------------------+ 
;¦ Mod Player by Sarwaz / Mistery                                            ¦
;¦ Module: Mod Loader                                                         ¦
;¦ This Piece of code is Copyright by Manuel Astudillo - 1996                        ¦
;+---------------------------------------------------------------------------+

include misc.inc

; Implementation of Macros


Get_Number_Of_Patterns MACRO
	local @Search,@nochange
	push ax
	push cx
	push di
	mov cl,cs:[song.leng]
	xor di,di
	mov al,cs:[Song.Order]
@Search:
	inc di
	cmp al,cs:[Song.Order+di]
	jae @nochange
	mov al,cs:[Song.Order+di]
@nochange:
	dec cl
	jnz @Search
	inc al
	mov cs:[Song.NumOfPatterns],al
	pop di
	pop cx
	pop ax
	ENDM


;---------------------------------------------------------------------------
; ModLoad Procedure
; Load A mod file into a SarSong structure
; In: ds:dx Asciiz with Mod Filename
; Out es:di Pointer to SarSong
; Errors: Carry Flag set and Ax Error Code
; Errors Codes: 0 = File not found
;               1 = Not Enough Memory
;               2 = Corrupted File
;---------------------------------------------------------------------------

ModFileHandle dw ?
FileBuff      dw ?
Sample_Size   dw ?
Gus_Mem_Pointer dd ?

ModLoad proc far
	pusha
	push    ds
	mov     cx,1084
	Call    LoadFile2           ;Load Mod Header without closing
	jc      @FileNotFound

	mov     cs:[ModFileHandle],bx
	mov     cs:[FileBuff],dx

	push    cs
	pop     es
				;Check if it is a mod File
	mov     cs:[Song.NumOfchannels],4
	mov     ds,cs:[FileBuff]             ;Lets See For 4 channels mods
	
	cmp     ds:[1080],'.K.M'
	jz      @ModFileOk
	
	cmp     ds:[1080],'NHC4'
	jz      @ModFileOk              ;Lets Test for 6 channels

	cmp     ds:[1080],'4TLF'   
	jz      @ModFileOk
	
	mov     cs:[Song.NumOfChannels],6
	cmp     ds:[1080],'NHC6'
	jz      @ModFileOk

	cmp     ds:[1080],'6TLF'
	jz      @ModFileOk
					;Lets Test for 8 channels
	mov     cs:[Song.NumOfChannels],8
	cmp     ds:[1080],'NHC8'
	jz      @ModFileOk

	cmp     ds:[1080],'8TLF'
	jz      @ModFileOk
	
	
	jmp     @CorruptedFile          ;Not a MOD File ...

		      ; If we have a Mod file, then lets fill Some structures

@ModFileOk:
	mov     cs:[Sample_Size],30
	mov     cs:[Number_Of_Samples],31
	mov     cs:[Song.Speed],6
	mov     cs:[Song.BPM],125
	mov     cs:[Song.Restart],0
	

	 ;Song Info
					;copy [Song.SonName],0,20
	mov     cx,20
	xor     si,si
	lea     di,Song.SonName
	rep     movsb
	
	mov     al,ds:[950]
	mov     es:[song.leng],al
					;copy [Song.Order],952,128
	mov     cx,128
	mov     si,952
	lea     di,Song.Order
	rep     movsb
	 
	;Instrument Info
	xor     si,si
	lea     di,Song.Inst
	mov     cl,cs:[Number_Of_Samples]
@GetInstrumentInfo:
	push    cx                                        
	push    si
	push    di
	mov     cx,22
	add     si,20
	add     di,offset SarInst.InstName
	rep     movsb
	pop     di
	pop     si
	pop     cx
					;copy [di][SarInst.InstName],[si+20],22
	mov     ax,ds:[si+42]
	xchg    ah,al                   ;Change to Big Endian
	shl     ax,1
	mov     cs:[di][SarInst.Len],ax
	mov     al,ds:[si+44]
	test    al,00001000b                    ;Test Sign
	jz      @NotSigned
	or      al,11110000b                    ;Extend Sign
@NotSigned:
	mov     cs:[di][SarInst.Finetune],al
	mov     al,ds:[si+45]
	mov     cs:[di][SarInst.Volume],al
	mov     ax,ds:[si+46]
	xchg    ah,al
	shl     ax,1
	mov     cs:[di][SarInst.RepStart],ax
	mov     cs:[di][SarInst.Sloop],1        ;Default loop
	mov     bx,ds:[si+48]
	xchg    bh,bl
	shl     bx,1
	;add     ax,bx
	mov     cs:[di][SarInst.RepLength],bx;ax
	or      ax,ax
	jnz     @@Loop
	cmp     bx,4
	ja      @@Loop
	mov     cs:[di][SarInst.Sloop],0
@@Loop:

	add     di,size SarInst
	add     si,cs:Sample_Size
	dec     cl
	jnz     @GetInstrumentInfo

	mov     dx,cs:[FileBuff]
	FreeMem                                 ;Free File Buffer

						;Load Patterns
	Get_Number_Of_Patterns                  ;Return in Song.NumOfPatterns
	mov     al,cs:Song.NumOfChannels
	mov     bl,5    ;SarSong Note Size
	mul     bl
	mov     cs:Song.TotalRowSize,al         ;Save Row Size
	shl     ax,6
	mov     cs:Song.TotalPatSize,ax
	mov     bp,0

	mov     cl,cs:Song.NumOfPatterns        
@LoadAllPatterns:
	push    cx
	mov     ax,cs:song.TotalPatSize         ;Lets Alloc Mem For one Pat
	allocmem
	jc      @NotEnoughMem
	mov     cs:Song.PatternsSeg[bp],dx      ;Save Pat Segment
	mov     es,dx
	xor     di,di
	add     bp,2
	xor     dh,dh
	mov     dl,cs:Song.NumOfChannels
	shl     dx,6
	
@LoadOnePattern:        
	push    dx
	mov     bx,cs:[ModFileHandle]
	mov     cx,4                ;Read Four Bytes (one Note)
	lea     dx,TmpPackNote
	push    cs
	pop     ds
	ReadFile
	jc      @CorruptedFile
				;Unpack the note

	mov     al,cs:[TmpPackNote]
	and     al,11110000b
	mov     ah,cs:[TmpPackNote+2]
	and     ah,11110000b
	shr     ah,4
	or      al,ah
	cmp     al,31
	jbe     @SampNumOk
	xor     al,al
@SampNumOk:
	mov     cs:[TmpNote.SampNum],al
	mov     al,cs:[TmpPackNote+1]
	mov     ah,cs:[tmpPackNote]
	and     ah,00001111b
	mov     cs:[TmpNote.Period],ax
	mov     al,cs:[TmpPackNote+3]
	mov     ah,cs:[TmpPackNote+2]
	and     ah,00001111b
	mov     cs:[TmpNote.Effect],ax


	push cx
	push si
	push di
	mov cx,5        ;length
	lea si,tmpnote
	rep movsb 
	pop di
	pop si
	pop cx
	
	add     di,5
	pop     dx
	dec     dx
	jnz     @LoadOnePattern
	pop     cx
	dec     cl
	jnz     @LoadAllPatterns
				
				;Load Samples Datas
	cmp     cs:device.card,GUS        
	jz      @GusLoad

	lea     di,Song.Inst
	xor     bh,bh
	mov     bl,cs:[Number_Of_Samples]
	mov     bp,bx
       
@LoadSamplesLow:
	mov     ax,cs:[di][SarInst.Len]
	or      ax,ax
	jz      @NoSample
	Allocmem
	jc      @notenoughmem
	mov     word ptr cs:[di][SarInst.SampSeg],dx
	
	mov     bx,cs:ModFileHandle
	mov     cx,cs:[di][SarInst.Len]
	mov     ds,dx
	xor     dx,dx
	ReadFile
	jc      @corruptedFile
@Nosample:        
	add     di,Size SarInst
	
	dec     bp
	jnz     @LoadSamplesLow
	pop     ds
	popa
	clc
	ret

@GusLoad:
	mov     cs:Gus_Mem_Pointer,0
	lea     di,Song.Inst
	xor     bh,bh
	mov     bl,cs:[Number_Of_Samples]
	mov     bp,bx

@LoadSamplesGus:
	mov     ax,cs:[di][SarInst.Len]
	or      ax,ax
	jz      @@NoSample
	Allocmem
	jc      @notenoughmem
	
	push    dx
	mov     bx,cs:ModFileHandle
	mov     cx,cs:[di][SarInst.Len]
	mov     ds,dx
	xor     dx,dx
	ReadFile
	jc      @corruptedFile
	
	mov     ebx,cs:Gus_Mem_Pointer
	mov     cs:[di][SarInst.SampSeg],ebx
	mov     cx,cs:[di][SarInst.Len]
	call    Mem2Gus
	mov     cs:Gus_Mem_Pointer,ebx
	pop     dx
	freemem
@@NoSample:        
	add     di,Size SarInst
	dec     bp
	jnz     @LoadSamplesGUS
	pop     ds
	popa
	clc
	ret



@FileNotFound:
	pop     ds
	popa
	xor     ax,ax
	stc
	ret
@CorruptedFile:
	pop     ds
	popa
	mov     ax,2
	stc
	ret
@NotEnoughmem:
	pop     ds
	popa
	mov ax,1
	stc
	ret
ModLoad endp

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
