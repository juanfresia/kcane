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
;           SIMON SAYS MINIGAME FUNCTIONS
; --------------------------------------------------
	.GLOBAL SIMON_SAYS_SETUP
	.GLOBAL SIMON_SAYS_PLAY
	.GLOBAL SIMON_SAYS_FINISHED
	; 2**SIMON_COLORS_BITS = SIMON_COLORS
	.EQU SIMON_COLORS, 4
	.EQU SIMON_COLORS_BITS, 2
	.EQU SIMON_SAYS_ROUNDS, 5

	; Screen constants for Simon says
	.EQU SIMON_RECTS_WIDTH, (TFT_WIDTH / 2)
	.EQU SIMON_RECTS_HEIGHT, (TFT_HEIGHT / 2)

CSEG

; Configures the Simon says minigame by choosing the
; first random color and storing it. Once the Simon
; says minigame is started, the color will be shown.
SIMON_SAYS_SETUP:
	CLR R1
	STS simon_chosen_colors_amount, R1
	STS simon_player_last_color, R1
	STS simon_game_cleared, R1
	CALL SIMON_SAYS_PICK_NEXT_COLOR
	RET

; Picks the next correct color the player should
; guess, and stores it in the correct address of the
; simon_correct_colors buffer. It also sets the flag
; for showing the colors on the next iteration and
; increases the chosen colors variable.
SIMON_SAYS_PICK_NEXT_COLOR:
	; If simon_chosen_colors_amount has already
	; reached SIMON_SAYS_ROUNDS, then the game
	; has been cleared
	LDS R18, simon_chosen_colors_amount
	CPI R18, SIMON_SAYS_ROUNDS
	BRNE simon_continue_choosing_colors
	LDI R18, 1
	STS simon_game_cleared, R18
	RET
	
simon_continue_choosing_colors:
	LDI R24, SIMON_COLORS_BITS
	CALL RANDGEN
	; R24 has now a random color to store
	CLR R1
	LDS R18, simon_chosen_colors_amount
	LDI ZL, LOW(simon_correct_colors)
	LDI ZH, HIGH(simon_correct_colors)
	ADD ZL, R18
	ADC ZH, R1
	; The storing address for R24 is pointed by Z
	ST Z, R24	
	; Increase the chosen colors amount
	INC R18
	STS simon_chosen_colors_amount, R18
	STS simon_player_last_color, R1
	; Set the boolean for showing the colors
	LDI R18, 1
	STS simon_show_colors, R18
	RET

; Blink in white a corner of the Simon says.
; Receives the (x,y) coordinates of the upper-left
; button point on R25:R24 and R23:R22.
SIMON_SAYS_BLINK_BUTTON:
	PUSH R17
	PUSH R16
	LDI R21, HIGH(SIMON_RECTS_WIDTH)
	LDI R20, LOW(SIMON_RECTS_WIDTH)
	LDI R19, HIGH(SIMON_RECTS_HEIGHT)
	LDI R18, LOW(SIMON_RECTS_HEIGHT)
	LDI R17, HIGH(WHITE)
	LDI R16, LOW(WHITE)
	CALL TFT_FILL_RECT_HW
	CALL SIMON_SAYS_DELAY
	CALL SIMON_SAYS_SHOW_SCREEN
	POP R16
	POP R17
	RET

; Shows SIMON_COLORS coloured rectangles on screen.
; They should be arranged in a matrix according to
; SIMON_SCREEN_ROWS and SIMON_SCREEN_COLS.
SIMON_SAYS_SHOW_SCREEN:
	PUSH R16
	PUSH R17
	CLR R24
	CALL SIMON_SAYS_MAP_BUTTON_TO_COORDS
	LDI R21, HIGH(SIMON_RECTS_WIDTH)
	LDI R20, LOW(SIMON_RECTS_WIDTH)
	LDI R19, HIGH(SIMON_RECTS_HEIGHT)
	LDI R18, LOW(SIMON_RECTS_HEIGHT)
	LDI R17, HIGH(GREEN_DARK)
	LDI R16, LOW(GREEN_DARK)
	CALL TFT_FILL_RECT_HW
	LDI R24, 1
	CALL SIMON_SAYS_MAP_BUTTON_TO_COORDS
	LDI R21, HIGH(SIMON_RECTS_WIDTH)
	LDI R20, LOW(SIMON_RECTS_WIDTH)
	LDI R19, HIGH(SIMON_RECTS_HEIGHT)
	LDI R18, LOW(SIMON_RECTS_HEIGHT)
	LDI R17, HIGH(RED_LIGHT)
	LDI R16, LOW(RED_LIGHT)
	CALL TFT_FILL_RECT_HW
	LDI R24, 2
	CALL SIMON_SAYS_MAP_BUTTON_TO_COORDS
	LDI R21, HIGH(SIMON_RECTS_WIDTH)
	LDI R20, LOW(SIMON_RECTS_WIDTH)
	LDI R19, HIGH(SIMON_RECTS_HEIGHT)
	LDI R18, LOW(SIMON_RECTS_HEIGHT)
	LDI R17, HIGH(MAGENTA)
	LDI R16, LOW(MAGENTA)
	CALL TFT_FILL_RECT_HW
	LDI R24, 3
	CALL SIMON_SAYS_MAP_BUTTON_TO_COORDS
	LDI R21, HIGH(SIMON_RECTS_WIDTH)
	LDI R20, LOW(SIMON_RECTS_WIDTH)
	LDI R19, HIGH(SIMON_RECTS_HEIGHT)
	LDI R18, LOW(SIMON_RECTS_HEIGHT)
	LDI R17, HIGH(BLUE_DARK)
	LDI R16, LOW(BLUE_DARK)
	CALL TFT_FILL_RECT_HW
	POP R17
	POP R16
	RET

; Returns on R25:R24 the (x,y) coordinates of the
; upper-left point of a button. The button number is
; received on R24.
SIMON_SAYS_MAP_BUTTON_TO_COORDS:
	CPI R24, 0
	BRNE simon_test_one
	CLR R25
	CLR R24
	CLR R23
	CLR R22
	RET
simon_test_one:
	CPI R24, 1
	BRNE simon_test_two
	LDI R25, HIGH(SIMON_RECTS_WIDTH)
	LDI R24, LOW(SIMON_RECTS_WIDTH)
	CLR R23
	CLR R22
	RET
simon_test_two:
	CPI R24, 2
	BRNE simon_test_three
	CLR R25
	CLR R24
	LDI R23, HIGH(SIMON_RECTS_HEIGHT)
	LDI R22, LOW(SIMON_RECTS_HEIGHT)
	RET
simon_test_three:
	LDI R25, HIGH(SIMON_RECTS_WIDTH)
	LDI R24, LOW(SIMON_RECTS_WIDTH)
	LDI R23, HIGH(SIMON_RECTS_HEIGHT)
	LDI R22, LOW(SIMON_RECTS_HEIGHT)
	RET

; Delay used by the Simon says minigame after
; blinking a color. 
SIMON_SAYS_DELAY:
	PUSH ZL
	PUSH ZH
	PUSH R16
	PUSH R17
	PUSH R18
	PUSH R19
	PUSH R20
	LDI R16, 25
simon_says_delay_loop:	
	CALL SHOW_DISPLAYS
	DEC R16
	BRNE simon_says_delay_loop
	POP R20
	POP R19
	POP R18
	POP R17
	POP R16
	POP ZH
	POP ZL
	RET

; Shows the correct colors chosen so far in sequence
; by highlighting them on the screen.
SIMON_SAYS_SHOW_RIGHT_COLORS:
	PUSH R16
	CALL SIMON_SAYS_SHOW_SCREEN
	CALL SIMON_SAYS_DELAY
	LDS R16, simon_chosen_colors_amount
	LDI ZL, LOW(simon_correct_colors)
	LDI ZH, HIGH(simon_correct_colors)
simon_show_colors_loop:
	LD R24, Z+
	CALL SIMON_SAYS_PLAY_TONE
	CALL SIMON_SAYS_MAP_BUTTON_TO_COORDS
	CALL SIMON_SAYS_BLINK_BUTTON
	CALL SIMON_SAYS_DELAY
	DEC R16
	BRNE simon_show_colors_loop
	; Clear the show colors flag
	CLR R1
	STS simon_show_colors, R1
	POP R16
	RET

; Retrieves the button number of a touched button
; on screen by reading the TFT touched x,y values.
; Note: this function assumes the player has indeed
; touched the screen (i.e. you shoudl validate the
; z coordinate before calling this function). Returns
; the pressed button number on R24.
SIMON_SAYS_MAP_TOUCH_TO_BUTTON:
	CLR R24
	LDS R19, TOUCH_Y_HIGH
	LDS R18, TOUCH_Y_LOW
	ROR R19
	ROR R18
	CPI R18, (TFT_HEIGHT / 4)
	BRLO simon_touch_test_x
	LDI R24, 2
simon_touch_test_x:
	LDS R19, TOUCH_X_HIGH
	LDS R18, TOUCH_X_LOW
	ROR R19
	ROR R18
	CPI R18, (TFT_WIDTH / 4)
	BRLO simon_touch_ret
	INC R24
simon_touch_ret:
	RET

; Performs the magic conversion of blinked to
; touch button of the game by using the 
; simon_touch_to_blink_table. The initial and final
; color values are received/returned on R24.
SIMON_SAYS_MAP_COLOR_BLINK_TO_TOUCH:
	MOV R18, R24
	CALL GET_STRIKES
	LSL R24
	LSL R24
	ADD R24, R18
	LDI ZL, LOW(simon_touch_to_blink_table)
	LDI ZH, HIGH(simon_touch_to_blink_table)
	ADD ZL, R24
	ADC ZH, R1
	LPM R24, Z
	RET

; Pretty function that plays a different buzzer tone
; according to the button touched. The button is
; received on R24. The function also returns the
; same button number on R24.
SIMON_SAYS_PLAY_TONE:
	PUSH R24
	CPI R24, 0
	BREQ simon_tone_0
	CPI R24, 1
	BREQ simon_tone_1
	CPI R24, 2
	BREQ simon_tone_2
	CPI R24, 3
	BREQ simon_tone_3
simon_tone_0:
	CALL BUZZER_TONE_1
	POP R24
	RET	
simon_tone_1:
	CALL BUZZER_TONE_2
	POP R24
	RET	
simon_tone_2:
	CALL BUZZER_TONE_3
	POP R24
	RET	
simon_tone_3:
	CALL BUZZER_TONE_5
	POP R24
	RET	

; Plays the simon says minigame in a non-blocking 
; way by checking if the player has touched a button
; or not. Every time a player touches a button, the
; function determinates whether or not the button was
; the correct one, and makes progress on the minigame
; by calling SIMON_SAYS_PICK_NEXT_COLOR if necessary.
SIMON_SAYS_PLAY:
	; Check if the right colors should be shown
	LDS R18, simon_show_colors
	CPI R18, 1
	BREQ show_colors_and_exit
	; Now check if the user pressed a color
	CALL TFT_READ_TOUCH
	LDS R18, TOUCH_Z_VALID
	CPI R18, 0
	BREQ simon_play_no_button_touched
	; If here, the touchscreen was pressed
	CALL SIMON_SAYS_MAP_TOUCH_TO_BUTTON
	PUSH R24
	CALL SIMON_SAYS_PLAY_TONE
	CALL SIMON_SAYS_MAP_BUTTON_TO_COORDS
	CALL SIMON_SAYS_BLINK_BUTTON
	POP R24
	CALL SIMON_SAYS_MAP_COLOR_BLINK_TO_TOUCH
	CLR R1
	LDS R19, simon_player_last_color
	LDI ZL, LOW(simon_correct_colors)
	LDI ZH, HIGH(simon_correct_colors)
	ADD ZL, R19
	ADC ZH, R1
	LD R18, Z
	CP R18, R24
	BREQ simon_play_good_color_touched
	; If here, player has touched a bad color
	CALL INC_STRIKES
	CALL SIMON_SAYS_SETUP
	RET
simon_play_good_color_touched:
	; If here, player has touched a good color
	LDS R18, simon_chosen_colors_amount
	LDS R19, simon_player_last_color
	INC R19
	CP R18, R19
	BREQ simon_play_pick_another_color
	STS simon_player_last_color, R19
	CALL SIMON_SAYS_DELAY
	RET

simon_play_pick_another_color:	
	CALL SIMON_SAYS_PICK_NEXT_COLOR
	RET

show_colors_and_exit:
	CALL SIMON_SAYS_SHOW_RIGHT_COLORS
simon_play_no_button_touched:
	RET

; Returns true (as 1) on R24 if the simon says 
; minigame was cleared by the player. If it hasn't 
; already, returns false (as 0).
SIMON_SAYS_FINISHED:
	LDS R24, simon_game_cleared
	RET
	
; Tables used for the magic mapping of this game
simon_touch_to_blink_table:
	; Cases when strikes are 0
	DB 2, 3, 0, 1
	; Cases when strikes are 1
	DB 3, 2, 1, 0
	; Cases when strikes are 2
	DB 1, 3, 0, 2
	
	DSEG
	; Buffer for storing the correct colors
simon_correct_colors:
	BYTE SIMON_SAYS_ROUNDS
	; Number of colors shown so far
simon_chosen_colors_amount:
	BYTE 1
	; Last number of color pressed by player
simon_player_last_color:
	BYTE 1
	; Boolean to determinate whether or not the
	; correct colors should be shown on the
	; next minigame iteration
simon_show_colors:
	BYTE 1
	; Boolean to set when minigame finishes
simon_game_cleared:
	BYTE 1

