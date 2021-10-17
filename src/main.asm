!source "macros.asm"

	+BasicUpstart65
	sei
	+MapIO

	ldx #0

loop
	cpx $d012
	bne loop
	stx $d020
	stx $d021
	inx
	jmp loop
