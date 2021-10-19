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

	; acknowledge the VIC interrupt
	lda #$ff
	sta $d019

	; read color from buffer for this raster line we're currently processing
	ldx .rb_line
	lda .rb_line+1
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
	ldx .rb_line
	lda .rb_line+1
	beq irq_inc_low

	; check if we hit the last screen line (PAL has 312 lines, so 312-256=56)
	inx
	cpx #56
	bne irq_set_vic_line

	; we hit the last line, so reset to line zero
	lda #0
	sta .rb_line
	sta .rb_line+1
	sta $d012
	lda #$1b
	sta $d011
	jmp irq_done

irq_inc_low:
	inx

irq_set_vic_line:
	stx .rb_line
	stx $d012
	bne irq_done

	; handle rollover (screen line 255 -> 256)
	inc .rb_line+1
	lda #$9b				; set high bit (bit 7) in VIC for irqs on raster lines >= 256
	sta $d011

irq_done:
	; restore registers and return
	lda .irq_temp
	ldx .irq_temp+1
	rti

.rb_line	!word $00
.rb_buffer	!fill 512, $00
.irq_temp	!byte $00, $00, $00
