;-----------------------------------------------------------------
; 320x200x256 Multidimensional Scroll Rutines by Manuel Astudillo.
; May 97
; Note: coded for SAR MAP structures
;-----------------------------------------------------------------


ScrollPlanes struc
        HorzPanPos      db 0
        VertPanPos      db 0
        MapPointer      dd ?
ScrollPlanes ends


InitScrollSystem proc
        mov     edx,64000
        call    AllocMem
        jc      @InitScrollError
        mov     [VirtualScreen],edx
        clc
        ret
@InitScrollError:
        stc
        ret
InitScrollSystem endp


;SetHorzPanPos
;In: al (Pan position of a tile)

SetHorzPanPosPlane1 proc
        mov     [Plane1.HorzPanPos],al        
        ret
SetHorzPanPosPlane1 endp


; IncHorzPan

IncHorzPanPlane1    proc
        mov     edi,[Plane1.MapPointer]
        mov     bl,[edi.TileXwidth]
        mov     al,[Plane1.HorzPanPos]
        inc     al
        cmp     al,bl
        jbe     @NotOverflow
        xor     al,al
        mov     [Plane1.HorzPanPos],al
        stc
        ret
@NotOverflow:
        mov     [Plane1.HorzPanPos],al
        clc
        ret
IncHorzPanPlane1    endp

; decHorzPan

DecHorzPanPlane1        proc
        mov     edi,[Plane1.MapPointer]
        mov     bl,[edi.TileXwidth]
        mov     al,[Plane1.HorzPanPos]
        dec     al
        xor     ah,ah
        div     bl
        cmp     dl,bl
        jne     @NotOverflow2
        mov     [Plane1.HorzPanPos],dl
        stc
        ret
@NotOverflow2:
        mov     [Plane1.HorzPanPos],dl
        clc
        ret
DecHorzPanPlane1        endp

;IncVertPan

IncVertPanPlane1        proc
        mov     edi,[Plane1.MapPointer]
        mov     bl,[edi.TileYwidth]
        mov     al,[Plane1.VertPanPos]
        inc     al
        xor     ah,ah
        div     bl
        mov     [Plane1.VertPanPos],dl
        ret
IncVertPanPlane1        endp

;DecVertPan

DecVertPanPlane1        proc
        mov     edi,[Plane1.MapPointer]
        mov     bl,[edi.TileXwidth]
        mov     al,[Plane1.VertPanPos]
        dec     al
        xor     ah,ah
        div     bl
        mov     [Plane1.VertPanPos],dl
        ret
DecVertPanPlane1        endp


; Puts a tile in desired x,y pos according with PanPos
; In: esi,edi (source, dest);
;     ch,cl (Xpan,Ypan); dh,dl (Xw,Yw)

TmpReg1  dd 0
TmpReg2  dd 0


PutTile proc

        mov     byte ptr [TmpReg1],ch
        sub     dh,ch   ;Get new Screen Tile Width
        xor     ah,ah
        mov     al,dh
        mov     word ptr [TmpReg2],320
        sub     word ptr [TmpReg2],ax
        inc     dl
@Bucle:
        push    cx
        xor     ch,ch
        mov     cl,dh
        rep     movsb
        add     esi,[TmpReg1]
        add     edi,[TmpReg2]
        pop     cx
        dec     dl
        dec     cl
        jnz     @Bucle
        del     dl
        jnz     @Bucle

        ret
PutTile endp

; In: esi: Pointer to Picture
;     ax: X Pos, bx: Y Pos, cl: X Width, ch: Y Width

PutBob proc
        push    ebp
        push    ebx
        push    cx
        push    dx
        push    edi
        push    esi
        mov     ebp,[VideoPtr]
        add     ebp,64000
        
        and     ebx,0000ffffh
        lea     ebx,[ebx*4+ebx] ;bx*5
        shl     bx,6            ;bx*64
        add     bx,ax
        mov     edi,[VideoPtr]
        add     edi,ebx
        mov     dl,ch
        xor     ch,ch
@MoveBlock:
        push    cx
        push    edi
        rep     movsb
        pop     edi
        pop     cx
        add     edi,320
        cmp     edi,ebp
        jae     @Nomore
        dec     dl        
        jnz     @MoveBlock
@NoMore:
        pop     esi       
        pop     edi
        pop     dx
        pop     cx
        pop     ebx
        pop     ebp
        ret
PutBob endp



