# avr-gcc ABI call convention

- **Caller saved registers**: R18-R27 & R30, R31. The calling function must save them, so they can be freely used by any function without doing anything. Note the registers include the X and Z pointers, but not Y.
- **Callee saved registers**: R2-R17 & R28, R29. The value of these registers must be preserved during a function call, so any function must save these registers before using them, and load them before returning.
- **Fixed registers**: R0 & R1. R1 is always considered zero, so you must clear it after using it (for instance, when calling some MUL instruction). R0 is only used as a temp register.
- **Argument passing**: When calling a function, their arguments are passed from R25 to R8 and _aligned to 2 bytes_. For instance, when calling `foo(int arg0, int arg1)` the `arg0` must be passed in R25:R24 and `arg1` in R23:R22. The only data types of 32 bits are the float and long ones (double is treated like float, and pointers have 16 bits).
- **Argument returning**: The argument is returned on R25:R24 (short types like char are extended to 16 bits). If 32 bits are needed, they are returned on R25:R22.
