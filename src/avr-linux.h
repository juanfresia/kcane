#define __SFR_OFFSET 0
#include <avr/io.h>
#include <avr/interrupt.h>

#define TIMER0_OVF_ISR 0x5C

#define	LOW(x) lo8(x)
#define	HIGH(x) hi8(x)

#define CSEG .text
#define DB .byte
#define DSEG .data
#define BYTE .space





