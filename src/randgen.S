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
;                 RANDGEN FUNCTIONS
; --------------------------------------------------
	.GLOBAL SETUP_RANDGEN
	.GLOBAL RANDGEN

	.EQU RANDGEN_ITERATIONS, 5
	.EQU RANDGEN_MAGIC, 0xAA

CSEG

; Setups randgen_buffer variable for using RANDGEN.
; Basically, loads the RANDGEN_MAGIC value to the
; randgen_buffer (so it aint start with a 0 value). 
SETUP_RANDGEN:
	LDI R18, RANDGEN_MAGIC
	STS randgen_buffer, R18
	RET

; Returns a random N bits number on R24. The value
; of N is received on R24. It uses timer0 register
; value as an entropy source, looping 
; RANDGEN_ITERATIONS times performing some XORs. The 
; randgen_buffer is used for persisting the random 
; values through calls.
RANDGEN:
	; IF N > 8 or N == 0, panic (return 0)
	MOV R22, R24
	CLR R24
	CPI R22, 8
	BRSH randgen_panic
	CPI R22, 0
	BREQ randgen_panic
	; Load the randgen_buffer and do randomness
	LDS R18, randgen_buffer
	; Load timer 0 value and XOR it with the
	; previous randgen_buffer value
	INPUT R19, TCNT0
	EOR R18, R19
	
	; Now do RANDGEN_ITERATIONS XORs
	CLR R19
randgen_loop:
	CLR R20
	CLR R21
	SBRS R18, 7
	INC R20	
	SBRS R18, 6
	INC R21
	EOR R21, R20
	LSL R18
	ADD R18, R21

	INC R19
	CPI R19, RANDGEN_ITERATIONS
	BRNE randgen_loop

	STS randgen_buffer, R18
	; Since we must return a N bits random number
	; we must do R18 % (2**N). Note this is the 
	; same than taking the least N significative 
	; bits from R18 register.
mask_loop:
	LSL R24
	INC R24
	DEC R22
	BRNE mask_loop
	; R24 is now a mask of N bits
	AND R24, R18
randgen_panic:
	RET

	DSEG
; Randgen buffer for generating random numbers
randgen_buffer:
	BYTE 1

