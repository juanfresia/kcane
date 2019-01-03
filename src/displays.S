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
;                 DISPLAY FUNCTIONS
; --------------------------------------------------
	.GLOBAL SETUP_DISPLAYS
	.GLOBAL SHOW_DISPLAYS
	.GLOBAL DEC_DISPLAYS
	.GLOBAL CHECK_DISPLAYS_ARE_ZERO

	.EQU DISPLAYS_PORT, PORTL
	.EQU DISPLAYS_DDR, DDRL
	.EQU DISPLAYS_AMOUNT, 4
	.EQU PLAYING_MINUTES, 6

	CSEG

; Initializes the displays array in RAM memory. Uses
; the PLAYING_MINUTES constant as the initial value
; for a countdown in the displays.
SETUP_DISPLAYS:
	LDI R18, 0xFF
	OUTPUT DISPLAYS_DDR, R18
	LDI ZL, LOW(displays_ram)
	LDI ZH, HIGH(displays_ram)
	
	LDI R18, DISPLAYS_AMOUNT
	CLR R1
setup_displays_loop:
	ST Z+, R1
	DEC R18
	BRNE setup_displays_loop
	; Load the PLAYING_MINUTES tens and units
	LDI R18, (PLAYING_MINUTES / 10)
	STS displays_ram + 3, R18
	LDI R18, (PLAYING_MINUTES % 10)
	STS displays_ram + 2, R18
	RET

; Performs a displays multiplexing, showing in the
; displays the values of displays_ram. DISPLAYS_PORT
; is used for the multiplexing, being D0-D3 used as
; the control pins (connected to the ULN) and D4-D7 
; as the BCD number (connected to the 4511).
SHOW_DISPLAYS:
	LDI ZL, LOW(displays_ram)
	LDI ZH, HIGH(displays_ram)
	LDI R18, 0x1
next_display:
	LD R19, Z+
	SWAP R19
	ADD R19, R18
	OUTPUT DISPLAYS_PORT, R19

	PUSH R18	
	PUSH ZL	
	PUSH ZH
	CALL DISPLAY_DELAY
	POP ZH
	POP ZL
	POP R18

	LSL R18
	SBRS R18, DISPLAYS_AMOUNT
	RJMP next_display
	RET

; Decrement the displays by "1 second", considering
; the displays represent a MM:SS format. This
; function should be called every one second by the
; main program to properly make the countdown.
DEC_DISPLAYS:
	LDI ZL, LOW(displays_ram)
	LDI ZH, HIGH(displays_ram)
	; R18=display number (0 to DISPLAYS_AMOUNT)
	CLR R18
next_dec:
	LD R19, Z
	DEC R19
	
	CPI R19, 255 ; display = -1?
	BRNE dec_finished

	; If here, I have to decrement the
	; next display by 1 unit too
	LDI R19, 9 ; reset this display
	CPI R18, 1
	BRNE store_and_next_dec
	; Note the second display must be
	; reset to 5 and not to 9
	LDI R19, 5
store_and_next_dec:
	ST Z+, R19
	INC R18
	CPI R18, DISPLAYS_AMOUNT
	BRNE next_dec
	RET

dec_finished:
	ST Z, R19
	RET

; Checks if all the displays reached the 0 value
; (i.e. if the countdown is over). Returns true or
; false on R24 (false as 0, true as 1).
CHECK_DISPLAYS_ARE_ZERO:
	LDI ZL, LOW(displays_ram)
	LDI ZH, HIGH(displays_ram)
	CLR R24 ; R24 initially false
	; R18=display number (0 to DISPLAYS_AMOUNT)
	CLR R18;
check_zero_loop:	
	LD R19, Z+
	CPI R19, 0
	BRNE displays_not_zero
	INC R18
	CPI R18, DISPLAYS_AMOUNT
	BRNE check_zero_loop
	; If here, all displays are zero
	INC R24 ; R24 = true 
displays_not_zero:
	RET

; Performs a small delay: the time each display is
; turned on during the multiplexing.
DISPLAY_DELAY:
	LDI R18, 80
loop1:
	LDI R19, 20
loop2:
	LDI R20, 10
loop3:
	NOP
	DEC R20
	BRNE loop3

	DEC R19
	BRNE loop2

	DEC R18
	BRNE loop1
	RET

	DSEG
; Displays array in RAM memory
displays_ram:
	BYTE DISPLAYS_AMOUNT

