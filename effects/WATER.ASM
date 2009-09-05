;***************************************************************************
; Water Effect by Sarwaz / Mistery
; Date: 24-9-96
; Note: Real mode version
;***************************************************************************

radious segment
include radtabl.inc ;Radious table for each point
radious ends

code segment
assume cs:code,ds:code,ss:stack

align 4
sinus label dword
include sintbl.inc ;Sinustable in 16.16 

Seg_Pic dw 0
File_Pic1 db 'd:\data\barbie.raw',0

merror0 db 'Error Loading File!',36

WaitRetrace MACRO
        mov dx,3dah
@dw:
        in al,dx
        test al,8
        jz @dw
        ENDM

include misc.inc ;Miscelaneous functions


start:
            SetProgramSize                   
            
            push cs
            pop ds
            lea dx,File_Pic1
            mov cx,64800
            call LoadFile      
            jc @errorLoadingFile
            mov Seg_Pic,dx

            mov ax,13h              ; Set VGA 320*200 256c
            Int 10h

            mov ds,[Seg_Pic]      ; Set palette
            mov si,32              ; Header Offset 
            mov dx,3c8h
            xor al,al
            out dx,al
            mov ecx,256*3
            inc dl
            cli
@@again:                         ; rep outsb do not work with all cards
          ÿlodsb
           shr al,2 ;Hi Color
           out dx,al
           loop @@again
           sti

           xor ebp,ebp ;ebp will be our sinux index        
@WaterAll:        
        
        mov esi,[Addr_Pic]
        add esi,800
        mov edi,[_0a0000h]        
        xor ebx,ebx
        WaitRetrace
        
@@waterFrame:
        xor eax,eax
        mov al,radious[ebx]
        add eax,ebp
        shl eax,1
        and eax,255
        shl eax,2
        mov eax,sinus[eax]
        sar eax,12 ;mhhh ? changing this you get bigger waves
        add eax,ebx
        mov al,[esi+eax]
        mov [edi],al
        inc edi
        inc ebx
        cmp ebx,65536
        jnz @@waterframe
        
        add ebp,5
        and ebp,255
        in al,60h
        dec al
        jnz @waterall

        mov ax,4c00h
        int 21h

@ErrorLoadingFile:
        lea edx,Merror0
        mov ah,9h
        int 21h

        xor ah,ah ;Wait for keypressed
        dosint 16h
        
        mov ax,4c00h
        int 21h
        
code ends

stack segment stack
        db 100h dup (?)
stack ends

end start
