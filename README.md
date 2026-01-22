# Building a RISC-V CPU Core

This code is a fork of Steve Hoover's original code, prepared for the Linux Foundation course "Building a RISC-V CPU Core". See the corresponding repo [here](https://github.com/stevehoover/LF-Building-a-RISC-V-CPU-Core.git).



## CPU Description

The CPU implemented follows the RV32I architecture, which is a Risc-V (RV), with 32-bit instructions (32), and operating over integers (I). Operations like add and sub are at the core of this CPU, and in general, we may say that RV32I is at the core of every single RISC-V design.

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



### Program Counter (PC) Logic

This logic is responsible for the program counter (PC). The PC identifies the instruction our CPU will execute next. Most instructions execute sequentially, meaning the default behavior of the PC is to increment to the following instruction each clock cycle. Branch and jump instructions, however, are non-sequential. They specify a target instruction to execute next, and the PC logic must update the PC accordingly.

Note that:

1. The PC is a byte address, meaning it references the first byte of an instruction in the IMem. Instructions are 4 bytes long, so, although the PC increment is depicted as "+1" (instruction), the actual increment must be by 4 (bytes). The lowest two PC bits must always be zero in normal operation.
2. Instruction fetching should start from address zero, so the first $pc value with $reset deasserted should be zero, as is implemented in the logic diagram below.
3. Unlike our earlier counter circuit, for readability, we use unique names for $pc and $next_pc, by assigning $pc to the previous $next_pc.



### Instruction Memory (IMem) - Fetch Action

The instruction memory (IMem) holds the instructions to execute. To read the IMem, or "fetch", we simply pull out the instruction pointed to by the PC. IMem is implemented by instantiating a Verilog macro. This macro accepts a byte address as input, and produces the 32-bit read data as output. The macro is the following: `` `READONLY_MEM($pc, $$read_data[31:0]) ``, where ``$$`` identify assigned signals.

This instruction memory macro is not the typical SRAM memory, but a kind of flip-flop-only-based memory, that can give the data we need in the same cycle. Since it is a macro, there is no control over its inner workings; just give PC as the input address, and collect data with a 32-bit-wide structure.



### Decode logic

Now that we have an instruction to execute, we must interpret, or decode, it. We must break it into fields based on its type. These fields would tell us which registers to read, which operation to perform, etc.



#### Instruction Type Detection

At first, based on the RISC-V Base instruction formats, it is necessary to identify, at first, the type of instruction we are dealing with, if it is any of the R-I-S-B-U-J types.

<p align="center">
  <img src="https://github.com/user-attachments/assets/24af1633-3272-470e-ab67-59961f1e6721" width="600" />
</p>

The instruction type is determined by its opcode, in ``$instr[6:0]``. Where ``$instr[1:0]`` must be 2'b11 for valid RV32I instructions. We'll take the assumption that all instructions are valid, so we can simply ignore these two bits. The ISA defines the instruction type to be determined as follows.

<p align="center">
  <img src="https://github.com/user-attachments/assets/1e094d9f-00bb-4e58-91fa-a0b8c03cd9a6" width="600" />
</p>



#### Instruction Fields Extraction

Once we know the specific instruction type, we can start portioning it according to the fields it is composed. It can be done by filtering based on the instruction type. Note that most of the fields are kinda shared between the instructions, it is because of the immediate values that this idea is broken into pieces. However, it may be valid to extract them regardless of the instruction type, and then, depending on the instruction type, ignore the fields that are not applicable.

Immediate fields are not that easy, they vary from instruction to instruction, and even they have different patterns depending on the instruction type. In order to correctly shape it, use the following table from RV32I spec.

<p align="center">
  <img src="https://github.com/user-attachments/assets/92105d9c-e445-4d85-a627-7d95c7613d6e" width="600" />
</p>



#### Instruction Selection

To determine the specific instruction, we need to consider the opcode, instr[30], and funct3 fields. Note that instr[30] is $funct7[5] for R-type, or $imm[10] for I-type and is labeled "funct7[5]".

<p align="center">
  <img src="https://github.com/user-attachments/assets/bc9a501f-671f-403d-a6eb-9896d8815a32" width="600" />
</p>



### Register File Read

The register file is a small local storage of values the program is actively working with. We decoded the instruction to determine which registers we need to operate on. Now, we need to read those registers from the register file.

For the implementation purposes, the register file is a pretty typical array structure, so we can find a library component for it. This time, rather than using a Verilog module or macro as we did for IMem, we will use a TL-Verilog array definition, expanded by the M4 macro preprocessor. The directive is ``m4+rf(32, 32, $reset, $wr_en, $wr_index[4:0], $wr_data[31:0], $rd_en1, $rd_index1[4:0], $rd_data1, $rd_en2, $rd_index2[4:0], $rd_data2)``, which instantiates a 32-entry, 32-bit-wide register file connected to the given input and output signals, as depicted below. Each of the two read ports requires an index to read from and an enable signal that must assert when a read is required, and it produces read data as output (on the same cycle).

<p align="center">
  <img src="https://github.com/user-attachments/assets/43c6326f-04ce-4325-8419-8116ab26134a" width="600" />
</p>

For example, to read register 5 (x5) and register 8 (x8), $rd_en1 and $rd_en2 would both be asserted, and $rd_index1 and $rd_index2 would be driven with 5 and 8.



### Arithmetic Logic Unit (ALU)

Now that we have the register values, it’s time to operate on them. This is the job of the ALU. It will add, subtract, multiply, shift, etc, based on the operation specified in the instruction.

The diagram of the CPU flow has an error, as the immediate value shall be in place of ``op2``, not ``op1``, as it is currently in the diagram.

Our ALU's complete list of instructions to implement is the following.

<p align="center">
  <img src="https://github.com/user-attachments/assets/cd005a2f-394f-48b0-b7ef-5457f07c85ae" width="600" />
</p>

As you may notice, SLTU, SLTIU, SLT, SLTI, SRA, and SRAI result is based on variables that were not mentioned before; these are intermediate instructions that reduce the math in the one-line-per-instruction approach we are looking for in the ``$result`` assignment.

```verilog
   // 1. SLTU and SLTI (set if less than) results:
   $sltu_rslt[31:0]  = {31'b0, $src1_value < $src2_value};
   $sltiu_rslt[31:0] = {31'b0, $src1_value < $imm};
   
   // 2. SRA and SRAI (shift right arithmetic) results:
   // 2.1. Sign-extended src1, so that even if shifting 31 bits the sign is not lost
   $sext_src1[63:0] = {{32{$src1_value[31]}}, $src1_value};
   // 2.2. 64-bit sign-extended results, to be truncated
   //      Extends $sext_src1 by whatever $src2_value or $src2_value positions say
   $sra_rslt[63:0]  = $sext_src1 >> $src2_value[4:0];
   $srai_rslt[63:0] = $sext_src1 >> $src2_value[4:0];
```


### Register File Write

Now the result value from the ALU can be written back to the destination register specified in the instruction. However, it is important to consider there is a condition under which writing back to the register file is prohibited, and it is in the case the register to write is x0, which is an architecturally reliable register always containing the value zero.



### Branching Logic

Branching logic refers to the interpretation of conditional jump instructions, like BLT for "Branch if Less Than", which jumps to the target address (the target address becomes the new program counter value) if rs1 < rs2 in the instruction ``blt rs1, rs2, target_address``. The branching logic looks as follows.

<p align="center">
  <img src="https://github.com/user-attachments/assets/628e87d7-f564-4376-90c6-7d57f2f6dd3e" width="600" />
</p>

The complete list of branching instructions are is shown below.

<p align="center">
  <img src="https://github.com/user-attachments/assets/463b427a-98bc-4e1f-9290-0e14f00397dd" width="600" />
</p>

If we were to implement a logic diagram that computes if a branch is taken or not it'd be the following, which utilizes a MUX-alike model that chooses the specific branching instruction result, just like the following.

<p align="center">
  <img src="https://github.com/user-attachments/assets/e0af2b38-3ff5-46d0-8d86-cf34f795ee67" width="600" />
</p>

To implement the signed branching we utilized a XOR gate to validate the comparison, in a fashion of ``(Unsigned Comparison) XOR (Are the signs different?)``, if the unsigned comparison is a hit but the signs are different, that means in a signed comparison it is a miss (operation is inverted), but if the signs are equal the result from the unsigned comparison remains the same.



### Jumping Logic (Unconditional Branch)

The jumping logic, compared to branching logic, performs branching without requiring any condition to be met. RV32I ISA provides two forms of jump instructions:

1. Jump and Link (JAL): Jumps to PC + IMM. This logic is similar to branching logic, with the difference that it is unconditional.
2. Jump and Link Register (JALR): Jumps to SRC1 + IMM.

The "link" wording refers to the fact that these instructions capture their original ``PC + 4`` in a destination register.



### DMem

Our test program executes entirely out of the register file and does not require a data memory (DMem). But no CPU is complete without one. The DMem is written to by store instructions and read from by load instructions.
