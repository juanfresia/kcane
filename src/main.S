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
;            GENERAL PROJECT INFORMATION
; --------------------------------------------------
; Microcontroller used: ATmega2560 @16MHz
;
; Other hardware used: 
;   - 2.4'' TFT based on the ILI9320
;   - 7 segment displays multiplexing board, based
;   on CD4511 decoder and ULN2003 
;   - 3v buzzer and LEDs for game results
;
; Ports used: 
;   - TFT control pins on TFT_CONTROL_PORT (PORTF)
;   - TFT data pins distributed on PORTE, PORTG and PORTH
;   - Displays on DISPLAYS_PORT (PORTL)
;   - Wires for the bomb on WIRES_PORT (PORTK)
; --------------------------------------------------
	.MACRO INPUT dest, source
	.IF \source<0x40
	IN \dest, \source
	.ELSE
	LDS \dest, \source
	.ENDIF
	.ENDM
	
	.MACRO OUTPUT dest, source
	.IF \dest<0x40
	OUT \dest, \source
	.ELSE
	STS \dest, \source
	.ENDIF
	.ENDM

	#include "avr-linux.h"
	#include "interrupts.S"
	#include "displays.S"
	#include "tft-touch.S"
	#include "tft-draw.S"
	#include "games.S"
	#include "buzzer.S"

; --------------------------------------------------
;                    MAIN PROGRAM
; --------------------------------------------------

	CSEG	
	
main:
	; Stack configuration
	LDI R16, LOW(RAMEND)
	OUTPUT SPL, R16	
	LDI R16, HIGH(RAMEND)
	OUTPUT SPH, R16

	CALL SETUP
	SEI

loop:
	CALL SHOW_DISPLAYS
	CALL PLAY_CURRENT_GAME	
	CALL CHECK_BOMB_WAS_DEACTIVATED
	CPI R24, 1
	BREQ player_deactivated_bomb
	
	CALL CHECK_STRIKES_REACHED_MAX
	CPI R24, 1
	BREQ player_exploded
	 	
	LDS R18, second_has_passed
	CPI R18, 1
	BREQ decrement_countdown
	RJMP loop

player_deactivated_bomb:
	CALL GAME_VICTORY_SCREEN
	RJMP main

decrement_countdown:
	CALL DEC_DISPLAYS
	CLR R18
	STS second_has_passed, R18
	; Check if the displays reached zero
	CALL CHECK_DISPLAYS_ARE_ZERO
	CPI R24, 1
	BRNE loop
	; If the displays reached zero, game over!
player_exploded:
	CALL GAME_DEFEAT_SCREEN
	RJMP main

; --------------------------------------------------
;                AUXILIAR FUNCTIONS
; --------------------------------------------------

; Sets the used PORTs as input/output, enables and
; starts timmer0 overflow interrupt, and gives an
; initial value to used RAM variables.
SETUP:
	CALL SETUP_INTERRUPTS
	CALL SETUP_DISPLAYS
	CALL TFT_START
	CALL SETUP_BUZZER
	
	CALL GAME_STARTING_SCREEN
	
	CALL SETUP_GAMES

	; Clear the second_has_passed flag
	CLR R20
	STS second_has_passed, R20
	RET

	DSEG
; Auxiliar flag to know if a second has passed
second_has_passed:
	BYTE 1

