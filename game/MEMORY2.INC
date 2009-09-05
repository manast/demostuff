;-----------------------------------------------------------------
; Memory UNIT v0.1 coded by Sarwaz (a.k.a. Manuel Astudillo)
; for dos 32 extender.
; (c) Mistery / apr-97
;-----------------------------------------------------------------



;equ's

        TRUE    equ     1
        FALSE   equ     0
        FREE    equ     0
        USED    equ     1

; Structures


MCBstruc        struc
        MemStat db      0
        Len     dd      0       ;Memory block length without MCB
        MCBadrl dd      0
        MCBadrh dd      0
        MCBsign dd      'M.A.'  ;MCB block signature
        
MCBstruc        ends


; Variables

TotalMemory     dd      0
FirstMCBAdr     dd      0
MemoryInit      db      FALSE

; Procedures

InitMem proc
        push    eax
        push    edx
        mov     edx,0ffffffffh
        mov     ax,0EE42h
        int     31h
        mov     TotalMemory,eax
        mov     FirstMCBAdr,edx
        mov     [edx.MemStat],FREE
        mov     [edx.Len],eax
        mov     [edx.MCBadrl],0
        mov     [edx.MCBadrh],0
        mov     [edx.MCBSign],'M.A.'
        pop     edx
        pop     eax
        ret
InitMem endp


; AllocMem
; In: edx (bytes to alloc)
; Out: edx (Adress of allocated memory)
; Errors: carry set if not enough memory

AllocMem proc
        push    eax
        push    ebx
        push    ecx
        
        mov     ecx,edx

        cmp     MemoryInit,TRUE
        je      @NoInitMemory
        call    InitMem
        mov     MemoryInit,TRUE
@NoInitMemory:
                                        ;Search a MCB block with free memory
        mov     edx,[FirstMCBAdr]

@SearchFreeMCB:        
        cmp     [edx.MemStat],FREE        
        je      @TestMemBlock
@SearchFreeMCB2:
        mov     edx,[edx.MCBadrh]
        or      edx,edx
        jz      @NotEnoughMemory
        jmp     @SearchFreeMCB

@TestMemBlock:
        cmp     [edx.len],ecx           ;Test for space
        jb      @SearchFreeMCB2          ;If not search for another MCB
                                        ;Update this MCB
        mov     [edx.MemStat],USED
        mov     eax,[edx.len]
        sub     eax,size MCBstruc       ;Dec MCB length
        mov     [edx.len],ecx           ;Set New block length
        cmp     eax,ecx
        jbe     @SkipNewMCB
        mov     ebx,eax
        sub     ebx,ecx
        mov     eax,edx
        add     eax,ecx
        add     eax,size MCBstruc       ;Reserved space for new MCB
        mov     [eax.MemStat],FREE
        mov     [eax.len],ebx
        mov     [eax.MCBadrl],edx       ;Chain New MCB low pointer with Old MCB
        mov     ebx,[edx.MCBadrh]
        mov     [eax.MCBadrh],ebx       ;Chain New MCB high pointer with Old MCB
        mov     [edx.MCBadrh],eax       ;Chain Old MCB high pointer with New MCB
        mov     [eax.MCBSign],'M.A.'    ;Place signature
@SkipNewMCB:
        add     edx,size MCBstruc
        clc
        pop     ecx
        pop     ebx
        pop     eax
        ret
@NotEnoughMemory:
        stc
        pop     ecx
        pop     ebx
        pop     eax
        ret
AllocMem endp

; FreeMem
; In: edx (pointer to allocated Memory Block)
; Errors: carry set if wrong adress 

FreeMem proc
        push    eax
        push    ecx
        push    edx
        sub     edx,size MCBstruc
        cmp     [edx.MCBSign],'M.A.'    ;Test signature for correct MCB block
        jnz     @NotMCBBlock
        mov     [edx.MemStat],FREE
                                        ;Compact successive Free Mem blocks
                                        ;Test High
        cmp     [edx.MCBadrh],0
        je      @TestForLowBlock
        mov     eax,[edx.MCBadrh]
        cmp     [eax.MemStat],USED
        je      @TestForLowBlock
        mov     ecx,[eax.len]        ;Update MCB according with the next block
        add     ecx,size MCBstruc
        add     [edx.len],ecx
        mov     ecx,[eax.MCBadrh]
        mov     [edx.MCBadrh],ecx
@TestForLowBlock:
                                        ;Test Low
        cmp     [edx.MCBadrl],0
        je      @NoLowFreeBlock
        mov     eax,[edx.MCBadrl]
        cmp     [eax.MemStat],USED
        je      @NoLowFreeBlock
        mov     ecx,[edx.len]
        add     ecx,size MCBstruc
        add     [eax.len],ecx
        mov     ecx,[edx.MCBadrh]
        mov     [eax.MCBadrh],ecx
@NoLowFreeBlock:

        pop     edx
        pop     ecx
        pop     eax
        clc
        ret
@NotMcbBLock:
        pop     edx
        pop     ecx
        pop     eax
        stc
        ret
FreeMem endp



