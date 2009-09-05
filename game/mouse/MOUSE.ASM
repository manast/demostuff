; ---------------------------------------------------------------------
; Mouse unit. Improved Adam Seychell's Mouse unit by Sarwaz / Mistery
; ---------------------------------------------------------------------


.386p
.model flat

PUBLIC  MouseDriver
PUBLIC  SetMouseHor
PUBLIC  SetMouseVer
PUBLIC  SetMouseHandler
PUBLIC  Mouse_X  
PUBLIC  Mouse_Y 
PUBLIC  Mouse_LeftButton
PUBLIC  Mouse_RightButton
PUBLIC  Mouse_MiddleButton





.code


;----------------------------------------------------------------------------
; Resets the mouse driver
; Carry Set if mouse not present
;----------------------------------------------------------------------------

MouseDriver PROC
        Mov     Ax,0000h
        Int     33h
        or      ax,ax
        jz      @DrvNotInstalled
        clc
        Ret
@DrvNotInstalled:
        stc
        ret
MouseDriver ENDP

; In: cx,dx: min max mouse positions

SetMouseHor     proc
        push    ax
        mov     ax,7h
        int     33h
        pop     ax
        ret
SetMouseHor     endp

SetMouseVer     proc
        push    ax
        mov     ax,8h
        int     33h
        pop     ax
        ret
SetMouseVer     endp


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

Mouse_X                 dw      ?
Mouse_Y                 dw      ?
Current_Event_Handler   DD      ?
Mouse_LeftButton        DB      ?
Mouse_RightButton       DB      ?
Mouse_MiddleButton      DB      ?


Mouse_RM_CallStruct     Real_mode_Call_Struct <>



; Set Mouse Handler
; In Esi with pointer to the mouse event handler

SetMouseHandler PROC  ;Event_HandlerPtr :Dword

        ;mov     eax,Event_HandlerPtr    ; Save the event handler
        mov     [Current_Event_Handler],esi

   ; Allocate a real mode call back using DOS32 function AX=EE20 INT 31h
   ;


        mov     Esi,Offset ISR_Handler
        mov     Ax,0EE20h
        int     31h
        jc ExitError                    ; returns CX:DX -> real mode call back

        mov     BX,CX


    ; Emulate real mode interrupt ( AX=300h INT31h )
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
                                        ; Get Current Mouse Coords
        mov     ax,3h
        int     33h
        mov     [Mouse_X],cx
        mov     [Mouse_Y],dx

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
        Setne   Mouse_LeftButton
        Test    bl, 010b
        Setne   Mouse_RightButton
        Test    bl, 100b
        Setne   Mouse_MiddleButton
        movsx   edi,dx
        movsx   esi,cx
        mov     Mouse_X,cx
        Mov     Mouse_Y,dx 

        Call    [Current_Event_Handler]
        pop     ds
        pop     es
        popad
        retf
ISR_Handler ENDP

end
