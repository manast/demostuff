;----------------------------------------------------------------------------
; BitSorting Procedure
; Lineal Sorting Procedure, Radix Algorithm
; In: FacePointerArray,Number_of_VisibleFaces
; Out: FacePointerArray sorted (from z to Z)
; Uses: OneCount,ZeroCount
;----------------------------------------------------------------------------

BitSorting Proc
        mov dx,1         ;Mask = 1
        
        REPT 16        ;16 bits numbers
        local @sort,@innersort,@PutinZeros,@Ok
        
        mov ZeroCount,0
        mov OneCount,0
        lea bx,FacePointerArray
        lea si,ZeroArray
        lea di,OneArray
        mov bp,Number_of_VisibleFaces
@innersort:
        mov eax,[bx]
        test ax,dx
        jz @PutinZeros
        mov [di],eax
        add di,4
        inc OneCount
        jmp @Ok
@PutinZeros:
        mov [si],eax
        add si,4
        inc ZeroCount
@Ok:      
        add bx,4
        dec bp
        jnz @innersort
                                ;Join Arrays together
        lea di,FacePointerArray                        
        lea si,OneArray
        mov cx,OneCount
              
        rep movsd

        lea si,ZeroArray
        mov cx,ZeroCount

        rep movsd
        
        shl dx,1
        ENDM
        
        ret
BitSorting Endp
