`timescale 1ns/1ps

module risc_v_program_counter_unit_test_tb;
    logic clk;
    logic reset;
    logic [31:0] src1_value;
    logic [31:0] imm_value;
    logic is_branch;
    logic is_jump;
    logic [31:0] pc;

    program_counter pc_mod(
        .clk(clk),
        .reset(reset),
        .src1_value(src1_value),
        .imm_value(imm_value),
        .is_branch(is_branch),
        .is_jump(is_jump),
        .pc(pc)
    );

    // Monitor the outputs
    initial begin
        $monitor("Time: %0t | clk: %d | reset: %d | src1_value: %d | imm_value: %d | is_branch: %d | is_jump: %d | pc: %d", $time, clk, reset, src1_value, imm_value, is_branch, is_jump, pc);
        $dumpfile("./sim/unit_test/program_counter/program_counter.vcd");
        $dumpvars(0, risc_v_program_counter_unit_test_tb);
    end

    // Oscillating clock
    initial begin
        clk = 0;
        forever #2 clk = ~clk;
    end

    // Events to record
    initial begin
        #10 reset = 1;
        #10 reset = 0;
        #4;
        src1_value = 32'h0000_0012;
        imm_value = 32'h0000_0001;
        is_branch = 1'b1;
        is_jump = 1'b0;
        #4 is_branch = 1'b0;
        #10 is_jump = 1'b1;
        #14 is_jump = 1'b0;
        #10 $finish;
    end
endmodule