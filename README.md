# Building a RISC-V CPU Core

## CPU Description

This code is a fork of Steve Hoover's original code, prepared for the Linux Foundation course "Building a RISC-V CPU Core". See the corresponding repo [here](https://github.com/stevehoover/LF-Building-a-RISC-V-CPU-Core.git).

Some important details are:
1. The CPU will fully execute one instruction with each new clock cycle. Doing all of this work within a single clock cycle is only possible if the clock is running relatively slowly, which is our assumption.
2. The CPU created is very basic, not a client-server level, but more like a low-profile microcontroller CPU. Which means, it is not a cutting-edge design, but an exemplification of how to create a functional one.
3. A general-purpose CPU would typically have a large memory holding both instructions and data. At any reasonable clock speed, it would take many clock cycles to access memory. Caches would be used to hold recently-accessed memory data close to the CPU core. We are ignoring all of these sources of complexity. We are choosing to implement separate, and very small, instruction and data memories. It is typical to implement separate, single-cycle instruction and data caches, and our IMem and DMem are not unlike such caches.
4. We are ignoring all of the logic that would be necessary to interface with the surrounding system, such as input/output (I/O) controllers, interrupt logic, system timers, etc.
5. The CPU is designed under a 32-bit architecture.

The CPU block diagram looks as follows.
<p align="center">
  <img src="https://github.com/user-attachments/assets/2728dd14-8f96-4662-b45b-e8f05645be99" width="600" />
</p>

### PC Logic

This logic is responsible for the program counter (PC). The PC identifies the instruction our CPU will execute next. Most instructions execute sequentially, meaning the default behavior of the PC is to increment to the following instruction each clock cycle. Branch and jump instructions, however, are non-sequential. They specify a target instruction to execute next, and the PC logic must update the PC accordingly.

Note that:

1. The PC is a byte address, meaning it references the first byte of an instruction in the IMem. Instructions are 4 bytes long, so, although the PC increment is depicted as "+1" (instruction), the actual increment must be by 4 (bytes). The lowest two PC bits must always be zero in normal operation.
2. Instruction fetching should start from address zero, so the first $pc value with $reset deasserted should be zero, as is implemented in the logic diagram below.
3. Unlike our earlier counter circuit, for readability, we use unique names for $pc and $next_pc, by assigning $pc to the previous $next_pc.

### Instruction Memory (IMem)

IMem is implemented by instantiating a Verilog macro. This macro accepts a byte address as input, and produces the 32-bit read data as output. The macro is the following: `` `READONLY_MEM($pc, $$read_data[31:0]) ``, where ``$$`` identify assigned signals.

This instruction memory macro is not the typical SRAM memory, but a kind of flip-flop-only based, that can give the data we need in the same cycle. Since it is a macro, there is no control on the inner workings of it, just give PC as input address, and collect data with a 32-bit-wide structure.

### Fetch

The instruction memory (IMem) holds the instructions to execute. To read the IMem, or "fetch", we simply pull out the instruction pointed to by the PC.

### Decode logic

Now that we have an instruction to execute, we must interpret, or decode, it. We must break it into fields based on its type. These fields would tell us which registers to read, which operation to perform, etc.

### Register File Read

The register file is a small local storage of values the program is actively working with. We decoded the instruction to determine which registers we need to operate on. Now, we need to read those registers from the register file.

### Arithmetic Logic Unit (ALU)

Now that we have the register values, it’s time to operate on them. This is the job of the ALU. It will add, subtract, multiply, shift, etc, based on the operation specified in the instruction.

### Register File Write

Now the result value from the ALU can be written back to the destination register specified in the instruction.

### DMem

Our test program executes entirely out of the register file and does not require a data memory (DMem). But no CPU is complete without one. The DMem is written to by store instructions and read from by load instructions.
