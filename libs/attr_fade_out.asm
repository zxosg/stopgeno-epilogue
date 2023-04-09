    DEVICE ZXSPECTRUM48,31999 : ORG $8000

startFadeOut:
.ulaInit
    call    DebugUlaContentFadeOut
.debugLoop:
    ei
    halt
    ld      a,2
    out     (254),a
    ld      ix,$5800
    call    atrFadeOut
    xor     a
    out     (254),a
    in      a,(254)
    rra
    jr      nc,.ulaInit
    jr      .debugLoop

startFadeIn:
.ulaInit
    call    DebugUlaContentFadeIn
.debugLoop:
    ei
    halt
    ld      a,2
    out     (254),a
    call    atrFadeIn
    xor     a
    out     (254),a
    in      a,(254)
    rra
    jr      nc,.ulaInit
    jr      .debugLoop

startDEMO:
    call    DebugUlaContentFadeIn
    ei
.loopyLoop:
    DUP 10
        halt
        ld      a,1
        out     (254),a
        call    atrFadeIn
        xor     a
        out     (254),a
    EDUP
    DUP 10
        halt
        ld      a,1
        out     (254),a
        ld      ix,$5800
        call    atrFadeOut
        xor     a
        out     (254),a
    EDUP
    jp      .loopyLoop


DebugUlaContentRomPixels:
    ; ROM data into pixels
    sbc     hl,hl
    ld      de,$4000
    ld      bc,$1800
    ldir
    ret

DebugUlaContentFadeOut:
    call    DebugUlaContentRomPixels
    ex      de,hl   ; HL = $5800
    call    .doThird
    call    .doThird
.doThird:
    ld      (hl),l
    inc     l
    jr      nz,.doThird
    inc     h
    ret

DebugUlaContentFadeIn:
    call    DebugUlaContentRomPixels
    ; zeroing attributes (+1B in sysvars)
    ld      hl,de   ; HL = $5800
    inc     e       ; DE = $5801
    ld      (hl),l
    ld      b,3
    ldir
    ; set "target" data at $D800
    ld      hl,$D800
    call    .doThird
    call    .doThird
.doThird:
    ld      (hl),l
    inc     l
    jr      nz,.doThird
    inc     h
    ret

; atr fade out
; ix=vram addr (5800|d800)
atrFadeOut:
           ld   hl,ix
           ld   e,%00'001'001
            call .doThird
            call .doThird
.doThird:
            ld a,(hl)
            ld d,a
            rra
            or d
            rra
            or d
            and e   ; A = +8 / +1 for PAPER/INK when PAPER/INK is non-zero
            sub d
            neg     ; A = A - (+8/+1) (--PAPER, --INK)
            ld (hl),a
            inc l
            jp nz,.doThird
            inc h
           ret

;--------------------------------------------
; fade in, working-buffer attrs are in #5800
; target-value attrs are in #d800
; limited to fade-in from "less/equal" value-per-component (than target)
atrFadeIn:
            ld      hl,$5800
            ld      de,$D800
            ld      c,%01'001'001
            call    .doThird
            call    .doThird
.doThird:
            ld      a,(de)
            inc     e
            xor     (hl)    ; A = xor-difference between source/target value
            ld      b,a
            rra
            or      b
            rra
            or      b
            and     c       ; A = +64/+8/+1 for B+F/PAPER/INK when xor-diff is non-zero
            add     a,(hl)
            ld      (hl),a
            inc     l
            ; second attribute (optimization to have one JP less)
            ld      a,(de)
            inc     e
            xor     (hl)    ; A = xor-difference between source/target value
            ld      b,a
            rra
            or      b
            rra
            or      b
            and     c       ; A = +64/+8/+1 for B+F/PAPER/INK when xor-diff is non-zero
            add     a,(hl)
            ld      (hl),a
            inc     l
            jp      nz,.doThird
            inc     d
            inc     h
            ret

    SAVESNA "omega_fades.sna", startDEMO
    CSPECTMAP "omega_fades.map"

    IFNDEF LAUNCH_EMULATOR : DEFINE LAUNCH_EMULATOR 0 : ENDIF
    IF 0 == __ERRORS__ && 0 == __WARNINGS__ && 1 == LAUNCH_EMULATOR
        SHELLEXEC "( sleep 0.1s ; runCSpect -debug -brk -map=omega_fades.map -w3 omega_fades.sna ) &"
    ENDIF
