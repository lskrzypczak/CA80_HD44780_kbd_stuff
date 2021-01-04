       ; delay: input: D - delay in 2ms units
delay:  push    BC
        push    AF
        ld      B, D                    ; djnz works wit B register
.delay
        halt                            ; 2ms
        djnz    .delay                  ; while( --B )
        pop     AF
        pop     BC
        ret