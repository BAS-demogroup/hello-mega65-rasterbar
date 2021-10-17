!macro reserve_int {
	!fill int_sizeof, $00
}

!macro reserve_int64 {
	!fill int64_sizeof, $00
}

!macro reserve_long {
	!fill long_sizeof, $00
}

!macro reserve_ptr {
	!fill ptr_sizeof, $00
}

!macro reserve_short {
	!fill short_sizeof, $00
}

!macro BasicUpstart65 {
	* = $2001
	
	;!set .addrStr = toIntString(.addr)

	!byte $09,$20			;End of command marker (first byte after the 00 terminator)
	!byte $0a,$00			;10
	!byte $fe,$02,$30,$00	;BANK 0
	!byte <.end, >.end		;End of command marker (first byte after the 00 terminator)
	!byte $14,$00			;20
	!byte $9e				;SYS
	!text "8213"
	!byte $00
.end:
	!byte $00,$00			;End of basic terminators
}

!macro MapIO {
	lda #0
	tax
	tay
	taz
	map
	eom

	lda #$37
	sta $00
	lda #$35
	sta $01
}

!macro enable_40mhz {
	lda #65
	sta $00
}

!macro RunDMAJob .JobPointer {
	lda #(.JobPointer >> 16)
	sta $D702
	sta $D704
	lda #>.JobPointer
	sta $D701
	lda #<.JobPointer
	sta $D705
}

!macro DMAFillJob .SourceByte, .Destination, .Length, .Chain {
	!byte $00
	!if (.Chain) {
		!byte $07
	} else {
		!byte $03
	}
	
	!word .Length
	!word .SourceByte
	!byte $00
	!word .Destination & $FFFF
	!byte ((.Destination >> 16) & $0F)
	
	!if (.Chain) {
		!word $0000
	}
}

!macro DMACopyJob .Source, .Destination, .Length, .Chain, .Backwards {
	!byte $00 //No more options
	!if(.Chain) {
		!byte $04 //Copy and chain
	} else {
		!byte $00 //Copy and last request
	}	
	
	!set .backByte = 0
	!if(.Backwards) {
		!set .backByte = $40
		!set .Source = .Source + .Length - 1
		!set .Destination = .Destination + .Length - 1
	}
	!word .Length //Size of Copy

	!word .Source & $ffff
	!byte (.Source >> 16) + .backByte

	!word .Destination & $ffff
	!byte ((.Destination >> 16) & $0f)  + .backByte
	!if(.Chain) {
		!word $0000
	}
}

!macro short_copy .source, .destination, .length {
	ldx #.length
-	lda .source, x
	sta .destination, x
	dex
	bpl -
}

!macro short_fill .fill_byte, .destination, .length {
	ldx #.length
	lda #.fill_byte
-	sta .destination
	dex
	bpl -
}

!macro long_fill .fill_byte, .destination, .length {
	lda #<.length
	sta fill_dma + 2
	lda #>.length
	sta fill_dma + 3
	lda #.fill_byte
	sta fill_dma + 4
	lda .destination
	sta fill_dma + 7
	lda .destination + 1
	sta fill_dma + 8
	+RunDMAJob fill_dma
}

!macro long_copy .source, .destination, .length {
	lda #<.length
	sta copy_dma + 2
	lda #>.length
	sta copy_dma + 3
	lda #<.source
	sta copy_dma + 4
	lda #>.source
	sta copy_dma + 5
	lda #<.destination
	sta copy_dma + 7
	lda #>.destination
	sta copy_dma + 8
	+RunDMAJob copy_dma
}

!macro set_zp .zp, .ptr {
	lda .ptr
	sta .zp
	lda .ptr + 1
	sta .zp + 1
}

!macro store_word .value, .destination {
	lda #<.value
	sta .destination
	lda #>.value
	sta .destination + 1
}

!macro store_word_to_zp_offset .value, .zp, .offset {
	ldy #.offset
	lda #<.value
	sta (.zp), y
	iny
	lda #>.value
	sta (.zp), y
}

!macro store_word_to_zp_y .value, .zp {
	iny
	lda #<.value
	sta (.zp), y
	iny
	lda #>.value
	sta (.zp), y
}

!macro copy_ptr .ptr, .destination {
	lda .ptr
	sta .destination
	lda .ptr + 1
	sta .destination + 1
}

!macro copy_word_to_zp_offset .source, .zp, .offset {
	ldy #.offset
	lda .source
	sta (.zp), y
	iny
	lda .source + 1
	sta (.zp), y
}

!macro copy_word_to_zp_y .source, .zp {
	iny
	lda .source
	sta (.zp), y
	iny
	lda .source + 1
	sta (.zp), y
}

!macro copy_long_to_zp .source, .zp, .length {
	ldy #.length
-	lda .source, y
	sta (.zp), y
	dey
	bpl -
}

!macro copy_word_from_zp_offset .zp, .destination, .offset {
	ldy #.offset
	lda (.zp), y
	sta .destination
	iny
	lda (.zp), y
	sta .destination + 1
}

!macro copy_word_from_zp_y .zp, .destination {
	iny
	lda (.zp), y
	sta .destination
	iny
	lda (.zp), y
	sta .destination + 1
}
