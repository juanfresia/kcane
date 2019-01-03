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
;               TFT WRITING FUNCTIONS
; --------------------------------------------------
	#include "avr-linux.h"

	; TFT control pins
	; LCD_RD    TFT_CONTROL_PORT.0
	; LCD_WR    TFT_CONTROL_PORT.1
	; LCD_CD    TFT_CONTROL_PORT.2
	; LCD_CS    TFT_CONTROL_PORT.3
	; LCD_RESET TFT_CONTROL_PORT.4

	.EQU TFT_CONTROL_PORT, PORTF
	.EQU TFT_CONTROL_DDR, DDRF


	.EQU LCD_CONTROL_PORT_MASK, 0x1F

	; All signals are active low, so use SBI to idle
	; and CBI to active LCD_RD.
	.MACRO RD_ACTIVE
		CBI TFT_CONTROL_PORT, 0
	.ENDM

	.MACRO RD_IDLE
		SBI TFT_CONTROL_PORT, 0
	.ENDM

	; LCD_WR
	.MACRO WR_ACTIVE
		CBI TFT_CONTROL_PORT, 1
	.ENDM

	.MACRO WR_IDLE
		SBI TFT_CONTROL_PORT, 1
	.ENDM

	; LCD_CD
	.MACRO CD_COMMAND
		CBI TFT_CONTROL_PORT, 2
	.ENDM

	.MACRO CD_DATA
		SBI TFT_CONTROL_PORT, 2
	.ENDM

	; LCD_CS
	.MACRO CS_ACTIVE
		CBI TFT_CONTROL_PORT, 3
	.ENDM

	.MACRO CS_IDLE
		SBI TFT_CONTROL_PORT, 3
	.ENDM

	; LCD_RESET
	.MACRO TFT_RESET_LOW
		CBI TFT_CONTROL_PORT, 4
	.ENDM

	.MACRO TFT_RESET_HIGH
		SBI TFT_CONTROL_PORT, 4
	.ENDM

	.MACRO WR_STROBE
		WR_ACTIVE
		WR_IDLE
	.ENDM

	.EQU PORTH_MASK, 0x78
	.EQU PORTG_MASK, 0x20
	.EQU PORTE_MASK, 0x38

	.EQU DATA_MASK_76, 0xC0	; to H4, H3
	.EQU DATA_MASK_5,  0x20	; to E3
	.EQU DATA_MASK_4,  0x10	; to G5
	.EQU DATA_MASK_32, 0x0C	; to E4, E4
	.EQU DATA_MASK_10, 0x03	; to H6, H5

CSEG

; WRITE_8 writs register R25 into screen data.
; Rewrite this to re-map screen conections.
; For Arduino Mega (2560) the mapping is:
; ScreenData: D7 D6 D5 D4 D3 D2 D1 D0
; atmega2560: H4 H3 E3 G5 E5 E4 H6 H5
WRITE_8:
	PUSH R16
	PUSH R17
	; Deal with PORTH
	LDS R16, PORTH
	ANDI R16, ~PORTH_MASK

	; H6, H5
	MOV R17, R25
	ANDI R17, DATA_MASK_10
	LSL R17	; H1 --> H6
	LSL R17
	LSL R17
	LSL R17
	LSL R17
	OR R16, R17

	; H4, H3
	MOV R17, R25
	ANDI R17, DATA_MASK_76
	LSR R17	; H7 --> H4
	LSR R17
	LSR R17
	OR R16, R17
	STS PORTH, R16

	; Deal with PORTG (can use IN)
	INPUT R16, PORTG
	ANDI R16, ~PORTG_MASK

	; G5
	MOV R17, R25
	ANDI R17, DATA_MASK_4
	LSL R17	; G4 --> G5
	OR R16, R17
	OUTPUT PORTG, R16

	; Deal with PORTE (can use IN)
	INPUT R16, PORTE
	ANDI R16, ~PORTE_MASK
	; E5, E4
	MOV R17, R25
	ANDI R17, DATA_MASK_32
	LSL R17	; E3 --> E5
	LSL R17
	OR R16, R17

	MOV R17, R25
	ANDI R17, DATA_MASK_5
	LSR R17	; E5 --> E3
	LSR R17
	OR R16, R17

	OUTPUT PORTE, R16

	WR_STROBE

	POP R17
	POP R16
	RET

; Sets screen data pins as output.
SET_WRITE_DIR:
	PUSH R17
	INPUT R17, DDRH
	ORI R17, PORTH_MASK
	OUTPUT DDRH, R17

	INPUT R17, DDRE
	ORI R17, PORTE_MASK
	OUTPUT DDRE, R17

	INPUT R17, DDRG
	ORI R17, PORTG_MASK
	OUTPUT DDRG, R17
	POP R17
	RET

; Mid-level routines to talk to the screen

; WRITE_REGISTER_8 takes two 8 bit parameters:
;     address a in R25
;        data d in R24
; It stores d in address a of the TFT screen.
WRITE_REGISTER_8:
	CD_COMMAND
	CALL WRITE_8
	CD_DATA
	MOV R25, R24
	CALL WRITE_8
	RET

; WRITE_REGISTER_16 takes two 16 bit parameters:
;     address a in R25:R24
;        data d in R23:R22
; It stores d in address a of the TFT screen.
; It writes bytes in hi-lo order.
WRITE_REGISTER_16:
	CD_COMMAND
	CALL WRITE_8
	MOV R25, R24
	CALL WRITE_8

	CD_DATA
	MOV R25, R23
	CALL WRITE_8
	MOV R25, R22
	CALL WRITE_8
	RET

; WRITE_REGISTER_32 takes a one byte addres and a 32 bit data:
;     address a in R25
;        data d in R23:R22:R21:R20
; It stores d in address a of the TFT screen.
; It writes bytes in hi-lo order.
WRITE_REGISTER_32:
	PUSH R25
	CS_ACTIVE

	CD_COMMAND
	CALL WRITE_8

	CD_DATA
	MOV R25, R23
	CALL WRITE_8
	MOV R25, R22
	CALL WRITE_8
	MOV R25, R21
	CALL WRITE_8
	MOV R25, R20
	CALL WRITE_8

	CS_IDLE
	POP R25
	RET

