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
;                TFT TOUCH FUNCTIONS
; --------------------------------------------------
	; TouchScreen control pins
	; xp (x+) H5
	; xm (x-) F2
	; yp (y+) F3
	; ym (y-) H6

	.EQU TOUCH_XP_DDR, DDRH
	.EQU TOUCH_XM_DDR, DDRF
	.EQU TOUCH_YP_DDR, DDRF
	.EQU TOUCH_YM_DDR, DDRH

	.EQU TOUCH_XP_PORT, PORTH
	.EQU TOUCH_XM_PORT, PORTF
	.EQU TOUCH_YP_PORT, PORTF
	.EQU TOUCH_YM_PORT, PORTH

	.EQU TOUCH_XP_MASK, 0x20
	.EQU TOUCH_XM_MASK, 0x04
	.EQU TOUCH_YP_MASK, 0x08
	.EQU TOUCH_YM_MASK, 0x40

	.EQU TOUCH_Y_ADC, 0x3
	.EQU TOUCH_X_ADC, 0x2

	.EQU ADC_CHAN_MASK, 0x0F

CSEG

; Configures the ADCs used for reading the touched
; point on screen coordinaates.
TFT_ANALOG_INIT:
	PUSH R16

	LDI R16, (1 << REFS0)
	STS ADMUX, R16
	LDI R16, (1 << ADEN | 1 << ADPS0 | 1 << ADPS1 | 1 << ADPS2)
	STS ADCSRA, R16

	POP R16
	RET

; ANALOG_READ performs an ADC read from a channel
; (ADC pin) indicated by register R25.
; Result is stored in R25:R24.
ANALOG_READ:
	PUSH R16
	PUSH R17
	; Trigger ADC read
	LDS R16, ADMUX
	ANDI R16, ~ADC_CHAN_MASK
	ANDI R25, ADC_CHAN_MASK
	OR R16, R25
	STS ADMUX, R16
	LDI R16, (1 << ADSC)
	LDS R17, ADCSRA
	OR R17, R16
	STS ADCSRA, R17
adc_wait:
	LDS R17, ADCSRA
	SBRC R17, ADSC
	RJMP adc_wait

	LDS R24, ADCL
	LDS R25, ADCH

	POP R17
	POP R16
	RET

; Performs an ADC conversion of the x coordinate
; with ANALOG_READ. Returns the result on R25:R24.
TFT_READ_TOUCH_X:
	PUSH R17
	PUSH R16

	; yp and ym as input with port = 0
	INPUT R17, TOUCH_YP_DDR
	ANDI R17, ~TOUCH_YP_MASK
	OUTPUT TOUCH_YP_DDR, R17

	LDS R17, TOUCH_YM_DDR
	ANDI R17, ~TOUCH_YM_MASK
	STS TOUCH_YM_DDR, R17

	INPUT R17, TOUCH_YP_PORT
	ANDI R17, ~TOUCH_YP_MASK
	OUTPUT TOUCH_YP_PORT, R17

	LDS R17, TOUCH_YM_PORT
	ANDI R17, ~TOUCH_YM_MASK
	STS TOUCH_YM_PORT, R17

	; xp as output high
	LDS R17, TOUCH_XP_DDR
	ORI R17, TOUCH_XP_MASK
	STS TOUCH_XP_DDR, R17

	LDS R17, TOUCH_XP_PORT
	ORI R17, TOUCH_XP_MASK
	STS TOUCH_XP_PORT, R17

	; xm as output low
	INPUT R17, TOUCH_XM_DDR
	ORI R17, TOUCH_XM_MASK
	OUTPUT TOUCH_XM_DDR, R17

	INPUT R17, TOUCH_XM_PORT
	ANDI R17, ~TOUCH_XM_MASK
	OUTPUT TOUCH_XM_PORT, R17

	; Returns the read value in R25:R24.
	; Yes, this is right, the touchscreen coords
	; are inverted with respect to the TFT ones.
	LDI R25, TOUCH_Y_ADC
	CALL ANALOG_READ

	POP R16
	POP R17
	RET

; Performs an ADC conversion of the y coordinate
; with ANALOG_READ. Returns the result on R25:R24.
TFT_READ_TOUCH_Y:
	PUSH R17
	PUSH R16

	; xp and xm as input with port = 0
	INPUT R17, TOUCH_XP_DDR
	ANDI R17, ~TOUCH_XP_MASK
	OUTPUT TOUCH_XP_DDR, R17

	INPUT R17, TOUCH_XM_DDR
	ANDI R17, ~TOUCH_XM_MASK
	OUTPUT TOUCH_XM_DDR, R17

	INPUT R17, TOUCH_XP_PORT
	ANDI R17, ~TOUCH_XP_MASK
	OUTPUT TOUCH_XP_PORT, R17

	INPUT R17, TOUCH_XM_PORT
	ANDI R17, ~TOUCH_XM_MASK
	OUTPUT TOUCH_XM_PORT, R17

	; yp as output high
	INPUT R17, TOUCH_YP_DDR
	ORI R17, TOUCH_YP_MASK
	OUTPUT TOUCH_YP_DDR, R17

	INPUT R17, TOUCH_YP_PORT
	ORI R17, TOUCH_YP_MASK
 	OUTPUT TOUCH_YP_PORT, R17

	; ym as output low
	INPUT R17, TOUCH_YM_DDR
	ORI R17, TOUCH_YM_MASK
	OUTPUT TOUCH_YM_DDR, R17

	INPUT R17, TOUCH_YM_PORT
	ANDI R17, ~TOUCH_YM_MASK
	OUTPUT TOUCH_YM_PORT, R17

	; Returns the read value in R25:R24.
	; Read ADC from XP (coordintes are inverted).
	LDI R25, TOUCH_X_ADC
	CALL ANALOG_READ

	POP R16
	POP R17
	RET

; Reads both x and y analog pins from touchscreen
; and return its readings in registers:
; z2 (from yp): R25:R24
; z1 (from xm): R23:R22
TFT_READ_TOUCH_Z:
	PUSH R16
	PUSH R17

	; xp as output low
	INPUT R17, TOUCH_XP_DDR
	ORI R17, TOUCH_XP_MASK
	OUTPUT TOUCH_XP_DDR, R17

	INPUT R17, TOUCH_XP_PORT
	ANDI R17, ~TOUCH_XP_MASK
	OUTPUT TOUCH_XP_PORT, R17

	; ym as output high
	INPUT R17, TOUCH_YM_DDR
	ORI R17, TOUCH_YM_MASK
	OUTPUT TOUCH_YM_DDR, R17

	INPUT R17, TOUCH_YM_PORT
	ORI R17, TOUCH_YM_MASK
	OUTPUT TOUCH_YM_PORT, R17

	; xm and yp as input low
	INPUT R17, TOUCH_XM_DDR
	ANDI R17, ~TOUCH_XM_MASK
	OUTPUT TOUCH_XM_DDR, R17

	INPUT R17, TOUCH_XM_PORT
	ANDI R17, ~TOUCH_XM_MASK
	OUTPUT TOUCH_XM_PORT, R17

	INPUT R17, TOUCH_YP_DDR
	ANDI R17, ~TOUCH_YP_MASK
	OUTPUT TOUCH_YP_DDR, R17

	INPUT R17, TOUCH_YP_PORT
	ANDI R17, ~TOUCH_YP_MASK
 	OUTPUT TOUCH_YP_PORT, R17

	; Get both analog readings
	; z1 = ANALOG_READ xm (R25:R24)
	; z2 = ANALOG_READ yp (R23:R22)
	LDI R25, TOUCH_X_ADC
	CALL ANALOG_READ

	LDI R23, HIGH(1024)
	LDI R22, LOW(1024)

	SUB R22, R24
	SBC R23, R25

	LDI R25, TOUCH_Y_ADC
	CALL ANALOG_READ
	LDI R17, HIGH(1024)
	LDI R16, LOW(1024)
	SUB R16, R24
	SBC R17, R25
	MOV R24, R16 ; R25:R24 = R17:R16

	POP R16
	POP R17
	RET

; Performs an scaling of the x coordinate returned
; from ANALOG_READ and maps it to an interval suited
; for the screen. The mapping range is empirical and
; based on tftpaint example. The mapping is:
; [120, 920] ---> [0, 239]
; Which can be done like this:
; x' = (x - 120) * 239/800
; The multiplication is approximated with 5/16.
; The x and x' values are 16 bit numbers passed and
; returned through registers R25:R24.
TFT_SCALE_COORD_X:
	PUSH R16
	PUSH R17
	; x = x - 120
	LDI R16, LOW(120)
	LDI R17, HIGH(120)
	SUB R24, R16
	SBC R25, R17
	; x = x * 5
 	; This can never go out of range
	LDI R16, 5
	MUL R24, R16
	MOV R24, R0
	MOV R17, R1
	MUL R25, R16
	MOV R25, R0
	ADD R25, R17
	; x = x / 16 = x >> 4
	LSR R25
	ROR R24
	LSR R25
	ROR R24
	LSR R25
	ROR R24
	LSR R25
	ROR R24

	POP R17
	POP R16
	RET

; Performs an scaling of the y coordinate returned
; from ANALOG_READ and maps it to an interval suited
; for the screen. The mapping range is empirical and
; based on tftpaint example. The mapping is:
; [120, 940] ---> [0, 319]
; Which can be done like this:
; y' = (y - 120) * 319/820
; The multiplication is approximated with 3/8.
; The y and y' values are 16 bit numbers passed and
; returned through registers R25:R24.
TFT_SCALE_COORD_Y:
	PUSH R16
	PUSH R17
	; y = y - 120
	LDI R16, LOW(120)
	LDI R17, HIGH(120)
	SUB R24, R16
	SBC R25, R17
	; y = y * 3
 	; This can never go out of range
	LDI R16, 3
	MUL R24, R16
	MOV R24, R0
	MOV R17, R1
	MUL R25, R16
	MOV R25, R0
	ADD R25, R17
	; y = y / 8 = y >> 3
	LSR R25
	ROR R24
	LSR R25
	ROR R24
	LSR R25
	ROR R24

	POP R17
	POP R16
	RET

TFT_READ_TOUCH:
	PUSH R18
	PUSH R19
	PUSH R20
	PUSH R21
	PUSH R22
	PUSH R23
	PUSH R24
	PUSH R25

	CALL TFT_READ_TOUCH_X
	MOVW R18, R24 ; R19:R18 = R25:R24

	CALL TFT_READ_TOUCH_Y
	MOVW R20, R24 ; R21:R20 = R25:R24

	CALL TFT_READ_TOUCH_Z
	CPI R24, 0x32
	BRSH tft_read_touch_valid
	CPI R22, 0x32
	BRSH tft_read_touch_valid

	LDI R25, 0x0
	STS TOUCH_Z_VALID, R25
	RJMP tft_read_touch_exit

tft_read_touch_valid:

	LDI R25, 0xFF
	STS TOUCH_Z_VALID, R25

	MOVW R24, R20 ; R25:R24 = R21:R20
	CALL TFT_SCALE_COORD_Y
	STS TOUCH_Y_HIGH, R25
	STS TOUCH_Y_LOW, R24

	MOVW R24, R18 ; R25:R24 = R19:R18
	CALL TFT_SCALE_COORD_X
	STS TOUCH_X_HIGH, R25
	STS TOUCH_X_LOW, R24

tft_read_touch_exit:
	POP R25
	POP R24
	POP R23
	POP R22
	POP R21
	POP R20
	POP R19
	POP R18
	RET

DSEG

TOUCH_X_HIGH: BYTE 1
TOUCH_X_LOW: BYTE 1
TOUCH_Y_HIGH: BYTE 1
TOUCH_Y_LOW: BYTE 1
TOUCH_Z_VALID: BYTE 1
