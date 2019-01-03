## TFT Interface

```assembly

; Constants that represents the screen width and
; height in pixels
; TFT_WIDTH
; TFT_HEIGHT

; Fills the screen with a given color. The color is
; received on R25:R24.
TFT_FILL_SCREEN

; Draws a rectangle on the screen. Receives the
; following arguments (distances in pixels):
; The upper left x coordinate on R25:R24.
; The upper left y coordinate on R23:R22.
; The width of the rect in R21:R20.
; The height of the rect in R19:R18.
; The color to fill the rect with in R17:R16.
TFT_FILL_RECT_HW

; Retrieves the current point being touched by the
; user. The result is a pointer to an in-RAM struct
; returned in R25:R24. The values inside such struct
; are the following:
; 16 bits of the x coorinate pressed
; 16 bits of the y coorinate pressed
; 16 bits of z: if z=0, screen was not pressed!
TFT_GET_POINT

; Constants that define the size of a character when
; the font size is equal to 1. 
.EQU CHAR_WIDTH, 6
.EQU CHAR_HEIGHT, 8

; Draws a character on the screen. Receives the
; following arguments:
; The upper left x coordinate on R25:R24.
; The upper left y coordinate on R23:R22.
; The ASCII char to show on R21:R20 (set R21 to 0!).
; The character color on R19:R18.
; The font size in R17:R16 (set R17 to 0!).
TFT_DRAW_CHAR
```

