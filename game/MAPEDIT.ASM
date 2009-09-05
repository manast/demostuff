; www.listin.com
;-----------------------------------------------------------------
; Map Edit v0.1 by Manuel Astudillo. Copyright Feb 1997
; Coded for Dos 32 by Adam Seychell
;-----------------------------------------------------------------

.386
.Model Flat
.Stack

; Equ's

MouseXWidth     equ 16
MouseYWidth     equ 16
FntXwidth       equ 8
FntYwidth       equ 8
TRUE            equ 1
FALSE           equ 0

; External Stuff



.code

VideoPtr        dd      ?

MouseX          dw      ?
MouseY          dw      ?
MouseBack       dd      ?
MousePic        dd      ?
BoxBack         dd      ?

TileTmp         dd      ?

MenuPicFilename db      'BackMap.pcx',0
MenuPic         dd      ?

KeybBuff        db      128 DUP(0);
CursorX         dw      0
CursorY         dw      60



icons           dw      0,0,64,16,0,160,64,176,0,48,64,64,0,32,64,48
                dw      0,64,64,80,0,16,64,32
OfsTable        dd      offset LoadIcon,offset QuitIcon,offset ViewIcon
                dd      offset NewMapIcon,offset ShowTilesIcon
                dd      offset SaveIcon
SubLoadIcons    dw      123,76,244,91,0,100,64,116,123,95,244,110
SubLoadIconOfs  dd      offset LoadPcxIcon,offset CancelIcon,offset LoadMapIcon
SubSaveIcons    dw      123,76,244,91,0,100,64,116
SubSaveIconOfs  dd      offset SaveMapIcon,Offset CancelIcon
SubNewMapIcons  dw      0,100,64,116,168,60,192,68,264,60,288,68
                dw      160,80,200,88,160,100,200,108,166,130,230,146
SubNewMapIconOfs dd     offset CancelIcon,offset GetTileX,offset GetTileY
                dd      offset GetMapX,offset GetMapY,offset NewMapOkIcon

NumIcons        dw      6

LDIcon          db      FALSE
SVIcon          db      FALSE
NMIcon          db      FALSE
VGIcon          db      FALSE

Quit            db      FALSE

PickTile        db      FALSE

Grid            db      FALSE

tmp             dd      ?
PcxLoaded       db      FALSE


;Strings
String1         db 'Load Pcx',0
String2         db 'Enter Filename: ',0
String3         db 'Loading',0
String4         db 'Error Loading',0
MapString1      db 'Load Map',0
MapString2      db 'Save Map',0
MapString3      db 'Saving',0
MapString4      db 'Error Saving',0

String5         db 'Map Preferences',0
String6         db 'Tile X:',0
String7         db 'Tile Y:',0
String8         db 'Map X:',0
String9         db 'Map Y:',0
String10        db 'Tile Stored',0
String11        db '  Pos-X: ',0
String12        db '   Pos-Y: ',0
String13        db 'Press Any Key',0

SarMap Struc
        GfxLength       dd      ?        
        TileLength      dw      16*16
        TilArrLen       dw      0
        MapXWidth       dw      512
        MapYWidth       dw      512
        TileXWidth      db      16
        TileYWidth      db      16
        GfxPointer      dd      ?
        PalPointer      dd      ?
        TilePointer     dd      ?
        TileArrayp      dd      ?
        TileArrayIndex  dd      0
        MapPointer      dd      ?
SarMap ends

Map     SarMap <>;


Start:
 
        mov     ax,0ee02h
        int     31h
        mov     edi,0a0000h
        sub     edi,ebx
        mov     [VideoPtr],edi

        lea     edx,MenuPicFilename     ;Load Menus and Mouse Pictures
        call    LoadPcx
        jc      @exit
        mov     [MenuPic],edi
        
        mov     ax,0ee42h                       ;Alloc Mem For Structures
        mov     edx,MouseXWidth*MouseYWidth   
        int     31h
        jc      @exit
        mov     [MouseBack],edx
        
        mov     ax,0ee42h
        mov     edx,MouseXWidth*MouseYWidth   
        int     31h
        jc      @exit
        mov     [MousePic],edx

        mov     ax,0ee42h
        mov     edx,256*256
        int     31h
        jc      @exit
        mov     [BoxBack],edx

        mov     ax,0ee42h
        mov     edx,256*256
        int     31h
        jc      @exit
        mov     [TileTmp],edx

        mov     ax,0ee42h
        mov     edx,65536*2         ;128Kb for diferents tiles
        int     31h
        jc      @exit
        mov     [Map.TileArrayp],edx
        mov     edi,edx             ;Initialize to 0
        xor     al,al   
        mov     ecx,65535*2
        rep     stosb

        mov     ax,0ee42h        
        mov     edx,1024*1024       ;1Mb for Tiles data
        int     31h
        jc      @exit
        mov     [Map.GfxPointer],edx

        mov     ax,0ee42h
        mov     edx,1024*1024*2     ;2Mb for Map Data
        int     31h
        mov     [Map.MapPointer],edx
        mov     edi,edx             ;Initialize to 0
        xor     al,al
        mov     ecx,1024*1024*2
        rep     stosb

        mov     ax,0ee42h
        mov     edx,255*10
        int     31h
        jc      @exit
        mov     [InfoBarBack],edx
        
        mov     ax,13h                  ;Set mode 13h
        int     10h
        
        mov     esi,[MenuPic]
        call    UpdateIcons
        
        call    MouseDriver
        jc      @exit
        
        call    ShowMouse

        call    SetMouseHandler
                                ;Poll Stuff

@Poll:
        cmp     [Quit],TRUE
        jz     @exit
        
        xor     ax,ax
        int     16h
        mov     al,ah
        
        cmp     [VGIcon],FALSE        
        jz      @No1
        call    ViewMapKeys
@No1:        
        
        cmp     al,1
        jnz     @Poll
        Call    CancelIcon
        jmp     @Poll
@exit:
        call    MouseDriver

        mov     ax,3h
        int     10h

        mov     ax,4c00h
        int     21h


; Mouse Handler. Handles all the proggy stuff.

RestoreBackground       db FALSE

EventHandler proc
         pusha
         cmp    RestoreBackground,FALSE
         jz     @DontREstoreBack
         cmp    VGIcon,FALSE
         jz     @DontRestoreBox
         mov    esi,[BoxBack]
         
         mov    ax,[MouseX]
         mov    bx,[MouseY]
         cmp    Grid,FALSE
         jz     @@@NoGrids
         call   gridize                 ;!!!
@@@NoGrids:
         mov    cl,Map.TileXwidth
         mov    ch,Map.TileYwidth
         call   PutBob
         jmp    @DontRestoreBack

@DontRestoreBox:
         mov     esi,[MouseBack]         ;Handle Mouse Pic Movement
         mov     ax,[MouseX]
         mov     bx,[MouseY]
         mov     cl,MouseXWidth
         mov     ch,MouseYWidth
         call    PutBob
@DontRestoreBack:
        
         mov    ax,word ptr [Micky_X]
         mov    MouseX,ax
         mov    ax,word ptr [Micky_Y]
         mov    MouseY,ax
         mov    ax,[MouseX]
         mov    bx,[MouseY]
         
         cmp    VGIcon,FALSE
         jz     @@NOVGIcon
         
         cmp    Grid,FALSE
         jz     @NoGrid
         call   ShowGrid
@NoGrid:
         
         call   ShowInfoBar
                                        ;Get Box Bob
        mov     cl,Map.TileXwidth
        mov     ch,Map.TileYwidth
        mov     edi,[BoxBack]
        mov     esi,[Tmp]               ;[VideoPtr]
        cmp     Grid,FALSE
        jz      @@NoGRids
        call    gridize         ;!!!
@@NoGrids:
        call    GetBob
        mov     RestoreBackground,TRUE
        cmp     PickTile,TRUE
        jnz     @JustPutBox
        mov     esi,[TileTmp]
        call    PutMaskedBob
        jmp     @NoMousePicture
@JustPutBox:
        call    MaskRectangle             ;Put Box
        jmp     @NoMousePicture
        
@@NoVGIcon:
         
         mov    cl,MouseXWidth
         mov    ch,MouseYWidth
         mov    edi,[MouseBack]
         mov    esi,[VideoPtr]
         call   GetBob
         mov    RestoreBackground,TRUE
         mov    esi,[MousePic]
         call   PutMaskedBob

@NoMousePicture:

         cmp    RightButton,FALSE
         jz     @NoRightButton
         cmp    VGIcon,FALSE
         jz     @NORightButton
         cmp    PickTile,FALSE
         jz     @NoRightButton
         
         call   HideBox
         call   SaveTile
         call   SavedTileNotice
         mov    PickTile,FALSE
         call   showbox

@NoRightButton:
         
         cmp    LeftButton,FALSE
         jz     @RetIcon

         cmp    LDIcon,FALSE
         jz     @NoLDIcon
         lea    edi,SubLoadIconOfs
         lea    esi,SubLoadIcons
         jmp    @SubWindowsOk
         
@NoLDIcon:
         cmp    SVIcon,FALSE
         jz     @NoSVIcon
         lea    edi,SubSaveIconOfs
         lea    esi,SubSaveIcons
         jmp    @SubWindowsOk

@NoSVIcon:         
         cmp     NMIcon,FALSE
         jz      @NoNMIcon
         lea     edi,SubNewMapIconOfs
         lea     esi,SubNewMapIcons
         jmp     @SubWindowsOk

@NoNMIcon:
         cmp    VGIcon,FALSE
         jz     @NoVGIcon
         cmp    PickTile,TRUE
         jnz    @TilePicked
         mov    PickTile,FALSE
         jmp    @RetIcon

@TilePicked:
         mov    PickTile,TRUE
         mov    esi,[BoxBack]
         mov    edi,[TileTmp]
         mov    cx,[Map.TileLength]
         rep    movsb
         jmp    @RetIcon

@NoVGIcon:
         lea    edi,OfsTable
         lea    esi,Icons

@SubWindowsOk:         
         mov    cx,NumIcons
         xor    ebx,ebx

@CheckIcons:
        mov     ax,MouseX
        cmp     ax,[esi]        ;Test X1
        jb      @NoIcon
        cmp     ax,[esi+4]        ;Test X2
        ja      @NoIcon
        mov     ax,MouseY
        cmp     ax,[esi+2]       ;Test Y1
        jb      @NoIcon
        cmp     ax,[esi+6]      ;Test Y2
        ja      @NoIcon
        call    [ebx][edi]
        jmp     @RetIcon

@NoIcon:
        add     esi,8
        add     ebx,4
        dec     cx
        jnz     @CheckIcons

@RetIcon:
         mov     al,20h
         out     20h,al
         popa        
         ret
EventHandler endp


; Load Pcx
; In: edx (Offset of Filename in ASCIZZ)
; Return: edi : Pointer to 320x200 Picture followed by 768 palette bytes.

PcxHandle       dw      ?
DummyBuff       db      ?
PcxHeader       db      128     dup (?)
PcxPointer      dd      ?


LoadPcx proc
                                ;Open File
        mov     ah,3dh
        mov     al,0            ;read Only
        int     21h
        jc      @FileError
        mov     bx,ax
        mov     [PcxHandle],ax
                                ;Read Header
        mov     ah,3fh
        lea     edx,DummyBuff
        mov     ecx,128
        int     21h

                                ;Alloc Mem For Final Picture
        mov     ax,0ee42h
        mov     edx,64000+768   ;Pic & Pal
        int     31h
        jc      @NotEnoughMem
        mov     edi,edx
        mov     [PcxPointer],edx
        mov     ebx,64000        ;64000 bytes to process

@ReadFile:
        push    ebx
        mov     ah,3fh
        mov     bx,[PcxHandle]
        lea     edx,DummyBuff
        mov     ecx,1
        int     21h
        mov     al,[DummyBuff]

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
        push    cx
        mov     ah,3fh
        mov     bx,[PcxHandle]
        lea     edx,DummyBuff
        mov     ecx,1
        int     21h
        mov     al,[DummyBuff]
        pop     cx

@RepBytes:
        pop     ebx
        and     ecx,000000ffh
        sub     ebx,ecx
        rep     stosb
        cmp     ebx,0
        jg      @ReadFile

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


ShowMouse       proc
         push    ax
         push    bx
         push    cx
         push    esi
         push    edi
        
         mov     RestoreBackground,TRUE         

         mov     edi,[MousePic]  ;Get Mouse Pointer
         mov     esi,[MenuPic]
         mov     ax,128
         mov     bx,0
         mov     cl,16
         mov     ch,16
         call    GetBob
        
         mov    ax,[MouseX]     ;Get New Back Mouse Pick
         mov    bx,[MouseY]
         mov    cl,MouseXWidth
         mov    ch,MouseYWidth
         mov    edi,[MouseBack]
         mov    esi,[VideoPtr]
         call   GetBob

         mov    esi,[MousePic]  ;Plot Mouse Pointer
         call   PutMaskedBob

         pop    edi
         pop    esi
         pop    cx
         pop    bx
         pop    ax
         ret

ShowMouse       endp

ShowBox proc
         push    ax
         push    bx
         push    cx
         push    esi
         push    edi
        
         mov     RestoreBackground,TRUE         

        
         mov    ax,[MouseX]     ;Get New Back Mouse Pick
         mov    bx,[MouseY]
         cmp    grid,FALSE
         jz     @@@@Nogrid
         call   gridize         ;!!!
@@@@NoGrid:
         mov    cl,Map.TileXwidth
         mov    ch,Map.TileYwidth
         mov    edi,[BoxBack]
         mov    esi,[VideoPtr]
         call   GetBob
         cmp    PickTile,TRUE
         jz     @@DontPaintBOx

        call   MaskRectangle
@@DontPaintBOx:
         pop    edi
         pop    esi
         pop    cx
         pop    bx
         pop    ax
         ret
ShowBox endp

HideBox proc
         push   esi
         push   ax
         push   bx
         push   cx

        mov     esi,[BoxBack]
        mov     ax,[MouseX]
        mov     bx,[MouseY]
        cmp     Grid,FALSE
        jz      @Nogridize
        call    gridize         ;!!!
@Nogridize:
        mov     cl,Map.TileXwidth
        mov     ch,Map.TileYwidth
        call    PutBob
         
         pop    cx
         pop    bx
         pop    ax
         pop    esi

        ret
HideBox endp

HideMouse       proc
         push   esi
         push   ax
         push   bx
         push   cx
         mov     esi,[MouseBack]         
         mov     ax,[MouseX]
         mov     bx,[MouseY]
         mov     cl,MouseXWidth
         mov     ch,MouseYWidth
         call    PutBob
         pop    cx
         pop    bx
         pop    ax
         pop    esi

        ret
HideMouse       endp


; In: esi: Pointer to Picture
;     ax: X Pos, bx: Y Pos, cl: X Width, ch: Y Width

PutBob proc
        push    ebp
        push    ebx
        push    cx
        push    dx
        push    edi
        push    esi
        mov     ebp,[VideoPtr]
        add     ebp,64000
        
        and     ebx,0000ffffh
        lea     ebx,[ebx*4+ebx] ;bx*5
        shl     bx,6            ;bx*64
        add     bx,ax
        mov     edi,[VideoPtr]
        add     edi,ebx
        mov     dl,ch
        xor     ch,ch
@MoveBlock:
        push    cx
        push    edi
        rep     movsb
        pop     edi
        pop     cx
        add     edi,320
        cmp     edi,ebp
        jae     @Nomore
        dec     dl        
        jnz     @MoveBlock
@NoMore:
        pop     esi       
        pop     edi
        pop     dx
        pop     cx
        pop     ebx
        pop     ebp
        ret
PutBob endp

;In : esi,edi

GetBob proc
        push    ebx
        push    cx
        push    dx
        mov     ebp,esi
        add     ebp,64000
        
        and     ebx,0000ffffh
        lea     ebx,[ebx*4+ebx] ;bx*5
        shl     bx,6            ;bx*64
        add     bx,ax
        ;mov     esi,[VideoPtr]
        add     esi,ebx
        mov     dl,ch
        xor     ch,ch
@@MoveBlock:
        push    cx
        push    esi
        rep     movsb
        pop     esi
        pop     cx
        add     esi,320
        cmp     esi,ebp
        jae     @@@Nomore
        dec     dl        
        jnz     @@MoveBlock
@@@NoMore:
        
        pop     dx
        pop     cx
        pop     ebx

        ret
GetBob endp


PutMaskedBob proc
        push    ebx
        push    cx
        push    dx
        mov     ebp,[VideoPtr]
        add     ebp,64000
        
        and     ebx,0000ffffh
        lea     ebx,[ebx*4+ebx] ;bx*5
        shl     bx,6            ;bx*64
        add     bx,ax
        mov     edi,[VideoPtr]
        add     edi,ebx
        mov     dl,ch
        xor     ch,ch
@MoveBlk:
        push    cx
        push    edi
@FakeRep:
        mov     al,[esi]
        or      al,al
        jz      @Mask
        mov     [edi],al
@Mask:
        inc     esi
        inc     di
        dec     cl
        jnz     @FakeRep
        pop     edi
        pop     cx
        add     edi,320
        cmp     edi,ebp
        jae     @@Nomore
        dec     dl        
        jnz     @MoveBlk
@@Nomore:        
        pop     dx
        pop     cx
        pop     ebx
        ret
PutMaskedBob endp



; In: Esi, Edi. ax:X,bx:y, cl:widthX,ch:WidthY

Convert2Bob proc
        
        push    ebx
        push    cx
        push    dx
        
        mov     dl,ch
        xor     ch,ch
@@@MoveBlock:
        push    cx
        push    esi
        rep     movsb
        pop     esi
        pop     cx
        add     esi,320
        dec     dl        
        jnz     @@@MoveBlock
        
        pop     dx
        pop     cx
        pop     ebx
        
        

        ret
Convert2Bob endp


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

; In: Esi: Pointer to Icon
; ax,bx : X,Y, cl,ch: Xw,Yw

PaintIcon proc
        push    esi
        push    edi
        push    cx
        and     ebx,0000ffffh
        lea     ebx,[ebx*4+ebx] ;bx*5
        shl     bx,6            ;bx*64
        add     bx,ax
        mov     edi,[VideoPtr]
        add     edi,ebx
        mov     dl,ch
        xor     ch,ch
@@CopyBl:
        push    cx
        push    esi
        push    edi
        rep     movsb

        pop     edi
        pop     esi
        pop     cx
        add     edi,320
        add     esi,320
        dec     dl             
        jnz     @@CopyBl
        pop     cx
        pop     edi
        pop     esi

        ret
PaintIcon endp



UpdateIcons proc
        mov     esi,[MenuPic]
        mov     ax,0
        mov     bx,0
        mov     cl,64
        mov     ch,16
        call    PaintIcon       ;Load Icon
        add     esi,320*16
        mov     ax,0
        mov     bx,16
        call    PaintIcon       ;Save Icon
        add     esi,320*16
        mov     ax,0
        mov     bx,32
        call    PaintIcon       ;New Map Icon
        add     esi,320*16
        mov     ax,0
        mov     bx,48
        call    PaintIcon       ;View GfX
        add     esi,320*16
        mov     ax,0
        mov     bx,100
        call    PaintIcon       ;Cancel Icon
        add     esi,320*16
        mov     ax,0
        mov     bx,160
        call    PaintIcon       ;Quit Icon
        mov     esi,[MenuPic]
        add     esi,320*64+64
        mov     ax,0
        mov     bx,64
        call    PaintIcon       ;View Tiles

        ret
UpdateIcons endp


LoadIcon        Proc
        mov     ax,120
        mov     bx,60
        mov     cl,64
        mov     ch,64
        mov     esi,[MenuPic]
        add     esi,64
        call    PaintIcon
        mov     LDIcon,TRUE
        mov     NumIcons,3
        ret
LoadIcon        endp

SaveIcon        proc
        mov     ax,120
        mov     bx,60
        mov     cl,64
        mov     ch,64
        mov     esi,[MenuPic]
        add     esi,151
        call    PaintIcon
        mov     SVIcon,TRUE
        mov     NumIcons,2
        ret
SaveIcon        endp


LoadPcxIcon     proc
        mov     ax,51
        mov     bx,75
        mov     cl,255
        mov     ch,60
        call    Rectangle
        lea     esi,String1
        mov     cursorX,150
        mov     cursorY,80
        call    WriteString
        lea     esi,String2
        mov     cursorX,70
        mov     cursorY,100
        call    WriteString
        lea     esi,KeybBuff
        mov     cl,12           ;12 chars Max
        call    ReadString
        lea     esi,string3
        mov     cursorX,154
        mov     cursory,112
        call    WriteString
        
        lea     edx,KeybBuff
        call    LoadPcx
        jc      @LoadPcxError
        mov     [tmp],edi        
        mov     PcxLoaded,TRUE
        call    CancelIcon
        ret
@LoadPcxError:
        mov     cursorX,135
        mov     cursorY,112
        lea     esi,String4
        call    WriteString
        xor     ax,ax
        int     16h
        call    CancelIcon
        ret
LoadPcxIcon     endp


LoadMapIcon     proc
        mov     ax,51
        mov     bx,75
        mov     cl,255
        mov     ch,60
        call    Rectangle
        lea     esi,MapString1
        mov     cursorX,150
        mov     cursorY,80
        call    WriteString
        lea     esi,String2
        mov     cursorX,70
        mov     cursorY,100
        call    WriteString
        lea     esi,KeybBuff
        mov     cl,12           ;12 chars Max
        call    ReadString
        lea     esi,string3
        mov     cursorX,154
        mov     cursory,112
        call    WriteString
        
        lea     edx,KeybBuff
        call    LoadMap
        jc      @LoadMapError

        call    CancelIcon
        ret
@LoadMapError:
        mov     cursorX,135
        mov     cursorY,112
        lea     esi,String4
        call    WriteString
        xor     ax,ax
        int     16h
        call    CancelIcon
        ret
LoadMapIcon     endp


SaveMapIcon     proc
        mov     ax,51
        mov     bx,75
        mov     cl,255
        mov     ch,60
        call    Rectangle
        lea     esi,MapString2
        mov     cursorX,150
        mov     cursorY,80
        call    WriteString
        lea     esi,String2
        mov     cursorX,70
        mov     cursorY,100
        call    WriteString
        lea     esi,KeybBuff
        mov     cl,12           ;12 chars Max
        call    ReadString
        lea     esi,Mapstring3
        mov     cursorX,154
        mov     cursory,112
        call    WriteString
        
        lea     edx,KeybBuff
        lea     esi,Map
        call    SaveMap
        jc      @SaveMapError
        
        call    CancelIcon
        ret
@SaveMapError:
        mov     cursorX,135
        mov     cursorY,112
        lea     esi,MapString4
        call    WriteString
        xor     ax,ax
        int     16h
        call    CancelIcon
        ret

SaveMapIcon     endp


NewMapIcon      proc
                                ;Set Tmp Values
        mov     al,Map.TileXwidth
        mov     TileXTmp,al
        mov     al,Map.TileYwidth
        mov     TileYTmp,al
        mov     ax,Map.MapXwidth
        mov     MapXTmp,ax
        mov     ax,Map.MapYwidth
        mov     MapYTmp,ax
        
        mov     ax,80
        mov     bx,40
        mov     cl,230
        mov     ch,120
        call    Rectangle
        mov     cursorX,140
        mov     cursorY,42
        lea     esi,String5
        call    WriteString
        mov     cursorX,112
        mov     cursorY,60
        lea     esi,String6
        call    WriteString
        mov     al,TileXTmp
        Call    WriteByte

        mov     cursorX,208
        mov     cursorY,60
        lea     esi,string7
        call    WriteString
        mov     al,TileYTmp
        call    WriteByte

        mov     cursorX,112
        mov     cursorY,80
        lea     esi,String8
        call    WriteString
        mov     ax,MapXTmp
        call    WriteWord
        mov     cursorX,112
        mov     cursorY,100
        lea     esi,String9
        call    WriteString
        mov     ax,MapYTmp
        Call    WriteWord
        mov     esi,[MenuPic]
        add     esi,320*16*6
        mov     ax,166
        mov     bx,130
        mov     cl,64
        mov     ch,16
        call    PaintIcon       ;Ok Icon

        mov     NMIcon,TRUE
        mov     NumIcons,6
        
        ret
NewMapIcon      endp


TileXtmp        db ?
TileYtmp        db ?
MapXtmp         dw ?
MapYtmp         dw ?


GetTileX        proc
        
        call    HideMouse                                
                                ;Set Cursor
        mov     cursorX,168                                
        mov     cursorY,60
                                ;Read a Byte
        call    ReadByte
        jc      @OldTileX

        mov     TileXtmp,al
@OldTileX:
        mov     cursorX,168                                
        mov     cursorY,60
        
        mov     al,TileXtmp
        call    WriteByte

        call    ShowMouse
                                ;Update Map Structure
        ret
GetTileX        endp


GetTileY        proc
        call    HideMouse
        
        mov     cursorX,264
        mov     cursorY,60

        call    ReadByte
        jc      @OldTileY

        mov     TileYtmp,al
@OldTileY:

        mov     al,TileYTmp
        mov     cursorX,264
        mov     cursorY,60
        call    WriteByte

        call    ShowMouse

        ret
GetTileY        endp


GetMapX         proc
        call    HideMouse
        mov     cursorX,160
        mov     cursorY,80

        call    Readword
        jc      @OldMapX

        mov     MapXTmp,ax
@oldMapX:
        mov     ax,MapXTmp
        mov     cursorX,160
        mov     cursorY,80
        call    WriteWord

        call    ShowMouse

        ret
GetMapX         endp

GetMapY         proc
        call    HideMouse
        mov     cursorX,160
        mov     cursorY,100

        call    Readword
        jc      @OldMapY

        mov     MapYTmp,ax
@OldMapY:
        mov     ax,MapYTmp
        mov     cursorX,160
        mov     cursorY,100
        call    WriteWord

        call    ShowMouse

        ret
GetMapY         endp

NewMapOkIcon    proc
        push    ax
        push    bx
        mov     al,TileXTmp
        mov     Map.TileXwidth,al
        mov     bl,TileYTmp
        mov     Map.TileYwidth,bl
        mul     bl
        mov     Map.TileLength,ax
        mov     ax,MapXTmp
        mov     Map.MapXwidth,ax
        mov     ax,MapYTmp
        mov     Map.MapYwidth,ax
        call    CancelIcon
        pop     bx
        pop     ax
        ret
NewMapOkIcon    endp


CancelIcon      Proc
        cli
        call    HideMouse

        Call    ClearScreen
        Call    UpdateIcons
        mov     LDIcon,FALSE
        mov     SVIcon,FALSE
        mov     NMIcon,FALSE
        mov     VGIcon,FALSE
        mov     PickTile,FALSE
        mov     NumIcons,6
        call    ShowMouse
        sti

        ret
CancelIcon      endp

QuitIcon        Proc
        mov     [Quit],TRUE        
        ret
QuitIcon        Endp

ViewIcon        proc
        cmp     PcxLoaded,FALSE
        jz      @PcxNotLoaded
        call    HideMouse
        mov     esi,tmp
        call    Dump2Screen
        mov     esi,tmp
        add     esi,64000
        call    SetPalette
        call    ShowBox
        mov     VGIcon,TRUE
        mov     ax,32
        mov     bx,190
        
        mov     BarPosX,ax
        mov     BarPosY,bx
        mov     cl,255
        mov     ch,10
        mov     esi,[VideoPtr]
        mov     edi,[InfoBarBack]
        call    GetBob

        ;call    ShowGrid
        
        ret
@PcxNotLoaded:
        call    CancelIcon
        ret
ViewIcon        endp

SaveTile        proc         
         mov    ebx,Map.TileArrayp      ;Get Next Free Entrie
         add    ebx,Map.TileArrayIndex
         add    Map.TileArrayIndex,4    ;add a dword
         mov    eax,[ebx]               ;Update Next Entrie with correct adress
         add    ax,[Map.TileLength]
         adc    eax,0
         mov    [ebx+4],eax             
         mov    [Map.GfxLength],eax
         inc    [Map.TilArrLen]
         
         ;mov   eax,[ebx]
         ;add   eax,[Map.TileLenght]          ;Test if there are enough Room
         ;cmp   eax,1024*1024
         ;ja    @MemError

         mov    ebx,[ebx]
         mov    edi,[Map.GfxPointer]
         add    edi,ebx
         
         mov    esi,[TileTmp]
         mov    cx,[Map.TileLength]
         rep    movsb
         ret
SaveTile        endp


TilesPerLine    dw      ?
LinesPerPage    dw      ?
YLineAdder      dw      ?
TilesCounter    dw      0
PageTilesCounter dw     0

ShowTilesIcon   proc
        pusha
        call    ClearScreen
        xor     ebp,ebp
        
                                ;Calc TilesPerLine & LinesPerPage
        xor     dx,dx
        mov     ax,320
        xor     bh,bh
        mov     bl,Map.TileXwidth
        inc     bx
        div     bx
        mov     TilesPerLine,ax

        xor     dx,dx
        mov     ax,190
        mov     bl,Map.TileYwidth
        xor     bh,bh
        inc     bx
        div     bx
        mov     LinesPerPage,ax
                                        ;Calc YLineAdder
        
        xor     bh,bh        
        mov     bl,Map.TileYwidth
        inc     bx
        mov     YLineAdder,bx
        mov     TilesCounter,0
        mov     PageTilesCounter,0
        xor     ax,ax
        xor     bx,bx
        mov     dx,[Map.TilArrLen]        
        
@ShowTiles:        
        or      dx,dx
        jz      @NoMoreTiles2Show
        
        mov     cx,TilesCounter
        cmp     cx,TilesPerLine
        jnz     @NoNewLine
        inc     PageTilesCounter
        mov     cx,PageTilesCounter
        cmp     cx,LinesPerPage
        jnz     @NoNewPage
        call    @NewPage
        jmp     @NoNewLine
@NoNewPage:
        
        xor     ax,ax                   ;X=0
        add     bx,YLineAdder
        mov     TilesCounter,0
        

@NoNewLine:        
        push    bx
        mov     ebx,[Map.TileArrayp]      ;Get Next Free Entrie
        add     ebx,ebp
        mov     ebx,[ebx]
        mov     esi,[Map.GfxPointer]
        add     esi,ebx
        mov     cl,Map.TileXwidth
        mov     ch,Map.TIleYwidth
        pop     bx
        call    PutBob
        
        add     al,Map.TileXwidth
        adc     ah,0
        inc     ax
        add     ebp,4
        inc     TilesCounter
        dec     dx
        jmp     @ShowTiles
@NoMoreTiles2Show:
        call    PutBoxCursor
@Editing:        
        
        xor     ax,ax
        int     16h
        call    edittiles
        jnc     @Editing

        call    CancelIcon
        popa

        ret
ShowTilesIcon   endp


@NewPage Proc
                                ;Show 'Press Space' message
        mov     ax,LinesPerPage
        add     CurrentActiveTile,ax
        mov     ax,100
        mov     bx,190
        mov     cl,120
        mov     ch,10
        call    Rectangle
        mov     cursorX,105
        mov     cursorY,191
        lea     esi,String13
        call    WriteString
        xor     ax,ax
        int     16h
        call    ClearScreen
        mov     PageTilesCounter,0
        mov     TilesCounter,0
        xor     ax,ax
        xor     bx,bx
        ret
@NewPage endp        
        

BoxCursorX      dw      0
BoxCursorY      dw      0

PutBoxCursor proc
        push    ax
        push    bx
        push    cx
        push    esi
        push    edi
        mov     ax,BoxcursorX
        mov     bx,BoxCursorY
        mov     cl,Map.TileXwidth
        mov     ch,Map.TileYwidth
        mov     edi,[BoxBack]
        mov     esi,[VideoPtr]
        call    getBob
        call    MaskRectangle
        pop     edi
        pop     esi
        pop     cx
        pop     bx
        pop     ax
        ret
PutBoxCursor endp


RestoreBoxCursor proc
        push    ax
        push    bx
        push    cx
        push    esi
        push    edi
        mov     ax,BoxCursorX
        mov     bx,BoxCursorY
        mov     esi,[BoxBack]
        mov     edi,[VideoPtr]
        mov     cl,Map.TileXwidth
        mov     ch,Map.TileYwidth
        call    PutBob
        pop     edi
        pop     esi
        pop     cx
        pop     bx
        pop     ax
        ret
RestoreBoxCursor endp


PutTileCursor proc
        push    ax
        push    bx
        push    cx
        push    dx
        push    esi
        push    edi
        mov     ax,CurrentMapCursorX
        mov     bx,CurrentMapCursorY
        mov     cl,Map.TileXwidth
        mov     ch,Map.TileYwidth
        mov     edi,[BoxBack]
        mov     esi,[VideoPtr]
        call    getBob
        mov     ax,CurrentActiveTile        
        mov     dx,CurrentMapCursorX
        mov     bx,CurrentMapCursorY
        call    ShowTile
        pop     edi
        pop     esi
        pop     dx
        pop     cx
        pop     bx
        pop     ax
        ret
PutTileCursor endp


RestoreTileCursor proc
        push    ax
        push    bx
        push    cx
        push    esi
        push    edi
        mov     ax,CurrentMapCursorX
        mov     bx,CurrentMapCursorY
        mov     esi,[BoxBack]
        mov     edi,[VideoPtr]
        mov     cl,Map.TileXwidth
        mov     ch,Map.TileYwidth
        call    PutBob
        pop     edi
        pop     esi
        pop     cx
        pop     bx
        pop     ax
        ret
RestoreTilecursor endp


; In: ah, scan code 
; Note: up: Move up Square, Down: Move down, etc, Space: Select/Unselect,
; del: delete. ESC: exit

CurrentActiveTile dw 0;

EditTiles proc
        cmp     ah,4dh
        jnz     @NoRightCursor
        call    RestoreBoxCursor
        xor     bh,bh
        mov     bl,Map.TileXwidth
        inc     bx
        add     BoxCursorX,bx
        inc     CurrentActiveTile
        call    PutBoxCursor
@NoRightCursor:
        cmp     ah,4bh
        jnz     @NoLeftCursor
        call    RestoreBoxCursor
        xor     bh,bh
        mov     bl,Map.TileXwidth
        inc     bx
        sub     BoxCursorX,bx
        dec     CurrentActiveTile
        call    PutBoxCursor
@NoLeftCursor:
        cmp     ah,50h
        jnz     @NoDownCursor
        call    RestoreBoxCursor
        xor     bh,bh
        mov     bl,Map.TileYwidth
        inc     bx
        add     BoxCursorY,bx
        mov     bx,TilesPerLine
        add     CurrentActiveTile,bx
        call    PutBoxCursor
@NoDownCursor:
        cmp     ah,48h
        jnz     @NoUpCursor
        call    RestoreBoxCursor
        xor     bh,bh
        mov     bl,Map.TileYwidth
        inc     bx
        sub     BoxCursorY,bx
        mov     bx,TilesPerLine
        sub     CurrentActiveTile,bx
        call    PutBoxCursor
@NoUpCursor:        
        cmp     ah,39h
        jnz     @NoSpaceCursor
        ;cmp     PickTile,FALSE
        ;jnz     @PickATile
        ;mov     PickTile,TRUE
        call    EditMap
        

;@PickATile:
@NoSpaceCursor:
        cmp     ah,1
        jnz     @@NOEscKey
        stc     
        ret
@@NoEscKey:
        clc
        ret
EditTiles endp

MapXwindow      dw 0
MapYwindow      dw 0

CurrentMapCursorX  dw 0
CurrentMapCursorY  dw 0
CurrentMapPosX     dw 0
CurrentMapPosY     dw 0
MapRangeX          dw 0
MapRangeY          dw 0

EditMap proc
        call    ShowMap                                
        call    ShowInfoBar2
                                ;Set Ranges Of tiles per Line & page
        mov     ax,Map.MapXwidth
        mov     MapRangeX,ax
        mov     ax,TilesPerLine
        inc     ax
        sub     MapRangeX,ax

        mov     ax,Map.MapYwidth
        mov     MapRangeY,ax
        mov     ax,LinesPerPage
        inc     ax
        sub     MapRangeY,ax

@EditMap:        
                                ;Show Cursor
        call    PutTileCursor
        call    ShowInfoBar2
        
        xor     ax,ax
        int     16h             ;Get Key
        cmp     ah,4dh
        jnz     @@NORight
        call    RestoreTileCursor
        mov     bl,Map.TileXwidth     
        xor     bh,bh
        add     CurrentMapCursorX,bx
        inc     CurrentMapPosX
        Cmp     CurrentMapCursorX,320
        jb      @@NoRight
        sub     CurrentMapCursorX,bx
        dec     CurrentMapPosX
        mov     bx,MapRangeX
        cmp     MapXwindow,bx
        jae     @@NoRight
        inc     MapXwindow
        call    ShowMap
        

@@NORight:
        cmp     ah,4bh
        jnz     @@NoLeft
        call    RestoreTileCursor
        mov     bl,Map.TileXwidth
        xor     bh,bh
        sub     CurrentMapCursorX,bx
        dec     CurrentMapPosX
        cmp     CurrentMapCursorX,0
        jge     @@NoLeft
        add     CurrentMapCursorX,bx
        inc     CurrentMapPosX
        cmp     MapXwindow,0
        jle     @@NoLeft
        dec     MapXwindow
        call    ShowMap
        
@@NoLeft:
        cmp     ah,50h
        jnz     @@NODown
        call    RestoreTileCursor
        mov     bl,Map.TileYwidth
        xor     bh,bh
        add     CurrentMapCursorY,bx
        inc     CurrentMapPosY
        cmp     CurrentMapCursorY,200
        jb      @@NoDown
        sub     CurrentMapCursorY,bx
        dec     CurrentMapPosY
        mov     bx,MapRangeY
        cmp     MapYwindow,bx
        jae     @@NoDown
        inc     MapYwindow
        call    ShowMap
        call    ShowInfoBar2

@@NODown:
        cmp     ah,48h
        jnz     @@NoUP
        call    RestoreTileCursor
        mov     bl,Map.TileYwidth
        xor     bh,bh
        sub     CurrentMapCursorY,bx
        dec     CurrentMapPosY
        cmp     CurrentMapCursorY,0
        jge     @@NoUp
        add     CurrentMapCursorY,bx
        inc     CurrentMapPosY
        cmp     MapYwindow,0
        jle     @@NoUp
        dec     MapYwindow
        call    ShowMap
        
@@NoUp:
        cmp     ah,39h
        jnz     @@NoSpace
        call    SetTile
        call    ShowMap
        call    ShowInfoBar2
@@NoSpace:
        cmp     al,'g'
        jnz     @@NoDel
        mov     ax,CurrentActiveTile
        mov     CurrentActiveTile,0
        call    SetTile
        call    ShowMap
        mov     CurrentActiveTile,ax
        
@@NoDel:
        cmp     ah,1            ;Test ESC Key
        jnz     @EditMap
        ret
EditMap endp


;Saves 'CurrentActiveTile' into current Map Position. Calculted with:
;       CurrentMapXCursor,CurrentMapYCursor,MapXwindow,MapYwidow

SetTile proc
        push    ax                        
        push    ebx
                                
                        ;Get Offset into Map
        xor     ebx,ebx
        mov     bx,MapYwindow
        add     bx,CurrentMapPosY
        mov     ax,Map.MapYwidth
        mul     bx
        mov     bx,ax
        add     bx,MapXwindow
        add     bx,CurrentMapPosX
        shl     bx,1
        add     ebx,Map.MapPointer
        mov     ax,CurrentActiveTile
        mov     [ebx],ax
        pop     ebx
        pop     ax
        ret
SetTile endp


;Shows map from MapXwindow and MapYWindow position

TmpPointer      dd 0
TmpPointer2     dd 0

TilesPerLine2   dw 0
LinesPerPage2   dw 0

ShowMap proc
        pusha                        
                        ;Calc Tiles Per Line                        
        mov     bx,TilesPerLine
        add     bx,2
        mov     TilesPerLine2,bx
        mov     bx,LinesPerPage
        add     bx,2
        mov     LinesPerPage2,bx
                        
                        ;Get Offset into Map
        xor     ebx,ebx
        mov     bx,MapYwindow
        mov     ax,Map.MapYwidth
        mul     bx
        mov     bx,ax
        add     bx,MapXwindow
        shl     bx,1
        add     ebx,Map.MapPointer
        mov     TmpPointer,ebx
        mov     TmpPointer2,ebx

        xor     bx,bx
        mov     bp,LinesPerPage2
@ShowMap2:
        mov     cx,TilesPerLine2
        sub     TmpPointer,2
        xor     dx,dx
@ShowMapLine:
        push    bx
        add     TmpPointer,2
        mov     ebx,TmpPointer
        mov     ax,[ebx]        
        pop     bx
        call    ShowTile
        add     dl,Map.TileXwidth
        adc     dh,0
        dec     cx
        jnz     @ShowMapLine
        xor     eax,eax
        mov     ax,Map.MapXwidth
        shl     eax,1
        add     TmpPointer2,eax
        mov     eax,TmpPointer2
        mov     TmpPointer,eax
        add     bl,Map.TileYwidth
        adc     bh,0
        dec     bp
        jnz     @ShowMap2
        popa
        ret
ShowMap endp

; In:ax, Tile to show
; dx,bx, X,Y Pos

ShowTile proc
        push    cx
        push    esi
        push    edi
        push    ebp
        and     eax,0000ffffh
        shl     eax,2
        mov     ebp,Map.TileArrayp
        mov     esi,[ebp+eax]
        add     esi,[Map.GfxPointer]
        mov     edi,[VideoPtr]
        mov     cl,Map.TileXWidth
        mov     ch,Map.TileYwidth
        mov     ax,dx
        call    PutBob
        pop     ebp
        pop     edi
        pop     esi
        pop     cx
        ret
ShowTile endp


;Dinamic Info Bar with X,Y Positions of the mouse and some other niceties

InfoBarBack     dd      ?
BarPosX         dw      32
BarPosY         dw      190

ShowInfoBar     proc
        push    ax        
        push    bx
        push    cx
        push    esi
        mov     ax,BarPosX        
        mov     bx,BarPosY
        mov     cl,255
        mov     ch,10
        mov     esi,[InfoBarBack]
        call    PutBob                  ;Restore Background
        
        xor     bx,bx
        mov     cursorY,1
        mov     BarPosY,0
        
        cmp     MouseY,100
        ja      @LowBar
        mov     bx,190
        mov     cursorY,191
        mov     BarPosY,190
@LowBar:        
        mov     ax,32
        mov     cursorX,34
        call    Rectangle

        lea     esi,String11
        call    WriteString
        mov     ax,[MouseX]
        call    WriteWord
        lea     esi,String12
        call    WriteString
        mov     ax,[MouseY]
        call    WriteWord
        
        mov     ax,BarPosX
        mov     bx,BarPosY
        mov     cl,255
        mov     ch,10
        mov     esi,[Tmp]
        mov     edi,[InfoBarBack]
        call    GetBob
        
        pop     esi
        pop     cx
        pop     bx
        pop     ax

        ret
ShowInfoBar     endp

ShowInfoBar2    proc        
        push    ax        
        push    bx
        push    cx
        push    esi
        mov     ax,BarPosX        
        mov     bx,BarPosY
        mov     cl,255
        mov     ch,10
        mov     esi,[InfoBarBack]
        call    PutBob                  ;Restore Background
        
        xor     bx,bx
        mov     cursorY,1
        mov     BarPosY,0
        
        cmp     [CurrentMapCursorY],100
        ja      @@LowBar
        mov     bx,190
        mov     cursorY,191
        mov     BarPosY,190
@@LowBar:        
        mov     ax,32
        mov     cursorX,34
        call    Rectangle

        lea     esi,String11
        call    WriteString
        mov     ax,[CurrentMapposX]
        call    WriteWord
        lea     esi,String12
        call    WriteString
        mov     ax,[CurrentMapposY]
        call    WriteWord
        
        mov     ax,BarPosX
        mov     bx,BarPosY
        mov     cl,255
        mov     ch,10
        mov     esi,[VideoPtr]
        mov     edi,[InfoBarBack]
        call    GetBob
        
        pop     esi
        pop     cx
        pop     bx
        pop     ax
        ret
ShowInfoBar2    endp


TmpBack         dd      ?

SavedTileNotice proc
                                        ;Alloc tmp memory block
        mov     ax,0ee42h
        mov     edx,100*20
        int     31h
        jc      @exit
        mov     [TmpBack],edx
                                        ;Save Background
        mov     ax,110
        mov     bx,170
        mov     cl,100
        mov     ch,20
        mov     esi,[VideoPtr]
        mov     edi,[TmpBack]    
        call    GetBob

        call    Rectangle
        lea     esi,String10
        mov     cursorX,112
        mov     cursorY,175
        call    WriteString

        push    cx
        mov     cx,50         ;Delay cx csecs
@@@@1:
        push cx
        xor cx,cx
        mov dx,2710h
        mov ah,86h
        int 15h
        pop cx
        loop @@@@1
        pop     cx
        
                                        ;Restore Background
        mov     ax,110
        mov     bx,170
        mov     esi,[TmpBack]
        mov     edi,[VideoPtr]
        call    PutBob

                                ;DeAlloc tmp memory block
        mov     ax,00ee40h
        int     31h

        ret
SavedTileNotice endp




GetTileNumber proc


        ret
GetTileNumber endp


;In:    edi,cl; ch:color

DrawLine        proc
                push    ax
                push    cx
                push    edi
                mov     al,ch
                xor     ch,ch
                rep     stosb
                pop     edi
                pop     cx
                pop     ax

                ret
DrawLine        endp

;In Edi,cl;ch:color

DrawHorz        proc
        push    cx
        push    edi

@Drawing:
        mov     byte ptr [edi],ch
        add     edi,320
        dec     cl
        jnz     @Drawing
        pop     edi
        pop     cx
        ret
DrawHorz        endp

;In: Ax,Bx,Cl,Ch

Rectangle       proc
                push    ax
                push    bx
                push    cx
                push    dx
                push    esi
                push    edi
                movzx   edi,bx
                lea     edi,[edi*4+edi]
                shl     edi,6
                and     eax,0000ffffh
                add     edi,eax
                add     edi,[VideoPtr]
                push    cx
                mov     ch,15
                call    DrawLine
                pop     cx
                add     edi,320
                mov     dl,ch
                sub     dl,2
                push    cx
                sub     cl,2
                xor     ch,ch
                xor     al,al

@Borders:
                push    edi
                push    cx
                mov     byte ptr [edi],15
                inc     edi
                rep     stosb
                mov     byte ptr [edi],15
                pop     cx
                pop     edi
                add     edi,320
                dec     dl
                jnz     @Borders
                pop     cx
                mov     ch,15
                call    DrawLine
                pop     edi
                pop     esi
                pop     dx
                pop     cx
                pop     bx
                pop     ax
                ret
Rectangle       endp

;In: Ax,Bx,Cl,Ch

MaskRectangle       proc
                push    ax
                push    bx
                push    cx
                push    esi
                push    edi
                push    ebp
                
                mov     ebp,[VideoPtr]
                add     ebp,64000
                
                movzx   edi,bx
                lea     edi,[edi*4+edi]
                shl     edi,6
                and     eax,0000ffffh
                add     edi,eax
                add     edi,[VideoPtr]
                push    cx
                mov     ch,8
                call    DrawLine
                pop     cx
                add     edi,320
                mov     dl,ch
                sub     dl,2
                push    cx
                sub     cl,2
                xor     ch,ch
                xor     al,al

@@Borders:
                push    edi
                push    cx
                mov     byte ptr [edi],8
                and     ecx,000000ffh
                inc     ecx
                add     edi,ecx
                mov     byte ptr [edi],8
                pop     cx
                pop     edi
                add     edi,320
                cmp     edi,ebp
                jae     @NoMoreStuff
                dec     dl
                jnz     @@Borders
                pop     cx
                mov     ch,8
                call    DrawLine

                pop     ebp
                pop     edi
                pop     esi
                pop     cx
                pop     bx
                pop     ax
                ret
@NoMoreStuff:                
                pop     cx
                pop     ebp
                pop     edi
                pop     esi
                pop     cx
                pop     bx
                pop     ax

                ret
MaskRectangle       endp


;Draws a Grid at GridPosX,GridPosY

GridPosX        dw      0
GridPosY        dw      0

ShowGrid        proc
        pusha                                        
                                        ;Test GridPosX and GridPosY                                        
        mov     ax,GridPosX
        xor     bh,bh
        mov     bl,Map.TileXwidth
        cmp     ax,bx
        jnz     @NoSetZero
        mov     GridPosX,0
@NoSetZero:
        mov     bx,0ffffh
        cmp     ax,bx
        jnz     @NoSetMax
        mov     bl,Map.TileXwidth
        dec     bl
        xor     bh,bh
        mov     GridPosX,bx
@NoSetMax:
        mov     ax,GridPosY
        xor     bh,bh
        mov     bl,Map.TileYwidth
        cmp     ax,bx
        jnz     @@NoSetZero
        mov     GridPosY,0
@@NoSetZero:
        mov     bx,0ffffh
        cmp     ax,bx
        jnz     @@NoSetMax
        xor     bh,bh
        mov     bl,Map.TileYwidth
        dec     bl
        mov     GridPosY,bx
@@NoSetMax:
        



                                        
                                        
                                        ;Calc Number of Horz lines
        xor     dx,dx
        mov     ax,320
        sub     ax,GridPosX
        mov     bl,Map.TileXwidth
        xor     bh,bh
        div     bx
        cmp     dx,0ffffh
        adc     al,0
        mov     dl,al           ;Save dl
                                ;Calc First Horz Line adress
        mov     edi,[VideoPtr]
        xor     eax,eax
        mov     ax,GridPosX
        add     edi,eax
        xor     ebx,ebx
        mov     bl,Map.TileXwidth       ;Get Adder
        mov     ch,2        

@DrawHorzLines:                                
        mov     cl,200
        call    DrawHorz
        add     edi,ebx
        dec     dl
        jnz     @DrawHorzLines
                                        
                                ;Calc Numer of VertLines
        xor     dx,dx
        mov     ax,200
        sub     ax,GridPosY
        mov     bl,Map.TileYwidth
        xor     bh,bh
        div     bx
        cmp     dx,0ffffh
        adc     al,0
        mov     ch,al


        mov     edi,[VideoPtr]
        xor     eax,eax
        mov     ax,GridPosY
        mov     bx,320
        mul     bx
        add     edi,eax

        xor     ebx,ebx
        mov     bl,Map.TileYwidth       ;Get Adder
        mov     ax,320
        mul     bx
        mov     bx,ax
        


@DrawVertLines:        
        push    edi
        push    cx
        mov     cl,255
        mov     ch,2
        call    DrawLine
        mov     cl,65
        add     edi,255
        call    DrawLine
        pop     cx
        pop     edi

        add     edi,ebx
        dec     ch
        jnz     @DrawVertLines
        
        popa

        ret
ShowGrid        endp




ClearScreen proc
        push    eax 
        push    ecx
        push    edi
        mov     edi,[VideoPtr]
        xor     eax,eax
        mov     ecx,16000
        rep     stosd
        pop     edi
        pop     ecx
        pop     eax

        ret
ClearScreen endp

;In: Esi (128 Bytes Buffer),cl, Number to bytes to read (Max 127)
;Out: Buffer with String
;Note: echoes the keys while pressing them from Cursor Pos.

WaitForEnter    db FALSE

ReadString proc
                        ;Get Screen Offset from CursorX and CursorY
        push    ax
        push    cx
        push    esi
                        ;Clear Buffer
        push    edi
        push    cx
        mov     edi,esi
        xor     ch,ch
        inc     cl
        mov     al,0
        rep     stosb
        pop     cx
        pop     edi
        mov     WaitForEnter,FALSE

        mov     dl,cl
        call    PutCursor
@GetKey:
        xor     ax,ax
        int     16h
        cmp     ah,1ch
        jz      @EnterPressed
        cmp     ah,0eh
        jnz     @NoBackSpace
        mov     WaitForEnter,FALSE
        cmp     cl,dl
        jae     @GetKey
        inc     cl
        dec     esi
        mov     byte ptr [esi],0
        mov     al,32
        call    PaintChar
        sub     CursorX,FntXwidth
        call    PutCursor
        jmp     @GetKey

@NoBackSpace:
        cmp     WaitForEnter,TRUE
        jz      @GetKey

        mov     [esi],al
        call    PaintChar
        add     CursorX,FntXwidth
        call    PutCursor
        inc     esi
@NextKey:
        dec     cl
        jnz     @GetKey
        mov     WaitForEnter,TRUE
        jmp     @GetKey
@EnterPressed:
        mov     al,32
        call    PaintChar

        pop     esi
        pop     cx
        pop     ax
        ret
ReadString endp

;Paints a char at CursorX,CursorY position
; In: al: Char to paint

PaintChar proc
        push    edi
        push    esi
        push    ax
        push    cx
        push    dx

        mov     di,[CursorY]
        movzx   edi,di
        lea     edi,[edi*4+edi]
        shl     di,6
        add     di,CursorX
        add     edi,[VideoPtr]
                                ;Get Char Fnt Offset
        xor     esi,esi
        xor     ah,ah
        mov     si,ax
        cmp     si,46
        jae     @NoSpace
        mov     esi,51
        jmp     @OkeyDokey
@NoSpace:
        cmp     si,97
        jb      @NOMinusc
        cmp     si,123
        jae     @DoNothingAtAll
        sub     si,32
@Nominusc:
        sub     si,46
@OkeyDokey:

        shl     esi,3
        cmp     esi,320
        jae     @SecondFnt
        add     esi,184*320
        jmp     @FirstFnt
@SecondFnt:
        sub     esi,320
        add     esi,192*320
@FirstFnt:
        add     esi,[MenuPic]
        
        mov     cx,FntXwidth
        mov     dl,FntYwidth

@PChar:        
        push    edi                
        push    esi
        push    cx
        rep     movsb
        pop     cx
        pop     esi
        pop     edi
        add     edi,320
        add     esi,320
        dec     dl
        jnz     @PChar
@DoNothingAtAll:
        pop     dx
        pop     cx
        pop     ax
        pop     esi
        pop     edi
        ret
PaintChar endp

;In: Esi (Pointer to string finished in 0)

WriteString proc
        push    ax
        push    esi

@PString:
        mov     al,[esi]
        call    PaintChar
        add     CursorX,FntXwidth
        inc     esi
        cmp     byte ptr [esi],0
        jnz     @PString
        pop     esi
        pop     ax

        ret
WriteString endp



ByteTmp     db 4    dup (0);

ReadByte proc
        push    esi
        push    bx
        push    cx
            
        mov     cl,3
        lea     esi,ByteTmp
        call    ReadString
        
                                ;Convert to byte
        add     esi,2
        xor     bl,bl
        mov     cl,4
@TryNext:
        mov     al,[esi]
        dec     esi
        dec     cl
        jz      @Zero
        or      al,al
        jz      @TryNext
        sub     al,48
        cmp     al,9
        ja      @error
        
        mov     bl,al      ;Save Value
        dec     cl
        jz      @Zero
        mov     dl,10
@CB:
        mov     al,[esi]
        sub     al,48
        cmp     al,9
        ja      @Error
        mul     dl
        or      ah,ah
        jnz     @error
        add     bl,al
        jc      @error
        mov     al,10
        mul     dl
        mov     dl,al
        dec     esi
        dec     cl
        jnz     @CB
@zero:
        mov     al,bl   ;Return Value In Al
        pop     cx
        pop     bx
        pop     esi
        clc
        ret
@error:
        pop     cx
        pop     bx
        pop     esi

        stc     ;Undefined Value
        ret
ReadByte endp

WordTmp     db 6 dup (0);

ReadWord        proc        
        push    esi
        push    bx
        push    cx
        push    bp
        mov     cl,5
        lea     esi,WordTmp
        call    ReadString
        
                                ;Convert to word
        add     esi,4
        xor     bl,bl
        xor     ah,ah
        mov     cl,6
@@TryNext:
        mov     al,[esi]
        dec     esi
        dec     cl
        jz      @@Zero
        or      al,al
        jz      @@TryNext
        sub     al,48
        cmp     al,9
        ja      @@error

        
        mov     bx,ax      ;Save Value
        dec     cl
        jz      @@Zero
        mov     bp,10
@@CB:
        xor     ah,ah
        mov     al,[esi]
        sub     al,48
        cmp     al,9
        ja      @@error
        mul     bp
        or      dx,dx
        jnz     @@error
        add     bx,ax
        jc      @@error
        mov     ax,10
        mul     bp
        mov     bp,ax
        dec     esi
        dec     cl
        jnz     @@CB
@@zero:
        mov     ax,bx   ;Return Value In Al
        pop     bp
        pop     cx
        pop     bx
        pop     esi
        
        clc
        ret
@@error:        
        pop     bp
        pop     cx
        pop     bx
        pop     esi

        stc
        ret
ReadWord        endp


;In: al (byte to print)

WriteByte       proc
        push    ax
        push    dx
        push    esi
        push    bx
        push    ebp
        xor     ah,ah
        lea     ebp,ByteTmp
        mov     esi,2
        mov     bx,10
@Word_a_Asc:
        xor     dx,dx
        or      ax,ax
        jz      @finfirrin 
        div     bx
        add     dl,48
        mov     [ebp+esi],dl
        dec     esi
        cmp     esi,-1
        jnz     @Word_a_Asc
@finfirrin:
        cmp     esi,-1
        jz      @@RealEnd
        mov     byte ptr [ebp+esi],48
        dec     esi
        jmp     @finfirrin
@@RealEnd:        
        lea     esi,ByteTmp
        call    WriteString

        pop     ebp
        pop     bx
        pop     esi
        pop     dx
        pop     ax


        ret
WriteByte       endp


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




CursorChar      db '_',0

PutCursor proc
        push    esi
        lea     esi,CursorChar
        call    WriteString
        sub     CursorX,FntXwidth
        pop     esi
        ret
PutCursor endp


; In: MouseX,MouseY
; Out: ax,bx ('Gridized'coordinates)

Gridize proc
        push    cx
        push    dx
        xor     dx,dx
        mov     ax,[MouseX]
        xor     bh,bh
        mov     bl,Map.TileXwidth
        div     bx
        mul     bx
        add     ax,GridPosX
        mov     cx,ax   ;Save ax

        xor     dx,dx
        mov     ax,[MouseY]
        xor     bh,bh
        mov     bl,Map.TileYwidth
        div     bx
        mul     bx
        add     ax,GridPosY
        mov     bx,ax
        mov     ax,cx
        pop     dx
        pop     cx
        ret
Gridize endp



; Macros -------->


ViewMapKeys proc       
        mov     esi,[Tmp]
        
        cmp     al,22h  ;G Activate/DeActivate Grid
        jnz     @NoGridKey
        cmp     Grid,FALSE
        jz      @ActivateGrid
        mov     Grid,FALSE
        call    Dump2Screen
        call    ShowInfoBar
        call    ShowBox
        jmp     @NoGridKey
@ActivateGrid:
        mov     Grid,TRUE
        call    Dump2Screen
        call    ShowGrid
        call    ShowBox
        call    ShowInfoBar

@NoGridKey:
        cmp     Grid,TRUE
        jnz     @NotestGridKeys
        cmp     al,4bh          ;Test left
        jnz     @Noleft
        dec     [GridPosX]
        call    Dump2Screen
        call    ShowGrid
        call    ShowBOx
        call    ShowInfoBar
@Noleft:
        cmp     al,4dh          ;Test right
        jnz     @NoRight
        inc     [GridPosX]
        call    Dump2Screen
        call    ShowGrid
        call    ShowBox
        call    ShowInfoBar
        
@NoRight:
        cmp     al,50h          ;Test Down
        jnz     @NoDown
        inc     [GridPosY]
        call    Dump2Screen
        call    ShowGrid
        call    ShowBox
        call    ShowInfoBar
        
@NoDown:
        cmp     al,48h          ;Test Up
        jnz     @NoUp
        dec     [GridPosY]
        call    Dump2Screen
        call    ShowGrid
        call    showbox
        call    ShowInfoBar
        
@NoUp:
@NoTestGridKeys:
        ret
ViewMapKeys     endp        

; Saves a Map
; In: esi: pointer to Map Structure

MapHandle       dw ?

SaveMap proc
        push    eax
        push    ebx
        push    ecx
        push    edx
        push    edi
        
                                ;Create File
        mov     ah,3ch
        mov     cx,00100000b
        int     21h
        mov     bx,ax
        mov     [MapHandle],ax
        
                                ;Alloc Mem for Header
        mov     ax,0ee42h
        mov     edx,30          ;30 bytes for the header
        int     31h
        mov     edi,edx         
                                ;Place Signature
        mov     [edi],' raS'
        mov     [edi+4],'paM'
        mov     byte ptr [edi+7],1ah
                                ;Fill Header with Map Structure

        mov     eax,[esi.GfxLength]
        mov     [edi+8],eax
        mov     eax,[esi.TileArrayIndex] ;!!! Hey!!!!
        
        
        mov     [edi+12],eax
        mov     ax,[esi.TilArrLen]
        mov     [edi+16],ax
        mov     ax,[esi.MapXwidth]
        mov     [edi+18],ax
        mov     ax,[esi.MapYwidth]
        mov     [edi+20],ax
        mov     byte ptr [edi+22],01             ;V0.1
        mov     byte ptr [edi+23],0              ;No Compression
        mov     [edi+24],'ASTU'         ;Cript Key
        mov     al,[esi.TileXwidth]
        mov     [edi+28],al
        mov     al,[esi.TileYwidth]
        mov     [edi+29],al
        
                                        ;Save header
        mov     bx,[MapHandle]
        mov     ah,40h
        mov     ecx,30
        int     21h
                                        ;Free Header Memory
        mov     ax,0ee41h
        int     31h
        
                                        ;Save Palette
        mov     edx,[Tmp]
        add     edx,64000
        mov     ah,40h
        mov     ecx,768
        mov     bx,[MapHandle]
        int     21h
        
                                        ; Save Tile Array
        mov     edx,[esi.TileArrayp]
        xor     ecx,ecx
        mov     cx,[esi.TilArrLen]
        shl     ecx,2
        mov     bx,[MapHandle]
        mov     ah,40h
        int     21h
        
                                        ; Save Tile Atributtes
;        mov     edx,[esi.
                                        ; Save Gfx Data
        mov     edx,[esi.GfxPointer]
        mov     ecx,[esi.GfxLength]
        mov     ah,40h
        int     21h
        
                                        ; Save Map Data
        xor     ebx,ebx
        xor     eax,eax
        mov     ax,[esi.MapXwidth]
        mov     bx,[esi.MapYwidth]
        mul     ebx
        mov     bx,[MapHandle]
        mov     ecx,eax
        mov     edx,[esi.MapPointer]
        mov     ah,40h
        int     21h

        mov     ah,3eh
        int     21h
        pop     edi
        pop     edx
        pop     ecx
        pop     ebx
        pop     eax

        ret
SaveMap endp

TmpPal  db 768 dup (0)

;in edx: Offset of filename (AsciiZ)

LoadMap proc
        push    eax
        push    ebx
        push    ecx
        push    edx
        push    edi
        push    esi
                                            
                                ;Open File
        mov     ah,3dh
        mov     al,0            ;read Only
        int     21h
        jc      @@FileError
        mov     bx,ax
        mov     [MapHandle],ax

                                ;Alloc Mem for Header
        mov     ax,0ee42h
        mov     edx,30          ;30 bytes for the header
        int     31h
        mov     edi,edx         

                                ;Read Header
        mov     ah,3fh
        mov     edx,edi
        mov     ecx,30
        int     21h

                                ;Test for signature                                                
        cmp     [edi],' raS'
        ;jnz     @NoSarMapFile
        cmp     [edi+4],'paM'
        ;jnz     @NoSarMapFile
                                ; Get Header Info

         mov    eax,[edi+8]
         mov    [Map.GfxLength],eax
         
         mov    eax,[edi+12]
         mov    [Map.TileArrayIndex],eax

         mov    ax,[edi+16]
         mov    [Map.TilArrLen],ax

         mov    ax,[edi+18]
         mov    [Map.MapXwidth],ax
         mov    ax,[edi+20]
         mov    [Map.MapYwidth],ax

         ;cmp   [edi+22],01             ;Version
         ;cmp   [edi+23],0              ;Compression?
         ;cmp   [edi+24],               ;Encriptation
         mov    al,[edi+28]
         mov    [Map.TileXwidth],al
         mov    al,[edi+29]
         mov    [Map.TileYwidth],al

                                        ; Free Header Memory
        mov     ax,0ee41h
        int     31h
                                        ; Load Palette
        lea     edx,TmpPal
        mov     ah,3fh
        mov     ecx,768
        mov     bx,[MapHandle]
        int     21h
                                        ; Set Pal
        lea     esi,TmpPal
        call    SetPalette

        
                                        ; Load Tile Array
        mov     edx,[Map.TileArrayp]
        xor     ecx,ecx
        mov     cx,[Map.TilArrLen]
        shl     ecx,2
        mov     bx,[MapHandle]
        mov     ah,3fh
        int     21h
                                        ; Save Tile Atributtes
;        mov     edx,[esi.
                                        ; Load Gfx Data
        mov     edx,[Map.GfxPointer]
        mov     ecx,[Map.GfxLength]
        mov     ah,3fh
        int     21h
        
                                        ; Load Map Data
        xor     ebx,ebx
        xor     eax,eax
        mov     ax,[Map.MapXwidth]
        mov     bx,[Map.MapYwidth]
        mul     ebx
        mov     bx,[MapHandle]
        mov     ecx,eax
        mov     edx,[Map.MapPointer]
        mov     ah,3fh
        int     21h

        mov     ah,3eh
        int     21h
        


@Loaded:
        pop     esi
        pop     edi
        pop     edx
        pop     ecx
        pop     ebx
        pop     eax

        ret
@NoSarMapFile:
@@FileError:
        stc     
        jmp     @Loaded


LoadMap endp



;
;                        Mouse routines for DOS32
;
;                        Written by Adam Seychell
;
;
;
;****************************************************************************
;    Function: int MouseDriver();
; Description: Resets the mouse driver.
;      Return: nonzero if mouse driver is installed and zero if not.
;
;****************************************************************************
;    Function: void SetMouseHandler(void * event_hanlder);
; Description: Sets the current mouse event handler and will be called when
;              the mouse is moved or a button is pressed/released.
;              When the handler is called the following external
;              varibles are set with the mouse information
;
;              dword    Micky_X              ; Horizontal micky count
;              dword    Micky_Y              ; Vertical micky count
;              byte     LeftButton           ; 1 if pressed and 0 if released
;              byte     RightButton          ; 1 if pressed and 0 if released
;
;              To free the current mouse event handler simply reset the
;              mouse driver by calling "MouseDriver"
;
;    Returns: nothing
;      Notes: When the program terminates it must reset the mouse driver
;              (by calling MosueDriver) to disable the current mouse event 
;              handler. Otherwise the mouse driver will continue calling the
;              mouse event procedure.
;****************************************************************************
;


;----------------------------------------------------------------------------
MouseDriver PROC
        Mov     Ax,0000h
        Int     33h
        Movsx   Eax,ax
        Ret
MouseDriver ENDP



;----------------------------------------------------------------------------
;
;  Format of the Real Mode Call frame used by the DPMI service for switching
; to and from Real Mode
;
Real_mode_Call_Struct STRUC
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
Real_mode_Call_Struct ENDS

Align 4

Micky_X                 DD      ?
Micky_Y                 DD      ?
Current_Event_Handler   DD      ?
LeftButton              DB      ?
RightButton             DB      ?
MiddleButton            DB      ?


Mouse_RM_CallStruct     Real_mode_Call_Struct <>



SetMouseHandler PROC  ;Event_HandlerPtr :Dword

        ;mov     eax,Event_HandlerPtr    ; Save the event handler
        ;mov     Current_Event_Handler,eax  

   ; Allocate a real mode call back using DOS32 function AX=EE20 INT 31h
   ;


        mov     Esi,Offset ISR_Handler
        mov     Ax,0EE20h
        int     31h
        jc ExitError                    ; returns CX:DX -> real mode call back

        mov     BX,CX




    ; Emulate real mode interuup ( AX=300h INT31h )
    ; We are calling real mode int 33h Ax=000C, which will
    ; define the mouse event handler.
    ;
    ; expects   AX = 000Ch
    ;           ES:DX -> handler
    ;           CX = mask bits ( see mouse driver documentation )
    ;

        Mov     ax,000Ch
        mov     cx,01111111b

        push dword ptr   0              ; set  SS:SP = 00:00
        sub     esp,10                  ; ignore  CS, IP ,FS, GS, DS
        push    BX
        db 66h,9Ch                      ; pushf  16bit
        pushad
        mov     edi,esp
        mov     ax,0300h
        xor     cx,cx
        mov     bl,33h                  ; call mouse handler
        int     31h                     ; Emulate V86 interrupt
        popad
        db 66h,9Dh                      ; popf  16bit
        lea     esp,[esp+16]            ; Ignore SS,SP,CS,IP,FS,GS,ES & DS
        dec     ax
        jz ExitError



okk:
        mov     eax,-1
        Ret

ExitError:
        xor     eax,eax
        Ret

SetMouseHandler ENDP




;-------------------------------------------------------------------------
;
;                        THE  MAIN  MOUSE  HANDLER
;
;
;-------------------------------------------------------------------------
ISR_Handler PROC FAR
        pushad
        push    es
        push    ds

        mov     ax,SEG ISR_Handler
        mov     ds,ax
        mov     es,ax

        Test    bl, 001b
        Setne   LeftButton
        Test    bl, 010b
        Setne   RightButton
        Test    bl, 100b
        Setne   MiddleButton
        Movsx   Edi,di
        Movsx   Esi,si
        cmp     esi,320-MouseXWidth
        jl      @UpdateX
        mov     esi,320-MouseXWidth
@UpdateX:
        cmp     esi,0
        jg      @@UpdateX
        mov     esi,0
@@UpdateX:
        mov     Micky_X,esi
        cmp     edi,200
        jl      @UpdateY
        mov     edi,200
@UpdateY:
        cmp     edi,0
        jg      @@UpdateY
        mov     edi,0
@@UpdateY:
        Mov     Micky_Y, edi

        Call    EventHandler ;[Current_Event_Handler]
        pop     ds
        pop     es
        popad
        retf

;                       MOUSE HANDLER ENDS
;ננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננננ
ISR_Handler ENDP

SetPalette PROC ; in si the offset to palette
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



End Start



; - Header: 

;   First 8 Bytes are the file signature: 'SAR MAP',EOF  (EOF=1Ah)

;   offset       length (Bytes)          Description
;     8            4                   Gfx Data Length
;     12           4                   Tile Data Length
;     16           2                   Tile Array Length  (Explained later)
;     18           2                   Map X Length (in tiles)
;     20           2                   Map Y Length (in tiles)
;     22           1                   File Version
;     23           1                   Compresion mode (0= no compresion)
;     24           4                   Reserved - Cript Key
;     28           1                   Tile X Length
;     29           1                   Tile Y Length

;- Palette:
;   offset     length (Bytes)
;     30         768 

;- Tile Array:

;   Begins at offset 798 and is "Tile Array length" double words.
;   Its a double word array of offsets. Every position in the array is the
;   tile number, and the offset is where in the GFX Block is that tile GFX.

;- Tile atributes:
    
;   Its a table of "Tile Array length" bytes.
;   Every byte represents the attribute of each tile.
;   Sar edit uses this table:
;        0 = Background
;        1 = Solid
;        2 = Magic  (this can be used for secrets objects etc)
;        . = Magic
;        . = Magic
;        . = Magic
;        etc

;- Gfx Data:
   
;   Its the Graphics block. If it is compressed you have to decompress it
;   before you can use it.

;- Tile Data:
   
;   Its the MAP itself. At every position of each tile you a word (0-65535)
;   representing the tile number. You can get the Tile gfx just looking at
;   the Tile array table, and use that offset to copy from the GFX data.


;SarMap Struc
;        GfxLength       dd      ?        
;        TileLength      dw      16*16
;        TilArrLen       dw      0
;        MapXWidth       dw      512
;        MapYWidth       dw      512
;        TileXWidth      db      16
;        TileYWidth      db      16
;        GfxPointer      dd      ?
;        PalPointer      dd      ?
;        TilePointer     dd      ?
;        TileArrayp      dd      ?
;        TileArrayIndex  dd      0
;        MapPointer      dd      ?
;SarMap ends

 


