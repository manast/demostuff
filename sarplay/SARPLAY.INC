include SarSong.inc             ;Data structures


;Definitions of variables

Song            SarSong    <>
TmpNote         SarNote    <>
Device          SarDevice  <>
Channels        SarChannel 32  dup (?)
TMpPackNote     db 4 dup (0)
ModFilename     db 'prueba.mod',0
text            db 5 dup (0)
                db 36 
StepDiv         dd 0

include modload.inc             ;Mod Loader procedures
include play.inc
include sb.inc
include gus.inc
include init.inc
