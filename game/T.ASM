; Joystick test program


.386p
.model flat


.stack  100h


.code

include joystick.inc

msg1    db      'Joystick A Detected',13,10,36
msg3    db      'Joystick not detected',13,10,36
msg2    db      'Joystick B detected',13,10,36
msg4    db      'Button A - Joystick A Pressed',13,10,36
msg5    db      'Button B - Joystick B Pressed',13,10,36
msg6    db      'Right Pressed',13,10,36
msg7    db      'Left',13,10,36
msg8    db      'Up',13,10,36
msg9    db      'down',13,10,36


start:
        call    CheckJoystick
        test    cl,01b
        jz      @NoJoyA
        lea     edx,msg1
        mov     ah,9h
        int     21h
@NoJoyA:
        test    cl,10b
        jz      @NoJoyB
        lea     edx,msg2
        mov     ah,9h
        int     21h
@NoJoyB:        
        test    cl,11b
        jnz     @ButtonLoop
        lea     edx,msg3
        mov     ah,9h
        int     21h
        jmp     @dos

@ButtonLoop:
        mov     al,1
        mov     ah,1
        call    CheckButton
        jnz     @@NoPressedA
        lea     edx,msg4
        mov     ah,9h
        int     21h
@@NoPressedA:
        mov     al,1
        mov     ah,2
        call    CheckButton
        jnz     @@NoPressedB
        lea     edx,msg5
        mov     ah,9h
        int     21h
@@NoPressedB:
        call    CheckStick
        test    cl,_JOYA_RIGHT
        jz      @NoRight
        lea     edx,msg6
        mov     ah,9h
        int     21h
@NORight:
        test    cl,_JOYA_LEFT
        jz      @NOLeft
        lea     edx,msg7
        mov     ah,9h
        int     21h

@NoLeft:
        test    cl,_JOYA_UP
        jz      @NoUP
        lea     edx,msg8
        mov     ah,9h
        int     21h

@NoUP:  
        test    cl,_JOYA_DOWN
        jz      @NoDown
        lea     edx,msg9
        mov     ah,9h
        int     21h

@NoDown:
        in      al,60h
        dec     al
        jnz     @ButtonLoop

@dos:
        mov     ax,4c00h
        int     21h

end start
