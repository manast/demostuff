; Player Kernel -
; For SarPlay by Manuel Astudillo (a.k.a Sarwaz of Mistery)
; Copyright (c) 1996 Manuel Astudillo

;Process Song Data For Next Tick and Output to Soundcard

NextTick proc
	push    ds
	push    es
	dec     cs:Song.TickCont
	cmp     cs:Song.TickCont,0
	jnz     @SameNote
	call    GetNextNote                        ;Fills the Channels with
	call    ProcessCommands       
	mov     al,cs:Song.Speed                   ;Next Song Data
	mov     cs:Song.TickCont,al

@SameNote:
	call    ProcessContinousCmds
	cmp     cs:device.card,GUS        ;Gus?
	jz      @GusUpdateVoices
	cmp     cs:device.stereo,1
	jz      @FillStereo
	call    FillBuffer
	pop     es
	pop     ds
	ret

@FillStereo:        
	call    FillBufferStereo
	pop     es
	pop     ds
	ret

@GusUpdateVoices:
	mov     cl,2;cs:Song.NumOfChannels
	lea     bx,Channels
@UpdateVoice:
	push    bx
	push    cx

						;Update Commands:
	mov     al,cl                            ;Select Channel
	call    GusSetVoice        
						;Set Vol

	mov     cl,cs:[bx][SarChannel.SampVol]
	cmp     cl,cs:[bx][SarChannel.OldVol]
	jz      @NoNewVolume
	mov     cs:[bx][SarChannel.OldVol],cl
	xor     ch,ch
	mov     cl,60
	call    GusSetVolume
@NoNewVolume:
						;Set Panning
	mov     cl,cs:[bx][SarChannel.Panning]
	sar     cl,4
	call    GusSetPanning

	xor     eax,eax
	mov     ax,cs:[bx][SarChannel.period]     ;Set Freq.
	or      ax,ax
	jz      @NoNewFreq
	cmp     ax,cs:[bx][SarChannel.OldFreq]
	jz      @NoNewFreq
	mov     cs:[bx][SarChannel.OldFreq],ax
	mov     ecx,83116                                     
	xor     edx,edx
	xchg    ecx,eax
	jz      @NoNewFreq
	idiv    ecx
				     ;(Freq*1024)/44100
	mov     cx,ax        
	call    GusSetFreq
@NoNewFreq:

	mov     al,cs:[bx][SarChannel.SamNum]
	cmp     al,cs:[bx][SarChannel.SamNumOld]
	jz      @NoNewInstrument
	mov     cs:[bx][SarChannel.SamNumOld],al
	mov     ebp,cs:[bx][SarChannel.pSample]
	mov     esi,ebp
	mov     edi,ebp 
	xor     edx,edx
	mov     dx,cs:[bx][SarChannel.SampEnd]
	add     edi,edx
	call    GusSetInstrument        
@NoNewInstrument:

	cmp     cs:[bx][SarChannel.NewNote],TRUE
	jz      @UpdateNote
	jmp     @DontUpdateNOte
@UpdateNote:
	cmp     cs:[bx][SarChannel.looping],TRUE
	jz      @SetLoopMode
	mov     ebp,cs:[bx][SarChannel.pSample]
	mov     bl,0
	call    GusSetVCurr
	jmp     @DOntUpdateNote
@SetLoopMode:
	mov     ebp,cs:[bx][SarChannel.pSample]
	mov     bl,8
	call    GusSetVCurr

@DontUpdateNote:
	pop     cx
	pop     bx
	add     bx,size SarChannel
	dec     cl
	jnz     @UpdateVoice
	
	pop     es
	pop     ds
	ret

NextTick endp

;Read NextNote Pattern data and put it in Virtual Channels

GetNextNote proc        
	mov     si,cs:Song.PatOfs               ;Get Current Note Pattern Offset
	mov     ds,cs:Song.PatternSeg
	mov     di,offset Channels
	mov     cl,cs:Song.NumOfChannels
@GetNote:
						
	mov     cs:Changes,FALSE
	mov     cs:NewVolume,FALSE                      ;New Volume?
	mov     cs:[di][SarChannel.NewNote],FALSE
	;mov     cs:[di][SarChannel.NewSample],FALSE
							;Get Note Info
	
	mov     ax,ds:[si+3]                    
	mov     cs:[di][SarChannel.EffectCmd],ah        ;Cmds first
	mov     cs:[di][SarChannel.EffectParm],al

	cmp     ah,03h
	jnz     @NoReadTonePortPeriod
	mov     ax,ds:[si+1]
	or      ax,ax
	jz      @ReadTonePortPeriod
	mov     cs:[di][Sarchannel.TonePortPeriod],ax
	jmp     @ReadTonePortPeriod
@NoReadTonePortPeriod:
	mov     ax,ds:[si+1]
	or      ax,ax
	jz      @ReadTonePortPeriod
	mov     cs:changes,TRUE
	mov     cs:NewVolume,TRUE
	mov     cs:[di][SarChannel.NewNote],TRUE
	mov     cs:[di][SarChannel.NewNoteVib],TRUE
	mov     cs:[di][SarChannel.period],ax

@ReadTonePortPeriod:
	mov     bl,ds:[si]
	or      bl,bl
	jz      @NoNewSample
	;mov     cs:changes,TRUE
	mov     cs:[di][SarChannel.SamNum],bl
	dec     bl                              ;Sample 0 doesnt exist
						;Get Sample Info
	mov     ax,size SarInst
	mul     bl

	mov     bx,ax
	mov     eax,cs:[Song.Inst][bx][SarInst.SampSeg]
	mov     cs:[di][SarChannel.pSample],eax
	;cmp     cs:NewVolume,TRUE
	;jnz     @NoNewSample ;(NoNewVolume!!)
	mov     al,cs:[Song.Inst][bx][SarInst.Volume]
	mov     cs:[di][SarChannel.SampVol],al        

@NoNewSample:
	cmp     cs:Changes,FALSE
	jz      @NoNote
	
	mov     bl,cs:[di][SarChannel.SamNum]
	or      bl,bl
	jz      @NoNote
	dec     bl                              ;Sample 0 doesnt exist
						;Get Sample Info
	mov     ax,size SarInst
	mul     bl
	mov     bx,ax
	
	
	
	mov     eax,cs:[Song.Inst][bx][SarInst.SampSeg]
	mov     cs:[di][SarChannel.pSample],eax


	mov     cs:[di][SarChannel.SampOfs],0
	mov     cs:[di][SarChannel.SampFrac],0
	mov     ax,cs:[Song.Inst][bx][SarInst.Len]
	mov     cs:[di][SarChannel.SampEnd],ax

	mov     ax,cs:[Song.Inst][bx][SarInst.RepStart]
	mov     cs:[di][SarChannel.SampLoopStart],ax
	mov     bp,cs:[Song.Inst][bx][SarInst.RepLength]
	add     ax,bp
	cmp     cs:[Song.Inst][bx][SarInst.SLoop],1
	jz      @SampEndOk
	mov     ax,cs:[di][SarChannel.SampEnd]
@SampEndOk:        
	mov     cs:[di][SarChannel.SamploopEnd],ax
	mov     al,cs:[Song.Inst][bx][SarInst.SLoop]
	mov     cs:[di][SarChannel.Looping],al
	

	mov     al,cs:[Song.Inst][bx][SarInst.finetune]
	cbw
	sub     cs:[di][Sarchannel.period],ax

;============= TEST BLOCK USING PAL =============
	
	xor     ebx,ebx
	xor     edx,edx
	mov     eax,3546895     ;This is pal. Pal/period=freq
	mov     bx,cs:[di][SarChannel.period]
      ;  or      bx,bx
      ;  jz      @NoNote
	div     ebx
	xor     edx,edx
	mov     cs:[di][SarChannel.freq],ax
	shl     eax,8                   ;8 Bits Fixed Point
	mov     bx,cs:device.Mixfreq
	div     ebx
	mov     cs:[di][SarChannel.SampFreqAdder],eax

;============= END OF TEST BLOCK USING PAL ======


@NoNote:                                        ;There are'nt a new note        

	add     si,5
	add     di,size SarChannel
	dec     cl
	jnz     @GetNote

	inc     cs:Song.PatPos
	xor     ah,ah
	mov     al,cs:Song.NumOfchannels
	mov     bl,size SarNote
	mul     bl
	add     cs:Song.PatOfs,ax
	mov     bl,64
	mul     bl                              ;Pattern Length
	cmp     cs:song.PatPos,64
	jb      @SamePattern

	mov     cs:Song.PatPos,0
	mov     al,cs:Song.SeqPos
	cmp     cs:Song.Leng,al                 ;Test If Song Finished
	jnz     @NoRestart
	
	mov     al,cs:Song.Restart
	dec     al
	mov     cs:Song.SeqPos,al               ;Restart Song

@NoRestart:
	inc     cs:Song.SeqPos
	xor     ah,ah
	xor     bh,bh
	mov     al,cs:Song.SeqPos
	mov     si,ax
	mov     bl,cs:[Song.Order][si]
	shl     bl,1
	mov     ax,cs:[Song.PatternsSeg][bx]
	mov     cs:[Song.PatternSeg],ax
	;mov     cs:Song.PatPos,al
	mov     cs:Song.PatOfs,0
@SamePattern:        
	ret
GetNextNote endp

;FillBuffer Proc -
;Fills the buffer achieving the mixing of channels, etc ,etc

FillBuffer      proc                            
	cmp     cs:BufBlock,1
	jz      @block_1

@block_0:
	xor     di,di
	mov     cs:BufBlock,1
	jmp     @Fill

@block_1:
	mov     di,cs:DMABufferSize
	shr     di,1
	mov     cs:Bufblock,0
       
@fill:
	mov     es,cs:DMABuff                                                
						;Clear Buffer
	mov     al,0;80h
	mov     cx,cs:DmaBufferSize
	shr     cx,1
	push    di
	push    cx
	rep     stosb
	pop     cx
	pop     di
	lea     bx,Channels
	mov     dh,cs:Song.NumOfchannels
@AnotherChannel:
	push    di
	push    cx
	
	mov     ds,word ptr cs:[bx][SarChannel.pSample]
	mov     si,cs:[bx][SarChannel.SampOfs]        ;Get Sample Offset
	mov     dl,cs:[bx][SarChannel.SampFrac]       ;Get Offset Fractionary
	
@PutSample:        
	cmp     si,cs:[bx][SarChannel.SampLoopEnd]
	jb      @PlaySamp
	cmp     cs:[bx][SarChannel.Looping],0
	jz      @Filled ;@NoLoopStuff
	mov     si,cs:[bx][SarChannel.SampLoopStart]

@PlaySamp:
	
	;Linear Interpolation
	mov     ax,si
	inc     ax
	cmp     ax,cs:[bx][SarChannel.SampLoopEnd]
	jz      @@NoInterpolation        
	mov     al,ds:[si+1]  ; Next Sample         
	sar     al,1
	mov     ah,ds:[si]    ; Current Sample         
	sar     ah,1
	sub     al,ah           
	test    al,80h
	jnz     @@Negative
	mul     dl                    
	sal     ah,1
	mov     al,ds:[si]          
	add     al,ah              
	jmp     @@positive

@@Negative:                                                 
	neg     al
	mul     dl
	sal     ah,1
	mov     al,ds:[si]
	sub     al,ah
	jmp     @@Positive
   
						;Volume Scaling
@@NoInterpolation:        
	mov     al,ds:[si]
@@Positive:        
						 ;Volume Scaling
	imul    cs:[bx][SarChannel.SampVol]
	
	;mov     al,ah                           ;!!!
	add     es:[di],ah                 ;Put data in DMA buffer

	jno     @NoSaturation                   ;Saturation Control
	mov     al,-128            ;Lets Put Minimum
	
	jns     @SaturLow
	mov     al,127;
@SaturLow:
	mov     es:[di],al
@NoSaturation:

	inc     di
       
	add     dl,byte ptr cs:[bx][SarChannel.SampFreqAdder]
	adc     si,word ptr cs:[bx][SarChannel.SampFreqAdder+1]
	; USING PAL VERSION
       ; add     edx,cs:[bx][SarChannel.SampFreqAdder]
       ; mov     
       ; xor     ah,ah
       ; mov     al,dh
       ; mov     si,cs:[bx][SarChannel.SampOfs]

	; END OF USING PAL
	
	
	dec     cx
	jnz     @PutSample
	
@Filled:
	mov     cs:[bx][SarChannel.SampOfs],si
	mov     cs:[bx][SarChannel.SampFrac],dl

	pop     cx
	pop     di
	add     bx,size SarChannel
	dec     dh
	jnz     @AnotherChannel

	call    Convert2Unsigned
	
	ret
FillBuffer      endp

FillBufferStereo proc                            
	cmp     cs:BufBlock,1
	jz      @@block_1

@@block_0:
	xor     di,di
	mov     cs:BufBlock,1
	jmp     @@Fill

@@block_1:
	mov     di,cs:DMABufferSize
	shr     di,1
	mov     cs:Bufblock,0
       
@@fill:
	mov     es,cs:DMABuff                                                
						;Clear Buffer
	mov     al,0;80h
	mov     cx,cs:DmaBufferSize
	shr     cx,1
	push    di
	push    cx
	rep     stosb
	pop     cx
	pop     di
	lea     bx,Channels
	mov     dh,cs:Song.NumOfchannels
@@AnotherChannel:
	push    di
	push    cx
	
	mov     ds,word ptr cs:[bx][SarChannel.pSample]
	mov     si,cs:[bx][SarChannel.SampOfs]        ;Get Sample Offset
	mov     dl,cs:[bx][SarChannel.SampFrac]       ;Get Offset Fractionary
	cmp     cs:[bx][SarChannel.LeftVol],255        
	jz      @LeftChannel
	inc     di
@LeftChannel:

@@PutSample:        
	cmp     si,cs:[bx][SarChannel.SampLoopEnd]
	jb      @@PlaySamp
	cmp     cs:[bx][SarChannel.Looping],0
	jz      @@Filled ;@NoLoopStuff
	mov     si,cs:[bx][SarChannel.SampLoopStart]

@@PlaySamp:
	
	;Linear Interpolation
	mov     ax,si
	inc     ax
	cmp     ax,cs:[bx][SarChannel.SampLoopEnd]
	jz      @NoInterpolation        
	mov     al,ds:[si+1]  ; Next Sample         
	sar     al,1
	mov     ah,ds:[si]    ; Current Sample         
	sar     ah,1
	sub     al,ah           
	test    al,80h
	jnz      @Negative
	mul     dl                    
	sal     ah,1
	mov     al,ds:[si]          
	add     al,ah              
	jmp     @positive

@Negative:                                                 
	neg     al
	mul     dl
	sal     ah,1
	mov     al,ds:[si]
	sub     al,ah
	jmp     @Positive
   
						;Volume Scaling
@NoInterpolation:        
	mov     al,ds:[si]
@Positive:        
	imul    cs:[bx][SarChannel.SampVol]
	
	add     es:[di],ah                 ;Put data in DMA buffer

	jno     @@NoSaturation                   ;Saturation Control
	mov     al,-128            ;Lets Put Minimum
	
	jns     @@SaturLow
	mov     al,127;
@@SaturLow:
	mov     es:[di],al
@@NoSaturation:

	add     di,2
       
	add     dl,byte ptr cs:[bx][SarChannel.SampFreqAdder]
	adc     si,word ptr cs:[bx][SarChannel.SampFreqAdder+1]
	
	sub     cx,2
	jnz     @@PutSample
	
@@Filled:
	mov     cs:[bx][SarChannel.SampOfs],si
	mov     cs:[bx][SarChannel.SampFrac],dl

	pop     cx
	pop     di
	add     bx,size SarChannel
	dec     dh
	jnz     @@AnotherChannel

	call    Convert2Unsigned
	
	ret
FillBufferStereo endp

Convert2Unsigned proc
	
@convert:
	xor     byte ptr es:[di],80h            
	inc di
	dec     cx
	jnz     @convert

	ret
Convert2Unsigned endp


SB_Int          proc    far
	pusha
	call    AckSb
	mov     al,20h
	out     20h,al
	call    NextTick
	popa

	iret
SB_Int          endp


GUS_Int         proc    far
	pusha
	mov     al,20h
	out     20h,al
	call    NextTick
	popa
	iret
GUS_Int         endp

ModPlay proc far
	pusha
	push    cs
	pop     ds

					;Init Channels Panning Values
	lea     di,cs:Channels
	mov     cl,cs:[Song.NumOfChannels]
	shr     cl,1
@InitPanning:        
	mov     cs:[di][SarChannel.leftVol],255
	mov     cs:[di][SarChannel.rightvol],0
	add     di,size SarChannel
	mov     cs:[di][SarChannel.leftVol],0
	mov     cs:[di][SarChannel.rightVol],255
	dec     cl
	jnz     @InitPanning


	xor     ax,ax
	mov     cs:Song.SeqPos,al
	mov     si,ax
	xor     bh,bh
	mov     bl,cs:[Song.Order][si]
	shl     bl,1
	mov     ax,cs:[Song.PatternsSeg][bx]      ;Calc Next Pattern Seg
	mov     cs:Song.PatternSeg,ax
	mov     cs:Song.PatOfs,0


	mov     cs:Song.TickCont,1

	cmp     cs:Device.card,GUS
	jnz     @PlaySb
@PlayGus:                                       ;Attention!! For Gus Im Using
						;the Timer, Not GUS IRQ...
	
	call    HookTimer ;HookGusInt
	mov     ax,23850                           ;1/50 secs (1193000/50)
	call    ProgTimerFreq
	popa
	ret

@PlaySb:
	mov     al,0d1h        
	call    WriteDSP                        ;Turn On the speaker
	
	mov     al,40h
	call    WriteDSP

	xor     edx,edx
	mov     eax,256000000
	xor     ebx,ebx
	mov     bx,device.Mixfreq
	cmp     device.stereo,0
	
	jz      @NoDoubleFreq
	shl     bx,1
@NoDoublefreq:
	
	div     ebx
	mov     ebx,65535
	sub     ebx,eax

	
	mov     al,bh
	call    WriteDSP
	
	call    AllocDMA
	mov     al,device.IRQ
	mov     SBIRQ,al
	call    HookSbInt
	call    enable_Sb_int
	mov     al,device.DMAchan
	mov     DMA_Channel,al
	call    DMA_Transfer
	call    DMA_SB
	
	popa
	ret
ModPlay endp

ModStop proc    far
	cmp     cs:device.Card,GUS
	jz      @StopGus
	call    ResetDSP
	call    StopDMA
	ret
@StopGus:
	call    DeHookTimer
	xor     cl,cl
@StopGusVoices:        
	mov     al,cl
	call    GusSetVoice
	mov     bl,1
	call    GusSetVCurr
	inc     cl
	cmp     cl,14
	jnz     @StopGusVoices
	ret
ModStop endp


HookTimer proc
	push ds
	xor     ax,ax        
	mov     ds,ax
	mov     eax,ds:[8*4]
	mov     cs:TimerInt,eax
	mov     ax,cs
	shl     eax,16
	mov     ax,OFFSET Gus_Int
	mov     ds:[8*4],eax
	pop     ds
	ret
HookTimer endp

ProgTimerFreq   proc
	mov     dx,ax
	mov     al,036h
	out     43h,al
	mov     al,dl
	out     40h,al
	mov     al,dh
	out     40h,al
	ret
ProgTimerFreq   endp
	
DeHookTimer     proc                            ;And Restores 18.2 freq
	push ds
	mov     eax,cs:TimerInt
	xor     dx,dx
	mov     ds,dx
	cli
	mov     ds:[8*4],eax
	mov     al,036h
	out     43h,al
	mov     al,dl
	out     40h,al
	mov     al,dh
	out     40h,al
	sti
	pop ds
	ret
DeHookTimer ENDP



; ==========================================================================
; ==================== Player Commands Processing ==========================
; ==========================================================================

ProcessCommands proc
	lea     di,Channels
	mov     cl,cs:[Song.NumOfChannels]
	
@ProcessNextChannel:        
	mov     al,cs:[di][SarChannel.EffectCmd]
	mov     ah,cs:[di][SarChannel.EffectParm]
	cmp     al,03h
	jz      @PrepareTonePortamento
	cmp     al,04h
	jz      @PrepareVibrato
	cmp     al,05h
	jz      @PrepareTonePortamento
	cmp     al,06h
	jz      @PrepareVibrato
	cmp     al,07h
	jz      @PrepareTremolo
	cmp     al,09h
	jz      @SampleOffset
	cmp     al,0Bh
	jz      @PositionJump
	cmp     al,0Ch
	jz      @SetVolume
	cmp     al,0Dh
	jz      @PatternBreak
	cmp     al,0Eh
	jz      @SpecialCmds
	cmp     al,0Fh
	jz      @SetSpeed
	jmp     @Processed

@PrepareTonePortamento:
	or      ah,ah
	jz      @IncProcessed
	mov     cs:[di][SarChannel.PortaInc],ah
@IncProcessed:
	mov     ax,cs:[di][SarChannel.TonePortPeriod]
	mov     bx,cs:[di][SarChannel.period]
	cmp     ax,bx
	ja      @Processed
	neg     cs:[di][SarChannel.PortaInc]
	jmp     @Processed

@PrepareVibrato:
	mov     bl,ah
	shr     bl,4
	and     ah,0fh
	or      bl,bl
	jz      @NoNewVibSpeed
	mov     cs:[di][SarChannel.VibSpeed],bl
@NoNewVibSpeed:
	or      ah,ah
	jz      @NoNewVibDepth
	mov     cs:[di][SarChannel.VibDepth],ah
@NoNewVibDepth:
	cmp     cs:[di][SarChannel.NewNoteVib],FALSE
	jz      @Processed      ;No New VibCenter
	mov     ax,cs:[di][SarChannel.period]
	mov     cs:[di][SarChannel.VibCenter],ax
	mov     cs:[di][SarChannel.NewNoteVib],FALSE
	jmp     @Processed

@PrepareTremolo:
	mov     bl,ah
	shr     bl,4
	and     ah,0fh
	or      bl,bl
	jz      @NoNewTremSpeed
	mov     cs:[di][SarChannel.TremSpeed],bl
@NoNewTremSpeed:
	or      ah,ah
	jz      @NoNewTremDepth
	mov     cs:[di][Sarchannel.TremDepth],ah
@NoNewTremDepth:
	mov     al,cs:[di][SarChannel.SampVol]
	mov     cs:[di][Sarchannel.TremCenter],al
	jmp     @Processed

@SampleOffset:
	xor     al,al
	cmp     ax,cs:[di][SarChannel.SampEnd]
	ja      @Processed
	mov     cs:[di][SarChannel.SampOfs],ax
	jmp     @Processed

@PositionJump:
	mov     cs:[Song.SeqPos],ah
	xor     ah,ah
	jmp     @ProcessJump

@SetVolume:
	mov     cs:[di][SarChannel.SampVol],ah
	jmp     @Processed

@PatternBreak:
	inc     cs:Song.SeqPos
@ProcessJump:        
	mov     cs:Song.PatPos,ah
	mov     al,ah
	mov     bl,cs:[Song.TotalRowSize]
	mul     bl
	mov     cs:Song.PatOfs,ax
	
	xor     ah,ah
	mov     al,cs:Song.SeqPos
	mov     si,ax
	xor     bh,bh
	mov     bl,cs:[Song.Order][si]
	shl     bx,1
	mov     ax,cs:[Song.PatternsSeg][bx]
	mov     cs:[Song.PatternSeg],ax
				     ;Calc Next Pattern Offset
	jmp     @Processed

; =============== E (Special Commands Here) =================

@SpecialCmds:
	xor     dh,dh
	mov     al,ah
	and     ah,0fh
	shr     al,4
	cmp     al,01h
	jz      @FineSlidePortUp
	cmp     al,02h
	jz      @FineSlidePortDown
	cmp     al,09h
	jz      @PrepareRetrig
	cmp     al,0Ah
	jz      @FineSlideVolUp
	cmp     al,0Bh
	jz      @FineSlideVolDown
	cmp     al,0Eh
	jz      @DelayPattern
	jmp     @Processed

@FineSlidePortUp:
	mov     dl,ah
	sub     cs:[di][SarChannel.Period],dx
	cmp     cs:[di][SarChannel.Period],20
	jbe     @Processed
	jmp     @DoFineSlidePortamento
@FineSlidePortDown:
	mov     dl,ah
	add     cs:[di][Sarchannel.period],dx
@DoFineSlidePortamento:        
	
	xor     ebx,ebx
	xor     edx,edx
	mov     eax,3546895     ;This is pal. Pal/period=freq
	mov     bx,cs:[di][SarChannel.period]
	or      bx,bx
	jz      @Processed
	div     ebx
	xor     edx,edx
	mov     cs:[di][SarChannel.freq],ax
	shl     eax,8                   ;8 Bits Fixed Point
	mov     bx,cs:device.Mixfreq
	div     ebx
	mov     cs:[di][SarChannel.SampFreqAdder],eax
	jmp     @Processed

@PrepareRetrig:
	mov     cs:[di][SarChannel.RetrigCont],ah
	jmp     @Processed

@FineSlideVolDown:
	mov     ch,cs:[di][SarChannel.SampVol]
	sub     ch,ah        
	cmp     ch,0
	jge     @FineVolSlideDone
	xor     ch,ch
	jmp     @FineVolSlideDone
@FineSlideVolUp:
	mov     ch,cs:[di][SarChannel.SampVol]
	add     ch,ah
	cmp     ch,64
	jle     @FineVolSlideDone      
	mov     ch,64
@FineVolSlideDone:
	mov     cs:[di][SarChannel.SampVol],ch
	jmp     @Processed

@DelayPattern:
	mov     al,ah
	mul     cs:[song.speed]
	mov     cs:[Song.Delay],al
	jmp     @Processed

@SetSpeed:
	cmp     ah,32
	jae     @SetTempo
	mov     cs:[Song.Speed],ah
	jmp     @Processed

@SetTempo:
	mov     cs:[Song.BPM],ah
	jmp     @Processed

@Processed:
	add     di,size SarChannel
	dec     cl
	jnz     @ProcessNextChannel
	ret
ProcessCommands endp

; ============== Continous Commands ===============

ProcessContinousCmds proc
						;Process Delay Pattern
	cmp     cs:Song.Delay,0
	jz      @NoDelay
	inc     cs:Song.TickCont
	dec     cs:Song.Delay
@NoDelay:

	lea     di,Channels
	mov     cl,cs:[Song.NumOfChannels]
	xor     dx,dx
	
@@ProcessNextChannel:        
	mov     al,cs:[di][SarChannel.EffectCmd]
	mov     ah,cs:[di][SarChannel.EffectParm]

	cmp     al,01h        
	jz      @SlidePortamentoUp
	cmp     al,02h
	jz      @SlidePortamentoDown
	cmp     al,03h
	jz      @TonePortamento
	cmp     al,04h
	jz      @Vibrato
	cmp     al,05h
	jz      @VolumeSlide    ; ToneP + VolSld
	cmp     al,06h
	jz      @VolumeSlide    ; Vibra + VolSld
	cmp     al,07h
	jz      @Tremolo
	cmp     al,0Ah
	jz      @VolumeSlide
	cmp     al,0Eh
	jz      @@SpecialCmds
	jmp     @@Processed

@SlidePortamentoUp:
	mov     dl,ah
	sub     cs:[di][SarChannel.Period],dx
	cmp     cs:[di][SarChannel.Period],20
	jbe     @@Processed
	jmp     @DoSlidePortamento
@SlidePortamentoDown:
	mov     dl,ah
	add     cs:[di][Sarchannel.period],dx
@DoSlidePortamento:        
	xor     ebx,ebx
	xor     edx,edx
	mov     eax,3546895     ;This is pal. Pal/period=freq
	mov     bx,cs:[di][SarChannel.period]
	or      bx,bx
	jz      @@Processed
	div     ebx
	xor     edx,edx
	mov     cs:[di][SarChannel.freq],ax
	shl     eax,8                   ;8 Bits Fixed Point
	mov     bx,cs:device.Mixfreq
	div     ebx
	mov     cs:[di][SarChannel.SampFreqAdder],eax
	jmp     @@Processed

@TonePortamento:
	mov     bx,cs:[di][SarChannel.TonePortPeriod]
	mov     al,cs:[di][SarChannel.PortaInc]
	cbw
	add     cs:[di][SarChannel.period],ax
	cmp     ax,0
	jl      @Minor
	cmp     cs:[di][SarChannel.period],bx
	jl      @DoSlidePortamento
	mov     cs:[di][SarChannel.period],bx
	jmp     @DoSlidePortamento
@Minor:
	cmp     cs:[di][SarChannel.period],bx
	jg      @DoSlidePortamento
	mov     cs:[di][SarChannel.period],bx
	jmp     @DoSlidePortamento


@Vibrato:
	mov     si,cs:[di][SarChannel.Vibpos]
	shl     si,1
	mov     ax,cs:[VibratoTable+si]
	mov     bl,cs:[di][SarChannel.VibDepth]
	xor     bh,bh
	imul    bx
	sar     ax,7
	add     ax,cs:[di][SarChannel.VibCenter]
	mov     cs:[di][SarChannel.period],ax
	xor     dh,dh
	mov     dl,cs:[di][SarChannel.VibSpeed]
	add     cs:[di][SarChannel.VibPos],dx
	and     cs:[di][SarChannel.VibPos],63
	jmp     @DoSlidePortamento

@Tremolo:
	mov     si,cs:[di][SarChannel.TremPos]
	shl     si,1
	mov     ax,cs:[VibratoTable+si]
	mov     bl,cs:[di][SarChannel.TremDepth]
	xor     bh,bh
	imul    bx
	sar     ax,7
	add     al,cs:[di][SarChannel.TremCenter]
	adc     ah,0
	cmp     ax,64
	jg      @TooHigh
	cmp     ax,0
	jge     @NotLow
	xor     al,al
	jmp     @NotLow
@TooHigh:
	mov     al,64
@NotLow:
	mov     cs:[di][SarChannel.SampVol],al
	xor     dh,dh
	mov     dl,cs:[di][Sarchannel.TremSpeed]
	add     cs:[di][SarChannel.TremPos],dx
	and     cs:[di][Sarchannel.TremPos],63
	jmp     @@Processed



@VolumeSlide:
	mov     ch,cs:[di][SarChannel.SampVol]
	cmp     ah,16
	jae     @UpVolSlide
@DownVolSlide:
	sub     ch,ah        
	cmp     ch,0
	jge     @VolSlideDone
	xor     ch,ch
	jmp     @VolSlideDone
@UpVolSlide:
	and     ah,0f0h
	shr     ah,4
	add     ch,ah
	cmp     ch,64
	jle     @VolSlideDone      
	mov     ch,64
@VolSlideDone:
	mov     cs:[di][SarChannel.SampVol],ch
	cmp     cs:[di][SarChannel.effectCmd],5
	jz      @TonePortamento
	cmp     cs:[di][Sarchannel.effectCmd],6
	jz      @Vibrato
	jmp     @@Processed

; ================= E (Special Commands) ===================

@@SpecialCmds:
	mov     al,ah
	and     ah,0fh
	shr     al,4
	cmp     al,09h
	jz      @RetrigNote
	jmp     @@Processed

@RetrigNote:
	dec     cs:[di][SarChannel.RetrigCont]
	jnz     @Processed
	mov     cs:[di][SarChannel.RetrigCont],ah
	mov     cs:[di][SarChannel.SampOfs],0
	jmp     @@Processed

@@Processed:
	add     di,size SarChannel
	dec     cl
	jnz     @@ProcessNextChannel

	ret
ProcessContinousCmds endp


;Procedures to get info about the playing song (For Synch stuff)

; GetPattern procedure
; Returns: al with the pattern number

GetPattern      proc far
	push    si
	xor     ah,ah
	mov     al,cs:Song.SeqPos
	mov     si,ax
	mov     al,cs:[Song.Order][si]
	pop     si
	ret
GetPattern      endp

;GetPosition procedure
;Returns: al with Song position

GetPosition     proc far
	mov     al,cs:Song.SeqPos
	ret
GetPosition      endp

;GetPatternRow procedure
;Returns: al with Row

GetPatternRow   proc
	mov     al,cs:Song.PatPos
	ret
GetPatternRow   endp

;Get The Volume of a Channel
; In:   al -> Channel
; Out:  ah -> Volume of that channel
; NOTE: First Channel is 0

GetChannelVolume proc far
	push    bx
	push    di
	xor     ah,ah
	mov     bx,size SarChannel
	mul     bx
	mov     bx,ax
	xor     ah,ah
	lea     di,Channels
;        cmp     cs:[bx][di][SarChannel.looping],0
;        jz      @VolZero
	mov     ah,cs:[bx][di][SarChannel.SampVol]
;@VolZero:
	pop     di
	pop     bx
	ret
GetChannelVolume        endp

; Get the period of a Channel
; In:   al -> Channel
; Out:  bx -> Period of that Channel

GetChannelPeriod proc far
	push    ax
	push    di
	xor     ah,ah
	mov     bx,size SarChannel
	mul     bx
	mov     bx,ax
	lea     di,Channels
	mov     bx,cs:[bx][di][SarChannel.period]
	pop     di
	pop     ax
	ret
GetChannelPeriod endp



;Get Number Of Channels
; Out: al

GetChannels proc far
	mov     al,cs:[Song.NumOfChannels]
	ret
GetChannels endp

;Out: ds:dx with SongName

GetSongName     proc far
	lea     dx,Song.SonName
	push    cs
	pop     ds
	ret
GetSongName     endp

; In: al Sample Number
;     bx Period

PlaySample      proc   far
	

	ret
PlaySample      endp
