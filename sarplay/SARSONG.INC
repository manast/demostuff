;旼컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴� 
;       Sarwaz Module Player - Structures
;       Tables And Structures Used in the Player. 
;       Copyright (c) 1996 Manuel Astudillo
; 컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴�

TRUE    equ     1
FALSE   equ     0

SarInst struc           ;Size = 32 bytes
        InstName        db 22 dup (0)
        SampSeg         dd ?
        Len             dw 0
        Finetune        db 0
        Volume          db 0
        RepStart        dw 0
        RepLength       dw 0
        SLoop           db 0
SarInst ends

SarNote struc           ;Size = 5 bytes
        SampNum         db 0
        Period          dw 0
        Effect          dw 0
SarNote ends

SarPattern struc

SarPattern ends

SarSong struc
        SonName         db 25 Dup (36)
        Leng            db 0
        Order           db 128 dup (0)
        SeqPos          db 0
        Restart         db 0
        NumOfPatterns   db 0
        TotalPatSize    dw 0
        TotalRowSize    db 0
        PatternSeg      dw ?
        PatOfs          dw 0
        PatPos          db 0
        NumOfChannels   db 0
        BPM             db 125
        Speed           db 6
        Inst            SarInst 31 dup (?)
        TickCont        db 0
        Delay           db 0
        PatternsSeg     dw 256 dup (0)
SarSong ends

Number_Of_Samples       db 0
BufBlock                db 0
NewVolume               db FALSE
changes                 db TRUE
TimerInt                dd 0

SarChannel struc
        SampVol         db 0
        period          dw 0
        freq            dw 0
        OldFreq         dw 0
        TonePortPeriod  dw 0    ;Period for Tone Portamento
        pSample         dd 0
        SamNum          db 0
        SamNumOld       db 0
        SampOfs         dw 0    ;Sample offset and Sample fractionary Ofs.
        SampFrac        db 0
        SampEnd         dw 0
        SampLoopStart   dw 0
        SampLoopEnd     dw 0
        Looping         db 0    ;1 = loop, 0 = no loop
        SampFreqAdder   dd 0
        EffectCmd       db 0
        EffectParm      db 0
        VibPos          dw 0    ;Offset in Vibrato Table
        VibCenter       dw 0
        VibSpeed        db 0
        VibDepth        db 0
        NewNoteVib      db FALSE
        TremPos         dw 0
        TremCenter      db 0
        TremSpeed       db 0
        TremDepth       db 0
        RetrigCont      db 0
        TonePortaTmp    dw 0
        PortaInc        db 0
        NewNote         db FALSE
        OldVol          db 0
        LeftVol         db 255
        RightVol        db 0
        Panning         db 128
SarChannel ends

SarDevice struc
        Card            db 0    ; 0 = Speaker, 1 = SB, 2 = GUS
        Ver             db 0    ; If Device = 1 then: 1 = SB 1.5
        MixFreq         dw 0    ;                     2 = SB 2.0 +
                                ;                     3 = SB pro
        Stereo          db 0    ;                     4 = SB 16 +
        IRQ             db 0    ; If Device = 2 then: 0 = Gus Ace
        BaseAdr         dw 0    ;                     1 = Gus Ultra
        DMAChan         db 0    ;                     2 = Gus PnP
SarDevice ends

VibratoTable dw 0,25,50,74,98,121,142,162,181,198,213,226,237,245,251,255,256
             dw 255,251,245,237,226,213,198,181,162,142,121,98,74,50,25,0,-25
             dw -50,-74,-98,-121,-142,-162,-181,-198,-213,-226,-237,-245,-251
             dw -255,-256,-255,-251,-245,-237,-226,-213,-198,-181,-162,-142
             dw -121,-98,-74,-50,-25

;FxTable1        dw      offset @Processed ;arpegio  ; 0 Arpegio
;                dw      offset @SlidePortaUp    ; 1
;                dw      offset @Processed;PortaDn          ; 2
;                dw      offset @PreparePortaNote        ; 3
;                dw      offset @PrepareVibrato  ; 4
;                dw      offset @Processed       ; 5
;                dw      offset @Processed       ; 6
;                dw      offset @PrepareTremolo  ; 7 (tremolo)
;                dw      offset @Processed       ; 8 (pan)
;                dw      offset @SampleOffset    ; 9
;                dw      offset @VolumeSlide     ; A
;                dw      offset @PositionJump    ; B
;                dw      offset @SetVolume       ; C
;                dw      offset @PatternBreak    ; D
;                dw      offset @SpecialCmds     ; E
;                dw      offset @SetSpeed        ; F
;
;FxTable2        dw      offset arpegio          ; 0 Arpegio
;                dw      offset PortaUp          ; 1
;                dw      offset PortaDn          ; 2
;                dw      offset PortaNote        ; 3
;                dw      offset Vibrato          ; 4
;                dw      offset nocmd;PortaSlide ; 5
;                dw      offset VibSlide         ; 6
;                dw      offset NoCmd            ; 7 (tremolo)
;                dw      offset NoCmd            ; 8 (pan)
;                dw      offset SmpOfs           ; 9
;                dw      offset VolSlide         ; A
;                dw      offset PatJump          ; B
;                dw      offset SetVolume        ; C
;                dw      offset PatBreak         ; D
;                dw      offset Extended         ; E
;                dw      offset SetSpeed         ; F
;
;EfxTable        dw      offset NoCmd            ; E0 (filter)
;                dw      offset FineUp           ; E1
;                dw      offset FineDn           ; E2
;                dw      offset nocmd;Glissando  ; E3
;                dw      offset nocmd;VibForm            ; E4
;                dw      offset nocmd;SetFineTune        ; E5
;                dw      offset nocmd;LoopPat            ; E6
;                dw      offset nocmd;TremForm           ; E7
;                dw      offset NoCmd            ; E8
;                dw      offset nocmd;Retrig             ; E9
;                dw      offset FineVolUp        ; EA
;                dw      offset FineVolDn        ; EB
;                dw      offset nocmd;SampleCut  ; EC 
;                dw      offset nocmd;SampleDelay        ; ED
;                dw      offset NoCmd            ; EE (delay pattern)
;                dw      offset NoCmd            ; EF (invert loop)

