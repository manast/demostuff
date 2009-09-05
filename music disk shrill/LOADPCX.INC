; LOADPCX by sarwaz / Mry


; Load Pcx
; In: edx (Offset of Filename in ASCIZZ)
; Return: edi : Pointer to Picture followed by 768 palette bytes.
;         PcxXsize,PcxYsize : Picture X,Y lengths global variables

PcxHandle       dw      ?
DummyBuff       db      ?
PcxHeader       db      128     dup (?)
PcxPointer      dd      ?
PcxCompressed   dd      ?
PcxLength       dd      ?
PcxTotalSize    dd      ?
PcxXsize        dw      ?
PcxYsize        dw      ?

LoadPcx proc
        
                                ;Open File
        mov     ah,3dh
        mov     al,0            ;read Only
        int     21h
        jc      @FileError
        mov     bx,ax
        mov     [PcxHandle],ax
                                
                                ;Get File Length                                
        mov     ah,42h
        mov     al,02h
        mov     bx,[PcxHandle]
        xor     edx,edx
        int     21h
        mov     [PcxLength],eax
        sub     [PcxLength],768 ;Sub Palette
        sub     [PcxLength],128 ;Sub Header
        mov     ah,42h
        mov     al,00h
        mov     bx,[PcxHandle]
        xor     edx,edx
        int     21h
                                
                                ;Read Header
        mov     ah,3fh
        lea     edx,PcxHeader
        mov     ecx,128
        int     21h

                                ;calc mem for final picture
        xor     eax,eax
        xor     ebx,ebx
        mov     ax,word ptr [PcxHeader+4]        ;Get Xmin
        mov     bx,word ptr [PcxHeader+8]        ;Get Xmax
        sub     bx,ax                   ;Get Xwidth
        inc     bx
        mov     [PcxXsize],bx
        mov     cx,word ptr [PcxHeader+6]        ;Get Ymin
        mov     ax,word ptr [PcxHeader+10]       ;Get Ymax
        sub     ax,cx                   ;Get Ywidth
        inc     ax
        mov     [PcxYsize],ax
        mul     ebx

        mov     edx,eax
        mov     [PcxTotalsize],eax      ;Save total size of picture

        add     edx,768                 ;Add palette length

                                ;Alloc Mem For Final Picture
     ;   mov     edx,64000+768   ;Pic & Pal
        call    AllocMem
        jc      @NotEnoughMem
        mov     [PcxPointer],edx
        
                                ;Alloc Mem for Compressed Data
        mov     edx,[PcxLength]
        call    AllocMem
        jc      @NotEnoughMem
        mov     [PcxCompressed],edx
                                ;Read compressed data
        mov     ah,3fh
        mov     bx,[PcxHandle]
        mov     edx,[PcxCompressed]
        mov     ecx,[PcxLength]
        int     21h
                                ;Decompress Data
        
        mov     ebx,[PcxTotalSize]    ;n bytes to process
        mov     esi,[PcxCompressed]
        mov     edi,[PcxPointer]
@Decompress:
        push    ebx
        mov     al,[esi]
        inc     esi
                ;Decode Pcx Data
        mov     ah,al
        and     ah,11000000b
        cmp     ah,11000000b
        jz      @Compressed
        mov     cl,1
        jmp     @RepBytes

@Compressed:
        and     al,00111111b
        mov     cl,al
        mov     al,[esi]
        inc     esi
@RepBytes:
        pop     ebx
        and     ecx,000000ffh
        sub     ebx,ecx
        rep     stosb
        cmp     ebx,0
        jg      @decompress

@GetPalette:
        mov     ax,4200h
        xor     edx,edx
        mov     bx,[pcxhandle]
        int     21h
        
        mov     ah,42h
        mov     al,02h                  ;Put Pointer to end of file
        mov     bx,[pcxHandle]
        xor     edx,edx
        int     21h
                                        ;eax with end of file
        sub     eax,768                ;Sub Palette length
        mov     edx,eax
        mov     ah,42h
        mov     al,00h
        mov     bx,[PcxHandle]
        int     21h
        
        mov     edx,[PcxPointer]
        add     edx,[PcxTotalSize]
        mov     ah,3fh
        mov     bx,[PcxHandle]
        mov     ecx,768
        int     21h
        jc      @FileError
                                ;CLose File
        mov     bx,[PcxHandle]
        mov     ah,3eh
        int     21h
        mov     edi,[PcxPointer]
        clc
        ret
@FileError:
        stc
        ret
@NotEnoughMem:
        stc
        ret
LoadPcx endp

; Dumps a Pcx data (uncompressed) into a VideoBuffer
; IN: esi,edi origin, dest, pointers
; In: ax Buffer X length
;     PcxXsize,PcxYsize Global Variables (updated by LoadPcx)

DumpPcx proc
        push    eax
        push    ebx
        push    edi
        push    esi
        push    ebp
        xor     ebx,ebx
        xor     ebp,ebp
        mov     bx,ax
        mov     bp,[PcxXsize]
        sub     bx,bp

        mov     dx,[PcxYsize]
@CopyLine:
        mov     ecx,ebp
        rep     movsb
        add     edi,ebx
        dec     dx
        jnz     @Copyline
        pop     ebp
        pop     esi
        pop     edi
        pop     ebx
        pop     eax
        ret
DumpPcx endp
