; PcxLite por Manuel Astudillo
; Saludos Jesus!


.386
.model flat
.Stack


EXTRN AllocMem : NEAR
EXTRN FreeMem  : NEAR

.code

;include memory.inc

PcxFilename     db      'picture.dat',0

Pcxadr          dd      0

VideoPtr        dd      0

start:

        mov     ax,0ee02h
        int     31h
        mov     edi,0a0000h
        sub     edi,ebx
        mov     [VideoPtr],edi

        mov     ax,13h
        int     10h
        lea     edx,PcxFilename
        call    LoadPcx
        jc      @exitnow
        mov     esi,edi
        add     esi,64000
        call    setpalette
        mov     Pcxadr,edi
        mov     esi,edi
        call    dump2screen
        
        xor     ax,ax
        int     16h


@exitnow:
        mov     ax,3h
        int     10h

        mov     ax,4c00h
        int     21h


; Load Pcx
; In: edx (Offset of Filename in ASCIZZ)
; Return: edi : Pointer to 320x200 Picture followed by 768 palette bytes.

PcxHandle       dw      ?
DummyBuff       db      ?
PcxHeader       db      128     dup (?)
PcxPointer      dd      ?
PcxCompressed   dd      ?
PcxLength       dd      ?

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
        lea     edx,DummyBuff
        mov     ecx,128
        int     21h

                                ;Alloc Mem For Final Picture
        mov     edx,64000+768   ;Pic & Pal
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
        
        mov     ebx,64000       ;64000 bytes to process
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
        add     edx,64000
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


Dump2Screen proc
        push    esi
        push    edi
        push    ecx
        mov     edi,[VideoPtr]
        mov     ecx,16000
        rep     movsd
        pop     ecx
        pop     edi
        pop     esi
        ret
Dump2Screen endp

SetPalette PROC ; in esi the offset to palette
        mov     dx,3c8h
        mov     al,0
        out     dx,al
        inc     dx
        mov     cx,300h
@SetPal:
        mov     al,[esi]
        shr     al,2
        out     dx,al
        inc     esi
        dec     cx
        jnz     @SetPal
        ret
SetPalette Endp


end start
