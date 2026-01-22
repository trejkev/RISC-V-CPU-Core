\m4_TLV_version 1d: tl-x.org
\SV
   // This code can be found in: https://github.com/stevehoover/LF-Building-a-RISC-V-CPU-Core/risc-v_shell.tlv
   
   m4_include_lib(['https://raw.githubusercontent.com/stevehoover/LF-Building-a-RISC-V-CPU-Core/main/lib/risc-v_shell_lib.tlv'])



   //---------------------------------------------------------------------------------
   // /====================\
   // | Sum 1 to 9 Program |
   // \====================/
   //
   // Program to test RV32I
   // Add 1,2,3,...,9 (in that order).
   //
   // Regs:
   //  x12 (a2): 10
   //  x13 (a3): 1..10
   //  x14 (a4): Sum
   // 
   // Uncomment the next m4_asm lines to enable the 1 to 9 sum test program
   // m4_asm(ADDI, x14, x0, 0)             // Initialize sum register a4 with 0
   // m4_asm(ADDI, x12, x0, 1010)          // Store count of 10 in register a2.
   // m4_asm(ADDI, x13, x0, 1)             // Initialize loop count register a3 with 0
   // Loop:
   // m4_asm(ADD, x14, x13, x14)           // Incremental summation
   // m4_asm(ADDI, x13, x13, 1)            // Increment loop count by 1
   // m4_asm(BLT, x13, x12, 1111111111000) // If a3 is less than a2, branch to label named <loop>
   // Test result value in x14, and set x31 to reflect pass/fail.
   // m4_asm(ADDI, x30, x14, 111111010100) // Subtract expected value of 44 to set x30 to 1 if and only iff the result is 45 (1 + 2 + ... + 9).
   // m4_asm(BGE, x0, x0, 0) // Done. Jump to itself (infinite loop). (Up to 20-bit signed immediate plus implicit 0 bit (unlike JALR) provides byte address; last immediate bit should also be 0)
   // m4_asm_end()
   // m4_define(['M4_MAX_CYC'], 50)
   //---------------------------------------------------------------------------------
   m4_test_prog()



\SV
   m4_makerchip_module   // (Expanded in Nav-TLV pane.)
   /* verilator lint_on WIDTH */
\TLV
   
   $reset = *reset;
   
   // Instruction Memory (IMem) puller
   `READONLY_MEM($pc[31:0], $$instr[31:0]);
   
   
   
   // Decode implementation
   
   // 1. Instruction type detection - x is don't care, must be together with ==?
   $is_r_instr = $instr[6:2] == 5'b01011 || 
                 $instr[6:2] ==? 5'b011x0 || 
                 $instr[6:2] == 5'b10100;
   $is_i_instr = $instr[6:2] ==? 5'b0000x || 
                 $instr[6:2] ==? 5'b001x0 || 
                 $instr[6:2] == 5'b11001;
   $is_s_instr = $instr[6:2] ==? 5'b0100x;
   $is_b_instr = $instr[6:2] == 5'b11000;
   $is_u_instr = $instr[6:2] ==? 5'b0x101;
   $is_j_instr = $instr[6:2] == 5'b11011;
   
   // 2. Instruction fields extraction - Don't care the type, unnecessary fields are ignored
   $funct7[6:0] = $instr[31:25];
   $rs2[4:0]    = $instr[24:20]; // Direction of the register 2 to read
   $rs1[4:0]    = $instr[19:15]; // Direction of the register 1 to read
   $funct3[2:0] = $instr[14:12];
   $rd[4:0]     = $instr[11:7]; // Direction of the register to write
   $opcode[6:0] = $instr[6:0];
   
   // 3. Determine when each field is valid or not
   $funct7_valid = $is_r_instr;
   $rs2_valid    = $is_r_instr || $is_s_instr || $is_b_instr;
   $rs1_valid    = $is_r_instr || $is_i_instr || $is_s_instr || $is_b_instr;
   $funct3_valid = $rs1_valid; // Share the same conditions
   $rd_valid     = $is_r_instr || $is_i_instr || $is_u_instr || $is_j_instr;
   $imm_valid    = $is_r_instr == 0;
   
   // 4. Obtain immediate field, depending on the instruction type
   
   $imm[31:0] = $is_i_instr ? {{21{$instr[31]}}, $instr[30:20]} : 
                $is_s_instr ? {{21{$instr[31]}}, $instr[30:25], $instr[11:8], $instr[7]} : 
                $is_b_instr ? {{20{$instr[31]}}, $instr[7], $instr[30:25], $instr[11:8], 1'b0} : 
                $is_u_instr ? {$instr[31:12], 12'b0} : 
                $is_j_instr ? {{12{$instr[31]}}, $instr[19:12], $instr[20], $instr[30:25], $instr[41:21], 1'b0} : 
                32'b0; // Default scenario
   
   // 5. Determine the instruction to execute - load and store not implemented (LB, LH, LW, LBU, LHU, SB, SH, SW)
   $dec_bits[10:0] = {$instr[30],$funct3,$opcode}; // Concatenate the relevant fields
   $is_lui   = $dec_bits ==? 11'bx_xxx_0110111;
   $is_auipc = $dec_bits ==? 11'bx_xxx_0010111;
   $is_jal   = $dec_bits ==? 11'bx_xxx_1101111;
   $is_jalr  = $dec_bits ==? 11'bx_000_1100111;
   $is_beq   = $dec_bits ==? 11'bx_000_1100011;
   $is_bne   = $dec_bits ==? 11'bx_001_1100011;
   $is_blt   = $dec_bits ==? 11'bx_100_1100011;
   $is_bge   = $dec_bits ==? 11'bx_101_1100011;
   $is_bltu  = $dec_bits ==? 11'bx_110_1100011;
   $is_bgeu  = $dec_bits ==? 11'bx_111_1100011;
   $is_addi  = $dec_bits ==? 11'bx_000_0010011;
   $is_slti  = $dec_bits ==? 11'bx_010_0010011;
   $is_sltiu = $dec_bits ==? 11'bx_011_0010011;
   $is_xori  = $dec_bits ==? 11'bx_100_0010011;
   $is_ori   = $dec_bits ==? 11'bx_110_0010011;
   $is_andi  = $dec_bits ==? 11'bx_111_0010011;
   $is_slli  = $dec_bits ==? 11'b0_001_0010011;
   $is_srli  = $dec_bits ==? 11'b0_101_0010011;
   $is_srai  = $dec_bits ==? 11'b1_101_0010011;
   $is_add   = $dec_bits ==? 11'b0_000_0110011;
   $is_sub   = $dec_bits ==? 11'b1_000_0110011;
   $is_sll   = $dec_bits ==? 11'b0_001_0110011;
   $is_slt   = $dec_bits ==? 11'b0_010_0110011;
   $is_sltu  = $dec_bits ==? 11'b0_011_0110011;
   $is_xor   = $dec_bits ==? 11'b0_100_0110011;
   $is_srl   = $dec_bits ==? 11'b0_101_0110011;
   $is_sra   = $dec_bits ==? 11'b1_101_0110011;
   $is_or    = $dec_bits ==? 11'b0_110_0110011;
   $is_and   = $dec_bits ==? 11'b0_111_0110011;
   $is_load  = $dec_bits ==? 11'bx_xxx_0000011; // In our implementation, all loads are treated the same way
   
   
   
   // ALU implementation
   
   // 1. SLTU and SLTI (set if less than) results:
   $sltu_rslt[31:0]  = {31'b0, $src1_value < $src2_value};
   $sltiu_rslt[31:0] = {31'b0, $src1_value < $imm};
   
   // 2. SRA and SRAI (shift right arithmetic) results:
   // 2.1. Sign-extended src1, so that even if shifting 31 bits the sign is not lost
   $sext_src1[63:0] = {{32{$src1_value[31]}}, $src1_value};
   // 2.2. 64-bit sign-extended results, to be truncated
   //      Extends $sext_src1 by whatever $src2_value or $src2_value positions say
   $sra_rslt[63:0]  = $sext_src1 >> $src2_value[4:0];
   $srai_rslt[63:0] = $sext_src1 >> $imm[4:0];
   
   // 3. Result computation depending on the instruction
   $result[31:0] = $is_andi    ? $src1_value &  $imm             :
                   $is_ori     ? $src1_value |  $imm             :
                   $is_xori    ? $src1_value ^  $imm             :
                   $is_addi    ? $src1_value +  $imm             :
                   $is_slli    ? $src1_value << $imm[5:0]        :
                   $is_srli    ? $src1_value >> $imm[5:0]        :
                   $is_and     ? $src1_value &  $src2_value      :
                   $is_or      ? $src1_value |  $src2_value      :
                   $is_xor     ? $src1_value ^  $src2_value      :
                   $is_add     ? $src1_value +  $src2_value      :
                   $is_sub     ? $src1_value -  $src2_value      :
                   $is_sll     ? $src1_value << $src2_value[4:0] : // Shift left logical
                   $is_srl     ? $src1_value >> $src2_value[4:0] : // Shift right logical
                   $is_sltu    ? $sltu_rslt                      : // Set if less than - Unsigned
                   $is_sltiu   ? $sltiu_rslt                     : // Set if less than immediate - unsigned
                   $is_lui     ? {$imm[31:12], 12'b0}            : // Load upper immediate
                   $is_auipc   ? $pc + $imm                      : // Add upper immediate to PC
                   $is_jal     ? $pc + 32'd4                     : // Jump and link -> Saves the address of the next instruction into return address reg,then jumps
                   $is_jalr    ? $pc + 32'd4                     : // Jump and link register -> Similar to JAL
                   $is_sra     ? $sra_rslt[31:0]                 : // Shift right arithmetic
                   $is_srai    ? $srai_rslt[31:0]                : // Shift right arithmetic with immediate value
                   $is_slt     ? (($src1_value[31] == $src2_value[31]) ? $sltu_rslt  : {31'b0, $src1_value[31]}) : // Set if less than
                   $is_slti    ? (($src1_value[31] == $imm[31]       ) ? $sltiu_rslt : {31'b0, $src1_value[31]}) : // Set if less than immediate
                   $is_load    ? $src1_value +  $imm             :
                   $is_s_instr ? $src1_value +  $imm             :
                   32'b0; // Default
   
   // 4. Write the result to the register file
   $wr_data[31:0] = $is_load ? $ld_data[31:0] : $result[31:0]; // Multiplex what to write, either DMem loaded data or ALU output
   $wr_en = $rd[4:0] != 5'b0 ? 1:0; // Can write only if rd is not x0, which is designed to be always zero
   
   
   
   // Program Counter implementation with Branching and Jumping Logic
   
   // 1. Identify if the branch/jump is taken or not
   $taken_br = $is_jal  ? 1'b1                       : // Unconditional jump
               $is_beq  ? $src1_value == $src2_value :
               $is_bne  ? $src1_value != $src2_value :
               $is_bltu ? $src1_value <  $src2_value :
               $is_bgeu ? $src1_value >= $src2_value :
               $is_blt  ? ($src1_value <  $src2_value) ^ ($src1_value[31] != $src2_value[31]):
               $is_bge  ? ($src1_value >= $src2_value) ^ ($src1_value[31] != $src2_value[31]):
               1'b0; // Default to zero
   // 2.1. Compute the new PC, as an offset of the current PC for branching and JAL logic
   $br_tgt_pc[31:0] = $pc[31:0] + $imm[31:0];
   // 2.2. Compute the new PC, as src1 + imm for JALR logic
   $jalr_tgt_pc[31:0] = $src1_value[31:0] + $imm[31:0];
   // 3. Choose the new PC, depending on the taken_br value
   $next_pc[31:0] = $reset    ? 0                  :
                    $taken_br ? $br_tgt_pc[31:0]   :
                    $is_jalr  ? $jalr_tgt_pc[31:0] :
                    $pc[31:0] + 4;
   // 4. Make sure PC holds the previous value of next_pc
   $pc[31:0] = >>1$next_pc[31:0];
   
   
   
   // Assert these to end simulation (before Makerchip cycle limit).
   m4+tb()
   *failed = *cyc_cnt > M4_MAX_CYC;
   
   // Register File (RF) puller
   m4+rf(32, 32, $reset, $wr_en, $rd[4:0], $wr_data[31:0], $rs1_valid, $rs1[4:0], $src1_value, $rs2_valid, $rs2[4:0], $src2_value)
   // Dynamic Memory (DMem) load and store
   m4+dmem(32, 32, $reset, $result[6:2], $is_s_instr, $src2_value[31:0], $is_load, $ld_data)
   m4+cpu_viz()
\SV
   endmodule
