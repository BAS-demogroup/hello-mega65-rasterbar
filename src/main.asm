!source "macros.asm"

	+BasicUpstart65
	sei
	+MapIO

start
	lda #0
	sta $d020
	sta $d021
	jmp start

