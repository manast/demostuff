; Joystick UNIT. V1.0   
; Coded by Manuel Astudillo (A.k.a. Sarwaz)
; (c) 1997


.386p
.model flat


; Equ's for Easy Testing

_JoyA_UP            equ     1000b
_JoyA_DOWN          equ     0100b
_JoyA_LEFT          equ     0010b
_JoyA_RIGHT         equ     0001b

_JoyB_UP            equ     10000000b
_JoyB_DOWN          equ     01000000b
_JoyB_LEFT          equ     00100000b
_JoyB_RIGH          equ     00010000b



Public CheckJoystick    ; Check A joystick and inits Stuff
Public CheckButton      ; Check for buttons pressing
Public CheckStick       ; Check for Stick moving



.code

; Global Var used

JoyA_CenterX    dw      ?
JoyA_CenterY    dw      ?

JoyB_CenterX    dw      ?
JoyB_CenterY    dw      ?


JoyA_Up         dw      ?
JoyA_Down       dw      ?
JoyA_Left       dw      ?
JoyA_Right      dw      ?

JoyB_Up         dw      ?
JoyB_Down       dw      ?
JoyB_Left       dw      ?
JoyB_Right      dw      ?

JOYA_DETECTED   db      0
JOYB_DETECTED   db      0


; CheckJoystick -
; It checks for joystick and calculate the center value, and umbrals
; Note: the init can fail if the user is playing with joystick while init
; Returns CL 
; Bit 0 - Joystick A
; Bit 1 - Joystick B

CheckJoystick   proc
        push    ax
        push    bx
        push    dx
        cli
        mov     dx,201h
        out     dx,al                   ; Send Dummy Value
        xor     bx,bx
@TestLoop1:
        in      al,dx
        test    al,1                    ; Check Joystick 1
        jz      @JoystickOk1
        inc     bx
        cmp     bx,0ffffh
        jnz     @TestLoop1
        xor     cl,cl
        jmp     @Joy1Not

@JoystickOk1:
                                        ; Get Center Value of Joy A
        mov     al,1    
        call    GetCenter
        mov     [JoyA_CenterX],si
        mov     [JoyA_CenterY],di
        mov     cl,1
        mov     [JOYA_DETECTED],1
@Joy1Not:
        mov     dx,201h
        out     dx,al                   ; Send Dummy Value
        xor     bx,bx
@TestLoop2:
        in      al,dx
        test    al,0100b
        jz      @JoystickOk2
        inc     bx
        cmp     bx,0ffffh
        jnz     @TestLoop2
        and     cl,01b
        call    GetUmbrals
        sti
        pop     dx
        pop     bx
        pop     ax
        ret
@JoystickOk2:
        mov     [JOYB_DETECTED],1
        mov     al,2
        call    GetCenter
        mov     [JoyB_CenterX],si
        mov     [JoyB_CenterY],di
        or      cl,10b
        call    GetUmbrals
        sti
        pop     dx
        pop     bx
        pop     ax
        ret
CheckJoystick   endp

; In: AL,AH
; AL - 1 = Joy A ; 2 = Joy B
; AH - 1 = Button A ; 2 = Button B

; Note: If the joystick A has 4 buttons then AH can test for buttons C and D 
;       with 3,4 respectively

; Returns:  Carry if pressed    


CheckButton     proc
        push    ax
        push    cx
        push    dx
        mov     dx,201h
        mov     cx,ax
        xchg    cl,ch
        in      al,dx           ; Get Joystick Status

        dec     cl
        cmp     ch,2
        jz      @JoyB
        mov     ch,00010000b
        shl     ch,cl
        test    al,ch
        jz      @NoPressed
        pop     dx
        pop     cx
        pop     ax
        stc
        ret
@NoPressed:
        pop     dx
        pop     cx
        pop     ax
        clc
        ret
@JoyB:
        mov     ch,01000000b
        shl     ch,cl
        test    al,ch
        jz      @NoPressed
        pop     dx
        pop     cx
        pop     ax
        stc
        ret
CheckButton     endp


; CheckStick 
; In: -
; Returns: cl
;       U D L R|U D L R
;  bit |7|6|5|4|3|2|1|0|
;        JOY B | JOY A


CheckStick      proc
        push    ax
        push    bx
        xor     cl,cl
        cmp     [JOYA_DETECTED],1
        jnz     @SkipA
                                ; Check Left|Right - Joy A
        mov     al,1
        mov     ah,1            ; X coord
        call    GetPosition
        call    GetPosition     ; Why? i dont know but its need :?
 
                                ; Check Left
        cmp     bx,[JoyA_Left]
        ja      @NoLeftA
        or      cl,00000010b
        jmp     @NoRightA
@NoLeftA:                       ; Check Right
        cmp     bx,[JoyA_Right]
        jb      @NoRightA
        or      cl,00000001b
@NoRightA:
                                ; Check Up|down - Joy A
        mov     al,1
        mov     ah,2            ; Y coord
        call    GetPosition

        cmp     bx,[JoyA_Up]
        ja      @NoUpA
        or      cl,00001000b
        jmp     @NoDownA
@NoUpA:
        cmp     bx,[JoyA_Down]
        jb      @NoDownA
        or      cl,00000100b
@NoDownA:
@SkipA:
                                ; Test the same for Joy B
        cmp     [JOYB_DETECTED],1
        jnz     @SkipB
        
        mov     al,2
        mov     ah,1            ; X coord
        call    GetPosition
                                ; Check Left
        cmp     bx,[JoyB_Left]
        ja      @NoLeftB
        or      cl,00100000b
        jmp     @NoRightB
@NoLeftB:                       ; Check Right
        cmp     bx,[JoyB_Right]
        jb      @NoRightB
        or      cl,00010000b
@NoRightB:
                                ; Check Up|down - Joy B
        mov     al,2
        mov     ah,2            ; Y coord
        call    GetPosition

        cmp     bx,[JoyB_Up]
        ja      @NoUpB
        or      cl,10000000b
        jmp     @NoDownB
@NoUpB:
        cmp     bx,[JoyB_Down]
        jb      @NoDownB
        or      cl,01000000b
@NoDownB:
@SkipB:
        pop     bx
        pop     ax
        ret
CheckStick      endp


; In: AL = 1 joy A, 2 = joy B
; Returns: si,di with X,Y center coords

ErrorStr1        db      13,10,'Bad News: a weird error ocurred with joystick Hardware',13,10,36

GetCenter       proc
        push    ax
        push    bx
        push    cx
        push    dx
        cli
        mov     dx,201h
        dec     al
        mov     cl,al
        shl     cl,1
        mov     ch,1
        shl     ch,cl
        xor     bx,bx
        out     dx,al           ; Send Dummy
        
@CenterX:
        in      al,dx
        test    al,ch
        jz     @CenterOkX
        inc     bx
        cmp     bx,0ffffh
        jnz     @CenterX        
@HardwareError:        
        lea     edx,ErrorStr1
        mov     ah,9h
        int     21h
        mov     ax,4c00h
        int     21h
@CenterOkX:        
        mov     si,bx
        xor     bx,bx
        shl     ch,1
        out     dx,al                   ; Send Dummy
        
      
@CenterY:
        in      al,dx
        test    al,ch
        jz      @CenterOky
        inc     bx
        cmp     bx,0ffffh
        jnz     @CenterY
        jmp     @HardWareError
@CenterOkY:
        mov     di,bx        
        sti
        pop     dx
        pop     cx
        pop     bx
        pop     ax
        ret
GetCenter       endp


; GetUmbrals
; Calculates the Umbral values in which the joystick is UP,DOWN,LEFT OR RIGHT

GetUmbrals      proc
        
        mov     ax,[JoyA_CenterX]
        shl     ax,1
        and     eax,0000ffffh
        mov     ebx,3
        or      eax,eax
        jz      @nodiv1
        xor     edx,edx
        div     ebx
@nodiv1:
        mov     [JoyA_Left],ax
        shl     ax,1
        mov     [JoyA_Right],ax

        mov     ax,[JoyA_CenterY]
        shl     ax,1
        and     eax,0000ffffh
        or      eax,eax
        jz      @nodiv2
        xor     edx,edx
        mov     ebx,3
        div     ebx
@nodiv2:
        mov     [JoyA_Up],ax
        shl     ax,1
        mov     [JoyA_Down],ax

        mov     ax,[JoyB_CenterX]
        shl     ax,1
        and     eax,0000ffffh
        mov     ebx,3
        or      eax,eax
        jz      @nodiv3
        xor     edx,edx
        div     ebx
@nodiv3:
        mov     [JoyB_Left],ax
        shl     ax,1
        mov     [JoyB_Right],ax

        mov     ax,[JoyB_CenterY]
        shl     ax,1
        and     eax,0000ffffh
        or      eax,eax
        jz      @nodiv4
        xor     edx,edx
        div     ebx
@nodiv4:
        mov     [JoyB_Up],ax
        shl     ax,1
        mov     [JoyB_Down],ax
        ret
GetUmbrals      endp


; In AL,AH
; AL = joystick A or B
; AH = X pos or Y pos
; Returns bx with position

GetPosition     proc
        push    ax
        push    cx
        push    dx
        cli
        cmp     al,2        
        jz      @Bjoyshift
        mov     al,0
@BJoyShift:
        dec     ah
        mov     cl,al
        add     cl,ah
        mov     ch,1
        shl     ch,cl   ; ch has the mask of the correct bit to test
        xor     bx,bx
        mov     dx,201h
        out     dx,al   ; send dummy
@GetPos:
        in      al,dx
        test    al,ch
        jz      @PosOk
        inc     bx
        cmp     bx,0ffffh
        jnz     @GetPos
        
@PosOk:
        sti
        pop     dx        
        pop     cx
        pop     ax
        ret
GetPosition     endp

end
