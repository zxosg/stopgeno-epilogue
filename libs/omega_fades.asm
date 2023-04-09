; Z80 assembly, syntax for sjasmplus: https://github.com/z00m128/sjasmplus
; to assemble run: sjasmplus omega_fades.asm
    OPT --syntax=abf
    DEVICE ZXSPECTRUM48,31999
    ORG $8000

;------------------------------------------------------------------------------
; ULA attributes "fade out" effect, going through PAPER/INK values,
; decrements them (individually) by 1 every iteration (call of routine)
;
; No input ; modifies AF, BC, D, HL
atrFadeOut:
    ld      hl,$5800
    ld      bc,(3<<8) | %00'001'001 ; B = 3, C = mask for INK/PAPER "1"
.doThird:               ; process 256 bytes (third of ULA screen)
    ld      a,(hl)      ; read current attribute
    ; for both PAPER and INK (individually), all three bits are merged into one by OR
    ld      d,a         ; the merged bits will land into "bottom" bit (b0 INK, b3 PAPER)
    rra                 ; setting those to "1" for non-zero INK/PAPER value
    or      d           ; and "0" for zero INK/PAPER - this will be then subtracted
    rra                 ; from current attribute
    or      d           ; *here* the bits 0 and 3 are "1" for non-zero INK and PAPER
    and     c           ; extract those bottom INK (+1)/PAPER (+8) bits into A
    ; subtract that value from current attribute, to decrement INK/PAPER individually
    sub     d           ; A = decrement - attribute
    neg                 ; A = attribute - decrement (new attribute value)
    ld      (hl),a      ; write the darkened attribute value
    inc     l
    jp      nz,.doThird ; process next attribute, until 256 of them were done
    inc     h
    djnz    .doThird    ; repeat for next third of ULA screen
    ret
    DISPLAY "atrFadeOut routine size: ",/D,$-atrFadeOut

;------------------------------------------------------------------------------
; ULA attributes "fade in" effect, adding 1 to PAPER/INK/BRIGHT components
; every iteration (call of routine), until the ULA attribute does reach
; same value as corresponding byte in "target" area at $D800..$DCFF
; The "fade in" way requires the initial attributes to be "less/equal" to target
; values, but the effect will settle by wrapping around also for "greater" values,
; probably causing unwanted visual artefacts.
;
; The main trick of effect works on the same principle as "fade out" effect,
; adding one to PAPER/INK components until they reach the target value, so
; it may be helpful to first understand the mechanics of FadeOut before this one.
;
; Input: target attribute values at $D800..$DCFF ; modifies AF, BC, DE, HL
atrFadeIn:
    ld      hl,$5800
    ld      de,$D800        ; FLASH+BRIGHT is treated as third component (F+B together)
    ld      c,%01'001'001   ; bit-mask of PAPER/INK bottom bits, and FLASH+BRIGHT
    ; do three times screen third processing to process whole ULA screen
    call    .doThird
    call    .doThird
.doThird:               ; process 256 bytes (third of ULA screen)
    ld      a,(de)      ; target attribute value + advance pointer to next one
    inc     e
    xor     (hl)        ; A = xor-difference between source/target value
    ld      b,a         ; the xor-difference yield zero when target value was reached
    rra                 ; otherwise there is non-zero value in the component
    or      b           ; So each component individually is again merged into
    rra                 ; single 0/1 value representing zero/non-zero state of xor-diff
    or      b           ; producing "value to add to current attribute"
    and     c           ; having +1/+8/+64 bits for INK/PAPER/B+F as needed
    add     a,(hl)      ; add it with current attribute (raising it toward target value)
    ld      (hl),a      ; write the patched attribute into ULA VRAM
    inc     l
    ; same block again: saves one "JP nz" = -7680T = fast enough to not show tearing
    ld      a,(de)
    inc     e
    xor     (hl)
    ld      b,a
    rra
    or      b
    rra
    or      b
    and     c
    add     a,(hl)
    ld      (hl),a
    inc     l
    jp      nz,.doThird ; process next attribute, until 256 of them were done
    inc     d           ; adjust high-bytes of pointers to be ready for next screen-third
    inc     h
    ret
    DISPLAY "atrFadeIn routine size: ",/D,$-atrFadeOut

;------------------------------------------------------------------------------
; calling 10 times "fade in", then 10 times "fade out", and then again
; to demonstrate them.
; Press keys 1 to 5 to set delay between iteractions (1 = 50 FPS, 5 = 3 FPS)
startDEMO:
    call    PrepareTestData
    ei
.resetFunctionCounter:
    ld      ixl,20      ; 20..11 calls "fade in", 10..1 calls "fade out" (ten times each)
.loopyLoop:
    ld      b,1
.speedWait:
    halt                ; synchronize with display beam by waiting for ROM interrupt
    djnz    .speedWait
    ld      a,1
    out     (254),a     ; BORDER 1 (to see performance-timing visually in border stripe)
    ld      a,ixl
    cp      11          ; "fade in" for 20..11 values
    call    nc,atrFadeIn
    ld      a,ixl
    cp      11          ; "fade out" for 10..1 values
    call    c,atrFadeOut
    xor     a
    out     (254),a     ; BORDER 0
    ; check for keys 1-5 and adjust speedwait based on the key (1 = fast, 5 = slow)
    ld      a,~(1<<3)   ; fourth keyboard-matrix row, keys 1-5
    in      a,(254)     ; read the keyboard matrix, flip the logic (to 1 = pressed)
    cpl
    and     $1F         ; if any key from 1-5 was pressed, it forms new wait-delay value
    jr      z,.noKeyPressed
    ld      (.speedWait-1),a    ; modify "LD B,1" instruction with new wait value
.noKeyPressed:
    dec     ixl         ; adjust "function counter" to run correct function next time
    jr      nz,.loopyLoop
    jr      .resetFunctionCounter

; Sets test-data for FadeOut/FadeIn demoing:
; - chessboard pixels in the ULA VRAM at $4000
; - zeroing attributes of ULA VRAM (black ink, black paper)
; - at $D8000 creating "target attributes", three blocks of 0..255 values
PrepareTestData:
    ; set chessboard pixels in ULA
    ld      hl,$4000
    ld      de,$4001
    ld      bc,$0100
    ld      (hl),%1010'1010
    ldir
    ld      bc,$00FF
    ld      (hl),%0101'0101
    ldir
    ld      hl,$4000
    ld      bc,$1800-$200+1
    ldir
    ; zeroed attributes of ULA screen
    ld      hl,$5800
    ld      bc,$2FF
    ld      (hl),l
    ldir
    ; at $D800: 3x 0-255 attribute bytes in "target" area for FadeIn effect
    ld      hl,$D800
    ld      b,3
.doThird:
    ld      (hl),l
    inc     l
    jr      nz,.doThird
    inc     h
    djnz    .doThird
    ret

    SAVESNA "omega_fades.sna", startDEMO : CSPECTMAP "omega_fades.map"
    DISPLAY "Try keys 1 to 5 to change speed-delay between effect calls"

    IFDEF LAUNCH_EMULATOR : IF 0 == __ERRORS__ && 0 == __WARNINGS__
            SHELLEXEC "( sleep 0.1s ; runCSpect -debug -brk -map=omega_fades.map -w3 omega_fades.sna ) &"
    ENDIF : ENDIF
