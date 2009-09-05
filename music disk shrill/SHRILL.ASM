; Shrill Music disk coded by Sarwaz

.386p
.model flat

.stack  1024


include usmp.inc        ; Useless player, yahoo!

.code

EXTRN Allocmem : NEAR
EXTRN Freemem  : NEAR


include svga.inc
include loadpcx.inc
;include string.inc

; equ's

        o               equ     offset
        NumSongs        equ     4

; Filenames

BackPicture     db 'shrill.dat',0
Modfilename     db 'e:\demos\mags\imp10\data.002',0
Modfilename2    db 'd:\dark\maldito.xm',0

ModuleArray     dd      o song1,o song2,o song3,o song4,0

song1   db      'zalt1.mod',0
song2   db      'zalt2.mod',0
song3   db      'zalt3.mod',0
song4   db      'zalt4.mod',0


; Pointers

VideoBuffer     dd      ?
BackPicP        dd      ?
USS_Header      dd      ?


; Variables

ActiveMod       db      0       ; Mod that is being Active
PlayingMod      db      0       ; Mod that is being Playingvfg


start:
                        ; Test for svga
        call    checkVBE
        jc      @gotodos
        xor     ax,ax
        int     16h
        
        call    HardwareInit
        
        call    USS_Setup
        jc      @exit

        mov     eax,101h
        call    SetVBEMode      ; set 640x480
        
        lea     edx,backPicture
        call    LoadPcx
        jc      @exit

        mov     [BackPicP],edi
        call    AllocBuffer
        mov     [VideoBuffer],edx
        mov     esi,edi
        mov     edi,edx
        mov     ax,640
        call    DumpPCX

        mov     esi,[BackPicP]
        add     esi,[PcxTotalSize]
        call    SetPalette
        
        mov     esi,[VideoBuffer]
        call    Dump2Screen

                                        ; Load a module
        lea     esi,ModFilename
        call    Mod_load
        mov     [USS_Header],esi
        call    USMP_StartPlay


                                        ; Main Loop
@MainLoop:
                                        ;Test Keys
        xor     ax,ax
        int     16h

        cmp     ah,48h
        jnz     @NoUpPressed
        cmp     ActiveMod,0
        jz      @SetMax
        dec     ActiveMod
        jmp     @MainLoop
@SetMax:        
        mov     [ActiveMod],NumSongs-1
        jmp     @MainLoop
@NoUpPressed:

        cmp     ah,50h
        jnz     @NoDownPressed
        cmp     ActiveMod,Numsongs-1
        jz      @SetMin
        inc     ActiveMod
        jmp     @MainLoop
@SetMin:
        mov     [ActiveMod],0
        jmp     @MainLoop
@NoDownPressed:
        cmp     ah,4bh
        jnz     @NoLeftPressed
        call    USMP_PrevOrder
        jmp     @MainLoop
@NoLeftPressed:
        cmp     ah,4dh
        jnz     @NoRightPressed
        call    USMP_NextOrder
        jmp     @MainLoop
@NoRightPressed:
        cmp     ah,1ch
        jnz     @NoEnterPressed
                                        ; Start Playing Active Mod if ActiveMod
                                        ; diferent of playing mod
        mov     dl,ActiveMod
        cmp     dl,PlayingMod
        jz      @NoEnterPressed
        mov     PlayingMod,dl
        xor     ebx,ebx
        mov     bl,dl
        pusha
        mov     esi,[Uss_header]
        call    USMP_StopPlay
        mov     esi,[Uss_header]
        call    USMP_freeModule
        popa
        mov     esi,[ModuleArray+ebx*4]
        call    XM_Load
        mov     [Uss_header],esi
        call    USMP_StartPlay
        jmp     @MainLoop
@NoEnterPressed:
        cmp     ah,1
        jz      @exit
        jmp     @MainLoop
        
@exit:
        mov     esi,[USS_Header]
        call    USMP_StopPlay
@gotodos:        
        mov     ax,3h
        int     21h
        mov     ax,4c00h
        int     21h


; Procs & stuff

SetPalette PROC ; in esi the offset to palette
        push    ax
        push    cx
        push    dx
        push    esi
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
        pop     esi
        pop     dx
        pop     cx
        pop     ax
        ret
SetPalette Endp



end start
