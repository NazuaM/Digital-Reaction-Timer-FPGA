# Digital Reaction Timer on Nexys A7 FPGA

A high-speed synchronous digital system implemented in VHDL that accurately measures human reaction time in milliseconds. The project features an unpredictable pseudo-random delay to prevent user anticipation, robust hardware debouncing, and a multiplexed 8-digit 7-segment display output.

## 🚀 Features
* **Precise 1ms Timing**: High-frequency 100 MHz clock division down to a stable 1ms timing resolution.
* **Pseudo-Random Delay**: A 16-bit Linear Feedback Shift Register (LFSR) creates a completely unpredictable waiting window between 1.5 and 1.835 seconds.
* **Input Conditioning**: Hardware debouncing and rising-edge detection prevent false triggers or double-counting from mechanical switch noise.
* **Intelligent Scoring**: Displays reaction times dynamically alongside descriptive performance thresholds ("FAST" for < 300ms, "SLOW" for >= 300ms) or an "Err" message for premature attempts.

## 🛠️ System Architecture

The design uses a modular approach split across three primary components managed by a central Moore Finite State Machine (FSM):

1. **`debounce.vhd`**: Filters mechanical bounce from physical buttons.
2. **`seven_seg_driver.vhd`**: Handles time-multiplexing for the 8-digit display, BCD conversion, and text decoding.
3. **`reaction_timer.vhd`**: The top-level controller hosting the FSM states (`IDLE`, `WAITING`, `READY`, `RESULT`, `EARLY`) and the LFSR logic.

### LFSR Configuration
* **Bit-Width**: 16-bit
* **Initial Seed**: `x"ACE1"`
* **Feedback Polynomial Taps**: Bits 15, 13, 12, and 10
* **Scaling**: Left-shifted by 9 bits (multiplied by 512) and added to a 1.5s base delay counter to guarantee human-perceivable randomness.

## 💻 Hardware Requirements
* **Development Board**: Digilent Nexys A7-50T (Artix-7 FPGA)
* **Toolchain**: Xilinx Vivado (2024.2 or compatible)
* **Peripherals Used**: 
  * 16 x On-board LEDs (Visual stimulus cue)
  * 8-Digit 7-Segment Display (Score/Error tracker)
  * CPU Reset Button (Active-low system reset)
  * Push Buttons (Start and React controls)
