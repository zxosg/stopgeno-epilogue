;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Busy soft ;; LZX Universal depacker ;; 05.01.2017 ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Supported compression types

TYPZX7	=	3	// Original ZX7 compression (similar to known ZX7 compressor)
TYPBLK	=	4	// Bitstream BLK (elias-gama length for both unpack/packed blocks)
TYPBS1	=	5	// Bitstream standart BS1 (0=unp,10=2sek,110=3sek,1110+EG=sekvence,1111+EG=unp)

;; Supported offset codings

POSOF4	=	4	// Four step offsets (1,2,3,4 / 2,4,6,8 / 3,6,9,12 / 4,8,12,16 bits)
POSOF1	=	5	// One fixed offset (ofs1 = number of offset bits)
POSOF2	=	6	// Two fixed offsets  (ofs1,ofs2 = two numbers of offset bits)
POSOFD	=	7	// Simple elias-gama coding offset (ofs1,ofs2 not used)

;; Note: LZM and LZE compressions are not supported by this LZX depacker.
;; In this case it is needed to use optimized "DecLzm" or "DecLze" depackers.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Setting for depacker according to compression identification -tXYoAoB

com	=	3	;; Compression type - one from TYPZX7 TYPBLK TYPBS1
pos	=	6	;; Offset coding - one from POSOF4 POSOF1 POSOF2 POSOFD
ofs1	=	7	;; Number of bits for 1st offset - required for POSOF1 POSOF2 POSOF4
ofs2	=	11	;; Number of bits for 2nd offset - required for POSOF2 only

;; This is needed to set according to compression ID string from name of compressed file:
;;  -tXYoAoB ... means setting  com=X, pos=Y, ofs1=A, ofs2=B   (ofs1 ofs2 only when required)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Set optimization of depacker

spd	=	0

;; Possible values:
;;  0 ... optimized for code length - short but slow
;;  1 ... compromise between length and speed
;;  2+ .. optimized for speed - but longer code

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	OUTPUT	DecLzx01.cod

;; Input:
;;  HL = address of source packed data
;;  DE = address of destination to depack data

depack	ld	a,#80		;; Initial value what means there are no bits from bitstream in A

;; Processing of compression types

    IF com=TYPZX7
decldi	ldi			;; Copy one unpacked byte                 *** ZX7 compression ***
declop
      IF spd < 2
	call	getbit		;; Get bit from bitstrem
      ELSE
	add	a,a		;; Get bit optimized for speed
	call	z,getbyt
      ENDIF
	jr	c,decldi	;; If bit=1 then next unpacked byte follows
	call	getlen		;; If bit=0 then get length of next sequence
	ret	c		;; If length > 65535 then end of data (end mark)
	inc	bc
    ENDIF

    IF com=TYPBLK
declop	call	getlen		;; Get length of next block              *** BLK compression ***
	ret	c		;; If length > 65535 then end of data (end mark)
      IF spd < 2
	call	getbit		;; Get bit from bitstrem
      ELSE
	add	a,a		;; Get bit optimized for speed
	call	z,getbyt
      ENDIF
	jr	nc,decinc	;; If bit=0 then packed sequence follows
	ldir			;; If bit=1 then copy unpacked data
	jr	declop		;; Processing next block
decinc	inc	bc
    ENDIF

    IF com=TYPBS1
decldi	ldi			;; Copy one unpacked byte                 *** BS1 compression ***
declop
      IF spd < 2
	call	getbit		;; Get bit from bitstrem
      ELSE
	add	a,a		;; Get bit optimized for speed
	call	z,getbyt
      ENDIF
	jr	nc,decldi	;; 0 ... next unpacked byte follows
	ld	bc,#02		;; Set length to 2
      IF spd < 2
	call	getbit		;; Get bit from bitstrem
      ELSE
	add	a,a		;; Get bit optimized for speed
	call	z,getbyt
      ENDIF
	jr	nc,decoff	;; 10 ... sequence (length=2) follows
	inc	c		;; Set length to 3
      IF spd < 2
	call	getbit		;; Get bit from bitstrem
      ELSE
	add	a,a		;; Get bit optimized for speed
	call	z,getbyt
      ENDIF
	jr	nc,decoff	;; 110 ... sequence (length=3) follows
      IF spd < 2
	call	getbit		;; Get bit from bitstrem
      ELSE
	add	a,a		;; Get bit optimized for speed
	call	z,getbyt
      ENDIF
	jr	nc,decsek	;; 1110 ... sequence (length=4+) follows
	call	getlnx		;; 1111 ... get length of unpacked block (length >= 8)
	ret	c		;; If length > 65535 then end of data (end mark)
	ldir			;; Copy unpacked data
	jr	declop		;; Processing next block
decsek	dec	c		;; C=3 but we need only 2 bits additionally
	call	getlnx		;; Get length of packed sequence (length >= 4)
    ENDIF

decoff	push	bc		;; Store length of sequence to stack

;; Processing of sequence offsets codings

    IF pos=POSOFD
	call	getlen		;; Read elias-gama value (it is enough)		*** OFD offset ***
    ENDIF

    IF pos=POSOF1
	ld	c,ofs1		;; Number of bits of one fixed offset		*** OF1 offset ***
	call	getvlc		;; Read value (C=number of value bits)
	scf			;; Increment offset value (for later sbc hl,bc)
	ASSERT	ofs1 >= 1 and ofs1 <= 16
    ENDIF

    IF pos=POSOF2
	ld	bc,#FFFF	;; Set offset to -1				*** OF2 offset ***
	ld	xl,ofs2-ofs1	;; We will read N bits, N = difference between bitwide of offsets
      IF spd < 2
	call	getbit		;; Get bit from bitstrem
      ELSE
	add	a,a		;; Get bit optimized for speed
	call	z,getbyt
      ENDIF
	call	nc,getvlx	;; If longer offset then reading N bits - it is first part of offset
	and	a		;; Clearing carry only (later 'call getlop' needs it)
	inc	bc		;; Increment offset (-1 => 0, or part of longer offset + 1)
	ld	xl,ofs1		;; Number of bits of shorter offset
	call	getlop		;; Reading bits of offset (next part of longer or entire shorter offset)
	scf			;; Next increment offset value (for later sbc hl,bc)
	ASSERT	ofs1 >= 1 and ofs1 <= 15 and ofs2 >= 2 and ofs2 <=16 and ofs1 < ofs2
    ENDIF

    IF pos=POSOF4
	ld	c,#02		;; Next two bits means offset width		*** OF4 offset ***
	call	getvlc		;; Reading these two bits from bitstream
	inc	c		;; Adjust two bits to value in range 1..4
	ld	xh,c		;; XH will be reading offset counter
	ld	c,b		;; Clearing BC for next reading offset value
of4lop	ld	xl,ofs1		;; Number of bits of one part of offset
	call	getlop		;; Reading part of offset
	inc	bc		;; Increment temporary offset value
	dec	xh		;; (it is needed for covering of bigger interval)
	jr	nz,of4lop	;; Repeat for given with of offset
	ASSERT	ofs1 >= 1 and ofs1 <= 4
    ENDIF

;; Copy packed sequence

	ex	(sp),hl		;; Store address to source data and get sequence length
	push	hl		;; Store sequence length
	ld	h,d		;; DE keeps destination address whole time
	ld	l,e		;; Substract offset from destination address
	sbc	hl,bc		;; and now HL points to source data of copied sequence
	pop	bc		;; Restore BC = length of copied sequence
	ldir			;; Copy sequence
	pop	hl		;; Restore address to packed source data
	jr	declop		;; Copy finished and we can continue in next block of data

;; Get value from bitstream

    IF com=TYPBS1 or pos=POSOF1 or pos=POSOF2 or pos=POSOF4
      IF com=TYPZX7 or com=TYPBLK or pos=POSOFD
getlen	ld	c,#00		;; Reading of elias-gama value with no additional bits
      ENDIF
getlnx
      IF spd = 0
	call	getbit		;; Get bit from bitstrem
      ELSE
	add	a,a		;; Get bit optimized for speed
	call	z,getbyt
      ENDIF
	inc	c		;; Computing zero bits before value bits
	jr	nc,getlnx	;;
getvlc	ld	xl,c		;; XL = bit width of next reading value
getvlx	ld	bc,#00		;; Initialize reading value to zero
    ELSE
getlen	ld	bc,#00		;; Initialize reading value to zero
	ld	xl,c		;; Initialize bit counter to zero
getv11
      IF spd = 0
	call	getbit		;; Get bit from bitstrem
      ELSE
	add	a,a		;; Get bit optimized for speed
	call	z,getbyt
      ENDIF
	inc	xl		;; Computing zero bits before value bits
	jr	nc,getv11	;; End computing when bit 1 => carry will be set
    ENDIF
				;; Read bit of value (first bit of elias-gama is allways 1)
      IF spd = 0
getlop	call	nc,getbit	;; Get bit from bitstrem
      ENDIF
      IF spd = 1
	jr	c,getnxt
getlop	add	a,a		;; Get bit optimized for speed
	call	z,getbyt
      ENDIF
      IF spd > 1
	jr	c,getnxt
getlop	add	a,a		;; Get bit optimized for speed
	jr	z,getss2
      ENDIF
getnxt	rl	c		;;  (in case of reading elias-gama we have CY=1 for first time)
	rl	b		;; Include bit into value
	ret	c		;; If value > 65535 then return immediatelly with CY=1
	dec	xl		;;  (value > 65535 is usually used as end mark)
	jr	nz,getlop	;; Repeat for all needed bits of value
	ret			;; Return with CY=0 (not end mark)

      IF spd > 1
getss2	ld	a,(hl)		;; Buffer is empty so we must read next byte from bistream
	adc	a,a		;; LSB bit will be returned reading bit
	inc	hl		;; Move to next byte in packed data
	jp	getnxt
      ENDIF

;; Get one bit from bitstrem

    IF spd < 2
getbit	add	a,a		;; Reading bit from buffer (A = temporary buffer for bits)
	ret	nz		;; If there were some bits in buffer then return
    ENDIF
getbyt	ld	a,(hl)		;; Buffer is empty so we must read next byte from bistream
	adc	a,a		;; LSB bit will be returned reading bit
	inc	hl		;; Move to next byte in packed data
	ret

;; Validation of parameters 'com' and 'pos'
;; (only for sure for prevention of set not supported values)

	ASSERT	com=TYPZX7 or com=TYPBLK or com=TYPBS1
	ASSERT	pos=POSOF4 or pos=POSOF1 or pos=POSOF2 or pos=POSOFD

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
