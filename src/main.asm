!source "macros.asm"

!addr .rb_read_buffer_ptr	= $02
!addr .rb_write_buffer_ptr	= $04
!addr .rb_colors_ptr		= $06

	+BasicUpstart65
	sei
	+MapIO

	; initialize our handler for processing VIC interrupts
	jsr set_irq_handler

	; initialize read/write buffer pointers (start with read=0/write=1)
	lda .rb_write_index
	jsr rb_set_buffer_ptrs

	; enable interrupts to start rasterbars
	cli

update_wait:
	; idle wait until update flag is set
	lda .rb_need_update
	beq update_wait

	; clear update flag
	lda #0
	sta .rb_need_update

	; copy rasterbar 0 into write buffer at appropriate Y position
	lda #<.rb0_colors
	sta .rb_colors_ptr
	lda #>.rb0_colors
	sta .rb_colors_ptr+1
	lda .rb_write_buffer_ptr
	adc #$a0
	sta .rb_write_buffer_ptr
	ldx #8
	ldy #0
copy_loop:
	lda (.rb_colors_ptr), y
	sta (.rb_write_buffer_ptr), y
	iny
	dex
	bne copy_loop

	jmp update_wait


set_irq_handler:
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
	rts


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
	sty .irq_temp+1

	; acknowledge the VIC interrupt
	lda #$ff
	sta $d019

	; read color for this raster line we're currently processing
	ldy #0
	lda (.rb_read_buffer_ptr), y

	; set border and background colors
	sta $d020
	sta $d021

	; increment read buffer pointer
	inc .rb_read_buffer_ptr
	bne irq_inc_raster_line
	inc .rb_read_buffer_ptr+1

irq_inc_raster_line:
	; increment to next raster line
	ldy .rb_cur_line
	lda .rb_cur_line+1
	beq irq_inc_low

	; check if we hit the last screen line (PAL has 312 lines, so 312-256=56)
	iny
	cpy #56
	bne irq_set_vic_line

	; we hit the last line, so reset to line zero
	lda #0
	sta .rb_cur_line
	sta .rb_cur_line+1
	sta $d012
	lda #$1b
	sta $d011

	; swap read/write buffer pointers
	lda #1
	eor .rb_write_index
	sta .rb_write_index
	jsr rb_set_buffer_ptrs

	; and flag that we need an update for the next frame
	lda #1
	sta .rb_need_update
	jmp irq_done

irq_inc_low:
	iny

irq_set_vic_line:
	sty .rb_cur_line
	sty $d012
	bne irq_done

	; handle rollover (screen line 255 -> 256)
	inc .rb_cur_line+1
	lda #$9b				; set high bit (bit 7) in VIC for irqs on raster lines >= 256
	sta $d011

irq_done:
	; restore registers and return
	lda .irq_temp
	ldy .irq_temp+1
	rti


; set read/write buffer pointers, zero flag specifies write buffer index
rb_set_buffer_ptrs:
	bne _rb_sbp_write_buf_1

	; ZF clear: use buffer 1 for read and 0 for write
	lda #<.rb_color_buffer_1
	sta .rb_read_buffer_ptr
	lda #>.rb_color_buffer_1
	sta .rb_read_buffer_ptr+1

	lda #<.rb_color_buffer_0
	sta .rb_write_buffer_ptr
	lda #>.rb_color_buffer_0
	sta .rb_write_buffer_ptr+1
	rts

_rb_sbp_write_buf_1:
	; ZF set: use buffer 0 for read and 1 for write
	lda #<.rb_color_buffer_0
	sta .rb_read_buffer_ptr
	lda #>.rb_color_buffer_0
	sta .rb_read_buffer_ptr+1

	lda #<.rb_color_buffer_1
	sta .rb_write_buffer_ptr
	lda #>.rb_color_buffer_1
	sta .rb_write_buffer_ptr+1
	rts


.rb_cur_line			!word $00
.rb_color_buffer_0		!fill 312, $00
.rb_color_buffer_1		!fill 312, $00
.rb_write_index			!byte $01
.rb_need_update			!byte $01

.rb0_colors				!byte $06, $0e, $03, $01, $01, $03, $0e, $06
.rb0_ypos				!word $00
.rb0_ydir				!byte $01			; 0=up, 1=down

