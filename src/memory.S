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
;             MEMORY MINIGAME FUNCTIONS
; --------------------------------------------------
	.GLOBAL MEMORY_SETUP
	.GLOBAL MEMORY_PLAY
	.GLOBAL MEMORY_FINISHED

	.EQU MEMORY_STAGES, 5
	.EQU MEMORY_BUTTONS, 4

	; 2**MEMORY_COMBS is the amount of possible
	; combinations for this minigame
	.EQU MEMORY_COMBS, 4
	; Entry size in the memory_combinations table
	.EQU MEMORY_COMB_SIZE, ((MEMORY_BUTTONS + 2) * MEMORY_STAGES) 
	
	; Memory screen constants
	.EQU MEMORY_BUTTON_BORDER, 2
	.EQU MEMORY_GIANT_NUMBER_SIZE, 10
	.EQU MEMORY_GIANT_NUMBER_H, (TFT_CHAR_H * MEMORY_GIANT_NUMBER_SIZE)
	.EQU MEMORY_GIANT_NUMBER_W, (TFT_CHAR_W * MEMORY_GIANT_NUMBER_SIZE)
	.EQU MEMORY_GIANT_NUMBER_X, ((TFT_WIDTH - MEMORY_GIANT_NUMBER_W) / 2 - 2 * MEMORY_BUTTON_BORDER)
	.EQU MEMORY_GIANT_NUMBER_Y, ((TFT_HEIGHT - MEMORY_GIANT_NUMBER_H) / 2)
	.EQU MEMORY_BUTTON_FONT_SIZE, 6
	.EQU MEMORY_BUTTON_NUMBER_X, ((TFT_WIDTH / 2 - MEMORY_BUTTON_FONT_SIZE * TFT_CHAR_W) / 2)
	.EQU MEMORY_BUTTON_NUMBER_Y, ((TFT_HEIGHT / 2 - MEMORY_BUTTON_FONT_SIZE * TFT_CHAR_H) / 2)
	.EQU MEMORY_STAGE_BAR_H, (MEMORY_GIANT_NUMBER_H / (MEMORY_STAGES + 1))
	.EQU MEMORY_STAGE_BAR_W, MEMORY_BUTTON_BORDER
	.EQU MEMORY_STAGE_BAR_X, (MEMORY_GIANT_NUMBER_X + MEMORY_GIANT_NUMBER_W + 5)
	.EQU MEMORY_STAGE_BAR_Y, ((MEMORY_GIANT_NUMBER_Y + MEMORY_GIANT_NUMBER_H - MEMORY_GIANT_NUMBER_SIZE))
	
CSEG

; Randomly picks one of the possible entries on the
; memory_combinations table and stores that data on
; the memory_stage_data buffer.
MEMORY_SETUP:
	LDI R24, MEMORY_COMBS
	CALL RANDGEN
	; R24 now has a random number between 0 and
	; 2**MEMORY_COMBS-1, so we use it to select 
	; one entry in the memory_combinations table
 	LDI ZL, LOW(memory_combinations)
	LDI ZH, HIGH(memory_combinations)
	LDI R18, MEMORY_COMB_SIZE
	MUL R24, R18
	ADD ZL, R0
	ADC ZH, R1
	CLR R1
	; Now that Z is pointing to some entry on
	; the table, load that entry's values into
	; the variables we will be using
	LDI XL, LOW(memory_stage_data)
	LDI XH, HIGH(memory_stage_data)
	LDI R19, MEMORY_COMB_SIZE
memory_setup_loop:	
	LPM R18, Z+
	ST X+, R18
	DEC R19
	BRNE memory_setup_loop
	; Tell the game to show the screen once
	LDI R18, 1
	STS memory_need_show_screen, R18
	; Finally, clear the variables
	STS memory_current_stage, R1
	STS memory_game_cleared, R1
	RET

; Plays the memory minigame in a non-blocking way by
; just asking if the screen was touched. Only when a
; a button is touched, performs a check to see 
; if it was the correct button or not. The game then
; proceeds for MEMORY_STAGES iterations, resetting
; completely if a wrong button is touched.
MEMORY_PLAY:
	; Check if the game needs to show the screen
	LDS R18, memory_need_show_screen
	CPI R18, 0
	BREQ memory_check_button_touched
	CALL MEMORY_SHOW_SCREEN
	CLR R1
	STS memory_need_show_screen, R1
memory_check_button_touched:
	CALL TFT_READ_TOUCH
	LDS R18, TOUCH_Z_VALID
	CPI R18, 0
	BREQ memory_no_button_touched
	; If here, the touchscreen was pressed
	CALL MEMORY_MAP_TOUCH_TO_BUTTON
	CALL MEMORY_PLAY_TONE
	; Check if player touched the proper button
	; Point at the current stage correct button
	LDS R18, memory_current_stage
	LDI ZL, LOW(memory_stage_data)
	LDI ZH, HIGH(memory_stage_data)
	LDI R19, (MEMORY_BUTTONS + 2)
	MUL R19, R18
	ADD ZL, R0
	ADC ZH, R1
	CLR R1
	LDI R18, (MEMORY_BUTTONS + 1)
	ADD ZL, R18
	ADC ZH, R1
	LD R18, Z ; R18 is the correct button
	CP R18, R24
	BREQ memory_play_good_button_touched
	; If here, player has touched a bad button
	CALL INC_STRIKES
	CALL MEMORY_SETUP
	RET
memory_play_good_button_touched:
	; If here, player has touched a good button
	LDS R18, memory_current_stage
	INC R18
	CPI R18, MEMORY_STAGES
	BREQ memory_player_cleared_game
	STS memory_current_stage, R18
	LDI R18, 1
	STS memory_need_show_screen, R18
	RET

memory_player_cleared_game:
	LDI R18, 1
	STS memory_game_cleared, R18
memory_no_button_touched:
	RET

; Returns true (as 1) on R24 if the memory minigame
; was cleared by the player. If it hasn't already,
; returns false (as 0).
MEMORY_FINISHED:
	LDS R24, memory_game_cleared
	RET

; Pretty function that plays a different buzzer tone
; according to the button touched. The button is
; received on R24. The function also returns the
; same button number on R24. Stolen from Simon says.
MEMORY_PLAY_TONE:
	PUSH R24
	CPI R24, 0
	BREQ memory_tone_0
	CPI R24, 1
	BREQ memory_tone_1
	CPI R24, 2
	BREQ memory_tone_2
	CPI R24, 3
	BREQ memory_tone_3
memory_tone_0:
	CALL BUZZER_TONE_1
	POP R24
	RET	
memory_tone_1:
	CALL BUZZER_TONE_2
	POP R24
	RET	
memory_tone_2:
	CALL BUZZER_TONE_3
	POP R24
	RET	
memory_tone_3:
	CALL BUZZER_TONE_5
	POP R24
	RET	

; Retrieves the button number of a touched button
; on screen by reading the TFT touched x,y values.
; Note: this function assumes the player has indeed
; touched the screen (i.e. you shoudl validate the
; z coordinate before calling this function). Returns
; the button number on R24. Stolen from Simon says.
MEMORY_MAP_TOUCH_TO_BUTTON:
	CLR R24
	LDS R19, TOUCH_Y_HIGH
	LDS R18, TOUCH_Y_LOW
	ROR R19
	ROR R18
	CPI R18, (TFT_HEIGHT / 4)
	BRLO memory_touch_test_x
	LDI R24, 2
memory_touch_test_x:
	LDS R19, TOUCH_X_HIGH
	LDS R18, TOUCH_X_LOW
	ROR R19
	ROR R18
	CPI R18, (TFT_WIDTH / 4)
	BRLO memory_touch_ret
	INC R24
memory_touch_ret:
	RET

; Delay used by the memory minigame after showing
; the giant number to memoize it. 
MEMORY_DELAY:
	PUSH ZL
	PUSH ZH
	PUSH R16
	PUSH R17
	PUSH R18
	PUSH R19
	PUSH R20
	LDI R16, 40
memory_delay_loop:	
	CALL SHOW_DISPLAYS
	DEC R16
	BRNE memory_delay_loop
	POP R20
	POP R19
	POP R18
	POP R17
	POP R16
	POP ZH
	POP ZL
	RET

; Shows the current stage giant number and buttons
; labels on the screen in a pretty format.
MEMORY_SHOW_SCREEN:
	PUSH R17
	PUSH R16
	PUSH R15
	; Start by filling the screen with black
	LDI R25, HIGH(BLACK)
	LDI R24, LOW(BLACK)
	CALL TFT_FILL_SCREEN
	; Now point at the current stage data
	LDS R18, memory_current_stage
	LDI ZL, LOW(memory_stage_data)
	LDI ZH, HIGH(memory_stage_data)
	LDI R19, (MEMORY_BUTTONS + 2)
	MUL R19, R18
	ADD ZL, R0
	ADC ZH, R1
	CLR R1
	; Load the first giant number and show it
	LDI R25, HIGH(MEMORY_GIANT_NUMBER_X)
	LDI R24, LOW(MEMORY_GIANT_NUMBER_X)
	LDI R23, HIGH(MEMORY_GIANT_NUMBER_Y)
	LDI R22, LOW(MEMORY_GIANT_NUMBER_Y)
	CLR R21
	LD R20, Z+
	LDI R26, 48
	ADD R20, R26 ; number to ASCII
	CLR R21
	LDI R19, HIGH(WHITE)
	LDI R18, LOW(WHITE)
	CLR R17
	LDI R16, MEMORY_GIANT_NUMBER_SIZE
	PUSH ZL
	PUSH ZH
	CALL TFT_DRAW_CHAR
	; Draw the current stage progress bar
	LDS R15, memory_current_stage
	INC R15
	LDI R23, HIGH(MEMORY_STAGE_BAR_Y)
	LDI R22, LOW(MEMORY_STAGE_BAR_Y)
memory_show_stage_progress_bar_loop:
	LDI R25, HIGH(MEMORY_STAGE_BAR_X)
	LDI R24, LOW(MEMORY_STAGE_BAR_X)
	LDI R21, HIGH(MEMORY_STAGE_BAR_W)
	LDI R20, LOW(MEMORY_STAGE_BAR_W)
	LDI R19, HIGH(MEMORY_STAGE_BAR_H)
	LDI R18, LOW(MEMORY_STAGE_BAR_H)
	LDI R17, HIGH(GREEN_LIGHT)
	LDI R16, LOW(GREEN_LIGHT)
	PUSH R23
	PUSH R22
	CALL TFT_FILL_RECT_HW
	POP R22
	POP R23
	LDI R19, HIGH(MEMORY_STAGE_BAR_H + 4)
	LDI R18, LOW(MEMORY_STAGE_BAR_H + 4)
	SUB R22, R18
	SBC R23, R19
	DEC R15
	BRNE memory_show_stage_progress_bar_loop
	CALL MEMORY_DELAY
	; Clear the screen and draw the button borders
	LDI R25, HIGH(BLACK)
	LDI R24, LOW(BLACK)
	CALL TFT_FILL_SCREEN
	CLR R25 ; Horizontal line
	CLR R24
	LDI R23, HIGH(TFT_HEIGHT / 2)
	LDI R22, LOW(TFT_HEIGHT / 2)
	LDI R21, HIGH(TFT_WIDTH)
	LDI R20, LOW(TFT_WIDTH)
	LDI R19, HIGH(MEMORY_BUTTON_BORDER)
	LDI R18, LOW(MEMORY_BUTTON_BORDER)
	LDI R17, HIGH(WHITE)
	LDI R16, LOW(WHITE)
	CALL TFT_FILL_RECT_HW
	CLR R23 ; Vertical line
	CLR R22
	LDI R25, HIGH(TFT_WIDTH / 2)
	LDI R24, LOW(TFT_WIDTH / 2)
	LDI R19, HIGH(TFT_HEIGHT)
	LDI R18, LOW(TFT_HEIGHT)
	LDI R21, HIGH(MEMORY_BUTTON_BORDER)
	LDI R20, LOW(MEMORY_BUTTON_BORDER)
	LDI R17, HIGH(WHITE)
	LDI R16, LOW(WHITE)
	CALL TFT_FILL_RECT_HW
	; Now draw the four button labels
	POP ZH
	POP ZL
	LDI R25, HIGH(MEMORY_BUTTON_NUMBER_X)
	LDI R24, LOW(MEMORY_BUTTON_NUMBER_X)
	LDI R23, HIGH(MEMORY_BUTTON_NUMBER_Y)
	LDI R22, LOW(MEMORY_BUTTON_NUMBER_Y)
	CLR R21
	LD R20, Z+
	LDI R26, 48
	ADD R20, R26 ; number to ASCII
	CLR R21
	LDI R19, HIGH(WHITE)
	LDI R18, LOW(WHITE)
	CLR R17
	LDI R16, MEMORY_BUTTON_FONT_SIZE
	PUSH ZL
	PUSH ZH
	CALL TFT_DRAW_CHAR	
	POP ZH
	POP ZL
	LDI R25, HIGH(MEMORY_BUTTON_NUMBER_X + TFT_WIDTH / 2)
	LDI R24, LOW(MEMORY_BUTTON_NUMBER_X + TFT_WIDTH / 2)
	LDI R23, HIGH(MEMORY_BUTTON_NUMBER_Y)
	LDI R22, LOW(MEMORY_BUTTON_NUMBER_Y)
	CLR R21
	LD R20, Z+
	LDI R26, 48
	ADD R20, R26 ; number to ASCII
	CLR R21
	LDI R19, HIGH(WHITE)
	LDI R18, LOW(WHITE)
	CLR R17
	LDI R16, MEMORY_BUTTON_FONT_SIZE
	PUSH ZL
	PUSH ZH
	CALL TFT_DRAW_CHAR	
	POP ZH
	POP ZL
	LDI R25, HIGH(MEMORY_BUTTON_NUMBER_X)
	LDI R24, LOW(MEMORY_BUTTON_NUMBER_X)
	LDI R23, HIGH(MEMORY_BUTTON_NUMBER_Y + TFT_HEIGHT / 2)
	LDI R22, LOW(MEMORY_BUTTON_NUMBER_Y + TFT_HEIGHT / 2)
	CLR R21
	LD R20, Z+
	LDI R26, 48
	ADD R20, R26 ; number to ASCII
	CLR R21
	LDI R19, HIGH(WHITE)
	LDI R18, LOW(WHITE)
	CLR R17
	LDI R16, MEMORY_BUTTON_FONT_SIZE
	PUSH ZL
	PUSH ZH
	CALL TFT_DRAW_CHAR	
	POP ZH
	POP ZL
	LDI R25, HIGH(MEMORY_BUTTON_NUMBER_X + TFT_WIDTH / 2)
	LDI R24, LOW(MEMORY_BUTTON_NUMBER_X + TFT_WIDTH / 2)
	LDI R23, HIGH(MEMORY_BUTTON_NUMBER_Y + TFT_HEIGHT / 2)
	LDI R22, LOW(MEMORY_BUTTON_NUMBER_Y + TFT_HEIGHT / 2)
	CLR R21
	LD R20, Z+
	LDI R26, 48
	ADD R20, R26 ; number to ASCII
	CLR R21
	LDI R19, HIGH(WHITE)
	LDI R18, LOW(WHITE)
	CLR R17
	LDI R16, MEMORY_BUTTON_FONT_SIZE
	CALL TFT_DRAW_CHAR	
	POP R15
	POP R16
	POP R17
	RET

; The following is a list of the memory combinations
; (i.e. every possible scenario that could happen).
; The format for listing them is:
; <stage 1>, <stage 2>, ... , <stage MEMORY_STAGES>
; Where each stage is made of MEMORY_BUTTONS+2 bytes:
; - The giant initial number on screen
; - The MEMORY_BUTTONS labels for the buttons
; - The right button (from 0 to MEMORY_BUTTONS - 1)
memory_combinations:
	DB 4, 1, 3, 4, 2, 3, 2, 2, 3, 4, 1, 3, 3, 1, 3, 4, 2, 2, 2, 3, 2, 4, 1, 0, 1, 2, 3, 1, 4, 0
	DB 1, 2, 3, 4, 1, 1, 2, 2, 3, 4, 1, 1, 2, 3, 1, 4, 2, 0, 3, 1, 2, 4, 3, 1, 1, 4, 3, 2, 1, 1
	DB 2, 1, 2, 4, 3, 1, 3, 1, 3, 4, 2, 0, 1, 4, 2, 3, 1, 3, 3, 1, 3, 4, 2, 0, 2, 4, 3, 2, 1, 3
	DB 3, 1, 2, 3, 4, 2, 1, 1, 4, 2, 3, 1, 2, 2, 1, 3, 4, 2, 1, 4, 3, 1, 2, 2, 4, 3, 2, 4, 1, 0
	DB 4, 1, 4, 2, 3, 3, 1, 2, 4, 1, 3, 1, 2, 1, 3, 4, 2, 1, 4, 1, 2, 3, 4, 1, 2, 3, 2, 4, 1, 2
	DB 2, 3, 4, 1, 2, 1, 2, 1, 3, 2, 4, 1, 3, 4, 3, 2, 1, 2, 4, 1, 3, 4, 2, 1, 3, 3, 2, 1, 4, 0
	DB 1, 3, 2, 4, 1, 1, 3, 1, 2, 4, 3, 0, 1, 4, 2, 3, 1, 3, 4, 2, 1, 4, 3, 0, 2, 3, 4, 1, 2, 2
	DB 3, 4, 1, 2, 3, 2, 2, 1, 2, 3, 4, 2, 3, 2, 4, 3, 1, 2, 2, 1, 2, 3, 4, 0, 3, 4, 2, 1, 3, 2
	DB 1, 1, 4, 3, 2, 1, 4, 2, 3, 1, 4, 1, 3, 1, 2, 4, 3, 2, 2, 2, 3, 4, 1, 0, 3, 4, 1, 2, 3, 2
	DB 2, 3, 1, 4, 2, 1, 4, 4, 3, 2, 1, 1, 2, 2, 3, 1, 4, 2, 2, 1, 4, 3, 2, 0, 4, 2, 4, 3, 1, 3
	DB 4, 2, 1, 3, 4, 3, 3, 4, 1, 2, 3, 0, 1, 2, 3, 4, 1, 2, 3, 2, 3, 4, 1, 0, 3, 2, 4, 3, 1, 0
	DB 3, 2, 4, 1, 2, 2, 4, 3, 2, 1, 4, 2, 4, 2, 3, 4, 1, 2, 4, 1, 4, 3, 2, 2, 1, 1, 4, 2, 3, 0
	DB 1, 3, 2, 1, 4, 1, 1, 2, 3, 4, 1, 2, 4, 3, 4, 1, 2, 1, 1, 2, 1, 3, 4, 1, 4, 3, 2, 1, 4, 3
	DB 2, 3, 4, 1, 2, 1, 1, 3, 4, 1, 2, 1, 4, 2, 3, 4, 1, 2, 1, 2, 4, 3, 1, 1, 1, 2, 3, 4, 1, 2
	DB 3, 4, 3, 2, 1, 2, 3, 4, 1, 2, 3, 0, 1, 1, 4, 3, 2, 1, 3, 1, 2, 4, 3, 0, 2, 1, 4, 3, 2, 1
	DB 4, 2, 4, 3, 1, 3, 4, 2, 1, 3, 4, 3, 4, 4, 2, 3, 1, 0, 1, 3, 4, 2, 1, 3, 4, 1, 3, 4, 2, 2
	
	DSEG
	; Current minigame stage (0 to MEMORY_STAGES - 1)
memory_current_stage:
	BYTE 1
	; Buffer for allocating all of the stage data
memory_stage_data:
	BYTE MEMORY_COMB_SIZE
	; Boolean to set when minigame finishes
memory_game_cleared:
	BYTE 1
	; Boolean to set when need to show screen
memory_need_show_screen:
	BYTE 1


