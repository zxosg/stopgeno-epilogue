;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Busy soft ;; LZE optimized depacker ;; 08.07.2016 ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;	OUTPUT	DecLze01.cod

;; Input:
;;  HL = address of source packed data
;;  DE = address of destination to depack data

depack	bit	6,(hl)		;; Get identification of block: 0=unpacked, 1=packed
	push	af
	ld	a,#3F
	call	depnum		;; Get length of block
	pop	af
	jr	nz,deprep	;; If packed block then jump
	ld	a,b
	or	c		;; If length = 0 then end of depacking
	ret	z
	ldir			;; Copy unpacked data block
	jr	depack

deprep	push	bc		;; Save block length
	ld	a,#7F
	call	depnum		;; Get relative offset of packed sequence
	ex	(sp),hl
	push	hl
	ld	h,d		;; DE = destination address
	ld	l,e
	sbc	hl,bc		;; HL = begin of source sequence in already unpacked data
	pop	bc		;; BC = length of sequence
	ldir			;; Copy sequence
	pop	hl
	jr	depack

depnum	and	(hl)		;; Mask one-byte value or high byte of two-byte value
	ld	c,a
	ld	b,#00		;; BC = value or high type of value
	bit	7,(hl)		;; Get type of value
	inc	hl
	ret	z		;; If short value then return
	ld	b,c
	ld	c,(hl)		;; Get low byte of two-byte value
	inc	hl
	ret


;; Format of packed data
;; ~~~~~~~~~~~~~~~~~~~~~
;; <Block><Block>...<Block><EndMark>
;;
;; Unpacked data blk:  <BlockLength> <Data..>
;; Repeated sequence:  <BlockLength> <Offset>
;;
;; <BlockLength>
;;   bit 6 ..... Identification: 0 = unpacked data, 1 = repeated sequence
;;   bit 7 ..... Length store: 0 = 6-bit length 0..63, 1 = 14-bit length 0..16383
;;   bit 0-5 ... whole 6-bit length  or  high byte of 14-bit length
;;   Additonal second byte: low byte of length in case of 14-bit length
;;
;; <Data..>
;;   Data bytes what are directly copied by LDIR
;;
;; <Offset>
;;   bit 7 ..... Offset store: 0 = 7-bit offset 0..127, 1 = 15-bit offset 0..32767
;;   bit 0-6 ... whole 7-bit offset  or  high byte of 15-bit offset
;;   Additonal second byte: low byte of offset in case of 15-bit offset
;;
;; Length = 0 means end mark.

