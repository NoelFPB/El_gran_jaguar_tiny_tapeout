# ASCII Text Printer Circuit

**Author**: Noel Prado, Daniel Mundo, Angel Orellana, and Julio Lopez.  
**Language**: Verilog  
**Description**: A circuit that is able to print two different texts. It utilizes 8 output pins, with each character printed as the ASCII character described in 8 bits.

## How it Works

This circuit is designed to output ASCII-encoded text sequences. The circuit can display two different texts.

**Select Input**: The select pins (`ui_in[1:0]`), a 2-bit binary input, determine which text sequence will be displayed:
- `2'b00` or `2'b11`: Outputs a sequence of characters that correspond to the beginning of a traditional song from Guatemala.
- `2'b01` or `2'b10`: Outputs a sequence of characters with the names of the people that participated in this project.

The text is displayed character-by-character, with each character's ASCII representation determined by the current value of an internal counter. The counter increments with each clock cycle until the specified limit for the chosen text sequence is reached, at which point it resets, allowing the sequence to be displayed repetitively.

## How to Test

To test this project, one needs to use an external microcontroller, where one can read digital input pins synchronously. After reading the characters via the input pins, you can send the pins to a computer via UART communication and display the texts on the computer terminal.

## Inputs

- Select bit 0: Used to define which text will be displayed.
- Select bit 1: Used to define which text will be displayed.

## Outputs

All output pins are used to output the ASCII characters. As this consists of 8 bits, each pin corresponds to one bit.
