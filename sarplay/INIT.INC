; Carry set if error initializing , ax = error code
; error codes: 1 = NO Soundcard detected

SB      equ     1
GUS     equ     2

InitPlayer proc far
        pusha
;        call    SetPlayerSize           ;!!CAUTION!!
        push    cs
        pop     ds
        call    ResetGus        
        jc      @NoGus
        WriteLn 'Gravis Ultrasound Detected'
        mov     device.card,GUS
        mov     device.ver,1
        mov     ax,cs:GUS_BASE_ADRESS
        mov     device.BaseAdr,ax
        mov     device.stereo,1
        mov     device.MixFreq,44100
        popa
        clc
        ret
@NoGus:        
        call    ResetDSP
        jc      @NoSbCard
        mov     device.card,SB          ;Sb Series
        mov     ax,SB_BASE_ADRESS
        mov     device.BaseAdr,ax
        ;call    DetectDeviceIRQ&DMA
        mov     device.IRQ,5
        mov     device.DMAChan,1
        call    GetVersion
        mov     device.ver,al
        mov     device.stereo,1
        mov     device.Mixfreq,22050

        cmp     device.stereo,0
        jz      @NoStereo
        mov     al,00h
        call    WriteMixer              ;Reset Mixer
        mov     al,0eh                  ;Turn Stereo ON
        call    ReadMixer
        mov     ah,al
        or      ah,22h
        mov     al,0eh
        call    WriteMixer

@NoStereo:

        xor     eax,eax
        mov     ax,device.Mixfreq
        xor     edx,edx
        mov     ebx,50
        div     ebx
        
        cmp      device.stereo,0
        jz      @NoDoubleBufSize
        shl     ax,1

@NoDoubleBufSize:
        shl     ax,1
        mov     DmaBufferSize,ax
        mov     BufBlock,0

        popa
        clc
        ret
@NoSbCard:
        popa
        mov     ax,1
        stc
        ret
InitPlayer endp

SetPlayerSize proc
        push    ax
        push    bx
        push    dx
        push    es
        mov     ah,62h          ;Get Program PSP adress
        int     21h
        dec     bx              ;Get psp MCB adress
        mov     es,bx
        mov     si,3
        mov     dx,es:[si]      ;get Actual Program Size
 ;       mov     bx,seg EndOfProggy
        mov     ax,es
        sub     bx,ax
 ;       lea     ax,EndOfProggy
        shr     ax,4
        add     bx,ax
        add     bx,dx   ;We Add player Code Size
        inc     bx
        mov     ah,4ah
        int     21h
        pop     es
        pop     dx
        pop     bx
        pop     ax
        ret
SetPlayerSize endp
