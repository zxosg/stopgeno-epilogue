;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Busy ;; LZM optimized depacker ;; 07.07.2016 ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;	OUTPUT	DecLzm01.cod

;; Input:
;;  HL = address of source packed data
;;  DE = address of destination to depack data

depack	ld	b,#00		;; All copied blocks will be no longer than 255 bytes
deplop	ld	c,(hl)		;; Get identification of block
	inc	hl		;; Move to next byte in packed data
	srl	c		;; BC = length of block or sequence
	ret	z		;; Zero length means end mark
	jr	c,deprep	;; If it is packed sequence then jump
	ldir			;; Copy unpacked data block
	jr	deplop

deprep	ld	a,e		;; Determine address of source sequence
	sub	(hl)		;; DE = destination address
	inc	hl
	push	hl
	ld	l,a
	ld	a,d
	sbc	a,b		;;  B = 0 (because BC = length up to 255)
	ld	h,a		;; HL = begin of source sequence in already unpacked data
	ldir			;; Copy sequence
	pop	hl
	jr	deplop


;; Format of packed data
;; ~~~~~~~~~~~~~~~~~~~~~
;; <Block><Block>...<Block><EndMark>
;;
;; Unpacked data blk:  <BlockLength> <Data..>
;; Repeated sequence:  <BlockLength> <Offset>
;;
;; <BlockLength>
;;   bit 0 ..... Identification: 0 = unpacked data, 1 = repeated sequence
;;   bit 1-7 ... length of block 1..127 (0 is end mark)
;;
;; <Data..>
;;   Data bytes what are directly copied by LDIR.
;;
;; <Offset>
;;   bit 0-7 ... relative offset of sequence 0..255
;;
;; Length = 0 means end mark.
