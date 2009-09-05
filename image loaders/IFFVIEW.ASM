; IFF PBM 320 * 200 * 256 loading procedure
; Unreal of SURPRISE!
; This is quite fast procedure for loading 320*200*256 PBM pictures (DPIIE)
; You can use it freely, as long as You want, in any way You want.

CODE SEGMENT PUBLIC
ASSUME CS:CODE
.286C                                   ; I am using some 286>> codes here

;======================================================================

Start:    
	call load                     ;we load the image!
	mov       ax,13h              ; 320*200*256, 1 byte = 1 point, no planes
	int       10h                 ; set with clearing video-memory

	mov       ax,seg DATA
	mov       ds,ax
	mov       si,offset PICTURE
	call      Show2sc   

ASD:      in        al,60h
	cmp       al,1
	jne       ASD
	mov       ax,03               ;back to text screen mode
	int       10h
	mov       ax,4c00h  ;End of program, 00=return value, no errors
	int       21h

;-----------------------------------------------------------------------
;- Show2Sc - includes Searching4CMAP, SettingColors, Seatching4BODY,   -
;- and finally Showing 320*200*256 IFF PBM to Screen.                  -
;- IN: DS:[SI] - address in segment and offset to the PBM picture data -
;-----------------------------------------------------------------------

Offset2BODY dw 0    ;There will be stored offset to the BODY chunk
Offset2CMAP dw 0    ;And there to CMAP
CurrentSi   dw 0    ;Save the si

Show2Sc:
;--------------------------------------: Searching for CMAP signature
	mov       CurrentSi,si
	mov       cx,64000                       ;Test only 1st 5000 bytes of IFF
CMAPSearch:mov      ax,word ptr ds:[si]
	cmp       ax,'MC'                       ; after XCHG ah,al='CM'
	je        CM_Found            ; jump if You found the CM part of
					; "CMAP" signature
	add       si,2

	dec       cx
	jnz       CMAPSearch

TheEnd:   ret

CM_Found:
	add       si,2
	mov       ax,word ptr ds:[si]
	cmp       ax,'PA'                       ; after xchg ah,al='AP'
	jne       TheEnd
	add       si,2
	mov       Offset2CMAP,si                ; store offset 
;--------------------------------------------------------------
	mov       si,CurrentSi
;--------------------------------------: Here is the part which sets colors
SetColors:
	mov       si,Offset2CMAP
	add       si,4                          ;skip the header of chunk

	cli                                     ; It's quite good 2 disable int. here
	mov       ax,0
	mov       dx,3c8h 
	out       dx,al 
	mov       cx,0300h            ; 768 times [palette size]
	inc       dx 
	
CSET:     mov       al,[si]
	shr       al,2                          ; Always divide by 4!
	out       dx,al 
	inc       si
	dec       cx
	jnz       CSET
	sti

;--------------------------------------: Search for BODY signature
Search4BODY:
	mov       si,CurrentSi
	mov       cx,64000
Search:   mov       ax,word ptr ds:[si]
	cmp       ax,'OB'
	je        BO_Found
	add       si,2
	dec       cx
	jnz       Search
	jmp       TheEnd
BO_Found:
	mov       ax,word ptr ds:[si+2]
	cmp       ax,'YD'
	jne       TEnd
	mov       Offset2BODY,si
TEND:

	mov       si,CurrentSi

;--------------------------------------: Finally show the picture
show256:
	mov       dx,3c4h
	mov       al,1
	out       dx,al
	inc       dx
	mov       al,100011b
	out       dx,al

	mov       si,Offset2BODY
	add       si,8

	mov       ax,0a000h
	mov       es,ax
	mov       di,0
	mov       cx,64000

Show1Ln:
	mov       al,byte ptr ds:[si]
	cmp       al,0
	jl        lower
	jge       higher

NoMatt: 
	dec       cx
	jnz       Show1Ln

Kn:       mov       dx,3c4h
	mov       al,1
	out       dx,al
	inc       dx
	mov       al,000011b
	out       dx,al                         ; Turn the screen on

	ret

higher:   
	cbw
	mov       dx,cx                         ;Store counter
	inc       dx                            ; And increase that stored one

	inc       ax                            ; Increase copy-loop length

WPUNR:    inc       si
	mov       bl,byte ptr ds:[si] ;get byte from PBM
	mov       byte ptr es:[di],bl ;copy to screen
	inc       di

	dec       dx
	cmp       dx,0                          ; if that's all, get owt
	je        Kn

	dec       ax
	jnz       WPUNR
	inc       si

	mov       cx,dx                         ; restore cx
	jmp       NoMatt

	
lower:
	neg       al
	cbw
	mov       dx,cx
	inc       dx

	inc       si
	inc       ax
	mov       bl,byte ptr ds:[si]
WPUNR1:   mov       byte ptr es:[di],bl
	inc       di
	dec       dx
	cmp       dx,0
	je        Kn

	dec       ax
	jnz       WPUNR1
	inc       si

	mov       cx,dx
	jmp       NoMatt

msdos proc
       mov ax,4C00h
       int 21h
       ret
msdos endp


load PROC
         
         mov ah,3dh
         mov al,00           ;read mode
         mov dx,seg DATA
         mov ds,dx
         lea dx,filenam      ;we get the offset of the file to read
         int 21h             ;eh!
         jc error            ;mmh!, bad filename!
         
         xchg ax,bx          ;lets put file handle in bx
         mov ah,3fh
         mov cx,64000        ;yep, 64000 bytes (320x200x256)
         lea dx,picture      ;image offset. aha!
         int 21h             ;reading!! in ax number of read bytes
         jc error2
         jmp fin             ;OK!

error:   mov ax,3
         int 10h
         mov dx,OFFSET merror;nothing yet
         mov ah,9
         int 21h
         call msdos

error2:  mov ax,3
         int 10h
         mov dx,OFFSET merror2 ;nothing yet
         mov ah,9
         int 21h
         call msdos

fin:         ;correctly loaded!
         ret

load endp



CODE ENDS
DATA SEGMENT
; There lies picture
   PICTURE DB 64000 DUP (?)
   filenam  db 'dib1.lbm',0
   handle1 dw 0
   merror db 'ERROR opening archive!!$'
   merror2 db 'ERROR reading archive!!$'
   good    db 'Archive loaded correctly!!$'
DATA ENDS
End Start
;***************************************************************************
;********************* Raw loader V.1.0 ************************************
;***************************************************************************
;********************* by Sarwaz/mistery ***********************************
;***************************************************************************
