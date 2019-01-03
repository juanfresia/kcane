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
;              GENERIC GAMES FUNCTIONS
; --------------------------------------------------
	#include "randgen.S"
	#include "simon.S"
	#include "wires.S"
	#include "memory.S"
	#include "barcode.S"
	
	.GLOBAL PLAY_CURRENT_GAME
	.GLOBAL SETUP_GAMES
	.GLOBAL GET_STRIKES
	.GLOBAL INC_STRIKES
	.GLOBAL CHECK_STRIKES_REACHED_MAX
	.GLOBAL CHECK_BOMB_WAS_DEACTIVATED

	.EQU GAMES_AMOUNT, 4
	.EQU MAX_STRIKES_AMOUNT, 3
	.EQU STRIKES_LEDS_PORT, PORTG
	.EQU STRIKES_LEDS_DDR, DDRG
	
	; Starting screen constants
	.EQU SS_BCK_COLOR, WHITE
	.EQU SS_TEXT_COLOR, BLUE_LIGHT
	.EQU SS_FONT_SIZE, 5
	.EQU SS_CHAR_W, (SS_FONT_SIZE * TFT_CHAR_W)
	.EQU SS_CHAR_H, (SS_FONT_SIZE * TFT_CHAR_H)
	.EQU SS_TEXT_CHARS, 5 ; "START" is the text
	.EQU SS_TEXT_Y, ((TFT_HEIGHT - SS_CHAR_H) / 2)
	.EQU SS_TEXT_X, ((TFT_WIDTH - SS_CHAR_W * SS_TEXT_CHARS) / 2)
	
	; Defeat screen constants
	.EQU DS_BCK_COLOR, RED_LIGHT
	.EQU DS_TEXT_COLOR, WHITE
	.EQU DS_FONT_SIZE, 6
	.EQU DS_CHAR_W, (DS_FONT_SIZE * TFT_CHAR_W)
	.EQU DS_CHAR_H, (DS_FONT_SIZE * TFT_CHAR_H)
	.EQU DS_TEXT_CHARS, 5 ; "BOOM!" is the text
	.EQU DS_TEXT_Y, ((TFT_HEIGHT - DS_CHAR_H) / 2)
	.EQU DS_TEXT_X, ((TFT_WIDTH - DS_CHAR_W * DS_TEXT_CHARS) / 2)
	
	; Victory screen constants
	.EQU VS_BCK_COLOR, GREEN_LIGHT
	.EQU VS_TEXT_COLOR, WHITE
	.EQU VS_FONT_SIZE, 4
	.EQU VS_CHAR_W, (VS_FONT_SIZE * TFT_CHAR_W)
	.EQU VS_CHAR_H, (VS_FONT_SIZE * TFT_CHAR_H)
	.EQU VS_TEXT_CHARS, 8 ; "VICTORY!" is the text
	.EQU VS_TEXT_Y, ((TFT_HEIGHT - VS_CHAR_H) / 2)
	.EQU VS_TEXT_X, ((TFT_WIDTH - VS_CHAR_W * VS_TEXT_CHARS) / 2)
	
	
	CSEG

; Initializes all minigames variables together with
; the strike counter. Should be called after 
; setting up the random generator.
SETUP_GAMES:
	CALL SETUP_RANDGEN
	CLR R1
	STS strikes_counter, R1
	STS current_minigame, R1
	; Setup LEDs for strikes
	INPUT R18, STRIKES_LEDS_DDR
	ORI R18, 0X07
	OUTPUT STRIKES_LEDS_DDR, R18
	INPUT R18, STRIKES_LEDS_PORT
	ANDI R18, 0xF8
	OUTPUT STRIKES_LEDS_PORT, R18
	; Call setup for all minigames
	CALL WIRES_SETUP
	CALL MEMORY_SETUP
	CALL SIMON_SAYS_SETUP
	CALL BARCODE_SETUP
	RET

; Shows a nice starting screen with the message
; defined on the starting_screen_text bufffer. The
; screen vanishes after the player touches it.
; IMPORTANT: This function is blocking!
GAME_STARTING_SCREEN:
	PUSH R17
	PUSH R16
	PUSH R15
	; First fill the screen with the right color
	LDI R25, HIGH(SS_BCK_COLOR)
	LDI R24, LOW(SS_BCK_COLOR)
	CALL TFT_FILL_SCREEN
	; Now loop showing the starting_screen_text
	LDI ZL, LOW(starting_screen_text)
	LDI ZH, HIGH(starting_screen_text)
	LDI R16, SS_TEXT_CHARS
	MOV R15, R16 ; R15 is the iterator
	LDI R25, HIGH(SS_TEXT_X)
	LDI R24, LOW(SS_TEXT_X)
games_starting_screen_text_loop:
	LDI R23, HIGH(SS_TEXT_Y)
	LDI R22, LOW(SS_TEXT_Y)
	CLR R21
	LPM R20, Z+ ; Char in R20
	LDI R19, HIGH(SS_TEXT_COLOR)
	LDI R18, LOW(SS_TEXT_COLOR)
	LDI R17, HIGH(SS_FONT_SIZE)
	LDI R16, LOW(SS_FONT_SIZE)
	PUSH R25
	PUSH R24
	CALL TFT_DRAW_CHAR
	POP R24
	POP R25
	ADIW R24, SS_CHAR_W ; R25:R24 += SS_CHAR_W
	DEC R15
	BRNE games_starting_screen_text_loop
	; Text was shown, so loop until screen is touched
games_starting_screen_touch_loop:
	CALL TFT_READ_TOUCH
	LDS R18, TOUCH_Z_VALID
	CPI R18, 0
	BREQ games_starting_screen_touch_loop
	CALL BUZZER_TONE_2
	CALL BUZZER_TONE_2
	CALL BUZZER_TONE_1
	CALL BUZZER_TONE_1
	CALL BUZZER_TONE_2
	CALL BUZZER_TONE_2
	POP R17
	POP R16
	POP R15
	RET

; Shows a the defeat screen with the message
; defined on the defeat_screen_text bufffer. The
; screen vanishes after the player touches it.
; IMPORTANT: This function is blocking!
GAME_DEFEAT_SCREEN:
	PUSH R17
	PUSH R16
	PUSH R15
	; First fill the screen with the right color
	LDI R25, HIGH(DS_BCK_COLOR)
	LDI R24, LOW(DS_BCK_COLOR)
	CALL TFT_FILL_SCREEN
	; Boom explosion sound (?)
	CALL BUZZER_EXPLOSION_FANFARE
	; Now loop showing the defeat_screen_text
	LDI ZL, LOW(defeat_screen_text)
	LDI ZH, HIGH(defeat_screen_text)
	LDI R16, DS_TEXT_CHARS
	MOV R15, R16 ; R15 is the iterator
	LDI R25, HIGH(DS_TEXT_X)
	LDI R24, LOW(DS_TEXT_X)
games_defeat_screen_text_loop:
	LDI R23, HIGH(DS_TEXT_Y)
	LDI R22, LOW(DS_TEXT_Y)
	CLR R21
	LPM R20, Z+ ; Char in R20
	LDI R19, HIGH(DS_TEXT_COLOR)
	LDI R18, LOW(DS_TEXT_COLOR)
	LDI R17, HIGH(DS_FONT_SIZE)
	LDI R16, LOW(DS_FONT_SIZE)
	PUSH R25
	PUSH R24
	CALL TFT_DRAW_CHAR
	POP R24
	POP R25
	ADIW R24, DS_CHAR_W ; R25:R24 += DS_CHAR_W
	DEC R15
	BRNE games_defeat_screen_text_loop
	; Text was shown, so loop until screen is touched
games_defeat_screen_touch_loop:
	CALL TFT_READ_TOUCH
	LDS R18, TOUCH_Z_VALID
	CPI R18, 0
	BREQ games_defeat_screen_touch_loop
	POP R17
	POP R16
	POP R15
	RET

; Shows a the victory screen with the message
; defined on the victory_screen_text bufffer. The
; screen vanishes after the player touches it.
; IMPORTANT: This function is blocking!
GAME_VICTORY_SCREEN:
	PUSH R17
	PUSH R16
	PUSH R15
	; First fill the screen with the right color
	LDI R25, HIGH(VS_BCK_COLOR)
	LDI R24, LOW(VS_BCK_COLOR)
	CALL TFT_FILL_SCREEN
	; Victory sound!
	CALL BUZZER_DEACTIVATION_FANFARE
	; Now loop showing the victory_screen_text
	LDI ZL, LOW(victory_screen_text)
	LDI ZH, HIGH(victory_screen_text)
	LDI R16, VS_TEXT_CHARS
	MOV R15, R16 ; R15 is the iterator
	LDI R25, HIGH(VS_TEXT_X)
	LDI R24, LOW(VS_TEXT_X)
games_victory_screen_text_loop:
	LDI R23, HIGH(VS_TEXT_Y)
	LDI R22, LOW(VS_TEXT_Y)
	CLR R21
	LPM R20, Z+ ; Char in R20
	LDI R19, HIGH(VS_TEXT_COLOR)
	LDI R18, LOW(VS_TEXT_COLOR)
	LDI R17, HIGH(VS_FONT_SIZE)
	LDI R16, LOW(VS_FONT_SIZE)
	PUSH R25
	PUSH R24
	CALL TFT_DRAW_CHAR
	POP R24
	POP R25
	ADIW R24, VS_CHAR_W ; R25:R24 += VS_CHAR_W
	DEC R15
	BRNE games_victory_screen_text_loop
	; Text was shown, so loop until screen is touched
games_victory_screen_touch_loop:
	CALL TFT_READ_TOUCH
	LDS R18, TOUCH_Z_VALID
	CPI R18, 0
	BREQ games_victory_screen_touch_loop
	POP R17
	POP R16
	POP R15
	RET
	
; Increases by 1 the number of strikes of the player
; during this game.
INC_STRIKES:
	LDS R18, strikes_counter
	INC R18
	STS strikes_counter, R18
	; Turn on LEDs strikes
	INPUT R18, STRIKES_LEDS_PORT
	MOV R19, R18
	ANDI R19, 0X07
	LSL R19
	INC R19
	ANDI R19, 0X07
	OR R18, R19
	OUTPUT STRIKES_LEDS_PORT, R18
	CALL BUZZER_DEFEAT_FANFARE
	RET

; Returns on R24 the number of strikes of this game.
GET_STRIKES:
	LDS R24, strikes_counter
	RET

; Checks whether or not the number of strikes has
; reached the MAX_STRIKES_AMOUNT value (i.e. if the
; game is over or not). Returns true or false (as 1
; or 0) on R24.
CHECK_STRIKES_REACHED_MAX:
	CLR R24
	LDS R18, strikes_counter
	CPI R18, MAX_STRIKES_AMOUNT
	BRLO check_strikes_ret
	INC R24
check_strikes_ret:	
	RET

; Checks if the bomb was deactivated by clearing all
; the minigames on it. That happens when the variable
; current_minigame reaches MINIGAMES_AMOUNT value. 
; The function returns true or false (1 or 0) on R24.
CHECK_BOMB_WAS_DEACTIVATED:
	CLR R24
	LDS R18, current_minigame
	CPI R18, GAMES_AMOUNT
	BRLO check_deactivated_ret
	INC R24
check_deactivated_ret:
	RET

; REALLY THE MOST IMPORTANT FUNCTION OF THE PROJECT!
; This function allows the user to play the current
; minigame in a non-blocking manner, and advances to 
; the next minigame when it is finished by increasing 
; the current_minigame variable. In order for this, 
; all minigames must implement these two functions:
; * <MINIGAME NAME>_PLAY : allows the user to play 
; that minigame in a NON-BLOCKING way. The easiest 
; way to achieve this is by simply asking if the 
; player has touched the screen and returning if not.
; * <MINIGAME NAME>_FINISHED : must store on R24 a 
; true or false value, telling if the player has or
; not cleared that game.
PLAY_CURRENT_GAME:
	PUSH R16
	CLR R1
	; Load in R16 the current minigame number
	LDS R16, current_minigame
	CPI R16, 0
	BREQ minigame_0
	CPI R16, 1
	BREQ minigame_1
	CPI R16, 2
	BREQ minigame_2
	CPI R16, 3
	BREQ minigame_3
	; SHOULD NOT HAPPEN!
	RET

check_minigame_finished:
	; R16 still has the current minigame. If R24 is
	CPI R24, 0 ; 1, the current minigame was cleared
	BREQ keep_playing_current_minigame
	; Current minigame was cleared if here
	INC R16 
	STS current_minigame, R16
	CALL BUZZER_VICTORY_FANFARE
keep_playing_current_minigame:
	POP R16
	RET

; ------------- Games sorted by number -------------

minigame_0:
	CALL SIMON_SAYS_PLAY
	CALL SIMON_SAYS_FINISHED
	RJMP check_minigame_finished

minigame_1:
	CALL BARCODE_PLAY
	CALL BARCODE_FINISHED
	RJMP check_minigame_finished

minigame_2:
	CALL MEMORY_PLAY
	CALL MEMORY_FINISHED
	RJMP check_minigame_finished

minigame_3:
	CALL WIRES_PLAY
	CALL WIRES_FINISHED
	RJMP check_minigame_finished

; Text to show on the starting screen
starting_screen_text:
	DB 'S', 'T', 'A', 'R', 'T', 0x00
; Text to show on the defeat screen
defeat_screen_text:
	DB 'B', 'O', 'O', 'M', '!', 0x00
; Text to show on the victory screen
victory_screen_text:
	DB 'V', 'I', 'C', 'T', 'O', 'R', 'Y', '!'
	
	DSEG
; Number of strikes during this game
strikes_counter:
	BYTE 1
; Current game counter
current_minigame:
	BYTE 1
