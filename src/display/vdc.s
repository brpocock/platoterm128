;;; vdc.s
;;;
;;; For now, just a test of setting modes for PLATO terminal
;;;
;;; brfennpocock@star-hope.org
;;;
;;; GPL v3+

	WRITEREG = $cdcc
	READREG = $cddc

setReg:	.macro reg,value
	ldx #\reg
	lda #\value
	jsr WRITEREG
	.endm

	* = $c000
	
initVDC:
	jsr blankScreen
	jsr initFont
	jsr setVDCPlato
	rts

blankScreen:
	;; Fill the first 2,048 ($800) bytes with zeroes
	;;
	;; Only 2,000 are used for KERNAL 80×25 mode,
	;; but avoid a flash of junk when setting up
	;; for 64×32 mode.
	setReg $12, 0		; start at $0000
	setReg $13, 0
	setReg $18, 0		; fill mode
	setReg $1e, 0		; 256 bytes
	setReg $1f, 0		; fill with zeroes
	setReg $1e, 0
	setReg $1f, 0		; fill $100-$1ff
	setReg $1e, 0
	setReg $1f, 0		; fill $200-$2ff
	setReg $1e, 0
	setReg $1f, 0		; fill $300-$3ff
	setReg $1e, 0
	setReg $1f, 0		; fill $400-$4ff
	setReg $1e, 0
	setReg $1f, 0		; fill $500-$5ff
	setReg $1e, 0
	setReg $1f, 0		; fill $600-$6ff
	setReg $1e, 0
	setReg $1f, 0		; fill $700-$7ff
	rts

initFont:
	;; TODO: Upload a PLATO-compatible font set.
	;; 512 character positions are available at 16×8 px each.
	;; Only the first (128?) are needed for PLATO.
	;; The remaining (384?) will be used as “scratch”
	;; characters for bitmap display.
	rts

setVDCPlato:
	setReg 4,35		; vertical total height in characters
	setReg 6,32		; vertical displayed characters (32 rows)
	setReg 8,3		; interlaced sync + video mode
	;; we might also try mode 2 in the preceding like
	setReg 9,$ff		; character vertical total (16 scanlines)
	setReg $a, 0		; cursor mode (non-blinking, full block)
	setReg $b, $ff		; cursor end scan line (line 15)
	setReg $c, 0		; character map start (high)
	setReg $d, 0		; character map start (low)
	setReg $e, 0		; cursor pointer (high)
	setReg $f, 0		; cursor pointer (low)
	setReg $14, $08		; attribute map (high)
	setReg $15, 0		; attribute map (low)
	setReg $17, 16		; character height (16 scanlines)
	setReg $1a, 0		; background color (black)
	setReg $1b, 64		; characters per row

	ldx #$1c		; character bitmap base / RAM type
	jsr READREG
	ldx #$1c
	and #$10		; preserve RAM chip type
	ora #$01		; character bitmap address (below)
	jsr WRITEREG
	;; The character bitmap address value sets bits 13-15, in 8KiB
	;; increments, so on an unexpanded C=128 the only sane values
	;; are 0 or 1.
	;; 
	;; The 2048 positions each for the character map and attribute
	;; map bring us to 4096 = $1000 = 4KiB, so there's 4KiB wasted
	;; space, but we only need 512×16 = 8192 = $2000 = 8KiB for
	;; all allowable character bitmaps (same as the KERNAL, only
	;; the KERNAL leaves half that space blank).

	setReg $1d,14		; underline is near bottom of character
	setReg $22,14		; left margin covers first six chars
	setReg $23,79		; right margin covers last six chars
	setReg $24,1		; lower RAM refresh rates
	rts
