`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/13/2019 08:23:07 PM
// Design Name: 
// Module Name: control_unit
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module control_unit(
input [31:0] ins,
output reg store_imm, ALU_src, mem2reg, reg_write, mem_read, mem_write,
ALU_op0, ALU_op1
);

wire [5:0] opcode = ins[5:0];

always @(*)
begin
    casex(opcode)
    6'b00_0011: begin//load instructions
        store_imm = 0; //immidiate of store = ins[31:25, 11:7]
        ALU_src = 1; //1 means from immidiate_extender
        mem2reg = 1;
        reg_write = 1;
        mem_read = 1;
        mem_write = 0;
        {ALU_op1, ALU_op0} = 2'b00; //this means ALU_sel = add
        end
        
    6'b10_0011: begin//store instructions
        store_imm = 1;
        ALU_src = 1; //1 means from immidiate_extender
        mem2reg = 0;
        reg_write = 0;
        mem_read = 0;
        mem_write = 1;
        {ALU_op1, ALU_op0} = 2'b00; //this means ALU_sel = add
        end

    6'b01_0011: begin//I-format instructions
        store_imm = 0;
        ALU_src = 1; //1 means from immidiate_extender
        mem2reg = 0;
        reg_write = 1;
        mem_read = 0;
        mem_write = 0;
        {ALU_op1, ALU_op0} = 2'b11; //this means ALU_sel same ass R-format
        end
    
    6'b11_0011: begin//R-format instructions
        store_imm = 0;
        ALU_src = 0; //0 means rs2
        mem2reg = 0;
        reg_write = 1;
        mem_read = 0;
        mem_write = 0;
        {ALU_op1, ALU_op0} = 2'b10; //this means ALU_sel same ass R-format
        end
 
    
    default: begin
        store_imm = 1'bx;
        ALU_src = 1'bx; //1 means from immidiate_extender
        mem2reg = 1'bx;
        reg_write = 1'bx;
        mem_read = 1'bx;
        mem_write = 1'bx;
        {ALU_op1, ALU_op0} = 2'bxx; //this means ALU_sel = add
        end

    endcase
end

endmodule



module control_tb;
reg clk;
wire store_imm, ALU_src, mem2reg, reg_write, mem_read, mem_write, ALU_op0, ALU_op1;
reg [31:0] ins;


control_unit control(.ins(ins), .store_imm(store_imm), .ALU_src(ALU_src),
 .mem2reg(mem2reg), .reg_write(reg_write), .mem_read(mem_read), .mem_write(mem_write),
.ALU_op0(ALU_op0), .ALU_op1(ALU_op1));


initial
begin
    clk = 0;
    forever #5 clk = ~clk;
end

initial
begin

ins = 32'h00500113; //addi x2, x0, 5
#10;
ins = 32'h00100133; //add x2, x0, x1
#10;
ins = 32'h00002103; //lw x2, 0(x0)
#10;
ins = 32'h00202023;//sw x2, 0(x0)
#10;

$finish;
end


endmodule




