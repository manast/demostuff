; SarPlayer By Manuel Astudillo (c) 1996
; SarPlayer Main Program

public modload,modplay,modstop,getpattern
public getpatternrow,getposition
public getchannels,getchannelvolume,getchannelperiod
public getsongname,initplayer

code segment
        assume cs:code,ds:code;,ss:stacky
.386
include sb.inc
include init.inc
;include misc.inc
include modload.inc
include sarsong.inc
include play.inc

Song            SarSong    <>
TmpNote         SarNote    <>
Device          SarDevice  <>
Channels        SarChannel 32  dup (?)
TMpPackNote     db 4 dup (0)
StepDiv         dd 0


start:
 ;       push    cs
 ;       pop     ds
 ;       SetProgramSize
 EndOfProggy:

code ends

;Stacky  Segment stack
;        db      100h    DUP ('SARWAZ')
;Stacky  ends

end start



