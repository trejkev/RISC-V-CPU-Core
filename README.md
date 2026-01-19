# Building a RISC-V CPU Core

## CPU Description

This code is a fork of Steve Hoover's original code, prepared for the Linux Foundation course "Building a RISC-V CPU Core".

Some important details are:
1. The CPU will fully execute one instruction with each new clock cycle. Doing all of this work within a single clock cycle is only possible if the clock is running relatively slowly, which is our assumption.
2. The CPU created is very basic, not a client-server level, but more like a low-profile microcontroller CPU. Which means, it is not a cutting-edge design, but an exemplification of how to create a functional one.
3. A general-purpose CPU would typically have a large memory holding both instructions and data. At any reasonable clock speed, it would take many clock cycles to access memory. Caches would be used to hold recently-accessed memory data close to the CPU core. We are ignoring all of these sources of complexity. We are choosing to implement separate, and very small, instruction and data memories. It is typical to implement separate, single-cycle instruction and data caches, and our IMem and DMem are not unlike such caches.
4. We are ignoring all of the logic that would be necessary to interface with the surrounding system, such as input/output (I/O) controllers, interrupt logic, system timers, etc.

The CPU block diagram looks as follows.
<p align="center">
  <img src="https://github.com/user-attachments/assets/2728dd14-8f96-4662-b45b-e8f05645be99" width="600" />
</p>

The CPU has some important stages to note, these are the following:

1. **PC Logic**: This logic is responsible for the program counter (PC). The PC identifies the instruction our CPU will execute next. Most instructions execute sequentially, meaning the default behavior of the PC is to increment to the following instruction each clock cycle. Branch and jump instructions, however, are non-sequential. They specify a target instruction to execute next, and the PC logic must update the PC accordingly.
2. **Fetch**: The instruction memory (IMem) holds the instructions to execute. To read the IMem, or "fetch", we simply pull out the instruction pointed to by the PC.
3. **Decode Logic**: Now that we have an instruction to execute, we must interpret, or decode, it. We must break it into fields based on its type. These fields would tell us which registers to read, which operation to perform, etc.
4. **Register File Read**: The register file is a small local storage of values the program is actively working with. We decoded the instruction to determine which registers we need to operate on. Now, we need to read those registers from the register file.
5. **Arithmetic Logic Unit (ALU)**: Now that we have the register values, it’s time to operate on them. This is the job of the ALU. It will add, subtract, multiply, shift, etc, based on the operation specified in the instruction.
6. **Register File Write**:  Now the result value from the ALU can be written back to the destination register specified in the instruction.
7. **DMem**: Our test program executes entirely out of the register file and does not require a data memory (DMem). But no CPU is complete without one. The DMem is written to by store instructions and read from by load instructions.


## Course Description

This free mini-workshop, offered by by [Steve Hoover](https://www.linkedin.com/in/steve-hoover-a44b607/) of [Redwood EDA, LLC](https://redwoodeda.com), [Linux Foundation](https://www.linuxfoundation.org/), and [RISC-V International](https://riscv.org) is a crash course in digital logic design and basic CPU microarchitecture. Using the Makerchip online integrated development environment (IDE), you’ll implement everything from logic gates to a simple, but complete, RISC-V CPU core. You’ll be amazed by what you can do using freely-available online tools for open-source development. You’ll walk away with fundamental skills for a career in logic design, and you’ll position yourself on the forefront by learning to use the emerging Transaction-Level Verilog language extension (even if you don’t already know Verilog).

This course is available [in this repository](https://github.com/stevehoover/LF-Building-a-RISC-V-CPU-Core-Course/blob/main/course.md) as well as via the [EdX platform](https://www.edx.org/course/building-a-risc-v-cpu-core) (with a certification option). Thousands have registered and/or completed this course, [including Claude](https://www.linkedin.com/posts/steve-hoover-a44b607_aitl-verilog-activity-7110383796658520066-LGzp) (Anthropic's AI chatbot):

*If I were an actual student, I would give you glowing ratings as an instructor!*

&nbsp; &nbsp; &nbsp; *--Claude*

![VIZ](LF_VIZ.png)

## Welcome

Congratulations for taking this step to expand your knowledge of computer hardware.

At this time, there are no course corrections or platform issues to report. Please do let us know within the EdX platform if anything gets in your way. There's a great deal of infrastructure to maintain for the course, and we aim to keep it all running smoothly. Now, please head back to [EdX](https://www.edx.org/course/building-a-risc-v-cpu-core) or the [Markdown version](course.md) of this course and continue.

## RISC-V Starting-Point Code

To begin the first RISC-V lab, when instructed to do so, Ctrl-click this link to <a href="https://makerchip.com/sandbox?code_url=https:%2F%2Fraw.githubusercontent.com%2Fstevehoover%2FLF-Building-a-RISC-V-CPU-Core%2Fmaster%2Frisc-v_shell.tlv" target="_blank" atom_fix="_">open starting-point code in makerchip</a>.

## RISC-V Reference Solution

In case you get stuck, we've got your back! These <a href="https://makerchip.com/sandbox?code_url=https:%2F%2Fraw.githubusercontent.com%2Fstevehoover%2FLF-Building-a-RISC-V-CPU-Core%2Fmain%2Frisc-v_solutions.tlv" target="_blank" atom_fix="_">reference solutions</a> (Ctrl-click) will help with syntax, etc. without handing you the answers.

Here's a pre-built logic diagram of the final CPU. Ctrl-click here to [explore in its own tab](https://raw.githubusercontent.com/stevehoover/LF-Building-a-RISC-V-CPU-Core/main/lib/riscv.svg).

![Final Core](lib/riscv.svg)

## Finished!

Congratulations!!!

After completing this course, we hope you are inspired to continue your journey. These ideas might help:
  - Try the tutorials in [Makerchip](https://makerchip.com).
  - Learn more about [TL-Verilog](https://redwoodeda.com/tl-verilog).
  - Explore the [RISC-V](https://riscv.org) ecosystem.
  - Take [other courses](https://training.linuxfoundation.org/full-catalog/) from [Linux Foundation](https://www.linuxfoundation.org/)
  - Discover [other training](https://www.redwoodeda.com/publications) from [Redwood EDA, LLC](https://redwoodeda.com)
  - Get your core running on real hardware using FPGAs [in the cloud](https://github.com/stevehoover/1st-CLaaS) or [on your desktop](https://github.com/shivanishah269/risc-v-core/).
  - Install [TL-Verilog tools](https://www.redwoodeda.com/products).
  - Learn about the [WARP-V](https://github.com/stevehoover/warp-v) TL-Verilog CPU core generator.
