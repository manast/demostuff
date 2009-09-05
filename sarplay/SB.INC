; ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
; ³ Sound Blaster Procedures by Sarwaz of Mistery (a.k.a Manuel Astudillo)   ³
; ³ Copyright by Manuel Astudillo                                            ³
; ³ Description:                                                             ³
; ³ All kind of usefull procedures for coding low level SB Cards Series,     ³
; ³ including some DMA procedures and all!                                   ³
; ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ


;-----------------------------------------------------------------------------
; Some usefull variables
;-----------------------------------------------------------------------------

SB_BASE_ADRESS  dw ?

DMA_BuffSeg     dw ?
DMA_Channel     db ?
;SB_INT          db ? ;Dummy Line

;------------------------------------------------------------------------------
; WriteDSP procedure
; Writes a byte to DSP
; In: al
; -----------------------------------------------------------------------------

WriteDSP proc far
	push dx
	push ax
	mov dx,cs:SB_BASE_ADRESS
	add dx,0ch              ;2xCh
	
@NotReady:
	in al,dx
	and al,80h              ;test bit 7
	jnz @NotReady
	pop ax

	out dx,al               ;Write the Byte
	pop dx  
	ret
WriteDSP endp

;------------------------------------------------------------------------------
; ReadDSP procedure
; Reads a byte from the DSP
; Out: al
;------------------------------------------------------------------------------

ReadDSP proc  far
	push dx
	mov dx,cs:SB_BASE_ADRESS
	add dx,0eh              ;We have to test bit 7 of 2xeh 
@NoData:
	in al,dx
	and al,80h
	jz @Nodata

	sub dx,4
	in al,dx
	pop dx
	ret
ReadDSP endp


AckSB proc
	
	mov  dx,cs:[SB_base_ADress]
	add  dx,0eh 
	in   al,dx

	ret
AckSb endp

;Mixer Stuff

;ReadMixer reads from the address in AL on the mixer chip.

ReadMixer proc

  mov  dx,cs:[SB_BASE_ADRESS]  ;Load in address for the Mixer
  add  dx,4        ;selection register.

  out  dx,al       ;Select the Mixer register.

  mov  cx,6        ;Wait for the chip.
@MixLoop:
  in   al,dx
  loop @MixLoop

  inc  dx          ;Read the data out of the data register.
  in   al,dx
  ret
ReadMixer endp


;WriteMixer will write AH to register AL of the Mixer chip.

WriteMixer proc

  mov  dx,cs:[SB_BASE_ADRESS]  ;Load in address for the Mixer
  add  dx,4        ;selection register.

  out  dx,al       ;Select the Mixer register.

  mov  cx,6        ;Wait for the chip.
@@MixLoop:
  in   al,dx
  loop @@MixLoop

  inc  dx          ;Send the data to the data register.
  mov  al,ah
  out  dx,al
  dec  dx

  mov  cx,35       ;Wait for the chip.
@@MixLoop2:
  in   al,dx
  loop @@MixLoop2
  ret

WriteMixer endp


;------------------------------------------------------------------------------
; GetVersion procedure
; Gets the version of the SB
; Out: Screen.
;      Al = 01 if Sb.15
;         = 02 if Sb.2.0
;         = 03 if Sb Pro
;         = 04 if Sb 16
; Destroys DX
;------------------------------------------------------------------------------

sbMsg           db 'Sound Blaster 1.5 Detected',13,10,36
sb20Msg         db 'Sound Blaster 2.0 Detected',13,10,36
sbProMsg        db 'Sound Blaster Pro Detected',13,10,36
sb16Msg         db 'Sound Blaster 16 series Detected',13,10,36

GetVersion PROC
	mov al,0e1h
	call writeDSP
	call readDSP
	cmp al,4        ;check for Sb 16
	jz @sb16
	cmp al,3        ;check for sb pro
	jz @sbPro
	cmp al,2        ;check for sb2.0
	jz @Sb20
	lea dx,SbMsg
	mov ah,9h
	int 21h
	mov al,1
	ret

@sb20:
	mov ah,9h
	lea dx,Sb20Msg
	int 21h
	mov al,2
	ret
@sbPro:
	mov ah,9h
	lea dx,SbProMsg
	int 21h
	mov al,3
	ret
@sb16:
	mov ah,9h
	lea dx,sb16Msg
	int 21h
	mov al,4
	ret
GetVersion endp


;------------------------------------------------------------------------------
; ResetDSP procedure
; Resets DSP if SB
; Out: If Succesfull carry=0 and SB_BASE_ADRESS with correct base adress
;      If not succesufull carry=1
;------------------------------------------------------------------------------

ResetDSP proc
					;Find SB if any, and Reset DSP
	mov SB_BASE_ADRESS,210h

@Look4SB:
	mov dx,SB_BASE_ADRESS

	add dx,6
	mov al,1
	out dx,al               ;Write a 1 to 2x6h, that Starts DSP reset

				;Wait at least 3 microsecs
	mov cl,40
@wait3ms:
	in al,dx
	loop @wait3ms

	xor al,al
	out dx,al               ;Write a 0 to 2x6h, that Stops DSP reset

	add dx,8                ;Check for 0AAh
	mov cx,100
@CheckPort:
	in al,dx
	and al,80h              ;check if DSP is ready to read
	jz @PortNotReady
	
	sub  dx,4                ;DSP port is ready to be
	in   al,dx               ;read.  Read and check for
	add  dx,4                  ;an AAh.
	cmp  al,0AAh
	je   @GoodReset

@PortNotReady:                  ;Keep trying for upto
  loop @CheckPort               ;100 micro seconds.

@BadReset:                       
	add SB_BASE_ADRESS,10h   ;Check Again For next Base Adress
	cmp SB_BASE_ADRESS,290h  
	jnz @Look4SB
	stc
	ret
@GoodReset:
	clc
	ret
ResetDSP endp


;------------------------------------------------------------------------------
; Procedure Create DMA buffer
; In: CX Buffer Lenght (Divisible by 16)
; Out: DX segment of the DMA buffer, and DMABuff
;------------------------------------------------------------------------------

DMABuffSeg      dw ?
DMABuff         dw ?
DMABuffSize     dw ?


Create_DMA_Buffer PROC

	push ax
	push bx
	push di
	push es
	push ds

	push cs
	pop  ds

	mov DMABuffSize,cx

	mov  bx,cx                ;Allocate memory for the
	mov  cl,3                 ;DMABuff.  DMABuffSize / 8
	shr  bx,cl                ;gives you twice as much space
				  ;as you need.

	mov  ah,48h               ;Allocate the mem for DOS.
	int  21h
	jnc  GoodMem

	; jmp  Exit               ;We will assume that there is enough mem

GoodMem:
	mov  [DMABuffSeg],ax
	mov  [DMABuff],ax

	and  ax,0fffh             ;See if you just happened to get
	jz   ClearBuff            ;some memory which is exactly on
				  ;a physical 64k boundary.

	mov  ax,[DMABuff]         ;Find the next highest physical
	and  ax,0f000h            ;64K segment.
	add  ax,1000h
	mov  dx,ax                ;Save it away.
	mov [DMABuff],dx

	sub  ax,[DMABuffSeg]      ;See if DMABuff can fit between
	mov cx,DMABuffsize
	shr cx,4
	cmp  ax,cx                ;DMABuffSeg and the next highest
	jae  ClearBuff            ;physical 64K segment.

	add dx,1000h
	mov  [DMABuff],dx         ;No, then use the next highest
				  ;physical 64K segment.

ClearBuff:
	mov  es,[DMABuff]         ;Initialize the buffer to
	xor  di,di                ;8080h which is no sound
	mov  cx,DMABufferSize     ;for the SB cards.
	shr  cx,1
	cld
	mov  ax,8080h ;Just no sound
	rep  stosw

	mov dx,DMAbuff

	pop ds
	pop es
	pop di
	pop bx
	pop ax
	ret

Create_DMA_Buffer endp


; --------------------------------------------------------------------------
; Procedure Alloc DMA
; Allocs DMA Buffer WITHOUT Waste Memory
; Idea by Manuel Astudillo
; --------------------------------------------------------------------------

DmaBufferSize   dw      0

AllocDMA        proc
	mov     bx,1                            ;Alloc 16 bytes
	mov     ah,48h
	int     21h
	mov     bx,ax
	and     bx,0fffh
	jz      @EsCorrecto
	mov     bx,ax
	and     bx,0f000h
	add     bx,1000h
	sub     bx,ax                           ;Alloc Dummy Memory
	sub     bx,1                            ;Sub MCB length
	
	mov     es,ax                           ;Free initial 16 bytes
	mov     ah,49h
	int     21h
	
	mov     ah,48h
	int     21h
	mov     cx,ax                           ;Save Segment
	mov     bx,cs:DmaBufferSize             ;Alloc DMA buffer 
	shr     bx,4
	inc     bx
	mov     ah,48h
	int     21h
	mov     cs:DMABuff,ax
						;Free Dummy Memory        
	mov     es,cx                                              
	mov     ah,49h
	int     21h

	jmp     @ClearBuff
	
@EsCorrecto:
	mov     es,ax
	mov     ah,49h
	int     21h
	mov     bx,cs:DmaBufferSize
	shr     bx,4
	inc     bx
	mov     ah,48h
	int     21h
	mov     cs:DMABuff,ax

@ClearBuff:
	mov  es,[DMABuff]         ;Initialize the buffer to
	xor  di,di                ;8080h which is no sound
	mov  cx,DMABufferSize     ;for the SB cards.
	shr  cx,1
	cld
	mov  ax,8080h ;Just no sound
	rep  stosw
	
	ret
AllocDMA        endp


;-----------------------------------------------------------------------------
; Procedure DMA_Transfer
; Programs DMA for transfer (from DMA channels 1 to 3) and SB auto-init mode
; In: DMA_channel,DMABuff
;-----------------------------------------------------------------------------

;note: Actually only works for DMA channel 1

;DMABufferSize equ 8192

DMA_Transfer PROC
	push ax        
	push cx
	push dx

	mov al,4
	add al,cs:DMA_channel
	out 0ah,al                ;Set Mask Bit for desired DMA channel

	xor al,al
	out 0ch,al

	mov al,58h
	add al,cs:DMA_Channel      ;DMA mode (58h+DMA_Chann. for auto-init Sb mode)
	out 0bh,al

		;This is dma channel 1 specific code

	mov  ax,cs:[DMABuff]  ;Tell the DMA where the data is.
	mov  cl,4

	mov  dl,ah         ;Compute the MS 4 bits of linear
	xor  dh,dh         ;address.
	shr  dl,cl

	shl  ax,cl         ;Compute the LS 16 bits.

	out  02h,al        ;Send LS 8 bits of linear address.
	mov  al,ah
	out  02h,al        ;Send next 8 bits of linear address.
	mov  al,dl
	out  83h,al        ;Send MS 4 bits.

	mov  ax,cs:DMABufferSize  ;DMA length is defined as
	dec  ax                ;actual length - 1.

	out  03h,al        ;Send LS 8 bits of length.
	mov  al,ah
	out  03h,al        ;Send MS 8 bits of length.

	mov  al,cs:DMA_Channel  ;Turn back on DMA channel 1.
	out  0ah,al
		
	pop dx
	pop cx
	pop ax

	ret
DMA_Transfer endp

DMA_SB proc
	push ax
	; SB DMA Transfer here

	mov  al,48h        ; Set Buffer Size command
	call WriteDSP      ;

	mov  ax,cs:DMABufferSize   ;DSP size if length - 1. div 2 because auto-init
	shr  ax,1
	dec  ax

	call WriteDSP     ;Send DSP LS 8 bits of length.
	mov  al,ah
	call WriteDSP     ;Send DSP MS 8 bits of length.

	cmp     cs:device.ver,3
	jz      @HighSpeed
	
	mov al,1ch             ; Set Auto-init mode for Sb2.0,SbPro
	call WriteDSP
	pop ax
	ret
      
@HighSpeed:       
	mov al,90h       ; Set High Speed Auto Init For SBPRO
	call WriteDSP
	
	pop ax

	ret
DMA_SB endp


;------------------------------------------------------------------------------
; Procedure HookSBInt
; Hooks SB_INT
; In: SBIRQ
;------------------------------------------------------------------------------

;sb_int label byte


SBIRQ         db ?                      
OldDSPVect    dd   ?   ;The is for the old interrupt vector.

HookSbInt PROC

	mov  al,cs:[SBIRQ]               ;Get Old interupt vector.
	add  al,8
	mov  ah,35h
	int  21h
	mov  cs:[word ptr OldDSPVect+2],bx
	mov  cs:[word ptr OldDSPVect],es

	push ds                       ;Hook the DSP int vector.
	mov  al,cs:[SBIRQ]
	add  al,8
	mov  dx,seg SB_INT
	mov  ds,dx
	mov  dx,offset SB_INT
	mov  ah,25h
	int  21h
	pop  ds

	ret
HookSbInt endp

;------------------------------------------------------------------------------
; Procedure Enable_SB_INT
; In: SBIRQ
;------------------------------------------------------------------------------

OriginalPIC db ?

Enable_SB_INT Proc

	mov  cl,cs:[SBIRQ]
	mov  ah,1
	shl  ah,cl
	not  ah

	in   al,21h
	mov  cs:[OriginalPIC],al
	and  al,ah
	out  21h,al

	ret

Enable_SB_INT endp

StopDMA proc
	mov al,0dah
	call WriteDSP
	ret
StopDMA endp

; -------------------------------------------------------------------------
; DetectIrq&DMA - 
; Detects Irq and DMA by hardware
; -------------------------------------------------------------------------

DetectIrq&Dma proc
			
		       
			;Save Old Irq's
			;Get Old interupt vector.
	mov  al,8+2
	mov  ah,35h
	int  21h
	mov  cs:[word ptr Oldirq2],bx
	mov  cs:[word ptr Oldirq2],es

	mov  al,8+3
	mov  ah,35h
	int  21h
	mov  cs:[word ptr Oldirq3],bx
	mov  cs:[word ptr Oldirq3],es
	
	mov  al,8+4
	mov  ah,35h
	int  21h
	mov  cs:[word ptr Oldirq4],bx
	mov  cs:[word ptr Oldirq4],es

	mov  al,8+5
	mov  ah,35h
	int  21h
	mov  cs:[word ptr Oldirq5],bx
	mov  cs:[word ptr Oldirq5],es
	
	mov  al,8+7
	mov  ah,35h
	int  21h
	mov  cs:[word ptr Oldirq7],bx
	mov  cs:[word ptr Oldirq7],es
	
						;Hook Interrupts
	cli

	push ds                
	mov  al,8+2
	mov  dx,seg SBirq2
	mov  ds,dx
	mov  dx,offset SBirq2
	mov  ah,25h
	int  21h
	
	mov  al,8+3
	mov  dx,seg SBirq3
	mov  ds,dx
	mov  dx,offset SBirq3
	mov  ah,25h
	int  21h
	
	mov  al,8+4
	mov  dx,seg SBirq4
	mov  ds,dx
	mov  dx,offset SBirq4
	mov  ah,25h
	int  21h
	
	mov  al,8+5
	mov  dx,seg SBirq5
	mov  ds,dx
	mov  dx,offset SBirq5
	mov  ah,25h
	int  21h
	
	mov  al,8+7
	mov  dx,seg SBirq7
	mov  ds,dx
	mov  dx,offset SBirq7
	mov  ah,25h
	int  21h
	sti
	pop  ds
	in   al,21h
	mov  bl,al                      ;Save IMR
	and  al,01000011b               ; Enable Ints
	out  21h,al
	mov  cs:DmaBufferSize,5         ;5 bytes!        
	call allocDMA
	mov  cs:DMA_Channel,1
@NextDMA:        
	call  ProgTransfer
	call  SB_DMA
	cmp   cs:SBIrq,0
	jz    @SBIrqDetected
	inc   DMA_Channel
	cmp   cs:DMA_Channel,4
	jnz   @NextDMA
	jz    @NOIRQDETECTED
@SBIrqDetected:        

	


	ret
DetectIrq&Dma endp

;Dummies Interrupts

SbIrq2 proc
     push       ax
     mov        cs:[SbIrq],2
     call       AckSb
     mov        al,20h
     in         20h,al
     pop        ax
     iret
SbIrq2 endp

SbIrq3 proc
     push       ax
     mov        cs:[SbIrq],3
     call       AckSb
     mov        al,20h
     in         20h,al
     pop        ax
     iret
SbIrq3 endp

SbIrq4 proc
     push       ax
     mov        cs:[SbIrq],4
     call       AckSb
     mov        al,20h
     in         20h,al
     pop        ax
     iret
SbIrq4 endp


SbIrq5 proc
     push       ax
     mov        cs:[SbIrq],5
     call       AckSb
     mov        al,20h
     in         20h,al
     pop        ax
     iret
SbIrq5 endp

SbIrq7 proc
     push       ax
     mov        cs:[SbIrq],7
     call       AckSb
     mov        al,20h
     in         20h,al
     pop        ax
     iret
SbIrq7 endp

SbIrq9 proc
     push       ax
     mov        cs:[SbIrq],9
     call       AckSb
     mov        al,20h
     in         20h,al
     pop        ax
     iret
SbIrq9 endp

SbIrq10 proc
     push       ax
     mov        cs:[SbIrq],10
     call       AckSb
     mov        al,20h
     in         20h,al
     pop        ax
     iret
SbIrq10 endp

SbIrq11 proc
     push       ax
     mov        cs:[SbIrq],11
     call       AckSb
     mov        al,20h
     in         20h,al
     pop        ax
     iret
SbIrq11 endp

SbIrq12 proc
     push       ax
     mov        cs:[SbIrq],12
     call       AckSb
     mov        al,20h
     in         20h,al
     pop        ax
     iret
SbIrq12 endp

SbIrq15 proc
     push       ax
     mov        cs:[SbIrq],15
     call       AckSb
     mov        al,20h
     in         20h,al
     pop        ax
     iret
SbIrq15 endp
