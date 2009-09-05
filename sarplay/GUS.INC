;--------------------------------------------------------------------------
;              GUS Driver v1.0 For Sarplay by Sarwaz of Mistery           |
;        Greets Goes to Mark Dixon for his Pascal Sources which           |
;        helped me a lot. Tnx Mark.                                       |
;--------------------------------------------------------------------------

MaxVoices       equ     14


; Tnx to Luis Crespo for those Constants...
; Constants

  GUSIRQStat dw   6h
  GUSPage    dw  102h
  GUSRegSel  dw  103h
  GUSDataLow dw  104h
  GUSDataHi  dw  105h
  GUSDRAM    dw  107h

;Gus internal Registers

  rgDMACtl   equ 41h ;  {Control de DMA}
  rgRAML     equ 43h ;  {Direcci¢n DRAM de la GUS, 16 bits bajos}
  rgRAMH     equ 44h ;  {Direcci¢n DRAM de la GUS, 8 bits altos}
  rgTimerCtl equ 45h ;  {Control del Timer}
  rgSampCtl  equ 49h ;  {Control de muestreo}
  rgReset    equ 4Ch ;  {Pues eso: registro de reset}

  rgVoiceCtl equ 00h ;  {Control de voz}
  rgVFreq    equ 01h ;  {Frecuencia de voz}
  rgVStartH  equ 02h ;  {Inicio de loop}
  rgVStartL  equ 03h ;
  rgVEndH    equ 04h ;  {Fin de voz}
  rgVEndL    equ 05h ;
  rgVVolRate equ 06h ;
  rgVVol     equ 09h ;  {Volumen de voz}
  rgVCurrH   equ 0Ah ;  {Posici¢n actual}
  rgVCurrL   equ 0Bh ;
  rgVPanPos  equ 0Ch ;  {Posici¢n de la voz: izquierda, centro o derecha}
  rgVVolCtl  equ 0Dh ;
  rgActVoc   equ 0Eh ;  {N£mero de voces activas}
  rgIRQStat  equ 8Fh ;  {Estado de IRQ, lectura}


;Lets Define Some Variables

GUS_BASE_ADRESS dw      ?
  VolTbl db  000h,004h,0a0h,0b0h,0c0h,0c8h,0d0h,0d8h,0e0h,0e4h,0e8h,0ech,0f1h
         db  0f4h,0f6h,0fah,0ffh

; GusRead, reads a value from Gus Memory
; In: ebx 
; Out: al

GusRead proc
        push    ebx
        push    dx
        and     ebx,00ffffffh
        mov     dx,103h
        add     dx,cs:GUS_BASE_ADRESS
        mov     al,43h
        out     dx,al
        inc     dx              ;104h
        mov     ax,bx
        out     dx,ax
        dec     dx              ;103h
        mov     al,44h
        out     dx,al
        shr     ebx,16
        mov     al,bl
        add     dx,2            ;105h
        out     dx,al
        add     dx,2            ;107h
        in      al,dx
        pop     dx
        pop     ebx
        ret
GusRead endp

;GusWrite Writes a value to GUS Memory
;In: ebx (Adress) , al (Value)


GusWrite proc
        push    ebx
        push    cx
        push    dx
        mov     cl,al
        and     ebx,00ffffffh
        mov     dx,103h
        add     dx,cs:GUS_BASE_ADRESS
        mov     al,43h
        out     dx,al
        inc     dx              ;104h
        mov     ax,bx
        out     dx,ax
        dec     dx              ;103h
        mov     al,44h
        out     dx,al
        shr     ebx,16
        mov     al,bl
        add     dx,2            ;105h
        out     dx,al
        add     dx,2            ;107h
        mov     al,cl
        out     dx,al
        pop     dx
        pop     cx
        pop     ebx
        ret
GusWrite endp
  
; Test for a base Adress. Returns al=1 if succesfull.

GusTest proc
        mov     dx,cs:GUS_BASE_ADRESS
        add     dx,103h
        mov     al,4ch
        out     dx,al
        add     dx,2            ;105h
        xor     al,al
        out     dx,al
        call    GusDelay
        call    GusDelay
        sub     dx,2            ;103h
        mov     al,4ch
        out     dx,al
        add     dx,2
        mov     al,1
        out     dx,al
        mov     ebx,0
        mov     al,0aah
        call    GusWrite
        mov     ebx,100h
        mov     al,55h
        call    GusWrite
        mov     ebx,0
        call    GusRead
        cmp     al,0aah
        jz      @BaseOk
        xor     al,al
        ret
@BaseOk:
        mov     al,1
        ret
GusTest endp
  
;Find And Resets GUS Card. If Not Find, Carry Flag Set
  
ResetGus proc  
        push    cx
        push    dx
        mov     cl,8
        mov     cs:GUS_BASE_ADRESS,200h
@FindGus:
        call    GusTest
        cmp     al,1
        jz      @GusOk
        add     cs:GUS_BASE_ADRESS,10h
        dec     cl
        jnz     @FindGus
        pop     dx
        pop     cx
        stc
        ret
@GusOk:                              ;Reseting GUS (Credits Bigge/Mry!!)
        
        push    ax bx cx dx

        mov     dx,cs:GUS_BASE_ADRESS
        mov     al, 3 or 8              ;Turn off output
        out     dx, al                  ;dx = u_Base

        mov     bx, dx
        add     bx, 103h                ;bx = u_Command
        mov     cx, dx
        add     cx, 105h                ;cx = DataHi
        mov     dx, bx                  ;dx = u_Command
        mov     al, 4Ch                 ;Initialization register
        out     dx, al
        mov     dx, cx                  ;dx = DataHi
        xor     al, al                  ;Clear bit (Initializing state)
        out     dx, al
        call    GusDelay
        call    GusDelay
        mov     dx, bx                  ;dx = u_Command
        mov     al, 4Ch                 ;Initialzation register
        out     dx, al
        mov     dx, cx                  ;dx = u_DataHi
        mov     al, 1                   ;Set bit (Non-init-state)
        out     dx, al
        call    GusDelay
        call    GusDelay

        mov     dx, bx                  ;dx = u_Command
        mov     al, 41h                 ;DMA control register
        out     dx, al
        mov     dx, cx                  ;dx = u_DataHi
        xor     al, al                  ;Clear any pending DMA IRQs
        out     dx, al
        mov     dx, bx                  ;dx = u_Command
        mov     al, 45h                 ;Timer control register
        out     dx, al
        mov     dx, cx                  ;dx = u_DataHi
        xor     al, al                  ;Clear any pending timer IRQs
        out     dx, al
        mov     dx, bx                  ;dx = u_Command
        mov     al, 49h                 ;Sample control register
        out     dx, al
        mov     dx, cx                  ;dx = u_DataHi
        xor     al, al                  ;Clear any pending sample control IRQs
        out     dx, al

        mov     dx, bx                  ;dx = u_Command
        mov     al, 0Eh                 ;Set highest active voice
        out     dx, al
        inc     dx
        inc     dx                      ;dx = u_DataHi
        mov     al, MaxVoices or 0C0h
;       or      al, 0C0h
        out     dx, al

        sub     dx, 0FFh                ;dx = u_Status
        in      al, dx                  ;Get status byte
        mov     dx, bx                  ;dx = u_Command
        mov     al, 41h                 ;DMA control register
        out     dx, al
        mov     dx, cx                  ;dx = u_DataHi
        in      al, dx
        mov     dx, bx                  ;dx = u_Command
        mov     al, 49h                 ;Sample control register
        out     dx, al
        mov     dx, cx                  ;dx = u_DataHi
        in      al, dx
        mov     dx, bx                  ;dx = u_Command
        mov     al, 8Fh                 ;IRQ status register
        out     dx, al
        mov     dx, cx                  ;dx = u_DataHi
        in      al, dx

        push    bx cx
        xor     cx, cx
@@VoiceClearLoop:
        sub     dx, 3h                  ;dx = u_Voice
        mov     al, cl                  ;Select a voice
        out     dx, al
        inc     dx                      ;dx = u_Command
        xor     al, al                  ;Write voice mode
        out     dx, al
        inc     dx
        inc     dx                      ;dx = u_DataHi
        mov     al, 3                   ;Stop voice immediately
        out     dx, al
        dec     dx
        dec     dx                      ;dx = u_Command
        mov     al, 0Dh                 ;Volume control register
        out     dx, al
        inc     dx
        inc     dx                      ;dx = u_DataHi
        mov     al, 3                   ;Stop voice ramp immediately
        out     dx, al
        inc     cx
        cmp     cx, 32
        jnz     @@VoiceClearLoop
        pop     cx bx

        mov     dx, bx                  ;dx = u_Command
        mov     al, 41h                 ;DMA control register
        out     dx, al
        mov     dx, cx                  ;dx = u_DataHi
        in      al, dx
        mov     dx, bx                  ;dx = u_Command
        mov     al, 49h                 ;Sample control register
        out     dx, al
        mov     dx, cx                  ;dx = u_DataHi
        in      al, dx
        mov     dx, bx                  ;dx = u_Command
        mov     al, 8Fh                 ;IRQ status register
        out     dx, al
        mov     dx, cx                  ;dx = u_DataHi
        in      al, dx

        mov     dx, bx                  ;dx = u_Command
        mov     al, 4Ch                 ;Initialization register
        out     dx, al
        mov     dx, cx                  ;dx = u_DataHi
        mov     al, 7
        out     dx, al

        sub     dx, 105h                ;dx = u_Base
        mov     al, 8                   ;Output & line-in ON, mic OFF
        out     dx, al

                                ;Set Correct Ports Values        

        mov     ax,cs:Gus_Base_Adress
        add     cs:GUSIRQStat,ax
        add     cs:GUSPage,ax
        add     cs:GUSRegSel,ax
        add     cs:GUSDataLow,ax
        add     cs:GUSDataHi,ax
        add     cs:GUSDRAM,ax
        
        pop     dx cx bx ax
        
        
        pop     dx
        pop     cx
        clc
        ret
ResetGus endp
  
GusDelay  Proc  
        push    ax
        push    dx
        mov     dx, 0300h
        in      al, dx
        in      al, dx
        in      al, dx
        in      al, dx
        in      al, dx
        in      al, dx
        in      al, dx
        pop     dx
        pop     ax
        ret
GusDelay  endp
  
;In: al with current voice  
GusSetVoice proc  
        push    dx
        mov     dx,cs:GUSPage
        out     dx,al
        pop     dx
        ret
GusSetVoice endp



; Set Volume Of a Channel
; In: cx volume
GusSetVolume proc
        push    ax
        push    bx
        push    dx
        xor     bh,bh
        shr     cl,2
        mov     bl,cl
        mov     cl,cs:[bx+VolTbl]
        xor     ch,ch
        shl     cx,8

        mov     dx,GUSRegSel
        mov     al,rgVVol
        out     dx,al
        mov     dx,GUSDataLow
        mov     ax,cx
        out     dx,ax
        pop     dx
        pop     bx
        pop     ax
        ret
GusSetVolume endp
        


;Set Paning Position of a channel
;In cl Pan Position

GUSSetPanning proc
        push    ax
        push    dx
        mov     dx,GUSRegSel
        mov     al,rgVPanPos
        out     dx,al
        mov     dx,GUSDataHi
        mov     al,cl
        out     dx,al
        pop     dx
        pop     ax
        ret
GUSSetPanning endp


;Set Gravis Freq on a Channel
; cx, frequence

GusSetFreq proc
        push    ax
        push    dx
        mov     dx,GusRegSel
        mov     al,rgVFreq
        out     dx,al
        mov     dx,GUSDataLow
        mov     ax,cx
        out     dx,ax
        pop     dx
        pop     ax
        ret
GusSetFreq endp


;GusSetInstrument

;In: ebp,esi,edi (Start,loop,End)
GusSetInstrument proc
        push    ax
        push    dx
        push    ecx
                                ;Loop!
        mov     dx,GusRegSel
        mov     al,rgVStartH
        out     dx,ax
        mov     dx,GusDataLow
        mov     ecx,esi
        shr     ecx,7
        mov     ax,cx
        out     dx,ax
        mov     dx,GusRegSel
        mov     al,rgVStartL
        out     dx,al
        mov     dx,GusDataLow
        mov     ecx,esi
        shl     ecx,9
        mov     ax,cx
        out     dx,ax
                                        ;End!
        mov     dx,GUSRegSel
        mov     al,rgVEndH
        out     dx,al
        mov     dx,GUSDataLow
        mov     ecx,edi
        shr     ecx,7
        mov     ax,cx
        out     dx,ax
        mov     dx,GUSRegSel
        mov     al,rgVEndL
        out     dx,al
        mov     dx,GUSDataLow
        mov     ecx,edi
        shl     ecx,9
        mov     ax,cx
        out     dx,ax
                                        ;Start!
        mov     dx,GUSRegSel
        mov     al,rgVCurrH
        out     dx,al
        mov     dx,GUSDataLow
        mov     ecx,ebp
        shr     ecx,7
        mov     ax,cx
        out     dx,ax
        mov     dx,GUSRegSel
        mov     al,rgVCurrL
        out     dx,al
        mov     dx,GUSDataLow
        mov     ecx,ebp
        shl     ecx,9
        mov     ax,cx
        out     dx,ax
        pop     ecx
        pop     dx
        pop     ax
        ret
GusSetInstrument endp

GusStopVoice Proc
        push    ax
        push    bx
        push    dx
        mov     bl,1
        call    GusSetMode
        pop     dx
        pop     bx
        pop     ax
        ret
GusStopVoice endp

;HookGusInt PROC

                    ;Get Old timer interupt vector.
;        mov  al,8
;        mov  ah,35h
;        int  21h
;        mov  cs:[word ptr TimerInt+2],bx
;        mov  cs:[word ptr TimerInt],es

;        push ds                       ;Hook the DSP int vector.
;        mov  al,8
;        mov  dx,seg GUS_INT
;        mov  ds,dx
;        mov  dx,offset GUS_INT
;        mov  ah,25h
;        int  21h
;        pop  ds

;        ret
;HookGusInt endp


;       This register stands for "Mode" at GusPlayVoice Proc

;
;           =================================
;           | 7 | 6 | 5 | 4 | 3 | 2 | 1 | 0 |
;           =================================
;             |   |   |   |   |   |   |   |
;             |   |   |   |   |   |   |   +---- Voice Stopped
;             |   |   |   |   |   |   +-------- Stop Voice
;             |   |   |   |   |   +------------ 16 bit data
;             |   |   |   |   +---------------- Loop enable
;             |   |   |   +-------------------- Bi-directional loop enable
;             |   |   +------------------------ Wave table IRQ
;             |   +---------------------------- Direction of movement
;             +-------------------------------- IRQ pending
;        (*)Bit 0 = 1 : Voice is stopped. This gets set by hitting the end
;                   address (not looping) or by setting bit 1 in this reg.
;           Bit 1 = 1 : Stop Voice. Manually force voice to stop.
;           Bit 2 = 1 : 16 bit wave data, 0 = 8 bit data
;           Bit 3 = 1 : Loop to begin address when it hits the end address.
;           Bit 4 = 1 : Bi-directional looping enabled
;           Bit 5 = 1 : Enable wavetable IRQ. Generate an irq when the voice
;                       hits the end address. Will generate irq even if looping
;                       is enabled.
;        (*)Bit 6 = 1 - Decreasing addresses, 0 = increasing addresses. It is
;                       self-modifying because it might shift directions when
;                       it hits one of the loop boundaries and looping is enabled.
;        (*)Bit 7 = 1 - Wavetable IRQ pending. If IRQ's are enabled and
;                       looping is NOT enabled, an IRQ will be constantly
;                       generated until voice is stopped. This means that
;                       you may get more than 1 IRQ if it isn't handled
;                       properly.


;  Function  GUSFindMem : Longint;

;  { Returns how much RAM is available on the GUS }

;  Var
;    I : Longint;
;    B : Byte;
;  Begin
;    GUSPoke($40000, $AA);
;    If GUSPeek($40000) <> $AA then I := $3FFFF
;      else
;    Begin
;      GUSPoke($80000, $AA);
;      If GUSPeek($80000) <> $AA then I := $8FFFF
;        else
;      Begin
;        GUSPoke($C0000, $AA);
;        If GUSPeek($C0000) <> $AA then I := $CFFFF
;          else I := $FFFFF;
;      End;
;    End;
;    GUSFindMem := I;
;  End;


;  Function VoicePos( V : Byte) : Longint;
;  Var
;    P : Longint;
;    Temp0, Temp1 : Word;
;  Begin
;    Port [Base+$102] := V;
;    Port [Base+$102] := V;
;    Port [Base+$102] := V;
;    Port [Base+$103] := $8A;
;    Temp0 := Portw[Base+$104];
;    Port [Base+$103] := $8B;
;    Temp1 := Portw[Base+$104];
;    VoicePos := (Temp0 SHL 7)+ (Temp1 SHR 8);
;  End;


;In: ebp, bl (start,Mode)
GusSetVCurr proc  
        push    ax
        push    dx
        push    ecx
        mov     dx,GUSRegSel
        mov     al,rgVoiceCtl
        out     dx,al
        mov     dx,GUSDataHi
        mov     al,3
        out     dx,al
        mov     dx,GusRegSel
        mov     al,rgVCurrH
        out     dx,al
        mov     dx,GUSDataLow
        mov     ecx,ebp
        shr     ecx,7
        mov     ax,cx
        out     dx,ax
        mov     dx,GusRegSel
        mov     al,rgVCurrL
        out     dx,al
        mov     dx,GUSDataLow
        mov     ecx,ebp
        shl     ecx,9
        mov     ax,cx
        out     dx,ax
        mov     dx,GusRegSel
        mov     al,rgVoiceCtl
        out     dx,al
        mov     dx,GUSDataHi
        mov     al,bl
        out     dx,al
        pop     ecx
        pop     dx
        pop     ax

        ret
GusSetVCurr endp

;In bl
GusSetMode proc
        push    ax
        push    dx
        mov     dx,cs:GusRegSel
        mov     al,rgVoiceCtl
        mov     dx,cs:GusDataHi
        mov     al,bl
        out     dx,al
        pop     dx
        pop     ax
        ret
GusSetMode endp

