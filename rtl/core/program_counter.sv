module program_counter(
    input  logic clk       ,
    input  logic reset     ,
    input  logic [31:0] src1_value,
    input  logic [31:0] imm_value,
    input  logic is_branch ,
    input  logic is_jump   ,
    output logic [31:0] pc);

    logic [31:0] next_pc;

    // Pure combinational logic to select next pc, will execute whenever any of
    // the involved variables change, regardless of the clock signal
    always @ (*) begin
        if (reset) begin
            next_pc[31:0] = 32'b0;
        end
        else if (is_branch) begin
            next_pc[31:0] = pc[31:0] + imm_value[31:0];
        end
        else if (is_jump) begin
            next_pc[31:0] = src1_value[31:0] + imm_value[31:0];
        end
        else begin
            next_pc[31:0] = pc[31:0] + 32'd4;
        end
    end

    // PC will hold the old value always, unless posedge clock happens
    always @ (posedge clk) begin
        pc[31:0] <= next_pc[31:0];
    end

endmodule