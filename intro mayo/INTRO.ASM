; Intro For Icing 96
; Coded by Sarwaz 
; Note: This Stuff began to grow the 23th April and 
; was finished the 22th May
; Lame Unoptimized Code (Who cares?)

extrn begin:far,finish:far
extrn fakecopper:far
public exit,FadeFrameF
;equivalents here
      
      ;Font Equivalents
      fntWidth         equ 28
      fntHeigth        equ 40
      
      ;Water Effect Equivalents
        XPOS    equ 0
        YWIDTH  equ 400
        XWIDTH  equ 79
        YSPEED  equ 1
        XSPEED  equ 1

        MLEFT   equ 2    
        MRIGHT  equ 3
        MUP     equ 5
        MDOWN   equ 1

        YINC1   equ 2
        YINC2   equ 1
        XINC1   equ 3
        XINC2   equ 1
              
        LogoYpos equ 176
        LogoXpos equ 0
        LogoWidth equ 160
        LogoHeigth equ 50


      ;Main Plasma Constants
        Nframes equ 100
        LinePos equ 0
        Height equ 400
        SPEED1 equ 7
        SPEED2 equ 7
        SPEED12 equ 13
        modu equ 8191
        SPEED22 equ 13

        Xinc1p equ 14
        Xinc2p equ 14
        Xinc12 equ 10
        Xinc22 equ 10


fnt segment
include intro.fnt
fnt ends

mayolog segment
include mayo.log
mayolog ends

Code Segment
        assume cs:code,ds:code,ss:stacky
.386

; Variables

sin64 label byte
include sintable

creditsTXT:
include credits.inc
FntOffset Label Byte
include FntOff.inc
include d:\sarwaz\sarplay\sarplay.inc     ;SB Player

PicSegment dw 0
LogSegment dw 0
TitleSeg dw 0
;Water Effect Variables

WaveXtmp1 db 0
WaveXtmp2 db 0
WaveYtmp1 db 0
WaveYtmp2 db 0
WaveXind1 db 64
WaveXind2 db 0
WaveYind1 db 128
WaveYind2 db 0

;Main Plasma Variables

ind1 dw 0
ind2 dw 0
ind12 dw 0
ind22 dw 0

ind3 dw 0
ind4 dw 0
ind5 dw 0

MainSin label byte 
include MainSin.inc


SinPoint1 label word 
include SinPoint1.inc

palette label byte  ;We will have 5 plasma palettes ;)
include plasma.col
irqs db 0


RGB db 3 DUP (?)
Frame_counter dw 0
gus_present db 0 ;1 = present
exitmsg db 'Mayo 64k Intro - Presented At Icing 96',13,10
        db 'By Mistery - May 1996',13,10,36
ModName db 'demo3.mod',0

;Code itself

;Some macros here

SetPalette PROC ;In ax, the seggy, in si the offset
        push ds
        mov     ds,ax
        mov     dx,3c8h
        mov     al,0
        out     dx,al
        inc     dx
        mov     cx,300h
        rep     outsb
        pop ds
        ret
SetPalette Endp

SetBlock MACRO  setsize
        mov     ah,4ah
        mov     bx,setsize
        int     21h
ENDM

Alloc MACRO amount, where
        mov     ah,48h
        mov     bx,amount
        int     21h
        mov     where,ax
ENDM


Start:
        
        push cs
        pop ds
;        in al,21h  ;First We have to desactivate the keyboard
;        mov cs:irqs,al
;        or al,00000010b 
;        out 21h,al
        push es
        call begin ;We Initializate the music System
        pop es
        mov cs:gus_present,bl
        cmp     bl,1
        jz      @GusOk
        call    InitPlayer      ;Init SbPlayer
        lea     dx,ModName
        call    Modload
        call    ModPlay
@GusOk:        
        Setblock 300000/16
        mov cs:Picsegment,SEG fnt
        mov cs:Logsegment,SEG Mayolog
        call Fadeout
        call Init_Modex ;320x400 unchained
        CAll BlankScreen
        mov ax,cs:PicSegment
        mov si,32
        Call SetPalette 
        Call Credits ;The credits Part of the intro
        mov ax,cs:Logsegment
        mov si,32
        Call SetPalette
        Call WatTitle   ;The Water Title
        Call Fakecopper
        call Init_modex
        CAll PlasmaSequence
exit:
        cmp cs:Gus_present,255
        jz nostopmuzac
        Call finish ;Stop the music
nostopmuzac:
        call    modstop
        mov ax,3h
        int 10h
        mov ah,9h
        lea dx,exitmsg
        push cs
        pop ds
        int 21h
        mov al,cs:irqs
        out 21h,al
        mov ax,4c00h ;exit from this Proggy
        int 21h

;Procedures and Macros

ClearScreen MACRO
        mov ax,0F02h
        mov dx,3c4h
        out dx,ax
        mov cx,32000
        xor ax,ax
        xor di,di
        rep stosd
        ENDM

ddelay PROC  ; In Cx Cents
@@@@1:
        push cx
        xor cx,cx
        mov dx,2710h
        mov ah,86h
        int 15h
        pop cx
        loop @@@@1
        ret
ddelay Endp


WaitVertRetrace Proc
        mov dx,3dah
dw1:
        in al,dx
        test al,8
        jnz dw1
dw2:
        in al,dx
        test al,8
        jz dw2
        ret
WaitVertRetrace Endp

Credits PROC
      lea si,creditsTXT
      
nextsentence:      
      mov bx,word PTR cs:[si+2] ;Coord Y
      shl bx,4
      lea ebx,[ebx+ebx*4] ;bx=bx*80
      mov di,word PTR cs:[si] ;Coord X
      add di,bx  ;in Di the Offset in screen Of the Sentence
      mov bx,si
      add bx,4
      Call WriteSentence
      mov si,bx
      cmp cl,1
      jnz gogo_go_johnny_go
      mov cx,250
      call ddelay 
      Call FadeOut
      ClearScreen
      pusha
      mov ax,cs:Picsegment
      mov si,32
      Call SetPalette  
      popa
gogo_go_johnny_go:
      cmp cl,2
      jnz nextsentence
      ret
Credits Endp

;In Di Screen Offset
;In Bx Text String Finished in 0,1 or 2
;Returns: In cl: 0,1, or 2


WriteSentence PROC
        push si
        mov ds,cs:PicSegment
        mov ax,0a000h
        mov es,ax
sentence:        
        mov cl,cs:[bx]
        cmp cl,2
        ja okok
        inc bx
        pop si
        ret
okok:
        Call GetFntOffset ;In cl the ascii Char
        Call Wletter
        add di,fntwidth/4
        inc bx
        jmp sentence
WriteSentence Endp

; In cl the Ascii Code
; Returns: in si, the Offset into Picsegment where the LetterBegins

GetFntOffset PROC
        push cx
        push bx
        lea bx,FntOffset
        sub cl,65 ;'A' Ascci Code
        xor ch,ch
        mov si,cx
        shl si,1
        mov si,cs:[bx+si]
        add si,800 ;Skip the palette
        pop bx
        pop cx
        ret
GetFntOffset Endp


;In ds:si pointing to the letter
;   es:di Pointing to the screen (80x400 grid)

WLetter PROC
        push di
        mov al,02h
        mov ah,01h ;Plane 0 active and 2
        mov dx,3c4h
        mov bp,fntheigth
@@@@@1:
        mov cx,fntwidth
@@2:
        out dx,ax
        movsb   ;Move a byte from ds:si to es:di
        dec di
        shl ah,1
        cmp ah,16
        jnz noinc_di
        inc di
        mov ah,01h ;Again to plane 0
noinc_di:
        dec cl
        jnz @@2
        add di,80-(fntwidth/4)
        add si,320-fntwidth
        dec bp
        jnz @@@@@1
        pop di
        ret
Wletter Endp

WatTitle proc
       CAll WriteTitLogo
       mov cx,200
       call ddelay 
       mov cs:Frame_counter,200
       Alloc 1024,cs:TitleSeg
       mov es,cs:TitleSeg
       xor di,di
       mov ds,cs:LogSegment
       mov si,800
       mov bl,128
@copy:
       mov cx,32
       rep movsd
       add si,192
       dec bl
       jnz @copy
       push es
       pop ds
       xor si,si
       mov ax,0a000h
       mov es,ax
       mov di,0 ;The screen Offset Where the effect will Exist
       call WaitVertRetrace
pep:
       Call Water
       in al,60h
       dec al
       jz exit
       cmp cs:Frame_counter,63
       ja nofade
       Call FadeFrame
nofade:
       dec cs:Frame_counter
       jnz pep
       ret
WatTitle Endp

Water PROC
          
          add cs:WaveXtmp1,XSPEED+MRIGHT
          add cs:WaveYtmp1,YSPEED+MUP
          sub cs:WaveXtmp2,XSPEED+MLEFT
          sub cs:WaveYtmp2,YSPEED+MDOWN
          
          mov al,cs:WaveYtmp1
          mov cs:WaveYind1,al
          mov al,cs:WaveYtmp2
          mov cs:WaveYind2,al
          mov cx,YWIDTH
          xor di,di
bucley:   
          xor bh,bh
          mov bl,cs:WaveYind1
          mov al,cs:Sin64[bx]
          mov bl,cs:WaveYind2
          add al,cs:Sin64[bx]
          
          ;add al,cl   ;This is an optional line.. comment it or not thats the key
          
          xor ah,ah
          mov si,ax
          shl si,7 ;si*128
          
          add cs:WaveYind1,YINC1
          add cs:WaveYind2,YINC2
          
          mov al,cs:WaveXtmp1
          mov cs:WaveXind1,al
          mov al,cs:WaveXtmp2
          mov cs:WaveXind2,al
          
          mov dx,XWIDTH
buclex:   
          push di
          push si
          add di,dx
          ;add di,XPOS
          
          mov bl,cs:WaveXind1
          mov al,cs:sin64[bx]
          mov bl,cs:WaveXind2
          add al,cs:sin64[bx]
          
          add cs:waveXind1,XINC1
          add cs:waveXind2,XINC2
          
          add al,ah
          xor ah,ah
          add si,ax
          movsb
          ;mov es:[di],ds:[si]
          pop si
          pop di
          dec dx
          jnz buclex
          
          mov dx,3c4h   ;Here We Switch Planes, so the odd lines are 0_2
          test cl,1     ; and the even are 1_3
          jz plane0_2
          mov ax,0a02h
          out dx,ax
          jmp cocoliso
plane0_2:          
          mov ax,0502h
          out dx,ax
cocoliso:          
          add di,80
          dec cx
          jz byebye_Bitch
          jmp bucley
byebye_Bitch:
          ret
Water ENDP          


WriteTitLogo PROC
        Call WaitVertRetrace
        Call Clear 
        mov ds,cs:LogSegment
        mov si,800+150 ;LogoOffset ;Logo Offset into PicSegment
        mov ax,0a000h+5*LogoYPos
        mov es,ax
        xor di,di
        xor bl,bl        
        mov dx,3c4h
@logoWrit:        
        mov bh,LogoWidth/2   
@line0:
        mov ax,0102h  ;Plane 0
        out dx,ax
        movsb
        dec di
        mov ax,0402h ; Plane 2
        out dx,ax
        movsb
        dec bh
        jnz @line0
        add si,320-LogoWidth
        add di,80-logowidth/2
        mov bh,LogoWidth/2
@line1:
        mov ax,0202h ; Plane 1
        out dx,ax
        movsb
        dec di
        mov ax,0802h ; Plane 3
        out dx,ax
        movsb
        dec bh
        jnz @line1
        add si,320-LogoWidth
        add di,80-logowidth/2
        inc bl
        cmp bl,logoheigth/2
        jb @logowrit
        ret
WriteTitLogo Endp

plasmaline PROC
       push si
       base1=offset MainSin
       base2=offset SinPoint1
       base3=offset SinPoint1
       base3=base3+4096     ;+4096
       screen=0
       shl si,1
       mov bp,ds:ind1
       mov dx,ds:ind2
       REPT 40
       mov bx,bp
       
       mov bx,WORD PTR ds:[bx+si+base2]
       mov al,BYTE PTR ds:[bx+si+base1] ;si
       mov bx,dx
       
       mov bx,WORD PTR ds:[bx+si+base3]  ;bx+  ;si
       add al,BYTE PTR ds:[bx+si+base1] ;si
       add al,64
       
       base2=base2+Xinc1p ;Always increment this in 2 power 
       base1=base1+2
       base3=base3-Xinc2p ;Same here
        
       mov bx,bp
        
       mov bx,WORD PTR ds:[bx+si+base2]
       mov ah,BYTE PTR ds:[bx+si+base1] ;si
       mov bx,dx
        
       mov bx,WORD PTR ds:[bx+si+base3]  ;bx+  ;si
       add ah,BYTE PTR ds:[bx+si+base1] ;si
       add ah,64
        
        
       mov es:[screen],ax
       screen=screen+2
       base2=base2+Xinc1p ;Always increment this in 2 power 
       base1=base1+2
       base3=base3-Xinc2p ;Same here
       ENDM
       pop si
       ret
plasmaline ENDP

plasmaline2 PROC
        push si
        base1=offset MainSin
        base2=offset SinPoint1
        base3=offset SinPoint1
        base3=base3+4096     ;+4096
        screen=0
        shl si,1
        mov bp,ds:ind12
        mov dx,ds:ind22
        REPT 40
        mov bx,bp
        
        mov bx,WORD PTR ds:[bx+si+base2]
        mov al,BYTE PTR ds:[bx+si+base1] ;si
        mov bx,dx
        
        mov bx,WORD PTR ds:[bx+si+base3]  ;bx+ ;si
        add al,BYTE PTR ds:[bx+si+base1] ;si
        
        base2=base2+Xinc12 ;Always increment this in 2 power 
        base1=base1+2
        base3=base3-Xinc22 ;Same here
        
        mov bx,bp
        
        mov bx,WORD PTR ds:[bx+si+base2]
        mov ah,BYTE PTR ds:[bx+si+base1] ;si
        mov bx,dx
        
        mov bx,WORD PTR ds:[bx+si+base3]  ;bx+ ;si
        add ah,BYTE PTR ds:[bx+si+base1] ;si
        
        mov es:[screen],ax
        screen=screen+2
        base2=base2+Xinc12 ;Always increment this in 2 power 
        base1=base1+2
        base3=base3-Xinc22 ;Same here
        ENDM
        pop si
        ret
plasmaline2 ENDP

IncEs MACRO
        mov dx,es
        add dx,5
        mov es,dx
        ENDM

MainPlasma PROC
        push cs
        pop ds
        mov dx,3c4h
        mov ax,0502h
        out dx,ax
doplasma:
        mov ax,0a000h+linepos*5
        mov es,ax
        

        xor si,si
        add ds:ind1,SPEED1*2
        add ds:ind2,SPEED2*2
        and ds:ind1,modu
        and ds:ind2,modu

        add ds:ind12,SPEED12*2
        add ds:ind22,SPEED22*2
        and ds:ind12,modu
        and ds:ind22,modu
        Call WaitVertRetrace
        cmp cs:Frame_counter,63
        ja doframe
        Call FadeFrame
doframe:        
        
        call plasmaline2
        
        mov dx,3c4h 
        mov ax,0a02h  ;Select bit planes 0 and 2
        out dx,ax
        
    
        call plasmaline

        inc si
        incEs

        call plasmaline2
        
        mov dx,3c4h
        mov ax,0502h  ;Select bit planes 1 and 3
        out dx,ax
        
        call plasmaline
        inc si
        incEs
        
        cmp si,Height
        jl doframe
        dec word Ptr cs:Frame_Counter
        jz endd
        in al,60h
        dec al
        jnz cont_happy
        pop ax ;Dummy :)
        jmp exit
cont_happy:
        jmp doplasma
endd:
        ret
MainPlasma Endp


;--------------------------------------------------------------------------
; FadeOut - Fades From current Palette to 0 - Needs RGB temporary Variable 
; with 3 bytes
;--------------------------------------------------------------------------

;In , Number Of registers

FadeFramef PROC
        Call FadeFrame
        retf
FadeFramef Endp

FadeFrame Proc ;Fades a Frame
          mov bx,OFFSET RGB
          mov cl,255
@@@2:          
          mov dx,3c7h
          mov al,cl
          out dx,al
          mov dx,3c9h
          in al,dx
          mov cs:[bx],al
          in al,dx
          mov cs:[bx+1],al
          in al,dx
          mov cs:[bx+2],al
          cmp byte PTR cs:[bx],0
          jz col1
          dec byte PTR cs:[bx]
col1:     
          cmp byte PTR cs:[bx+1],0
          jz col2
          dec byte PTR cs:[bx+1]
col2:
          cmp byte PTR cs:[bx+2],0
          jz col3
          dec byte PTR cs:[bx+2]
col3:
          mov dx,3c8h
          mov al,cl
          out dx,al
          inc dx
          mov al,cs:[bx]
          out dx,al
          mov al,cs:[bx+1]
          out dx,al
          mov al,cs:[bx+2]
          out dx,al
          dec cl          
          jnz @@@2
          ret
FadeFrame Endp


FadeOut PROC;From current palette To 0,0,0
          push ax
          push bx
          push cx
          push dx
          mov ch,63
@@@1:          
          call WaitVertRetrace
          Call FadeFrame
          dec ch
          jnz @@@1
          pop dx
          pop cx
          pop bx
          pop ax
          ret
FadeOut ENDP

BlankScreen Proc
        Call WaitVertReTrace
        mov dx,3c8h
        xor al,al
        out dx,al
        inc dx
        mov al,63
        out dx,al
        out dx,al
        out dx,al
        Call Clear
        mov cl,4   ;We Wait For a few frames here
blankframe:
        Call WaitVertRetrace
        dec cl
        jnz blankframe
        ret
BlankScreen Endp


Clear Proc
        mov ax,0f02h ;Four Bitplanes
        mov dx,3c4h
        out dx,ax
        mov ax,0a000h
        mov es,ax
        xor di,di
        xor ax,ax
        mov cx,4000h
        rep stosd
        ret
Clear Endp


PlasmaSequence PROC
        lea si,palette
        mov ax,cs
        Call SetPalette 
        mov word ptr cs:Frame_Counter,200
        Call MainPlasma
        mov word ptr cs:Frame_Counter,200
        lea si,palette+768
        mov ax,cs
        Call SetPalette 
        call MainPlasma
        mov cs:Frame_Counter,200
        lea si,palette+768*2
        mov ax,cs
        call SetPalette 
        Call MainPlasma
        mov cs:Frame_Counter,200
        lea si,palette+768*3
        mov ax,cs
        call SetPalette 
        call MainPlasma
        ret
PlasmaSequence Endp

init_modex PROC ;320x200x256 4 bit planes
       SEQC_ADRR equ 3c4h
       CRTC_ADRR equ 3d4h
        
       mov ax,13h ;First We initialize the 320x200x256 color mode
       int 10h
       mov dx,SEQC_ADRR
       mov ax,0604h
       out dx,ax  ;This disables CHAIN-4
       mov dx,CRTC_ADRR
       mov ax,0014h  ;Disables dword mode
       out dx,ax
       mov ax,0e317h
       out dx,ax  ;Sets the byte mode

                      ;Lets Clean the screen
       mov ax,0F02h ;This will enable the 4 bit planes (for more speed in 
       mov dx,SEQC_ADRR            
       out dx,ax    ;the cleaning operation)
       mov ax,0a000h
       mov es,ax
       xor di,di
       mov cx,4000h  ;In words, all the display memory
       xor ax,ax
       rep stosd
       mov dx,3d4h
       mov ax,9
       out dx,ax  ;320x400
       ret
init_modex endp



Code Ends

stacky segment stack
        db 100h DUP (0)
Stacky Ends

End Start






