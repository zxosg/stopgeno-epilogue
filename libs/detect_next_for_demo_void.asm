
    ;; detect Z80N (ie. Next-compatible machine), and tune settings when detected
    ; modifies: AF always, H (!) on regular Z80
    ld      a,$80
    DB $ED, $24, $00, $00   ; mirror a : nop : nop
    dec     a
    jr      nz,.notZ80nCpu
    ;; Z80N detected - do ZX Next configuration fine-tuning + check
    ld      bc,$243B
    ; check 50/60Hz mode
    ld      a,$05
    out     (c),a
    inc     b
    in      a,(c)           ; A = nextreg $05 "Peripheral 1"
    dec     b
    bit     2,a
    jr      z,.video50HzDetected
    ;; report some error about 60Hz not supported, recommending user to switch to 50Hz?
    ; .. ??? ... TODO
                ld a,2 : out (254),a    ; BORDER 2 (red) to signal 60Hz freeze
    jr      $   ; freeze
.video50HzDetected:
    ; check VGA/RGB/HDMI video mode
    ld      a,$11
    out     (c),a
    inc     b
    in      a,(c)           ; A = nextreg $11 "Video timing"
    dec     b
    inc     a               ; HDMI is "7" in bottom 3 bits
    and     $07             ; (A == 0) => HDMI mode
    jr      nz,.notHdmiMode
    ; HDMI detected, on core 3.1.x that means bad timing (214T per scanline, 312 lines),
    ; but in future cores it may be fixed to have correct ZX128 timing
    ; so either add here core version check, or display warning which can be skipped
    ; (or just remove the check and ignore the multicolors being broken)
    ; ... ??? .... TODO
.notHdmiMode:
    ; switch AY to ACB stereo
    ld      a,$08
    out     (c),a
    inc     b
    in      a,(c)           ; A = nextreg $08 "Peripheral 3"
    or      %0010'0000      ; switch ACB stereo ON
    out     (c),a           ; write nextreg $08
    dec     b
    ; switch AY to YM mode
    ld      a,$06
    out     (c),a
    inc     b
    in      a,(c)           ; A = nextreg $06 "Peripheral 2"
    and     %1111'1100      ; switch AY into "YM" mode (bottom bits %00)
;     inc a                   ; "AY" mode (bottom bits %01)
    out     (c),a           ; write nextreg $06
    ; continue with regular setup
    ;  |
    ;  v
.notZ80nCpu:
    ; regular ZX128 setup
