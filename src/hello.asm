!source "macros.asm"
	
	+BasicUpstart65
 
!zone main {
	sei
	
	+enable_40mhz
	
	rts

}

heap_bottom:
