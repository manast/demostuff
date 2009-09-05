;Sarwaz Sprites Engine (SSE (Tm)) in Mode X - By Sarwaz/MiSTERY

 crt_reg        equ 3d4h
 seq_reg        equ 3c4h

 plane0         equ 0102h                                 
 plane1         equ 0202h
 plane2         equ 0402h
 plane3         equ 0802h

 Head db 'Sarwaz Sprites Engine - Copyright Manuel Astudillo Rudolph 78965820-N' 
 SpritesTable dw 256 dup (0)
 Curr_Handle db 0 
 
 pushpointer macro
	push di
	endm
 
 poppointer macro
	pop di
	endm

;Put_Sprite. Prints a Sprite on the screen.
;Inputs: si - Sprite Number
;        ax,bx - New Coord X,New Coord Y

Put_Sprite PROC
	   shl si,1
	   mov es,cs:SpritesTable[si]
	   mov si,0a000h                
	   mov ds,si
	   xor si,si
	   mov di,es:[si+6]
	   mov es:[si],ax
	   mov es:[si+2],bx
	   shl bx,4  ;4 because 16*5=80. This should change to 64*5=320
	   lea ebx,[ebx*4+ebx]
	   add bx,ax
	   mov si,bx
	   
	   mov cl,es:[si+4]
	   mov bl,es:[si+5]
	   push bx
	   push cx
	   push si
	   call Copy ;Here We save the background
	   pop di
	   push ds
	   push es
	   pop ds
	   pop es
	   xor bx,bx
	   mov si,8   ;ds:08 = Begining of the sprite data
	   pop cx        
	   pop bx
	   call Copy
	   ret
Put_Sprite endp

;Move_Sprite. Moves a Sprite in the screen. 
;Inputs: Si, Number Of Sprite
;        cl, 0=move right, 1=move left,2=move up, 3=move down
;        ch, Speed. from 1 to 255 (anyway, more than 8 will produce too fast
;                                  Sprites)


Move_Sprite Proc
	    ;Primero tenemos que restaurar el fondo anterior
	    push si
	    push cx
	    shl si,1
	    mov ds,cs:SpritesTable[si]
	    xor si,si
	    mov bx,ds:[si+2]
	    shl bx,4
	    lea ebx,[ebx*4+ebx]
	    mov di,0a000h
	    mov es,di
	    mov di,bx
	    add di,ds:[si]
	    mov cl,ds:[si+4]
	    mov bl,ds:[si+5]
	    mov si,ds:[si+6]
	    Call Copy
			;Ahora tenemos que Incrementar las coords del 
			;Sprite y Pintarlo con Put_Sprite
	    xor si,si
	    pop cx
	    cmp cl,1
	    jz @left
	    cmp cl,2
	    jz @right
	    cmp cl,3
	    jz @up
	    cmp cl,4
	    jz @down
@left:
	    sub word ptr ds:si,ch
	    pop si
	    mov ax,ds:si
	    mov bx,ds:si+2
	    call Put_sprite
	    ret

@right:     
	    add word ptr ds:si,ch
	    pop si
	    mov ax,ds:si
	    mov bx,ds:si+2
	    call Put_sprite
	    ret

@up: 
	    sub word ptr ds:si+2,ch
	    pop si
	    mov ax,ds:si
	    mov bx,ds:si+2
	    call Put_sprite
	    ret

@down:
	    add word ptr ds:si+2,ch
	    pop si
	    mov ax,ds:si
	    mov bx,ds:si+2
	    call Put_sprite
	    ret
Move_Sprite Endp


;Copy sprite from ds:si to es:di, (From Host to VideoMem or ViceVersa)
;in cx X width
;in bx Y width

Copy proc 
    xor ch,ch
    xor bh,bh
    mov bp,bx
    shr bp,2
    neg bp
    add bp,80  ;This stuff do this: bp=80-bp
    shr cx,2
    mov dx,seq_reg
    mov ax,plane0
    out dx,ax
    pushpointer   ;for plane 0
    push bx
@plane0:
    push cx
    shr cx,1
    rep movsw
    adc cx,cx
    rep movsb
    pop cx
    add di,bp
    dec bx
    jnz @plane0
    pop bx
    poppointer    ;end plane 0

    mov ax,plane1
    out dx,ax
    pushpointer ;for plane 1
    push bx
@plane1:
    push cx
    shr cx,1
    rep movsw
    adc cx,cx
    rep movsb
    pop cx
    add di,bp
    dec bx
    jnz @plane1
    pop bx
    poppointer ;end plane 1

    mov ax,plane2 ;for plane 2
    out dx,ax
    pushpointer
    push bx
@plane2:
    push cx
    shr cx,1
    rep movsw
    adc cx,cx
    rep movsb
    pop cx
    add di,bp
    dec bx
    jnz @plane2
    pop bx
    poppointer ;End plane 2

    mov ax,plane3 ;for plane 3
    out dx,ax
    pushpointer
    push bx
@plane3:
    push cx
    shr cx,1
    rep movsw
    adc cx,cx
    rep movsb
    pop cx
    add di,bp
    dec bx
    jnz @plane3
    pop bx
    poppointer    ;end plane 3
    ret
Copy endp

;Create_Sprite. Reserves a Memory location for a specific Sprite.
; Inputs: Al=X,Bl=Y
; Output: es segment to the structure
;Note that the sprite has to have this equat. x*y<32000
; Format:
; Offset   Long   Description
;  0000     2       Screen Position X Coord
;  0002     2       Screen Position Y Coord
;  0004     1       Sprite X long
;  0005     1       Sprite Y long
;  0006     2       Offset Of Sprite Background (n+8)
;  0008     n       Sprite Data (organized in planes)
;  ...
;  n+8      n       Sprite BackGround (organized in planes)


Create_Sprite PROC
	 push ax
	 push bx
	 mul bl
	 mov cx,ax
	 shr ax,3
	 add ax,2
	 mov bx,ax
	 mov ax,48h
	 int 21h
	 mov es,ax
	 pop bx
	 pop ax
	 xor di,di
	 mov es:[di+4],al
	 mov es:[di+5],bl
	 add cx,6
	 mov es:[di+6],cx
	 ret
Create_Sprite endp

;Sets the data and the initial position of the sprite.
;Inputs : ax,bx the Initial position of the sprite in the screen
;         ds:si -> pointer to the sprite data in SSE Format (Explained later)
;         cl -> handle of the sprite

	 
Set_Sprite PROC
	push cx
	xor ch,ch
	shl cx,1
	
	lea di,SpritesTable
	add di,cx
	mov es,cs:di
	mov di,4
	mov cl,es:di ;In cl the sprite X width
	mov dl,es:di+1 ;In ch the sprite Y width
	xor ch,ch
	mov di,8

@@1: 
	push cx
	shr cl,1
	rep movsw
	adc cl,cl
	rep movsb
	pop cx
	add si,320
	sub si,cx
	dec dl
	jnz @@1
	ret
Set_Sprite endp
	
