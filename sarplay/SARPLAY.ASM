;ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
;³ Mod Player V1.0 by Manuel Astudillo (a.k.a Sarwaz / Mistery)              ³     
;³ Copyright (c) 1996                                                        ³
;³ Plays 4-6-8 Chn Mods in mono 8 bit SB card series                         ³
;ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ


code segment
assume cs:code,ds:code,ss:stacky
.386

include         sarplay.inc
InputName       db 128 dup (0)
ErrorMsg1       db 'No SOund CaRd FoUnD',10,13,36

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

start:
        push cs
        pop ds
        SetProgramSize

        cmp byte ptr es:[80h],0
        jz @nocommand
        call getFileNames ;Get commands: InputName,[OutputName]
                                                                       
        call    InitPlayer
        jc      @NoSC
                                                ;Here We load the mod
        ;lea     dx,ModFilename
        lea     dx,inputname
        call    ModLoad
        jc      @errorLoading
        WriteLn 'Mod Loaded correctly'

        call    ModPlay
;mierda:        
;        call    NextTick
;        jmp     mierda

        mov     ax,3h
        int     10h
        push    cs
        pop     ds
        
        ;       Show Info
        mov     ah,1h
        mov     cx,2000h        ;Hide Cursor
        int     10h
        
        SetCursor       8,0        
        WriteLn 'SarPlay v0.5 By Sarwaz of Mistery - Copyright (c) MiSTERY 1996'
        SetCursor       27,3
        WriteLn 'Song Name:'
        SetCursor       38,3
        push    ds
        push    dx
        Call    GetSongName        
        mov     ah,9h
        int     21h
        pop     dx        
        pop     ds

        SetCursor       29,5     
        WriteLn 'Song Position....:'        
        SetCursor       29,6
        WriteLn 'Playing Pattern..:'      ;last 19
        SetCursor       29,7
        WriteLn 'Current Row......:'
        SetCursor       31,10
        WriteLn 'Channels Volumes:'
        SetCursor       13,12
        WriteLn 'Chan1  Chan2  Chan3  Chan4  Chan5  Chan6  Chan7  Chan8'

lala:

        call    WaitRetrace
        SetCursor     29+19,5
        call    GetPosition
        call    WrHex

        SetCursor     29+19,6
        Call    GetPattern
        Call    WrHex
        
        SetCursor     29+19,7
        Call    GetPatternRow
        Call    WrHex

        mov     ax,13
        push    ax
        mov     ax,20
        push    ax
        mov     ax,0
        push    ax
        mov     ax,79
        push    ax
        call    borrar

        ;Write Volume Meters
        ;call    GetChannels
        mov     ch,13+1            ;Initital Row
        xor     cl,cl
@WriteVol:
        mov     bl,20
        mov     al,cl
        Call    GetChannelVolume
        shr     ah,3
        jz      @NoPaint


@Painting:        
        SetCursor       ch,bl
        
        push    ax
        push    cx
        mov     ah,0ah
        mov     al,254
        xor     bh,bh
        mov     cx,3
        int     10h
        pop     cx
        pop     ax
        dec     bl
        dec     ah
        jnz     @Painting
@NoPaint:
        add     ch,7
        inc     cl
        Call    GetChannels
        cmp     cl,al
        jnz     @WriteVol
        
        in      al,60h
        dec     al
        jnz     lala
         
        call    ModStop
        
        mov     ax,3h
        int     10h
        WriteLn 'SarPlay By Sarwaz (A.K.A Manuel Astudillo)'
        WriteLn 'CopyRight (c) December 1996'
        WriteLn ' '
        WriteLn ' '
        WriteLn 'Contact the Author At:'
        WriteLn ' '
        WriteLn 'E-Mail (Recomemded):'
        WriteLn 'crash@mail.s-gimvic.lj.edus.si'
        WriteLn ' '
        WriteLn 'Snail-Mail:'
        WriteLn 'Manuel Astudillo'
        WriteLn 'Calle Buganvillas - Casa Calma' 
        WriteLn 'San Pedro de Alcantara - MALAGA'
        WriteLn 'SPAIN'
        WriteLn ' '

        mov     ax,4c00h
        int     21h

@errorLoading:
        WriteLn 'Mod is fucked up!'

        mov     ax,4c00h
        int     21h

@NoSC:
        lea     dx,errormsg1
        mov     ah,9h
        int     21h
        mov     ax,4c00h
        int     21h
@nocommand:
        WriteLn 'SarPlayer By Sarwaz of Mistery (c) 1996'
        WriteLn 'Usage: SarPlay Modname'
        mov     ax,4c00h
        int     21h

;In al 

WaitRetrace proc
        mov     dx,3dah
@dw:
        in      al,dx
        test    al,8h
        jz @dw

        ret
WaitRetrace endp

WrHex   proc
        mov     dl,al
        and     al,0F0h
        shr     al,4
        cmp     al,10
        jb      @Noadd7
        add     al,7
@NoAdd7:
        add     al,'0'
        mov     ah,0ah
        mov     bh,0
        mov     cx,1
        int     10h
        call    AdvanceCursor
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

BORRAR PROC NEAR
;Borra una determinada zona de la pantalla indicadas por los parametros de entrada        
;Paso de parametros por pila
;  - Parametro fila inferior
;  - Parametro fila superior
;  - Parametro columna izquierda 
;  - Parametro columna derecha 
         PUSH BP
         MOV BP,SP  ;Paso parametros por pila
         PUSH AX    
         PUSH BX
         PUSH CX
         PUSH DX
         MOV CH,[bp+10]     ;parametro fila superior
         MOV DH,[bp+8]      ;parametro fila inferior
         MOV CL,[bp+6]      ;parametro columna izq 
         MOV DL,[bp+4]      ;parametro columna der 
         MOV BH,07h         ;atributo de relleno de zona
         MOV AH,06h         ;funcion 6
         MOV AL,0h
         INT 10h
         POP DX
         POP CX
         POP BX
         POP AX
         POP BP
         RET 8              ;suma SP 8 para sacar los parametros de la pila 
BORRAR ENDP

GetFilenames PROC

        lea di,InputName
        mov si,82h
@@buc:
        mov al,es:[si]
        cmp al,13
        jz @EndInputName
        cmp al,32
        jz @GetOutputName
        mov cs:[di],al
        inc si
        inc di
        cmp si,100h
        jnz @@buc
@endInputName:
        ;mov byte ptr cs:[di],0
        ret
@GetOutputName:
        ret
        inc si
        mov cx,si
        add cx,13
        ;lea di,OutputName
@@buc2:
        mov al,es:[si]
        cmp al,13
        jz @endOutputName
        cmp al,32
        jz @endOutputName
        mov cs:[di],al
        inc si
        inc di
        cmp si,cx
        jnz @@buc2
@endOutputName:
        mov byte ptr cs:[di],0
        ret
GetFilenames endp


code ends

stacky segment stack
        db 100h dup ('SARWAZ')
stacky ends

end start
