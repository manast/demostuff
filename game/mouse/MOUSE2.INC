;                       -=ð MOUSE.ASM ð=-

ifdef masm                                      ; Allow MASM assembly
Global  EQU     externdef
endif

extrn  MouseDriver     :Near
extrn  SetMouseHandler :Near
extrn  Micky_X         :Dword
extrn  Micky_Y         :Dword
extrn  RightButton     :Byte
extrn  LeftButton      :Byte
extrn  MiddleButton    :Byte
