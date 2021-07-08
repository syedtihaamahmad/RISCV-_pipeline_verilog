`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/13/2019 09:16:56 PM
// Design Name: 
// Module Name: risc_top
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


module risc_top(
input clk,
input rstn // active low asynchronous reset
    );
    

reg en;
wire PC_write, IF_ID_write, control_stall; //wires for hazard detect

initial
begin
    en = 1;
end

//program counter
wire [6:0] imem_addr;
pc program_counter(.pc_out(imem_addr), .rstn(rstn), .clk(clk), .halt(~PC_write));

//I-mem
wire [31:0] ins;
single_port_rom imem(.addr(imem_addr),.clk(clk), .q(ins));

//IF_ID
//-------------------------------------------------------------------------------//
wire [31:0] IF_ID_ins;
DFF #(.N(32)) FF_IF_ID_ins(.D(ins), .en(IF_ID_write), .rstn(rstn), .clk(clk), .Q(IF_ID_ins));
//-------------------------------------------------------------------------------//

// control Unit
wire store_imm, ALU_src, mem2reg, reg_write, mem_read, mem_write, ALU_op0, ALU_op1;
control_unit control(.ins(IF_ID_ins), .store_imm(store_imm), .ALU_src(ALU_src),
 .mem2reg(mem2reg), .reg_write(reg_write), .mem_read(mem_read), .mem_write(mem_write),
.ALU_op0(ALU_op0), .ALU_op1(ALU_op1));

// stalling mux
wire mx_ALU_src, mx_mem_read, mx_mem_write, mx_mem2reg, mx_reg_write;
mux_2x1 #(.N(5)) nop_mux(
.A0({ALU_src, mem_read, mem_write, mem2reg, reg_write}), 
.A1({5'b00000}), .sel(control_stall), 
.out({mx_ALU_src, mx_mem_read, mx_mem_write, mx_mem2reg, mx_reg_write}));


//regfile
wire [4:0] addr1 = IF_ID_ins[19:15]; //input
wire [4:0] addr2 = IF_ID_ins[24:20]; //input
wire [4:0] rd_addr = IF_ID_ins[11:7]; //input
wire [31:0] rs1, rs2; //outputs
wire [31:0] rd; //************* use this wire for loop back
wire [4:0] MEM_WB_rd_addr; //for pipeline, loopback
wire MEM_WB_reg_write;
regfile register(.addr1(addr1), .addr2(addr2), .rd_addr(MEM_WB_rd_addr),
.reg_write(MEM_WB_reg_write),.clk(clk),
.rs1(rs1), .rs2(rs2), .rd(rd)
);


//ALU control
wire [1:0] alu_op = {ALU_op1,ALU_op0};
wire [2:0] func3 = IF_ID_ins[14:12];
wire func7 = IF_ID_ins[30];
wire [3:0] ALU_sel;
ALU_control_unit ALU_ctrl(
.alu_op(alu_op),
.func3(func3),
.func7(func7),
.ALU_sel(ALU_sel));

//immidiate generator
wire [31:0] imm;
imm_generator imm_gen(.ins(IF_ID_ins),.sw(store_imm),.imm(imm));

wire [31:0] ID_EXE_rs1_input, ID_EXE_rs2_input; //coming from rs_select mux

//ID_EXE
//-------------------------------------------------------------------------------//
wire [31:0] ID_EXE_rs1, ID_EXE_rs2, ID_EXE_imm;
wire [4:0] ID_EXE_rd_addr;
DFF #(.N(32)) FF_ID_EXE_rs1(.D(ID_EXE_rs1_input), .en(en), .rstn(rstn), .clk(clk), .Q(ID_EXE_rs1));
DFF #(.N(32)) FF_ID_EXE_rs2(.D(ID_EXE_rs2_input), .en(en), .rstn(rstn), .clk(clk), .Q(ID_EXE_rs2));
DFF #(.N(32)) FF_ID_EXE_imm(.D(imm), .en(en), .rstn(rstn), .clk(clk), .Q(ID_EXE_imm));
DFF #(.N(5)) FF_ID_EXE_rd_addr(.D(rd_addr), .en(en), .rstn(rstn), .clk(clk), .Q(ID_EXE_rd_addr));
wire ID_EXE_alu_src;
wire [3:0] ID_EXE_alu_sel; 
DFF #(.N(4)) FF_ID_EXE_alu_sel(.D(ALU_sel), .en(en), .rstn(rstn), .clk(clk), .Q(ID_EXE_alu_sel));
DFF #(.N(1)) FF_ID_EXE_alu_src(.D(mx_ALU_src), .en(en), .rstn(rstn), .clk(clk), .Q(ID_EXE_alu_src));
//signals forwarded exactly to next stage
wire ID_EXE_mem_read, ID_EXE_mem_write; //used in mem stage
wire ID_EXE_mem2reg, ID_EXE_reg_write; //used in write back stage
DFF #(.N(1)) FF_ID_EXE_mem_read(.D(mx_mem_read), .en(en), .rstn(rstn), .clk(clk), .Q(ID_EXE_mem_read));
DFF #(.N(1)) FF_ID_EXE_mem_write(.D(mx_mem_write), .en(en), .rstn(rstn), .clk(clk), .Q(ID_EXE_mem_write));
DFF #(.N(1)) FF_ID_EXE_mem2reg (.D(mx_mem2reg), .en(en), .rstn(rstn), .clk(clk), .Q(ID_EXE_mem2reg));
DFF #(.N(1)) FF_ID_EXE_reg_write (.D(mx_reg_write), .en(en), .rstn(rstn), .clk(clk), .Q(ID_EXE_reg_write));

//Addr for data forwarding
// addr1, addr2
wire [4:0] ID_EXE_addr1, ID_EXE_addr2;
DFF #(.N(5)) FF_ID_EXE_addr1(.D(addr1), .en(en), .rstn(rstn), .clk(clk), .Q(ID_EXE_addr1));
DFF #(.N(5)) FF_ID_EXE_addr2(.D(addr2), .en(en), .rstn(rstn), .clk(clk), .Q(ID_EXE_addr2));
wire [2:0] ID_EXE_func3; //for LB,LBU,etc
DFF #(.N(3)) FF_ID_EXE_func3(.D(func3), .en(en), .rstn(rstn), .clk(clk), .Q(ID_EXE_func3));

//-------------------------------------------------------------------------------//


//selector: imm or rs2 
wire [31:0] ALU_b;
wire [31:0] mux_forB_out;
mux_2x1 #(.N(32)) imm_mux(.A0(mux_forB_out), .A1(ID_EXE_imm), .sel(ID_EXE_alu_src), .out(ALU_b));


//ALU
wire [31:0] ALU_out;
wire [31:0] ALU_a;//  = ID_EXE_rs1; //modifyed for data forwarding
ALU alu_unit(
  .a(ALU_a),
  .b(ALU_b),
  .out(ALU_out),
  .sel(ID_EXE_alu_sel)
  );

//EXE_MEM
//-------------------------------------------------------------------------------//
wire [31:0] EXE_MEM_ALU_out, EXE_MEM_rs2;
DFF #(.N(32)) FF_EXE_MEM_ALU_out(.D(ALU_out), .en(en), .rstn(rstn), .clk(clk), .Q(EXE_MEM_ALU_out));
DFF #(.N(32)) FF_EXE_MEM_rs2(.D(mux_forB_out), .en(en), .rstn(rstn), .clk(clk), .Q(EXE_MEM_rs2));
wire [4:0] EXE_MEM_rd_addr;
DFF #(.N(5)) FF_EXE_MEM_rd_addr(.D(ID_EXE_rd_addr), .en(en), .rstn(rstn), .clk(clk), .Q(EXE_MEM_rd_addr));
wire EXE_MEM_mem_read, EXE_MEM_mem_write; //used in mem stage
wire EXE_MEM_mem2reg, EXE_MEM_reg_write; //used in write back stage
DFF #(.N(1)) FF_EXE_MEM_mem_read(.D(ID_EXE_mem_read), .en(en), .rstn(rstn), .clk(clk), .Q(EXE_MEM_mem_read));
DFF #(.N(1)) FF_EXE_MEM_mem_write(.D(ID_EXE_mem_write), .en(en), .rstn(rstn), .clk(clk), .Q(EXE_MEM_mem_write));
DFF #(.N(1)) FF_EXE_MEM_mem2reg (.D(ID_EXE_mem2reg), .en(en), .rstn(rstn), .clk(clk), .Q(EXE_MEM_mem2reg));
DFF #(.N(1)) FF_EXE_MEM_reg_write (.D(ID_EXE_reg_write), .en(en), .rstn(rstn), .clk(clk), .Q(EXE_MEM_reg_write));
//addr for data forwarding
wire [4:0] EXE_MEM_addr2;
DFF #(.N(5)) FF_EXE_MEM_addr2(.D(ID_EXE_addr2), .en(en), .rstn(rstn), .clk(clk), .Q(EXE_MEM_addr2));
wire [2:0] EXE_MEM_func3; //for LB,LBU,etc
DFF #(.N(3)) FF_EXE_MEM_func3(.D(ID_EXE_func3), .en(en), .rstn(rstn), .clk(clk), .Q(EXE_MEM_func3));

//-------------------------------------------------------------------------------//


//DMEM
wire dmem_we = EXE_MEM_mem_write;
wire [31:0] dmem_out;
wire [8:0] dmem_addr = EXE_MEM_ALU_out [8:0];
wire [31:0] dmem_data;// = EXE_MEM_rs2; //Now this comes from mux
single_port_ram_with_init dmem(.data(dmem_data),.addr(dmem_addr), .we(dmem_we),.clk(clk), .q(dmem_out),
.func3(EXE_MEM_func3)); //to deal with LB,LBU,LH, etc

//MEM_WB
//-------------------------------------------------------------------------------//
wire [31:0] MEM_WB_ALU_out, MEM_WB_dmem_out;
DFF #(.N(32)) FF_MEM_WB_dmem_out(.D(dmem_out), .en(en), .rstn(rstn), .clk(clk), .Q(MEM_WB_dmem_out));
DFF #(.N(32)) FF_MEM_WB_ALU_out(.D(EXE_MEM_ALU_out), .en(en), .rstn(rstn), .clk(clk), .Q(MEM_WB_ALU_out));
wire MEM_WB_mem2reg; 
//wire MEM_WB_reg_write; //used in write back stage
DFF #(.N(1)) FF_MEM_WB_mem2reg (.D(EXE_MEM_mem2reg), .en(en), .rstn(rstn), .clk(clk), .Q(MEM_WB_mem2reg));
DFF #(.N(1)) FF_MEM_WB_reg_write (.D(EXE_MEM_reg_write), .en(en), .rstn(rstn), .clk(clk), .Q(MEM_WB_reg_write));
//wire [4:0] MEM_WB_rd_addr;
DFF #(.N(5)) FF_MEM_WB_rd_addr(.D(EXE_MEM_rd_addr), .en(en), .rstn(rstn), .clk(clk), .Q(MEM_WB_rd_addr));
//-------------------------------------------------------------------------------//


//write back stage mux
// *** rd assigned to output of mux
mux_2x1 #(.N(32)) wb_mux(.A0(MEM_WB_ALU_out), .A1(MEM_WB_dmem_out), .sel(MEM_WB_mem2reg), .out(rd));

////////////////////////////////////// Data forwarding ////////////////////////////////////
wire [1:0] forwardA, forwardB;
wire forwardC, forwardD, forwardE;

data_forwarding data_forw(.EX_MEM_rd(EXE_MEM_rd_addr), .MEM_WB_rd(MEM_WB_rd_addr),
 .ID_EX_rs1(ID_EXE_addr1), .ID_EX_rs2(ID_EXE_addr2), .EX_MEM_rs2(EXE_MEM_addr2),
 .IF_ID_rs1(addr1), .IF_ID_rs2(addr2),
 .EX_MEM_reg_write(EXE_MEM_reg_write), .MEM_WB_reg_write(MEM_WB_reg_write), .MEM_WB_mem2reg(MEM_WB_mem2reg),
.forwardA(forwardA), .forwardB(forwardB), .forwardC(forwardC), //2 bit sel of mux for rs1 and rs2
 .forwardD(forwardD), .forwardE(forwardE)
);

//modifying line ALU_a = ID_EXE_rs1
//A3 never used. 
wire [31:0] A3;
mux_4x2 #(.N(32)) mux_forwardA(.A0(ID_EXE_rs1),.A1(rd),.A2(EXE_MEM_ALU_out),.A3(A3),.sel(forwardA),.out(ALU_a));

//breaking ID_EXE_rs2 into 2 wires
//wire [31:0] mux_forB_out; //this is provided in place of ID_EXE_rs2 in mux_immediate
mux_4x2 #(.N(32)) mux_forwardB(.A0(ID_EXE_rs2),.A1(EXE_MEM_ALU_out),.A2(rd),.A3(A3),.sel(forwardB),.out(mux_forB_out));

//mem to mem transfer
mux_2x1 #(.N(32)) mem_transfer_mux(.A0(EXE_MEM_rs2), .A1(MEM_WB_dmem_out), .sel(forwardC), .out(dmem_data));

//rs1 to ID_EXE_rs1 pipeline register
mux_2x1 #(.N(32)) rs1_mux(.A0(rs1), .A1(rd), .sel(forwardD), .out(ID_EXE_rs1_input));
mux_2x1 #(.N(32)) rs2_mux(.A0(rs2), .A1(rd), .sel(forwardE), .out(ID_EXE_rs2_input));


////////////////////////////////////// Hazard Detection ////////////////////////////////////

hazard_detection_unit hazard_prot(
.ins(IF_ID_ins),
.ID_EXE_rd(ID_EXE_rd_addr),
.ID_EXE_mem_read(ID_EXE_mem_read), // for load only
.ID_EXE_mem_write(mem_write), //for store only
.PC_write(PC_write), .IF_ID_write(IF_ID_write), .control_stall(control_stall));




endmodule



module risc_tb;
reg clk, rstn;

risc_top ab_risc(.clk(clk), .rstn(rstn));

initial
begin
    clk = 0;
    forever #5 clk = ~clk;
end


initial
begin
rstn = 0;
#10;
    rstn = 1;
    #200;
    $finish;

end


//addi x1, x0, 5
//addi x3, x1, 4
//add x2, x0, x1
//lw x4, 0(x0)
//addi x1, x0, 5
//addi x1, x0, 5
//sw x3, 1(x0)
//add x3, x1, x3 

endmodule

