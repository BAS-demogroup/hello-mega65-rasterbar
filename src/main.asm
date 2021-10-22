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

	jmp init


;*****************************************************************************
; IRQ Handler
; -----------
; Called from the VIC for each raster line.  Simply looks up the color for
; the current raster line from our buffer, and sets the color for the border
; border and background colors to the VIC.
;*****************************************************************************

.irq_temp	!byte $00, $00

irq_handler:
	; save registers (faster than pha/txa/etc)
	sta .irq_temp
	stx .irq_temp+1

	; acknowledge the VIC interrupt
	lda #$ff
	sta $d019

	; check which buffer (0 or 1) we're reading from
	lda .rb_buffer_read_index
	bne irq_rb_buffer_1

	; read color for this raster line we're currently processing
	ldx .rb_cur_line
	lda .rb_cur_line+1
	beq irq_rb_line_low_0
	lda .rb_color_buffer_0+256, x
	jmp irq_rb_set
irq_rb_line_low_0:
	lda .rb_color_buffer_0, x
	jmp irq_rb_set

irq_rb_buffer_1:
	ldx .rb_cur_line
	lda .rb_cur_line+1
	beq irq_rb_line_low_1
	lda .rb_color_buffer_1+256, x
	jmp irq_rb_set
irq_rb_line_low_1:
	lda .rb_color_buffer_1, x

irq_rb_set:
	; set border and background colors
	sta $d020
	sta $d021

	; increment to next raster line
	ldx .rb_cur_line
	lda .rb_cur_line+1
	beq irq_inc_low

	; check if we hit the last screen line (PAL has 312 lines, so 312-256=56)
	inx
	cpx #56
	bne irq_set_vic_line

	; we hit the last line, so reset to line zero
	lda #0
	sta .rb_cur_line
	sta .rb_cur_line+1
	sta $d012
	lda #$1b
	sta $d011

	; swap read/write index and flag that we need an update for the next frame
	lda #1
	sta .rb_need_update
	eor .rb_buffer_read_index
	sta .rb_buffer_read_index
	lda #1
	eor .rb_buffer_write_index
	sta .rb_buffer_write_index
	jmp irq_done

irq_inc_low:
	inx

irq_set_vic_line:
	stx .rb_cur_line
	stx $d012
	bne irq_done

	; handle rollover (screen line 255 -> 256)
	inc .rb_cur_line+1
	lda #$9b				; set high bit (bit 7) in VIC for irqs on raster lines >= 256
	sta $d011

irq_done:
	; restore registers and return
	lda .irq_temp
	ldx .irq_temp+1
	rti

.rb_cur_line			!word $00
.rb_color_buffer_0		!fill 312, $00
.rb_color_buffer_1		!fill 312, $01
.rb_buffer_read_index	!byte $00
.rb_buffer_write_index	!byte $01
.rb_need_update			!byte $00
