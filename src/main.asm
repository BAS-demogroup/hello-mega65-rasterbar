!source "macros.asm"

	+BasicUpstart65
	sei
	+MapIO

	; disable CIA timer interrupts
	lda #$7f
	sta $dc0d
	sta $dd0d

	; acknowledge any pending CIA irqs
	lda $dc0d
	lda $dd0d

	; set our irq handler
	lda #<irq_handler
	sta $fffe
	lda #>irq_handler
	sta $ffff

	; set irq to trigger at raster line 0
	lda #0
	sta $d012
	lda #$1b
	sta $d011

	; enable VIC raster interrupts
	lda #$01
	sta $d01a
	cli

	; temp init code to cycle raster bar colors
	lda #0
	ldx #0
init:
	sta .rb_buffer, x
	inc
	inx
	bne init

init2:
	sta .rb_buffer+256, x
	inc
	inx
	bne init2

wait:
	inc
	jmp init

irq_handler:
	; save registers (faster than pha/txa/etc)
	sta .irq_temp
	stx .irq_temp+1
	sty .irq_temp+2

	; acknowledge the VIC interrupt
	lda #$ff
	sta $d019

	; read color for this raster line we're currently processing
	ldx .rb_line
	ldy .rb_line+1
	beq irq_rb_line_low
	lda .rb_buffer+256, x
	jmp irq_rb_set

irq_rb_line_low:
	lda .rb_buffer, x

irq_rb_set:	
	; set border and background colors
	sta $d020
	sta $d021

	; increment to next raster line
	lda .rb_line+1
	beq irq_inc_low

	; check if we hit the last screen line (PAL has 312 lines, so 312-256=56)
	inc .rb_line
	lda .rb_line
	cmp #56
	bne irq_set_vic

	; we hit the last line, so reset to line zero
	lda #0
	sta .rb_line
	sta .rb_line+1
	jmp irq_set_vic

irq_inc_low:
	inc .rb_line
	bne irq_set_vic
	lda #$80
	eor .rb_line+1
	sta .rb_line+1

irq_set_vic:
	; update VIC raster line irq
	lda .rb_line
	sta $d012
	lda .rb_line+1
	ora #$1b
	sta $d011

irq_done:
	; restore registers and return
	lda .irq_temp
	ldx .irq_temp+1
	ldy .irq_temp+2
	rti

.rb_line	!word $00
.rb_buffer	!fill 512, $00
.irq_temp	!byte $00, $00, $00
