    ORG $A100

_addan      EQU     $C6
_ldan       EQU     $3E

    ; 61B -> 60B, worst case inner loop 122T -> 103T. skip-case is 54T -> 42T
atrSetMaskColor:
.bias:     ld      h,a                       ; bias = -7...7
                                             ; fixed= 8...15 (bit 3)
           ld      l,_addan                  ; "add a,n" for bias
           sub     8
           jp      m,1F                      ; bias (-7..+7)
           ld      h,a                       ; adjusted fixed value to 0..7
           ld      l,_ldan                   ; "ld a,n" for fixed
        ; ^ entry modified to save 5B (includin -1 for "ld (.bs),hl")

1          ld      (.bs),hl
.sdata:    ld      de,#5555                  ; data
.svram:    ld      hl,#5555                  ; vram
           ld      c,7
           call    .doThird
           call    .doThird
.doThird:
.l1:
           ld      a,(de)
           and     %11000000                 ; test of bit 7 + extract bright value
           jp      m,.s1                     ; mark = skip attribute
           ld      b,a                       ; save bright value
           ld      a,(de)
           and     c                         ; 7, mask ink only
.bs:       add     a,#55                     ; bias (negative number) ; add a,* / ld a,* (fixed)
           jp      m,.s3                     ; if <0 then black
           cp      c                         ; if >7 then 7
           jp      c,.s2 ; ? "jr" for better worst case?
           ld      a,c
.s2:       or      b                         ; or bright
.s22:      ld      (hl),a                    ; save final color
.s1:       inc     e
           inc     l
           jp      nz,.l1       ; x256
           inc     d            ; +256 for next third
           inc     h
           ret
.s3:       ld      (hl),b       ; black + bright
           jr      .s1  ; ? "jp" for -2T when clamping to 0?
           ; or even unroll tail (+5B)

; de=vram addr
; hl=attr data (paper color is used for selection of area)
; a =area number (max 8 areas)
; call init first to reset 7 th bit of data for area that will be displayed
; area that won't be displayed will have 7th bit set
.init:     ld      (.sdata+1),hl
           ld      (.svram+1),de
           ret  ; why? can't you call single ".init" with HL+DE+A every time? (-4B *here*)

.inia:     ld      hl,(.sdata+1)    ; can be removed if only ".init" is called every time
           ld      e,a
           ld      bc,#300
.ilp:      ld      a,(hl)
           and     %00111000
           cp      e
           set     7,(hl)
           jr      nz,1F    ; needs flipped meaning for atrSetMaskColor: reset -> display, set -> skip
           res     7,(hl)   ; also more bytes to skip than to display -> faster init in this way
1          cpi
           jp      pe,.ilp
           ret
