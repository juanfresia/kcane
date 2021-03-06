
.org 0x0
	JMP main

#include "tft-draw.S"
#include "tft-touch.S"

CSEG

main:
	CALL TFT_START

	CLR R25
	CLR R24
	CLR R23
	CLR R22
	LDI R21, HIGH(120)
	LDI R20, LOW(120)
	LDI R19, HIGH(160)
	LDI R18, LOW(160)
	LDI R17, 0xC4
	LDI R16, 0xC4
	CALL TFT_FILL_RECT_HW

	LDI R25, HIGH(120)
	LDI R24, LOW(120)
	CLR R23
	CLR R22
	LDI R21, HIGH(120)
	LDI R20, LOW(120)
	LDI R19, HIGH(160)
	LDI R18, LOW(160)
	LDI R17, 0xC6
	LDI R16, 0xC6
	CALL TFT_FILL_RECT_HW

	CLR R25
	CLR R24
	LDI R23, HIGH(160)
	LDI R22, LOW(160)
	LDI R21, HIGH(120)
	LDI R20, LOW(120)
	LDI R19, HIGH(320)
	LDI R18, LOW(320)
	LDI R17, 0x1C
	LDI R16, 0x1C
	CALL TFT_FILL_RECT

	LDI R25, HIGH(120)
	LDI R24, LOW(120)
	LDI R23, HIGH(160)
	LDI R22, LOW(160)
	LDI R21, HIGH(240)
	LDI R20, LOW(240)
	LDI R19, HIGH(320)
	LDI R18, LOW(320)
	LDI R17, 0xFF
	LDI R16, 0xE0
	CALL TFT_FILL_RECT

	LDI R25, 0x0
	LDI R24, 120
	LDI R23, 0x0
	LDI R22, 100
	LDI R21, 0x0
	LDI R20, 0x34
	LDI R19, 0xFF
	LDI R18, 0xFF
	LDI R17, 0x00
	LDI R16, 0x01
	CALL TFT_DRAW_CHAR
/*
	LDI R25, 0xFF
	LDI R24, 0xE0
	CALL TFT_FILL_SCREEN
*/
end:
	CALL TFT_READ_TOUCH
	LDS R25, TOUCH_Z_VALID
	CPI R25, 0
	BREQ skip

	LDS R25, TOUCH_X_HIGH
	LDS R24, TOUCH_X_LOW
	LDS R23, TOUCH_Y_HIGH
	LDS R22, TOUCH_Y_LOW

	LDI R21, 0x0
	LDI R20, 65
	LDI R19, 0xFF
	LDI R18, 0xFF
	LDI R17, 0x00
	LDI R16, 0x05
	CALL TFT_DRAW_CHAR

skip:
	LDI R25, 200
	CALL MILI_DELAY

	RJMP end

main2:
	JMP main
