; --------------------------------------------------
;    KEEP CODING AND NOBODY EXPLODES (KCANE)
; --------------------------------------------------
; Project for 66.09.Laboratorio de Microcomputadoras
; Faculty of Engineering, University of Buenos Aires
;
; By Ana Czarnitzki, Alejandro García & Juan Fresia
; 
; --------------------------------------------------
;
; --------------------------------------------------
;                TFT DELAY FUNCTIONS
; --------------------------------------------------

; Delays for (R25 + 1) * 0.5 microseconds. Since R25
; is an 8 bit register, the maximum possible delay is
; 128 microseconds.
HALF_MICRO_DELAY:
	CLR R18                     ; 1 cycle
	NOP                         ; 1 cycle
half_micro_delay_loop:          ; 8 cycle loop = 500 ns
	CP R18, R25                 ; 1 cycle
	BREQ half_micro_delay_end   ; 1 cycle (non-taken)
	NOP
	NOP
	NOP                         ; 3 nop cycles
	INC R18                     ; 1 cycle
	RJMP half_micro_delay_loop  ; 2 cycles
half_micro_delay_end:
	RET                         ; 5 cycles

; Delays for R25 miliseconds. Since R25 is an 8 bit
; register, the maximum possible delay is 256 ms.
MILI_DELAY:
	PUSH R16
	PUSH R17
	CLR R16
	MOV R24, R25
mili_delay_loop:
	CP R16, R24
	BREQ mili_delay_end
	INC R16
	LDI R25, 200
	LDI R17, 10
mili_delay_loop2:
	CPI R17, 0
	BREQ mili_delay_loop
	DEC R17
	PUSH R16
	CALL HALF_MICRO_DELAY	; 100 us
	POP R16
	RJMP mili_delay_loop2
mili_delay_end:
	POP R17
	POP R16
	RET
