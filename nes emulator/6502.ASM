; ---------------------------------------------------------------------------
; 6502 Emulator
; by Sarwaz / Mistery (c) 1997
; ---------------------------------------------------------------------------

PUBLIC  6502_execute
PUBLIC  Create_6502_CPU
PUBLIC  6502_HardReset
PUBLIC  6502_SoftReset

.stack  100h

.code

; equ's
        reset_vector    equ     0FFFCh


; We will use the following equivalents for easy code

        dl      equ     rA
        dh      equ     rS
        cl      equ     rX
        ch      equ     rY
        si      equ     rPC

; FLAGS :

; 7 6 5 4 3 2 1 0
; S V 1 B D I Z C

6502_CPU_struc  struc
        PC      dw      ?
        A       db      ?
        X       db      ?
        Y       db      ?
        FLAG    db      ?
        ST      db      ?       ; Stack
        RAM     dd      ?
        ROM     dd      ?
        WritePtr         dd      dup     (65535)        ; Pointers to subs
        ReadPtr          dd      dup     (65535)        ; Pointers to subs
6502_CPU_struc  ends

6502_Flags_struc        struc
        carry           db      ?
        sign            db      ?
        interrupt       db      ?
        zero            db      ?
        overflow        db      ?
6502_Flags_struc        ends

6502_Flags      6502_Flags_struc        <>


; Decodes next instruction and jumps to that opcode.

decode  macro   cycles
        sub     ebp,cycles      ; 1
        jle     @6502_end       ; 1
        mov     al,[edi+esi]    ; 1             ; edi = Base adress of RAM
                                                ; si  = 6502 PC
        inc     esi             ; 1
        jmp     [6502_OffsetTable+eax*4]        ; 5
        endm

writeMem macro  ; In: al with data to write
        call    [MemoryWriteTab+ebx*4]
        endm

readMem macro   ; Out: al with data read
        call    [MemoryReadTab+ebx*4]
        endm

process_jump   macro                    ; This Might be optimized
        local   @Not_Jump
        jnz     @Not_Jump
        xor     bh,bh
        mov     bl,[edi+esi]
        inc     si
        test    bl,10000000b
        jnz     @Add_PC
        and     bl,01111111b
        sub     si,bx
        decode  2
@Add_PC:
        add     si,bx
        decode  2
@Not_Jump:
        inc     si
        decode  2
        endm

push_stack      macro
        mov     bl,rS
        xor     bh,bh
        add     bx,100h
        WriteMem
        dec     rS        
        endm

pop_stack       macro
        mov     bl,rS
        xor     bh,bh
        add     bx,100h
        ReadMem
        inc     rS
        endm


; In: ebx with 6502_cpu

6502_HardReset      proc
        mov     [ebx.rA],0
        mov     [ebx.rX],0
        mov     [ebx.rY],0
        push    ebx
        mov     ebx,reset_vector
        ReadMem
        mov     si,ax
        inc     ebx
        ReadMem
        shl     ax,8
        or      si,ax
        pop     ebx
        mov     [ebx.rPC],si
        mov     [ebx.rST],0FFh
        mov     [ebx.rF],022h   
        ret
6502_HardReset      endp

6502_SoftReset  proc
        push    ebx
        mov     ebx,reset_vector
        ReadMem
        mov     si,ax
        inc     ebx
        ReadMem
        shl     ax,8
        or      si,ax
        pop     ebx
        mov     [ebx.rPC],si
        ret
6502_SoftReset  endp


; In: eax, number of cycles to execute
;     ebx, pointer to a 6502_CPU

6502_execute    proc
        mov     rA,[ebx.A]
        mov     rX,[ebx.X]
        mov     rY,[ebx.Y]
        movzx   esi,[ebx.PC]
        mov     rS,[ebx.rST]
        saveflags
        mov     ebp,eax
        mov     [6502_CPU_tmpP],ebx
        xor     ebx,ebx

        decode  0
@BadOpcode:
                                        ; Halt CPU?
        cmp     [trap_bad_opcodes],FALSE
        jz      @badopcode_traped
        decode  0
@badopcode_traped:
        

@6502_end:
                                        ; Save current CPU status
        mov     ebx,[6502_CPU_tmpP]
        mov     [ebx.A],rA
        mov     [ebx.X],rX
        mov     [ebx.Y],rY
        mov     [ebx.PC],si
        mov     [ebx.ST],rS
        Restoreflags

        ret
6502_execute    endp



; Instructions:


; transfer instructions 

txs:
        mov     rS,rX
        decode  2
tsx:
        mov     rX,rS
        decode  2
tya:
        mov     rA,rY
        decode  2
tay:
        mov     rY,rA
        decode  2
txa:
        mov     rA,rX
        decode  2
tax:
        mov     rX,rA
        decode  2

; Memory -> registers 

lda_inmed:
        mov     rA,[edi+esi]
        inc     esi
        decode  2

lda_zp:
        mov     bl,[edi+esi]
        inc     esi
        xor     bh,bh
        ReadMem
        mov     rA,al
        decode  3

lda_zp_X:
        mov     bl,rX
        add     bl,[edi+esi]
        setc    bh              ; This takes 3 cycles... maybe can be optimiz.
        inc     esi
        ReadMem
        mov     rA,al
        decode  4

lda_abs:
        mov     bx,[edi+esi]
        add     esi,2
        ReadMem
        mov     rA,al
        decode  4

lda_abs_X:
        xor     bh,bh
        mov     bl,rX
        add     bx,[edi+esi]
        add     esi,2
        ReadMem
        mov     rA,al
        decode  4               ; This is just not 'really' true

lda_abs_Y:
        xor     bh,bh
        mov     bl,rY
        add     bx,[edi+esi]
        add     esi,2
        ReadMem
        mov     rA,al
        decode  4


ldx_inmed:
        mov     rX,[edi+esi]
        inc     esi
        decode  2

ldx_zp:
        mov     bl,[edi+esi]
        inc     esi
        xor     bh,bh
        ReadMem
        mov     rX,al
        decode  3

ldx_zp_Y:
        mov     bl,rY
        add     bl,[edi+esi]
        setc    bh
        inc     esi
        ReadMem
        mov     rX,al
        decode  4

ldx_abs:
        mov     bx,[edi+esi]
        add     esi,2
        ReadMem
        mov     rX,al
        decode  4

ldx_abs_Y:
        xor     bh,bh
        mov     bl,rY
        add     bx,[edi+esi]
        add     esi,2
        ReadMem
        mov     rX,al
        decode  4

ldy_inmed:
        mov     rY,[edi+esi]
        inc     esi
        decode  2

ldy_zp:
        mov     bl,[edi+esi]
        inc     esi
        xor     bh,bh
        ReadMem
        mov     rY,al
        decode  3

ldy_zp_X:
        mov     bl,rX
        add     bl,[edi+esi]
        setc    bh
        inc     esi
        ReadMem
        mov     rY,al
        decode  4

ldy_abs:
        mov     bx,[edi+esi]
        add     esi,2
        ReadMem
        mov     rY,al
        decode  4

ldy_abs_X:
        xor     bh,bh
        mov     bl,rX
        add     bx,[edi+esi]
        add     esi,2
        ReadMem
        mov     rY,al
        decode  4


; Registers -> Memory

sta_zp:
        mov     bl,[edi+esi]
        inc     esi
        xor     bh,bh
        mov     al,rA
        WriteMem
        decode  3

sta_zp_X:
        mov     bl,rX
        add     bl,[edi+esi]
        setc    bh
        inc     esi
        mov     al,rA
        WriteMem
        decode  4

sta_abs:
        mov     bx,[edi+esi]
        add     esi,2
        mov     al,rA
        WriteMem
        decode  4

sta_abs_X:
        xor     bh,bh
        mov     bl,rX
        add     bx,[edi+esi]
        add     esi,2
        mov     al,rA
        WriteMem
        decode  5

sta_abs_Y:
        xor     bh,bh
        mov     bl,rY
        add     bx,[edi+esi]
        add     esi,2
        mov     al,rA
        WriteMem
        decode  5

stx_zp:
        mov     bl,[edi+esi]
        inc     esi
        xor     bh,bh
        mov     al,rX
        WriteMem
        decode  3

stx_zp_Y:
        mov     bl,rY
        add     bl,[edi+esi]
        setc    bh
        inc     esi
        mov     al,rX
        WriteMem
        decode  4

stx_abs:
        mov     bx,[edi+esi]
        add     esi,2
        mov     al,rX
        WriteMem
        decode  4

sty_zp:
        mov     bl,[edi+esi]
        inc     esi
        xor     bh,bh
        mov     al,rY
        WriteMem
        decode  3

sty_zp_X:
        mov     bl,rX
        add     bl,[edi+esi]
        setc    bh
        inc     esi
        mov     al,rY
        WriteMem
        decode  4

sty_abs:
        mov     bx,[edi+esi]
        add     esi,2
        mov     al,rY
        WriteMem
        decode  4

; Flags instructions

sec:
        mov     [6502_Flags.Carry],1
        decode  2

sed:
        mov     [6502_Flags.decimal],1
        decode  2

sei:
        mov     [6502_Flags.interrupt],1
        decode  2

_clc:
        mov     [6502_Flags.carry],0
        decode  2
_cld:
        mov     [6502_Flags.decimal],0
        decode  2

_cli:   
        mov     [6502_Flags.Interrupt],0
        decode  2

_clv:
        mov     [6502_Flags.Overflow],0
        decode  2
        

; Increment / decrement

inc_zp:
        xor     bh,bh
        mov     bl,[edi+esi]
        inc     esi
        ReadMem
        inc     al
        WriteMem
        decode  5

inc_zp_X:
        mov     bl,rX
        add     bl,[edi+esi]
        setc    bh
        inc     esi
        ReadMem
        inc     al
        WriteMem
        decode  6

inc_abs:
        mov     bx,[edi+esi]
        add     esi,2
        ReadMem
        inc     al
        WriteMem
        decode  6

inc_abs_X:
        xor     bh,bh
        mov     bl,rX
        add     bx,[edi+esi]
        add     esi,2
        ReadMem
        inc     al
        WriteMem
        decode  7

inx:                    ; E8h
        inc     rX
        decode  2
iny:                    ; C8h
        inc     rY
        decode  2

dex:
        dec     rX
        decode  2

dey:
        dec     rY
        decode  2

dec_zp:
        xor     bh,bh
        mov     bl,[edi+esi]
        inc     esi
        ReadMem
        dec     al
        WriteMem
        decode  5

dec_zp_X:
        mov     bl,rX
        add     bl,[edi+esi]
        setc    bh
        inc     esi
        ReadMem
        dec     al
        WriteMem
        decode  6

dec_abs:
        mov     bx,[edi+esi]
        add     esi,2
        ReadMem
        dec     al
        WriteMem
        decode  6

dec_abs_X:
        xor     bh,bh
        mov     bl,rX
        add     bx,[edi+esi]
        add     esi,2
        ReadMem
        dec     al
        WriteMem
        decode  7

; Jump Instructions

jmp_abs:
        mov     si,[edi+esi]        
        decode  3

jmp_ind:
        mov     bx,[edi+esi]
        ReadMem
        mov     ah,al
        inc     bx
        ReadMem
        xchg    ah,al
        mov     si,ax
        decode  5

bcc:
        cmp     [6502_flags.carry],0
        process_jump
bcs:
        cmp     [6502_flags.carry],1
        process_jump
beq:
        cmp     [6502_flags.zero],1
        process_jump
bmi:
        cmp     [6502_flags.sign],1
        process_jump

bne:
        cmp     [6502_flags.zero],0
        process_jump

bpl:
        cmp     [6502_flags.sign],0
        process_jump

bvc:
        cmp     [6502_flags.overflow],0
        process_jump

bvs:
        cmp     [6502_flags.overflow],1
        process_jump

; Stack instructions

pha:
        mov     al,rA
        push_stack
        decode  3

php:
        PackFlags
        push_stack
        decode  3

pla:
        pop_stack
        mov     rA,al
        decode  4

plp:
        pop_stack
        DePackFlags
        decode  4

rti:
        pop_stack
        DePackFlags
        pop_stack
        mov     ah,al
        pop_stack
        xchg    ah,al
        mov     si,ax
        decode  6

rts:
        pop_stack
        mov     ah,al
        pop_stack
        xchg    ah,al
        mov     si,ax
        inc     si
        decode  6

jsr:
        mov     bx,[edi+esi]
        add     si,2
        mov     ax,si
        xchg    ah,al
        push_stack
        xchg    ah,al
        push_stack
        mov     si,bx
        decode  6
       

nop:                    ; EAh
        decode  2



; Table with offset to 6502 instrucions

6502_OffsetTable  label dword   
        dd brk                  ;00
        dd ora_I_X
        dd bad_opcode
        dd bad_opcode
        dd bad_opcode
        dd ora_zp
        dd asl_zp
        dd bad_opcode
        dd php
        dd ora_inmed
        dd asl_A
        dd bad_opcode
        dd bad_opcode
        dd ora_abs
        dd asl_abs
        dd bad_opcode           ;10
        dd bpl     
        dd ora_ind_Y     
        dd bad_opcode
        dd bad_opcode
        dd bad_opcode
        dd ora_zp_X
        dd asl_zp_X
        dd bad_opcode
        dd _clc
        dd ora_abs_Y
        dd bad_opcode
        dd bad_opcode
        dd bad_opcode
        dd ora_abs_X
        dd asl_abs_X
        dd bad_opcode           ;20
        dd jsr
        dd and_ind_X
        dd bad_opcode
        dd bad_opcode
        dd bit_zp
        dd and_zp
        dd rol_zp
        dd bad_opcode
        dd plp
        dd and_inmed
        dd rol_A
        dd bad_opcode
        dd bit_abs
        dd and_abs
        dd rol_abs
        dd bad_opcode           ;30
        dd bmi
        dd and_ind_X
        dd bad_opcode
        dd bad_opcode
        dd bad_opcode
        dd and_zp_X
        dd rol_zp_X
        dd bad_opcode
        dd sec
        dd and_abs_Y
        dd bad_opcode
        dd bad_opcode
        dd bad_opcode
        dd and_abs_X
        dd rol_abs_X
        dd bad_opcode
        dd rti                  ;40
        dd eor_ind_X
        dd bad_opcode
        dd bad_opcode
        dd bad_opcode
        dd eor_zp
        dd lsr_zp
        dd bad_opcode
        dd pha
        dd eor_inmed
        dd lsr_A
        dd bad_opcode 
        dd jmp_abs
        dd eor_abs
        dd lsr_abs
        dd bad_opcode
        dd bvc                  ;50
        dd eor_ind_Y
        dd bad_opcode
        dd bad_opcode
        dd bad_opcode
        dd eor_zp_X
        dd lsr_zp_X
        dd bad_opcode
        dd _cli
        dd eor_abs_Y
        dd bad_opcode
        dd bad_opcode
        dd bad_opcode
        dd eor_abs_X
        dd lsr_abs_X
        dd bad_opcode
        dd rts                  ;60        
        dd adc_ind_X
        dd bad_opcode
        dd bad_opcode
        dd bad_opcode
        dd adc_zp
        dd ror_zp
        dd bad_opcode
        dd pla
        dd adc_inmed
        dd ror_A
        dd bad_opcode
        dd jmp_ind
        dd adc_abs
        dd ror_abs
        dd bad_opcode
        dd bvs                  ; 70
        dd adc_ind_Y
        dd bad_opcode
        dd bad_opcode
        dd bad_opcode
        dd adc_zp_X
        dd ror_zp_X
        dd bad_opcode
        dd sei
        dd adc_abs_Y
        dd bad_opcode
        dd bad_opcode
        dd bad_opcode
        dd adc_abs_X
        dd ror_abs_X
        dd bad_opcode
        dd bad_opcode           ;80
        dd sta_ind_X
        dd bad_opcode
        dd bad_opcode
        dd sty_zp
        dd sta_zp
        dd stx_zp
        dd bad_opcode
        dd dey
        dd bad_opcode
        dd txa
        dd bad_opcode
        dd sty_abs
        dd sta_abs
        dd stx_abs
        dd bad_opcode
        dd bcc                  ;90
        dd sta_ind_Y
        dd bad_opcode
        dd bad_opcode
        dd bad_opcode
        dd sty_zp_X
        dd sta_zp_X
        dd stx_zp_Y
        dd bad_opcode
        dd tya
        dd sta_abs_Y
        dd txs
        dd bad_opcode
        dd bad_opcode
        dd sta_abs_X
        dd bad_opcode
        dd bad_opcode
        dd ldy_inmed            ;A0
        dd lda_ind_X
        dd ldx_inmed
        dd bad_opcode
        dd ldy_zp
        dd lda_zp
        dd ldx_zp
        dd bad_opcode
        dd tay
        dd lda_inmed
        dd tax
        dd bad_opcode
        dd ldy_abs
        dd lda_abs
        dd ldx_abs
        dd bad_opcode
        dd bcs                  ;B0
        dd lda_ind_Y
        dd bad_opcode
        dd bad_opcode
        dd ldy_zp_X
        dd lda_zp_X
        dd ldx_zp_Y
        dd bad_opcode
        dd clv
        dd lda_abs_X
        dd tsx
        dd bad_opcode
        dd ldy_abs_X
        dd lda_abs_X
        dd ldx_abs_Y
        dd bad_opcode
        dd cpy_inmed            ;C0
        dd cmp_ind_X
        dd bad_opcode
        dd bad_opcode
        dd cpy_zp
        dd cmp_zp
        dd dec_zp
        dd bad_opcode
        dd iny
        dd cmp_inmed
        dd dex
        dd bad_opcode
        dd cpy_abs
        dd cmp_abs
        dd dec_abs
        dd bad_opcode
        dd bne                  ; D0
        dd cmp_ind_Y
        dd bad_opcode
        dd bad_opcode
        dd bad_opcode
        dd cmp_zp_X
        dd dec_zp_X
        dd bad_opcode
        dd _cld
        dd cmp_abs_Y
        dd bad_opcode
        dd bad_opcode
        dd bad_opcode
        dd cmp_abs_X
        dd dec_abs_X
        dd bad_opcode
        dd cpx_inmed            ; E0
        dd sbc_ind_X
        dd bad_opcode
        dd bad_opcode
        dd cpx_zp
        dd sbc_zp
        dd inc_zp
        dd bad_opcode
        dd inx
        dd sbc_inmed
        dd nop
        dd bad_opcode
        dd cpx_abs
        dd sbc_abs
        dd inc_abs
        dd bad_opcode
        dd beq                  ;F0
        dd sbc_ind_Y
        dd bad_opcode
        dd bad_opcode
        dd bad_opcode
        dd sbc_zp_X
        dd inc_zp_X
        dd bad_opcode
        dd sed
        dd sbc_abs_Y
        dd bad_opcode
        dd bad_opcode
        dd bad_opcode
        dd sbc_abs_X
        dd inc_abs_X
        dd bad_opcode



end
