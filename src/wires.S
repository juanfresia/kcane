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
;              WIRES MINIGAME FUNCTIONS
; --------------------------------------------------
	.GLOBAL WIRES_SETUP
	.GLOBAL WIRES_PLAY
	.GLOBAL WIRES_FINISHED
	
	.EQU WIRES_PORT, PORTK
	.EQU WIRES_DDR, DDRK
	.EQU WIRES_PIN, PINK

	.EQU WIRES_AMOUNT, 4

	; 2**WIRES_COMBS is the amount of possible
	; combinations for this minigame
	.EQU WIRES_COMBS, 4
	.EQU WIRES_COMB_SIZE, 10 ; Each entry in the
	; wires_combinations table has this size 

	; Wires screen constants
	.EQU SCREEN_RECTS_AMOUNT, 4
	.EQU WIRES_FONT_SIZE, 10
	.EQU WIRES_RECTS_WIDTH, (TFT_WIDTH / SCREEN_RECTS_AMOUNT)
	.EQU WIRES_RECTS_HEIGHT, 60
	.EQU WIRES_NUMBER_H, (TFT_CHAR_H * WIRES_FONT_SIZE)
	.EQU WIRES_NUMBER_W, (TFT_CHAR_W * WIRES_FONT_SIZE)
	.EQU WIRES_NUMBER_X, ((TFT_WIDTH - WIRES_NUMBER_W) / 2)
	.EQU WIRES_NUMBER_Y, (WIRES_RECTS_HEIGHT + (TFT_HEIGHT - WIRES_RECTS_HEIGHT - WIRES_NUMBER_H)/ 2)
	.EQU WIRES_RECTS_BORDER, 2
	
CSEG

; Configures the WIRES_PORT as input and enables its
; pull ups. It also setups the variables for the
; minigame by calling RANDGEN.
WIRES_SETUP:
	; First just configure the port
	CLR R18
	OUTPUT WIRES_DDR, R18
	LDI R18, 0xFF
	OUTPUT WIRES_PORT, R18
	; We must now select some random variables
	; values using the wires_combinations table
	LDI R24, WIRES_COMBS
	CALL RANDGEN
	; R24 now has a random number between 0 and
	; 2**WIRES_COMBS-1, so we use it to select 
	; one entry in the wires_combinations table
 	LDI ZL, LOW(wires_combinations)
	LDI ZH, HIGH(wires_combinations)
	LDI R18, WIRES_COMB_SIZE
	MUL R24, R18
	ADD ZL, R0
	ADC ZH, R1
	CLR R1
	; Now that Z is pointing to some entry on
	; the table, load that entry's values into
	; the variables we will be using
	LPM R18, Z+
	STS correct_wire, R18
	LPM R18, Z+
	STS wires_screen_number, R18
	LDI XL, LOW(wires_screen_rects)
	LDI XH, HIGH(wires_screen_rects)
	CLR R24
wires_copy_rects:
	LPM R18, Z+
	ST X+, R18
	INC R24
	CPI R24, (SCREEN_RECTS_AMOUNT * 2)
	BRNE wires_copy_rects
	; Tell the game to show the screen once
	LDI R18, 1
	STS wires_need_show_screen, R18
	; Finally, clear the wires_game_cleared var
	STS wires_game_cleared, R1
	RET

; Plays the wires minigame in a non-blocking way by
; just asking if a wire has been cut. Only when one
; has, performs a check to determinate if it was the
; correct wire or not. Detonates the bomb or clears
; the minigame accordingly on the result.
WIRES_PLAY:
	; Check if the game needs to show the screen
	LDS R18, wires_need_show_screen
	CPI R18, 0
	BREQ wires_check_wires_present
	CALL WIRES_SHOW_SCREEN
	CLR R1
	STS wires_need_show_screen, R1
wires_check_wires_present:
	; Check if all wires are still present
	; (i.e. their value in  WIRES_PORT is 0)
	INPUT R18, WIRES_PIN
	LDI R19, ((1 << WIRES_AMOUNT) - 1)
	; R19 has a mask for taking the wires bits
	AND R18, R19
	CPI R18, 0
	BREQ no_wire_cut
	; If here, at least one wire has been cut.
	; Load now in R20 the correct wire
	LDS R20, correct_wire
	; Since the correct wire bit should be in 1
	; and the others in 0, make R19 like that
	LDI R19, 0x01
wires_small_loop:
	CPI R20, 0
	BREQ wires_comp_wires
	LSL R19
	DEC R20
	RJMP wires_small_loop
wires_comp_wires:
	; R19 has now a 1 in the correct_wire-th bit
	; So if R18 != R19 then a wrong wire was cut
	CP R18, R19
	BREQ correct_wire_cut
	; If here, a wrong wire has been cut! The
	; game should end and bomb should explode!
	LDI R18, MAX_STRIKES_AMOUNT
	; Call INC_STRIKES MAX_STRIKES_AMOUNT times
	; to force the game to be over
wires_strikes_loop:
	PUSH R18 
	CALL INC_STRIKES
	POP R18
	DEC R18
	BRNE wires_strikes_loop	
	RET
correct_wire_cut:
	; If here, the right wire has been cut! It's
	; a happy day and everybody was saved!
	LDI R18, 1 ; Make wires_game_cleared = true
	STS wires_game_cleared, R18
no_wire_cut:
	RET

; Returns true (as 1) on R24 if the wires minigame
; was cleared by the player. If it hasn't already,
; returns false (as 0).
WIRES_FINISHED:
	LDS R24, wires_game_cleared
	RET

; Shows the number and rectangles on screen. Since
; the wires minigame doesn't use the touchability of
; the screen, this function only draws.
WIRES_SHOW_SCREEN:
	PUSH R17
	PUSH R16
	PUSH R15
	; Start by filling the screen with black
	LDI R25, HIGH(BLACK)
	LDI R24, LOW(BLACK)
	CALL TFT_FILL_SCREEN
	; Draw the wires_number on its position
	LDI R25, HIGH(WIRES_NUMBER_X)
	LDI R24, LOW(WIRES_NUMBER_X)
	LDI R23, HIGH(WIRES_NUMBER_Y)
	LDI R22, LOW(WIRES_NUMBER_Y)
	CLR R21
	LDS R20, wires_screen_number
	LDI R26, 48
	ADD R20, R26 ; number to ASCII
	CLR R21
	LDI R19, HIGH(WHITE)
	LDI R18, LOW(WHITE)
	CLR R17
	LDI R16, WIRES_FONT_SIZE
	CALL TFT_DRAW_CHAR
	; Iteratively draw the wires rects
	CLR R15 ; R15 is the index i for iteration
	LDI ZL, LOW(wires_screen_rects)
	LDI ZH, HIGH(wires_screen_rects)
wires_show_rects:
	; Load this rect color and fill the args
	CLR R18
	CLR R25
	CLR R24
	LDI R23, HIGH(WIRES_RECTS_WIDTH)
	LDI R22, LOW(WIRES_RECTS_WIDTH)
	; Do rect.x = WIRES_RECT_WIDTH * i
wires_rectx_loop:
	CP R18, R15
	BREQ wires_rectx_loop_end
	ADD R24, R22
	ADC R25, R23
	INC R18
	RJMP wires_rectx_loop
wires_rectx_loop_end:
	CLR R23
	CLR R22
	LDI R21, HIGH(WIRES_RECTS_WIDTH - WIRES_RECTS_BORDER)
	LDI R20, LOW(WIRES_RECTS_WIDTH - WIRES_RECTS_BORDER)
	LDI R19, HIGH(WIRES_RECTS_HEIGHT - WIRES_RECTS_BORDER)
	LDI R18, LOW(WIRES_RECTS_HEIGHT - WIRES_RECTS_BORDER)
	LD R17, Z+
	LD R16, Z+
	CALL TFT_FILL_RECT_HW
	INC R15
	MOV R22, R15
	CPI R22, SCREEN_RECTS_AMOUNT
	BRNE wires_show_rects		

	POP R15
	POP R16
	POP R17
	RET

; The following is a list of the wires combinations
; (i.e. every possible scenario that could happen).
; The format for listing them is:
; DB: <wire>, <screen number>, <screen rects..>
; Note there should be 2**WIRES_COMBS here.
wires_combinations:
	; Cases when wires_screen_number = 1
	DB 1, 1, HIGH(WHITE), LOW(WHITE), HIGH(BLUE_DARK), LOW(BLUE_DARK), HIGH(WHITE), LOW(WHITE), HIGH(GREEN_DARK), LOW(GREEN_DARK)
	DB WIRES_AMOUNT-1, 1, HIGH(RED_LIGHT), LOW(RED_LIGHT), HIGH(RED_LIGHT), LOW(RED_LIGHT), HIGH(GREEN_DARK), LOW(GREEN_DARK), HIGH(WHITE), LOW(WHITE)
	DB WIRES_AMOUNT-1, 1, HIGH(BLUE_DARK), LOW(BLUE_DARK), HIGH(RED_LIGHT), LOW(RED_LIGHT), HIGH(BLUE_DARK), LOW(BLUE_DARK), HIGH(GREEN_DARK), LOW(GREEN_DARK)
	DB 1, 1, HIGH(RED_LIGHT), LOW(RED_LIGHT), HIGH(BLUE_DARK), LOW(BLUE_DARK), HIGH(RED_LIGHT), LOW(RED_LIGHT), HIGH(GREEN_DARK), LOW(GREEN_DARK)
	; Cases when wires_screen_number = 2
	DB WIRES_AMOUNT-1, 2, HIGH(GREEN_DARK), LOW(GREEN_DARK), HIGH(RED_LIGHT), LOW(RED_LIGHT), HIGH(BLUE_DARK), LOW(BLUE_DARK), HIGH(RED_LIGHT), LOW(RED_LIGHT)
	DB 0, 2, HIGH(WHITE), LOW(WHITE), HIGH(WHITE), LOW(WHITE), HIGH(BLUE_DARK), LOW(BLUE_DARK), HIGH(GREEN_DARK), LOW(GREEN_DARK)
	DB 0, 2, HIGH(WHITE), LOW(WHITE), HIGH(BLUE_DARK), LOW(BLUE_DARK), HIGH(RED_LIGHT), LOW(RED_LIGHT), HIGH(GREEN_DARK), LOW(GREEN_DARK)
	DB 1, 2, HIGH(GREEN_DARK), LOW(GREEN_DARK), HIGH(WHITE), LOW(WHITE), HIGH(WHITE), LOW(WHITE), HIGH(RED_LIGHT), LOW(RED_LIGHT)
	; Cases when wires_screen_number = 3
	DB 3, 3, HIGH(WHITE), LOW(WHITE), HIGH(BLUE_DARK), LOW(BLUE_DARK), HIGH(GREEN_DARK), LOW(GREEN_DARK), HIGH(BLUE_DARK), LOW(BLUE_DARK)
	DB 0, 3, HIGH(GREEN_DARK), LOW(GREEN_DARK), HIGH(BLUE_DARK), LOW(BLUE_DARK), HIGH(GREEN_DARK), LOW(GREEN_DARK), HIGH(RED_LIGHT), LOW(RED_LIGHT)
	DB 2, 3, HIGH(WHITE), LOW(WHITE), HIGH(WHITE), LOW(WHITE), HIGH(GREEN_DARK), LOW(GREEN_DARK), HIGH(RED_LIGHT), LOW(RED_LIGHT)
	DB 0, 3, HIGH(WHITE), LOW(WHITE), HIGH(GREEN_DARK), LOW(GREEN_DARK), HIGH(BLUE_DARK), LOW(BLUE_DARK), HIGH(RED_LIGHT), LOW(RED_LIGHT)
	; Cases when wires_screen_number = 4
	DB 2, 4, HIGH(BLUE_DARK), LOW(BLUE_DARK), HIGH(RED_LIGHT), LOW(RED_LIGHT), HIGH(WHITE), LOW(WHITE), HIGH(RED_LIGHT), LOW(RED_LIGHT)
	DB 3, 4, HIGH(BLUE_DARK), LOW(BLUE_DARK), HIGH(GREEN_DARK), LOW(GREEN_DARK), HIGH(WHITE), LOW(WHITE), HIGH(RED_LIGHT), LOW(RED_LIGHT)
	DB 1, 4, HIGH(WHITE), LOW(WHITE), HIGH(BLUE_DARK), LOW(BLUE_DARK), HIGH(GREEN_DARK), LOW(GREEN_DARK), HIGH(GREEN_DARK), LOW(GREEN_DARK)
	DB WIRES_AMOUNT-1, 4, HIGH(WHITE), LOW(WHITE), HIGH(RED_LIGHT), LOW(RED_LIGHT), HIGH(WHITE), LOW(WHITE), HIGH(GREEN_DARK), LOW(GREEN_DARK)

	DSEG
	; Correct wire number (should be in the
	; range from 0 to WIRES_AMOUNT - 1)
correct_wire:
	BYTE 1
	; Number to be shown on the screen
wires_screen_number:
	BYTE 1
	; Rectangles colors to appear on screen
wires_screen_rects:
	BYTE (WIRES_COMB_SIZE - 2)
	; Boolean to set when minigame finishes
wires_game_cleared:
	BYTE 1
	; Boolean to set when need to show screen
wires_need_show_screen:
	BYTE 1

