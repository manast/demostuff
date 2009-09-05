;******** WRITELN routine ********
STACK SEGMENT STACK
          db 100 DUP (?)
STACK ENDS

CODE SEGMENT
ASSUME CS:CODE
WRITELN macro _string
local _afterstring
          mov ax,SEG CODE
          mov ds,ax
          call _afterstring
          db _string,13,10,'$'
_afterstring:
          mov ah,9
          pop dx
          int 21h
          ENDM

MAIN PROC
          writeln 'Yeepa, This is real ASM!!'
          writeln 'Hehe, i am very happy of this routine'
          writeln 'wow, i will use it a lot'
          mov ax,4c00h
          int 21h
MAIN ENDP

CODE ENDS

END MAIN

