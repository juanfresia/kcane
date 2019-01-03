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
;            BARCODE MINIGAME FUNCTIONS
; --------------------------------------------------
	.GLOBAL BARCODE_SETUP
	.GLOBAL BARCODE_PLAY
	.GLOBAL BARCODE_FINISHED

	.EQU BARCODE_BUTTONS, 4

	; 2**BARCODE_COMBS is the amount of possible
	; combinations for this minigame
	.EQU BARCODE_COMBS, 4
	; Entry size in the barcode_combinations table
	.EQU BARCODE_COMB_SIZE, 2 
	
	; Memory screen constants
	.EQU BARCODE_BORDER, 30
	.EQU BARCODE_BARS_AMOUNT, 10
	.EQU BARCODE_BAR_H, ((TFT_HEIGHT - 3 * BARCODE_BORDER) / BARCODE_BARS_AMOUNT)
	
CSEG

; Randomly picks one of the possible entries on the
; barcode_combinations table and stores that data on
; the barcode_bars_buffer variable.
BARCODE_SETUP:
	LDI R24, BARCODE_COMBS
	CALL RANDGEN
	; R24 now has a random number between 0 and
	; 2**BARCODE_COMBS-1, so we use it to select 
	; one entry in the barcode_combinations table
 	LDI ZL, LOW(barcode_combinations)
	LDI ZH, HIGH(barcode_combinations)
	LDI R18, BARCODE_COMB_SIZE
	MUL R24, R18
	ADD ZL, R0
	ADC ZH, R1
	CLR R1
	; Now that Z is pointing to some entry on
	; the table, load that entry's values into
	; the variables we will be using
	LDI XL, LOW(barcode_bars_buffer)
	LDI XH, HIGH(barcode_bars_buffer)
	LDI R19, BARCODE_COMB_SIZE
barcode_setup_loop:	
	LPM R18, Z+
	ST X+, R18
	DEC R19
	BRNE barcode_setup_loop
	; Tell the game to show the screen once
	LDI R18, 1
	STS barcode_need_show_screen, R18
	; Finally, clear the game cleared flag
	STS barcode_game_cleared, R1
	RET

; Plays the barcode minigame in a non-blocking way by
; just asking if the screen was touched. Only when a
; the screen is touched, performs a check to see if
; it was on the correct place or not.
BARCODE_PLAY:
	; Check if the game needs to show the screen
	LDS R18, barcode_need_show_screen
	CPI R18, 0
	BREQ barcode_check_button_touched
	CALL BARCODE_SHOW_SCREEN
	CLR R1
	STS barcode_need_show_screen, R1
barcode_check_button_touched:
	CALL TFT_READ_TOUCH
	LDS R18, TOUCH_Z_VALID
	CPI R18, 0
	BREQ barcode_no_button_touched
	; If here, the touchscreen was pressed
	CALL BARCODE_MAP_TOUCH_TO_BUTTON
	; Check if player touched the proper button
	; Point at the current stage correct button
	LDI ZL, LOW(barcode_bars_buffer + BARCODE_COMB_SIZE - 1)
	LDI ZH, HIGH(barcode_bars_buffer + BARCODE_COMB_SIZE - 1)
	LD R18, Z 
	ANDI R18, 0X0F; R18 is the correct button
	CP R18, R24
	BREQ barcode_play_good_button_touched
	; If here, player has touched a bad button
	CALL INC_STRIKES
	CALL BARCODE_SETUP
	RET
barcode_play_good_button_touched:
	LDI R18, 1
	STS barcode_game_cleared, R18
barcode_no_button_touched:
	RET

; Returns true (as 1) on R24 if the barcode minigame
; was cleared by the player. If it hasn't already,
; returns false (as 0).
BARCODE_FINISHED:
	LDS R24, barcode_game_cleared
	RET

; Retrieves the button number of a touched button
; on screen by reading the TFT touched x,y values.
; Note: this function assumes the player has indeed
; touched the screen (i.e. you should validate the
; z coordinate before calling this function). Returns
; the button number on R24. Stolen from Simon says.
BARCODE_MAP_TOUCH_TO_BUTTON:
	CLR R24
	LDS R19, TOUCH_Y_HIGH
	LDS R18, TOUCH_Y_LOW
	ROR R19
	ROR R18
	CPI R18, (TFT_HEIGHT / 4)
	BRLO barcode_touch_test_x
	LDI R24, 2
barcode_touch_test_x:
	LDS R19, TOUCH_X_HIGH
	LDS R18, TOUCH_X_LOW
	ROR R19
	ROR R18
	CPI R18, (TFT_WIDTH / 4)
	BRLO barcode_touch_ret
	INC R24
barcode_touch_ret:
	RET

; Shows the barcode on screen
BARCODE_SHOW_SCREEN:
	PUSH R17
	PUSH R16
	PUSH R15
	; First fill screen with white
	LDI R25, HIGH(WHITE)
	LDI R24, LOW(WHITE)
	CALL TFT_FILL_SCREEN
	; Draw two small squares at the bottom
	CLR R25
	CLR R24
	LDI R23, HIGH(TFT_HEIGHT - BARCODE_BORDER)
	LDI R22, LOW(TFT_HEIGHT - BARCODE_BORDER)
	LDI R21, HIGH(BARCODE_BORDER)
	LDI R20, LOW(BARCODE_BORDER)
	LDI R19, HIGH(BARCODE_BORDER)
	LDI R18, LOW(BARCODE_BORDER)
	LDI R17, HIGH(BLACK)
	LDI R16, HIGH(BLACK)
	CALL TFT_FILL_RECT_HW
	LDI R25, HIGH(TFT_WIDTH - BARCODE_BORDER)
	LDI R24, LOW(TFT_WIDTH - BARCODE_BORDER)
	LDI R23, HIGH(TFT_HEIGHT - BARCODE_BORDER)
	LDI R22, LOW(TFT_HEIGHT - BARCODE_BORDER)
	LDI R21, HIGH(BARCODE_BORDER)
	LDI R20, LOW(BARCODE_BORDER)
	LDI R19, HIGH(BARCODE_BORDER)
	LDI R18, LOW(BARCODE_BORDER)
	LDI R17, HIGH(BLACK)
	LDI R16, HIGH(BLACK)
	CALL TFT_FILL_RECT_HW
	; Point at the barcode_bars_buffer and prepare
	; to loop for BARCODE_BARS_AMOUNT times
	LDI ZL, LOW(barcode_bars_buffer)
	LDI ZH, HIGH(barcode_bars_buffer)
	LDI R16, BARCODE_BARS_AMOUNT
	LDI R22, LOW(BARCODE_BORDER)
	LDI R23, HIGH(BARCODE_BORDER)
barcode_show_screen_byte_loop:
	CLR R17; R17 is a bit counter
	LD R15, Z+
barcode_show_screen_bit_loop:
	CPI R17, 8
	BREQ barcode_show_screen_byte_loop
	; If the 7th bit of R15 is 1, show a black bar
	SBRC R15, 7
	RJMP bardcode_show_screen_bar
bardcode_show_screen_next_bit:
	LDI R25, HIGH(BARCODE_BAR_H)
	LDI R24, LOW(BARCODE_BAR_H)
	ADD R22, R24
	ADC R23, R25
	LSL R15
	INC R17
	DEC R16
	BRNE barcode_show_screen_bit_loop
	POP R15
	POP R16
	POP R17
	RET
	
bardcode_show_screen_bar:
	; Show a black horizontal bar
	CLR R25
	CLR R24
	LDI R21, HIGH(TFT_WIDTH)
	LDI R20, LOW(TFT_WIDTH)
	LDI R19, HIGH(BARCODE_BAR_H)
	LDI R18, LOW(BARCODE_BAR_H)
	PUSH R17
	PUSH R16
	PUSH R22
	PUSH R23
	LDI R17, HIGH(BLACK)
	LDI R16, HIGH(BLACK)
	CALL TFT_FILL_RECT_HW
	POP R23
	POP R22
	POP R16
	POP R17
	RJMP bardcode_show_screen_next_bit

; The following is a list of the barcode combinations
; (i.e. every possible scenario that could happen).
; The format for listing them is:
; a stream of bits (1 for black bar, 0 for white one)
; plus 4 bits for the right button to be touched.
barcode_combinations:
	DB 0x5A, 0x80
	DB 0xAD, 0X41
	DB 0xD5, 0X40
	DB 0xB5, 0X43
	DB 0xA6, 0xC0
	DB 0xDA, 0x82
	DB 0xAA, 0X80
	DB 0xB6, 0XC2
	DB 0x5B, 0x40
	DB 0xD5, 0X03
	DB 0xAB, 0X42
	DB 0xAA, 0XC3
	DB 0xD6, 0x82
	DB 0xDA, 0XC2
	DB 0xDB, 0X42
	DB 0x6A, 0x83
	
	DSEG
	BYTE 1
	; Buffer for allocating the bars data
barcode_bars_buffer:
	BYTE BARCODE_COMB_SIZE
	; Boolean to set when minigame finishes
barcode_game_cleared:
	BYTE 1
	; Boolean to set when need to show screen
barcode_need_show_screen:
	BYTE 1


