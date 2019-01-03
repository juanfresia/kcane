; --------------------------------------------------
;       KEEP CODING AND NOBODY EXPLODES (KCANE)
; --------------------------------------------------
; Project for 66.09.Laboratorio de Microcomputadoras
; Faculty of Engineering, University of Buenos Aires
;
; By Ana Czarnitzki, Alejandro García & Juan Fresia
; 
; --------------------------------------------------
;
; --------------------------------------------------
;               INTERRUPT FUNCTIONS
; --------------------------------------------------
	CSEG

	.ORG 0
	JMP main
	
	; Timer0 interrupt
	.ORG TIMER0_OVF_ISR
	JMP T0_ISR
	
	.ORG _VECTORS_SIZE

; Setups the used interrupts and their registers.
; Note this function DOES NOT enable interrupts.
SETUP_INTERRUPTS:
	; Configure timer0 interrupt to count up to
	; 1 second with an extra count variable.
	; Making timer0 count 157 times with a
	; 1024:1 prescale and CLK of 16MHZ makes
	; it count 1024*157/16M = 0.01 second. Hence
	; count must count up to 100 for 1 second.
	CLR R20
	STS count, R20

	LDI R20, (1 << TOIE0)
	OUTPUT TIMSK0, R20

	LDI R20, 99 ; 256 - 99 = 157
	OUTPUT TCNT0, R20
	LDI R20, 0x05 ; Prescaler 1024:1
	OUTPUT TCCR0B, R20
	RET

; Timer0 interrupt handler that will be called every
; 0.01 seconds. Once the count variable reaches 100
; (i.e. 1 second elapsed), it must DEC_DISPLAYS.
T0_ISR:
	; First store the called saved registers 
	; since we don't know what important value
	; they could have right now
	PUSH R18
	PUSH R19
	PUSH R20
	PUSH R21
	PUSH R22
	PUSH R23
	PUSH R24
	PUSH R25
	PUSH R26
	PUSH R27
	PUSH R30
	PUSH R31
	INPUT R18, SREG ; Very important
	PUSH R18 
	LDI R20, 99
	OUTPUT TCNT0, R20

	LDS R20, count
	INC R20
	CPI R20, 100
	BREQ clear_count
	RJMP store_count
clear_count:
	; If here, one second has elapsed
	LDI R24, 1
	STS second_has_passed, R24
	CLR R20
store_count:
	STS count, R20
	; Restore the saved registers
	POP R18
	OUTPUT SREG, R18
	POP R31
	POP R30
	POP R27
	POP R26
	POP R25
	POP R24
	POP R23
	POP R22
	POP R21
	POP R20
	POP R19
	POP R18
	RETI
	
	DSEG
; Auxiliar counter for timer0 interrupt
count: 
	BYTE 1
