;様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様
;Macros by Unreal /S!P, And By Sarwaz /MiSTERY

ULoop MACRO what, where
	dec what
	jnz where
ENDM

IFF     MACRO   s,ofs,ss
	mov       ax,s
	mov       ds,ax
	mov       si,offset ofs
	mov       ax,ss
	mov       es,ax
	call      Show2Sc
	ENDM
RAMK PROC
	pusha
	mov       dx,03dah
C:        in        al,dx
	test      al,8
	jz        c
C1:       in        al,dx
	test      al,8
	jnz       c1
	popa
	ret
RAMK ENDP
SetMode MACRO scrmode
	mov       ax,scrmode
	int       10h
	ENDM

Wait4ESC:
	in        al,60h
	cmp       al,1
	jne       Wait4ESC
	ret

IfESC MACRO XCV
	in  al,60h
	cmp al,1
	je  XCV
ENDM

WaitESC MACRO XYZ
	local endd
	in  al,60h
	cmp al,1
	je endd
	jmp XYZ
endd:
ENDM


Quit      MACRO errorcode
	mov       ah,4ch
	mov       al,errorcode
	int       21h
	ENDM

SetPalette MACRO wherefrom, whereform
	mov       dx,3c8h
	mov       al,0
	out       dx,al
	inc       dx
	mov       ax,wherefrom
	mov       ds,ax
	mov       si,offset whereform
	mov       cx,300h
	rep       outsb
	endm

OpenF     MACRO     SEGGY, wh_param, wh_handle
	mov       ah,3dh                        ; Open file
	mov       dx,SEGGY
	mov       ds,dx
	mov       dx,offset wh_param  ; Adress to ASCIIZ filename
	mov       al,0                          ; Read
	int       21h
	mov       wh_handle,ax                  ; handle
	endm

ChLenF  MACRO wh_handle, lengthf    ;check length of a file
	mov       bx,wh_handle
	mov       ax,4202h            ; Set to end of file
	mov       cx,0                          ; We do it to know the length
	mov       dx,0                          ; of a file.
	int       21h
	mov       cx,ax                         ; Length of file in cx
	push      cx                            ; store for usage
	mov       bx,wh_handle                  ; Set counter back to position 0
	mov       ax,4200h
	mov       cx,0
	mov       dx,0
	int       21h
	pop       cx
	mov       lengthf,cx
	endm

REadF     MACRO     HowMany, ReadWhS, ReadWhO, Handlerek
	mov       cx, HowMany
	mov       ax,ReadWhS                ; segment whereto
	mov       ds,ax
	mov       dx,offset ReadWhO   ; offset whereto
	mov       ah,3fh
	mov       bx,handlerek                  ; handle
	int       21h                           ; Read cx bytes
	endm

WriteF    MACRO     WhereRS, WhereRO, hand00, savesize
	mov       bx,hand00           ; Restore handle
	mov       ax,WhereRS
	mov       ds,ax
	mov       dx,offset Wherero
	mov       cx,savesize
	mov       ah,40h                        ; Write 768 bytes of palette
	int       21h
	endm

CreateF MACRO       CrWhS, CrWhO, handle0
	mov     ah,3ch
	mov       cx,0
	mov       dx,CrWhS
	mov       ds,dx
	mov       dx,offset CrWhO
	int       21h
	mov       handle0,ax                    ; Store handle
	endm

CloseF    MACRO     handle1
	mov       ah,3eh                        ; Close file
	mov       bx,handle1
	int       21h
	endm

COPYDD    MACRO     ASEG, AOFS, BSEG, BOFS, SIZE_DOUBLE
	mov       ax,ASEG
	mov       ds,ax
	mov       si,offset AOFS
	mov       ax,BSEG
	mov       es,ax
	mov       di,offset BOFS
	mov       cx,SIZE_DOUBLE
	rep       movsd
	endm

FILLDD    MACRO     AxSEG, AxOFS, SIZE_WORDS, WHAT
	mov       ax,AxSEG
	mov       es,ax
	mov       di,offset AxOFS
	mov       ax,WHAT
	mov       cx,SIZE_WORDS
	rep       stosw
	endm

BlankPal MACRO      ZeroCol, HowMany
LOCAL Locke
	mov       dx,3c8h
	mov       al,ZeroCol
	out       dx,al
	inc       dx
	mov       cx,howmany

Locke:    mov       al,0
	out       dx,al
	out       dx,al
	out       dx,al
	loop      Locke
	endm

SetBlock MACRO  setsize
	mov     ah,4ah
	mov     bx,setsize
	int     21h
ENDM

Alloc MACRO amount, where
	mov     ah,48h
	mov     bx,amount
	int     21h
	mov     where,ax
ENDM

Free MACRO  segm
	mov     ah,49h
	mov     bx,segm
	mov     es,bx
	int     21h
ENDM

;Here begins my own rutines, Sarwaz.

init_modex MACRO ;320x200x256 4 bit planes
	  SEQC_ADRR equ 3c4h
	  CRTC_ADRR equ 3d4h
       
       
       mov ax,13h ;First We initialize the 320x200x256 color mode
       int 10h
       mov dx,SEQC_ADRR
       mov ax,0604h
       out dx,ax  ;This disables CHAIN-4
       mov dx,CRTC_ADRR
       mov ax,0014h  ;Disables dword mode
       out dx,ax
       mov ax,0e317h
       out dx,ax  ;Sets the byte mode

		  ;Lets Clean the screen
       mov ax,0F02h ;This will enable the 4 bit planes (for more speed in 
       mov dx,SEQC_ADRR            
       out dx,ax    ;the cleaning operation)
       mov ax,0a000h
       mov es,ax
       xor di,di
       mov cx,8000h  ;In words, all the display memory
       xor ax,ax
       rep stosw
       ENDM



;様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様様
