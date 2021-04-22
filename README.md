# Assembly Input/Output

I completed this project as part of CS 271 (Computer Architecture and Assembly Language) during Fall 2018 while I was a student at Oregon State University. **The instructor for that class has granted me express permission to post the source code I submitted for this project publicly for use in my professional portfolio.**

This project implements an assembler-level implementation of input and output. This project is written in MASM (Microsoft Macro Assembler) for the x86 architecture. 

The program reads in 10 unsigned integers from the user inputted line-by-line as strings, converts the strings to an array of unsigned 32-bit integers, and calculates the sum and average of the integers. It then converts the integers, their sum, and their average back to strings and prints them to the console. The program validates input to ensure that all numbers inputted are valid unsigned integers that can be stored in 32-bit registers, reprompting users for a new number after any invalid input. 

In addition to the main procedure, the code implements multiple other procedures and macros. Procedure parameters are passed on the system stack, and all called procedures are responsible for saving register contents of the calling procedure and cleaning up the system stack upon returning. 
