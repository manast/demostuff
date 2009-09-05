; Joystick UNIT. V1.0   
; Coded by Manuel Astudillo (A.k.a. Sarwaz)
; (c) 1997


; Equ's for Easy Testing

_JoyA_UP            equ     1000b
_JoyA_DOWN          equ     0100b
_JoyA_LEFT          equ     0010b
_JoyA_RIGHT         equ     0001b

_JoyB_UP            equ     10000000b
_JoyB_DOWN          equ     01000000b
_JoyB_LEFT          equ     00100000b
_JoyB_RIGH          equ     00010000b


EXTRN CheckJoystick     : NEAR
EXTRN CheckButton       : NEAR
EXTRN CheckStick        : NEAR


