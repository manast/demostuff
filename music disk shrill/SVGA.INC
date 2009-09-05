; ---------------------------------------------------------------------------
; SVGA Library by Sarwaz / Mistery
; (c) Mistery June 1997
; ---------------------------------------------------------------------------

; Structures

SVGAInfoBlock struc
        VESASignature   db      'VESA'
        VESAVersion     dw      ?
        OEMStringPtr    dd      ?
        Capabilities    db      4       DUP (?)
        VideoModePtr    dd      ?
        TotalMemory     dw      ?

        OemSoftwareRev      dw   ?         ; VBE implementation Software revision
        OemVendorNamePtr    dd   ?         ; Pointer to Vendor Name String
        OemProductNamePtr   dd   ?         ; Pointer to Product Name String
        OemProductRevPtr    dd   ?         ; Pointer to Product Revision String
        _Reserved_          db   222 dup (?); Reserved for VBE implementation
                                            ; scratch area
        OemData             db   256 dup (?); Data Area for OEM Strings

        Reserved            db      236     DUP (?)    
SVGAInfoBLock ends

ModeInfoBlock   struc

     ; Mandatory information for all VBE revisions
     ModeAttributes      dw ?      ; mode attributes
     WinAAttributes      db ?      ; window A attributes
     WinBAttributes      db ?      ; window B attributes
     WinGranularity      dw ?      ; window granularity
     WinSize             dw ?      ; window size
     WinASegment         dw ?      ; window A start segment
     WinBSegment         dw ?      ; window B start segment
     WinFuncPtr          dd ?      ; pointer to window function
     BytesPerScanLine    dw ?      ; bytes per scan line

     ; Mandatory information for VBE 1.2 and above
     XResolution         dw ?      ; horizontal resolution in pixels or chars
     YResolution         dw ?      ; vertical resolution in pixels or chars
     XCharSize           db ?      ; character cell width in pixels
     YCharSize           db ?      ; character cell height in pixels
     NumberOfPlanes      db ?      ; number of memory planes
     BitsPerPixel        db ?      ; bits per pixel
     NumberOfBanks       db ?      ; number of banks
     MemoryModel         db ?      ; memory model type
     BankSize            db ?      ; bank size in KB
     NumberOfImagePages  db ?      ; number of images
     _Reserved           db ?      ; reserved for page function

     ; Direct Color fields (required for direct/6 and YUV/7 memory models)
     RedMaskSize         db ?      ; size of direct color red mask in bits
     RedFieldPosition    db ?      ; bit position of lsb of red mask
     GreenMaskSize       db ?      ; size of direct color green mask in bits
     GreenFieldPosition  db ?      ; bit position of lsb of green mask
     BlueMaskSize        db ?      ; size of direct color blue mask in bits
     BlueFieldPosition   db ?      ; bit position of lsb of blue mask
     RsvdMaskSize        db ?      ; size of direct color reserved mask in bits
     RsvdFieldPosition   db ?      ; bit position of lsb of reserved mask
     DirectColorModeInfo db ?      ; direct color mode attributes

     ; Mandatory information for VBE 2.0 and above
     PhysBasePtr         dd ?      ; physical address for flat frame buffer
     OffScreenMemOffset  dd ?      ; pointer to start of off screen memory
     OffScreenMemSize    dw ?      ; amount of off screen memory in 1k units
     __Reserved          db 206 dup (?)  ; remainder of ModeInfoBlock
ModeInfoBlock ends


Real_Mode_Registers_Struc    struc
        RealMode_EDI         DD     ?
        RealMode_ESI         DD     ?
        RealMode_EBP         DD     ?
                             DD     ?                  ; Unused
        RealMode_EBX         DD     ?
        RealMode_EDX         DD     ?
        RealMode_ECX         DD     ?
        RealMode_EAX         DD     ?
        RealMode_flags       DW     ?
        RealMode_ES          DW     ?
        RealMode_DS          DW     ?
        RealMode_FS          DW     ?
        RealMode_GS          DW     ?
        RealMode_IP          DW     ?
        RealMode_CS          DW     ?
        RealMode_SP          DW     ?
        RealMode_SS          DW     ?              
Real_Mode_Registers_Struc    ends


;Variables

RM_Registers Real_Mode_Registers_struc <>

RM_8k_File_Buffer       dd      ?
RM_8k_Segment           dw      ?
SVGAInfoPtr             dd      ?
ModeInfoPtr             dd      ?
ProgramBaseAdress       dd      ?
ModeInfo        ModeInfoBlock   <>

N_Banks                 dw      ?
CurrentBank             dw      0

VideoPtr                dd      ?


PUBLIC  ScreenX,ScreenY

ScreenX                 dw      ?
ScreenY                 dw      ?


SVGAInfoArray   SVGAInfoBlock <>
ModeInfoArray   ModeInfoBlock <>


VesaStr1        db 'Mistery SVGA Library v0.1 by Sarwaz',13,10,36
VesaStr2        db 'Bad news: Vesa BIOS not found',13,10,36
VesaStr3        db 'þ VBE version ',36
VesaStr4        db ' found',13,10,36
VesaStr5        db 'þ Video Memory on board: ',36
VesaStr6        db ' Kb',13,10,'-----------------------------------',13,10,36

;Macros

SetCursor       macro   x,y
        push    ax
        push    dx
        mov     ah,2
        mov     dh,y
        mov     dl,x
        int     10h
        pop     dx
        pop     ax
                endm


; CheckVBE -
; Test for Vesa bios and shows information on screen
; Return: carry = 0 if vesa
;         carry = 1 if not vesa
; Global  SVGAInfoPtr -> pointer to SVGAInfoBlock

CheckVBE        proc
        lea     edx,VesaStr1
        mov     ah,9h
        int     21h       
                                ;Get 8k Real mode segment
        mov     ax,0EE02h
        int     31h
        mov     [RM_8k_segment],ax
        mov     [RM_Registers.RealMode_ES],ax
        and     eax,0ffffh
        shl     eax,4           ; calc the Phisic adress
        mov     ProgramBaseAdress,ebx
        sub     eax,ebx         ; calc the offset relative to Program Adress
        mov     RM_8k_File_Buffer,eax
        mov     SVGAInfoPtr,eax
        mov     [RM_Registers.RealMode_EDI],0
        mov     [RM_REgisters.RealMode_EAX],00004f00h
        mov     bx,10h
        xor     cx,cx
        lea     edi,RM_Registers
        mov     ax,0300h        ;Simulate Real Mode Interrupt
        int     31h

        mov     eax,[RM_Registers.RealMode_EAX]
        cmp     ax,004fh
        jz      @VBEOk
        lea     edx,VesaStr2
        mov     ah,9h
        int     21h
        stc
        ret
@VBEOk:
        lea     edx,VesaStr3
        mov     ah,9h
        int     21h
        mov     ebp,SVGAInfoPtr
        mov     al,byte ptr [ebp.VesaVersion+1]
        call    WrHex
        mov     ah,0ah
        mov     al,'.'
        mov     bh,0
        mov     cx,1
        int     10h
        call    AdvanceCursor
        mov     al,byte ptr [ebp.VesaVersion]
        call    WrHex
        lea     edx,VesaStr4
        mov     ah,9h
        int     21h
        lea     edx,VesaStr5
        mov     ah,9h
        int     21h
        mov     ax,[ebp.TotalMemory]
        shl     ax,6
        call    WriteWord

        lea     edx,VesaStr6
        mov     ah,9h
        int     21h

                                ;Copy SvgaInfo to internal Array
        mov     esi,ebp
        lea     edi,SVGAInfoArray
        mov     ecx,256
        rep     movsb

        clc
        ret


CheckVBE        endp


;SetVBEmode
; Sets a SVGA mode and return carry if error
; IN: AX, SVGA video mode
; OUT: ModeInfoPtr, Pointer to Mode Info Block

SetVBEmode      proc
                        ;First Check if Video Mode is supported
        test    ax,100000000b
        jnz     @SVGAVideoMode
        int     10h
        clc
        ret
@SVGAVideoMode:
        lea     ebp,SVGAInfoArray
        movzx   edx,word ptr [ebp.VideoModePtr+2]  ;Calc Phisic Adress
        shl     edx,4
        sub     edx,ProgramBaseAdress
        movzx   ebx,word ptr [ebp.VideoModePtr]
        add     edx,ebx
        mov     bx,ax
@TestMode:
        mov     ax,[edx]
        cmp     ax,0ffffh
        jz      @ModeNotAvailable
        add     edx,2
        cmp     ax,bx
        jnz     @TestMode
      
        mov     ax,4f02h        ;Set SVGA mode
        int     10h
                                ;Get mode Info
        mov     ax,RM_8k_segment
        mov     [RM_Registers.RealMode_ES],ax
        mov     [RM_Registers.RealMode_EDI],256
        mov     eax,[SVGAInfoPtr]
        add     eax,256
        mov     [ModeInfoPtr],eax
        mov     [RM_Registers.RealMode_EAX],00004f01h
        mov     [RM_Registers.RealMode_ECX],ebx
        mov     bx,10h
        xor     cx,cx
        lea     edi,RM_Registers
        mov     ax,0300h        ;Simulate Real Mode Interrupt
        int     31h

                                ;Calc Number of Banks per window
        mov     ebp,[ModeInfoPtr]
        xor     eax,eax
        xor     ebx,ebx
        xor     edx,edx
        mov     eax,640*480 ;[ebp.WinSize]      ;!!!!!!!!!
        mov     bx,[ebp.WinGranularity]
        shl     ebx,10
        div     ebx
        inc     ax
        mov     [N_Banks],ax
                                ; Get Video Ptr
        mov     ax,0ee02H
        int     31h
        mov     eax,0a0000h
        sub     eax,ebx
        mov     [VideoPtr],eax
                                ; Copy ModeInfoblock to internal array
        mov     esi,[ModeInfoPtr]
        lea     edi,ModeInfoArray
        mov     ecx,256
        rep     movsb

        mov     ax,[ModeInfoArray.Xresolution]
        mov     ScreenX,ax
        mov     ax,[ModeInfoArray.Yresolution]
        mov     ScreenY,ax
       
        clc
        ret
@ModeNotAvailable:
        stc      
        ret
SetVBEMode      endp

; Dumps a buffer to the screen (using bank switching)
; In: esi: Pointer to Buffer (buffer has to have Xscreen*Yscreen length)

Dump2Screen     proc
        pusha
        call    SetStartBank
        lea     ebp,ModeInfoArray
        xor     ebx,ebx
        mov     bx,[ModeInfoArray.Xresolution]
        xor     eax,eax
        mov     ax,[ModeInfoArray.Yresolution]
        mul     ebx                   ;Calc Buffer length

        
@NextBlock:               
        mov     edi,[VideoPtr]
                                        ;We dump in 64k blocks
        cmp     eax,65536 ;0ffffh
        jb      @LastBlock
        mov     ecx,16384 ;/4 ;0ffffh
        rep     movsd
        call    NextBank
        sub     eax,65536 ;0ffffh
        jmp     @NextBlock
@LastBlock:
        mov     ecx,eax
        rep     movsb
        popa
        ret
Dump2Screen     endp


; Allocates a Buffer for Video Transfers
; Out: edx, Pointer to buffer

AllocBuffer     proc
        push    ebp
        push    eax
        push    ebx

        lea     ebp,ModeInfoArray
        xor     ebx,ebx
        mov     bx,[ModeInfoArray.Xresolution]
        xor     eax,eax
        mov     ax,[ModeInfoArray.Yresolution]
        mul     ebx                   ;Calc Buffer length

        mov     edx,eax
        call    allocmem

        pop     ebx
        pop     eax
        pop     ebp
        ret
AllocBuffer     endp


;In: edi: buffer

ClearBuffer     proc
        pusha
        
        lea     ebp,ModeInfoArray
        xor     ebx,ebx
        mov     bx,[ModeInfoArray.Xresolution]
        xor     eax,eax
        mov     ax,[ModeInfoArray.Yresolution]
        mul     ebx                   ;Calc Buffer length

        mov     ecx,eax
        xor     al,al
        rep     stosb

        popa
        ret
ClearBuffer     endp




;  Switch to next bank
;  Needs GLobal variable CurrentBank

NextBank        proc
        push    eax
        push    ebx
        push    ecx
        push    edx
        push    ebp
        mov     eax,64
        lea     ebp,ModeInfoArray
        xor     ebx,ebx
        mov     bx,[ModeInfoArray.WinGranularity]
        xor     edx,edx
        div     ebx
        
        add     [CurrentBank],ax

        mov     dx,[CurrentBank]
        cmp     dx,[N_Banks]
        jb      @BankOk
        xor     dx,dx
        mov     [CurrentBank],0
@BankOk:
        xor     cx,cx
        mov     ax,4f05h
        xor     ebx,ebx
        int     10h
        pop     ebp
        pop     edx
        pop     ecx
        pop     ebx
        pop     eax
        ret
NextBank        endp


SetStartBank    proc
        push    ax
        push    bx
        push    cx
        push    dx
        mov     [CurrentBank],0
        xor     edx,edx
        xor     ecx,ecx
        mov     ax,4f05h
        xor     ebx,ebx
        int     10h
        pop     dx
        pop     cx
        pop     bx
        pop     ax
        ret
SetStartBank    endp


WrHex   proc
        mov     dl,al
        and     al,0F0h
        shr     al,4
        cmp     al,10
        jb      @Noadd7
        add     al,7
@NoAdd7:
        or      al,al
        jz      @Skip1
        add     al,'0'
        mov     ah,0ah
        mov     bh,0
        mov     cx,1
        int     10h
        call    AdvanceCursor
@Skip1:
        mov     al,dl
        and     al,0fh
        cmp     al,10
        jb      @@Noadd7
        add     al,7
@@Noadd7:
        add     al,'0'
        mov     ah,0ah
        mov     bh,0
        mov     cx,1
        int     10h
        call    AdvanceCursor

        ret
WrHex   endp

AdvanceCursor   proc
        pusha
        mov     ah,3h
        mov     bh,0
        int     10h
        inc     dl
        SetCursor dl,dh
        popa
        ret
AdvanceCursor   endp

wordTmp db 36,36,36,36,36,36

WriteWord       proc
        push    ax
        push    dx
        push    esi
        push    bx
        push    ebp

        lea     ebp,WordTmp
        mov     esi,4
        mov     bx,10
Word_a_Asc:
        xor     dx,dx
        or      ax,ax
        jz      finfirrin 
        div     bx
        add     dl,48
        mov     [ebp+esi],dl
        dec     esi
        cmp     esi,-1
        jnz     Word_a_Asc
finfirrin:
        cmp     esi,-1
        jz      @RealEnd
        mov     byte ptr [ebp+esi],48
        dec     esi
        jmp     finfirrin
        
@RealEnd:
        lea     esi,WordTmp
        call    WriteString

        pop     ebp
        pop     bx
        pop     esi
        pop     dx
        pop     ax
        ret
WriteWord       endp

writeString proc
        push    edx
        push    ax
        mov     edx,esi
        mov     ah,9h
        int     21h
        pop     ax
        pop     edx
        ret
WriteString endp

