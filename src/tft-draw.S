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
;               TFT DRAWING FUNCTIONS
; --------------------------------------------------
#include "avr-linux.h"
#include "tft-registers.S"
#include "tft-colors.S"
#include "tft-writing.S"
#include "tft-char-ROM.S"
#include "tft-delay.S"

CSEG

TFT_START:
	CALL TFT_INIT_PORTS
	CALL TFT_ANALOG_INIT
	CALL TFT_BEGIN

	LDI R25, 1
	CALL MILI_DELAY
	RET

TFT_RESET:
	CS_IDLE
	WR_IDLE
	RD_IDLE

	TFT_RESET_LOW
	LDI R25, 2		; Magic recipe
	CALL MILI_DELAY
	TFT_RESET_HIGH

	CS_ACTIVE
	CD_COMMAND
	CLR R25
	CALL WRITE_8
	WR_STROBE
	WR_STROBE
	WR_STROBE
	CS_IDLE
	RET

TFT_INIT_PORTS:
	PUSH R19

	INPUT R19, TFT_CONTROL_DDR
	ORI R19, LCD_CONTROL_PORT_MASK
	OUTPUT TFT_CONTROL_DDR, R19

	CALL SET_WRITE_DIR
	POP R19
	RET

; Defines the valid range for the screen addresses.
; The range is set by a pair of points (x1, y1) and
; (x2, y2) which makes a rectangle. Preconditions:
; x2 > x1 and y2 > y1.
; Each coordinate is a 16 bit number, and all of them
; are passed through the following registers:
;     x1 in R25:R24
;     y1 in R23:R22
;     x2 in R21:R20
;     y2 in R19:R18
TFT_SET_ADDR_WINDOW:
	PUSH R16
	PUSH R17
	PUSH R20
	PUSH R21
	PUSH R22
	PUSH R23
	PUSH R25

	CS_ACTIVE
	; Save y1 value
	MOVW R16, R22 ; R17:R16 = R23:R22
	; Define column address set
	; WRITE_REGISTER_32(ILI9341_COLADDRSET, x1, x2)
	MOV R23, R25
	MOV R22, R24
	LDI R25, ILI9341_COLADDRSET
	CALL WRITE_REGISTER_32
	; Define rows address set
	; WRITE_REGISTER_32(ILI9341_COLADDRSET, y1, y2)
	MOVW R22, R16 ; R23:R22 = R17:R16
	MOVW R20, R18 ; R21:R20 = R19:R18
	LDI R25, ILI9341_PAGEADDRSET
	CALL WRITE_REGISTER_32

	CS_IDLE

	POP R25
	POP R23
	POP R22
	POP R21
	POP R20
	POP R17
	POP R16
	RET

TFT_BEGIN:
	CALL TFT_RESET
	LDI R25, 200
	CALL MILI_DELAY

	CS_ACTIVE

	LDI R25, ILI9341_SOFTRESET
	LDI R24, 0x0
	CALL WRITE_REGISTER_8

	LDI R25, 50
	CALL MILI_DELAY

	LDI R25, ILI9341_DISPLAYOFF
	LDI R24, 0x0
	CALL WRITE_REGISTER_8

	LDI R25, ILI9341_POWERCONTROL1
	LDI R24, 0x23
	CALL WRITE_REGISTER_8

	LDI R25, ILI9341_POWERCONTROL2
	LDI R24, 0x10
	CALL WRITE_REGISTER_8

	LDI R25, HIGH(ILI9341_VCOMCONTROL1)
	LDI R24, LOW(ILI9341_VCOMCONTROL1)
	LDI R23, 0x2B
	LDI R22, 0x2B
	CALL WRITE_REGISTER_16

	LDI R25, ILI9341_VCOMCONTROL2
	LDI R24, 0xC0
	CALL WRITE_REGISTER_8

	LDI R25, ILI9341_MEMCONTROL
	LDI R24, ILI9341_MADCTL_MY | ILI9341_MADCTL_BGR
	CALL WRITE_REGISTER_8

	LDI R25, ILI9341_PIXELFORMAT
	LDI R24, 0x55
	CALL WRITE_REGISTER_8

	LDI R25, HIGH(ILI9341_FRAMECONTROL)
	LDI R24, LOW(ILI9341_FRAMECONTROL)
	LDI R23, 0x00
	LDI R22, 0x1B
	CALL WRITE_REGISTER_16

	LDI R25, ILI9341_ENTRYMODE
	LDI R24, 0x07
	CALL WRITE_REGISTER_8

	LDI R25, ILI9341_SLEEPOUT
	LDI R24, 0x00
	CALL WRITE_REGISTER_8

	LDI R25, 150
	CALL MILI_DELAY

	LDI R25, ILI9341_DISPLAYON
	LDI R24, 0x00
	CALL WRITE_REGISTER_8

	RET

; Fills the screen with a given color. The color is
; received on R25:R24.
TFT_FILL_SCREEN:
	PUSH R16
	PUSH R17

	MOVW R16, R24 ; R17:R16 = R25:R24
	CLR R25
	CLR R24
	CLR R23
	CLR R22
	LDI R21, HIGH(TFT_WIDTH - 1)
	LDI R20, LOW(TFT_WIDTH - 1)
	LDI R19, HIGH(TFT_HEIGHT - 1)
	LDI R18, LOW(TFT_HEIGHT - 1)
	CALL TFT_FILL_RECT

	POP R17
	POP R16
	RET

; Draws a filled rectangle in a range of screen
; addresses. The range is set by a point (x, y) on
; the upper-left vertex of the rectangle and a witdh
; and height. Each value is a 16 bit number, and all
; of them are passed through the following registers:
;      x in R25:R24
;      y in R23:R22
;  width in R21:R20
; height in R19:R18
;  color in R17:R16
TFT_FILL_RECT_HW:
	PUSH R18
	PUSH R19
	PUSH R20
	PUSH R21

	ADD R20, R24
	ADC R21, R25

	ADD R18, R22
	ADC R19, R23
	CALL TFT_FILL_RECT

	POP R21
	POP R20
	POP R19
	POP R18
	RET

; Draws a filled rectangle in a range of screen
; addresses. The range is set by a pair of points
; (x1, y1) and (x2, y2) which makes a rectangle.
; Precondition x2 > x1 and y2 > y1. Each value is a
; 16 bit number, and all of them are passed through
; the following registers:
;     x1 in R25:R24
;     y1 in R23:R22
;     x2 in R21:R20
;     y2 in R19:R18
;  color in R17:R16
TFT_FILL_RECT:
	PUSH R14
	PUSH R15
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
	PUSH R28
	PUSH R29

	CALL TFT_INIT_PORTS
	; x2-x1 <--- R29:R28
	; y2-y1 <--- R27:R26
	MOVW R28, R20
	SUB R28, R24
	SBC R29, R25
	MOVW R26, R18
	SUB R26, R22
	SBC R27, R23

	; setAddrWindow(x1, y1, x2, y2)
	CALL TFT_SET_ADDR_WINDOW
	; Loop to print every pixel
	CS_ACTIVE
	CD_COMMAND
	LDI R25, ILI9341_MEMORYWRITE
	CALL WRITE_8
	CD_DATA;

	; for (int x = (x2-x1); x > 0; x--)
	;     for (int y = (y2-y1); y > 0; y--)
	;			WRITE_8(hi(color))
	;			WRITE_8(lo(color))
	; x = R29:R28
	; y = R27:R26
	ADIW R28, 1
	ADIW R26, 1
	MOVW R14, R26 ; R15:R14 = R27:R26

	; If hi(color) == lo(color), write color once
	; the rest of the loop will only do WR_STROBE
	CP R16, R17
	BRNE tft_fill_rect_loop_x
	MOV R25, R17
	CALL WRITE_8
	WR_STROBE

tft_fill_rect_loop_x:
	MOVW R26, R14 ; R27:R26 = R15:R14
	CPI R28, 0x0
	BRNE tft_fill_rect_loop_y
	CPI R29, 0x0
	BRNE tft_fill_rect_loop_y
	RJMP tft_fill_rect_exit

tft_fill_rect_loop_y:
	CPI R27, 0x0
	BRNE tft_fill_rect_color_pixel
	CPI R26, 0x0
	BRNE tft_fill_rect_color_pixel
	SBIW R28, 1
	RJMP tft_fill_rect_loop_x

tft_fill_rect_color_pixel:
	; Skip optimization
	CP R16, R17
	BRNE tft_fill_rect_color_pixel_diff

tft_fill_rect_color_pixel_same:
  	WR_STROBE
	WR_STROBE
	SBIW R26, 1
	RJMP tft_fill_rect_loop_y

tft_fill_rect_color_pixel_diff:
	; WRITE_8(high(color))
	MOV R25, R17
	CALL WRITE_8
	; WRITE_8(low(color))
	MOV R25, R16
	CALL WRITE_8
	SBIW R26, 1
	RJMP tft_fill_rect_loop_y

tft_fill_rect_exit:
	POP R29
	POP R28
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
	POP R15
	POP R14
	RET

; Draws a character c on the screen with upper-left
; position (x, y), colour fg and size s. Each value
; is 16 bits, and are passed through registers:
;       x in R25:R24
;       y in R23:R22
;  char c in R21:R20 (R21 not used)
;      fg in R19:R18
;       s in R17:R16 (R17 not used)
TFT_DRAW_CHAR:
	PUSH R11
	PUSH R12
	PUSH R13
	PUSH R14
	PUSH R15
	PUSH R26
	PUSH R27
	PUSH R30
	PUSH R31
	; Save size in temporal registers
	CLR R15
	MOV R14, R16
	; Save color in R17:R16 to prepare for fill rect
	MOVW R16, R18
	; Save y coordinate
	MOVW R12, R22
	; Z = tft_char_ROM + (c*5)
	LDI ZH, HIGH(tft_char_ROM)
	LDI ZL, LOW(tft_char_ROM)

	LDI R26, 0x5
	MUL R20, R26
	ADD ZL, R0
	ADC ZH, R1

	CLR R26 ; R26 = i
	; Set width and height to size
	CLR R21
	MOV R20, R14
	CLR R19
	MOV R18, R14

tft_draw_char_next_line:
	CPI R26, TFT_CHAR_W
	BREQ tft_draw_char_exit

	CLR R27 ; R27 = j
	; Get char ROM data
	LPM R11, Z+		; line = font[char*5 + i]
	CPI R26, 0x5
	BRNE tft_draw_char_line_loop
	CLR R11

tft_draw_char_line_loop:
  	CPI R27, TFT_CHAR_H
	BREQ tft_draw_char_end_line
	INC R27
	SBRS R11, 0 ; line & 0x1
	RJMP tft_draw_char_line_loopNext

tft_drawChar_drawRect:
	; fillRect_HW(x+(i*size), y+(j*size), size, size, fg | bg);
	CALL TFT_FILL_RECT_HW

tft_draw_char_line_loopNext:
	; y += size
	ADD R22, R14
	ADC R23, R15
	LSR R11
	RJMP tft_draw_char_line_loop

tft_draw_char_end_line:
  	INC R26
	; x += size
	ADD R24, R14
	ADC R25, R15
	MOVW R22, R12 ; R23:R22 = R13:12
	RJMP tft_draw_char_next_line

tft_draw_char_exit:
	POP R31
	POP R30
	POP R27
	POP R26
	POP R15
	POP R14
	POP R13
	POP R12
	POP R11
	RET

