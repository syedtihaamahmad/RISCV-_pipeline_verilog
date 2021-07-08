`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/14/2019 05:12:20 AM
// Design Name: 
// Module Name: forward_hazard
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


//There are 2 sets of register banks i.e. ID_EX and EX_MEM
//rd is stored in EX_MEM
//rs1 and rs2 of next instruction is stored in ID_EX
module data_forwarding(
input [4:0] EX_MEM_rd, MEM_WB_rd, ID_EX_rs1, ID_EX_rs2, EX_MEM_rs2,
input EX_MEM_reg_write, MEM_WB_reg_write, MEM_WB_mem2reg,
input [4:0] IF_ID_rs1, IF_ID_rs2, //due to limitation of regfile to take extra cycle to write
output reg [1:0] forwardA, forwardB,
output reg forwardC, forwardD, forwardE  //2 bit sel of mux for rs1 and rs2
);

always @ (*)
begin
/*
    // EXE_MEM to ID_EXE forwarding i.e. 1 step back
    if(EX_MEM_reg_write && (EX_MEM_rd != 0) && (EX_MEM_rd == ID_EX_rs1)) 
        forwardA = 2'b10;
    if(EX_MEM_reg_write && (EX_MEM_rd != 0) && (EX_MEM_rd == ID_EX_rs2)) //for read after write
        forwardB = 2'b10;

// to deal with 2nd line after read after write
// MEM_WB to ID_EXE forwarding i.e. 2 steps back
    if(MEM_WB_reg_write && (MEM_WB_rd != 0) 
    && !(EX_MEM_reg_write && (EX_MEM_rd != 0) && (EX_MEM_rd == ID_EX_rs1)) //If this condition is met, data should be forwarded using above 2 conditions
    && (MEM_WB_rd == ID_EX_rs1))
        forwardA = 2'b01;
        
    if(MEM_WB_reg_write && (MEM_WB_rd != 0) 
    && !(EX_MEM_reg_write && (EX_MEM_rd != 0) && (EX_MEM_rd == ID_EX_rs2))
    && (MEM_WB_rd == ID_EX_rs2))
        forwardB = 2'b01;
*/   
    
    //Rewriting the above code to cater all conditions   
    
    //forwardA    
    if(MEM_WB_reg_write && (MEM_WB_rd != 0) //from MEM_WB
    && !(EX_MEM_reg_write && (EX_MEM_rd != 0) && (EX_MEM_rd == ID_EX_rs1)) //If this condition is met, data should be forwarded using above 2 conditions
    && (MEM_WB_rd == ID_EX_rs1))
        forwardA = 2'b01;
    else if(EX_MEM_reg_write && (EX_MEM_rd != 0) && (EX_MEM_rd == ID_EX_rs1)) //from EXE_MEM
        forwardA = 2'b10;
    else // no forwarding 
        forwardA = 2'b00;
    
    //forwardB
    if(MEM_WB_reg_write && (MEM_WB_rd != 0) //from MEM_WB
    && !(EX_MEM_reg_write && (EX_MEM_rd != 0) && (EX_MEM_rd == ID_EX_rs2))
    && (MEM_WB_rd == ID_EX_rs2))
        forwardB = 2'b10;
    else if(EX_MEM_reg_write && (EX_MEM_rd != 0) && (EX_MEM_rd == ID_EX_rs2)) //from EXE_MEM
        forwardB = 2'b01;
    else //no forwarding
        forwardB = 2'b00;
        
    //forwardC: for MEM_WB to EX_MEM forwarding
    //eg.lw x2, 0(x1)
    //   sw x2, 10(x1) //mem to mem transfer
    if(MEM_WB_reg_write &&
     (MEM_WB_mem2reg) && //*** detect if previous ins is load
      (MEM_WB_rd != 0) && (MEM_WB_rd == EX_MEM_rs2))
        forwardC = 1'b1;
    else
        forwardC = 1'b0;
        
        
     //forwardD:Pass rs1 from regfile or MEM_WB to pipeline register
     if(MEM_WB_reg_write && (MEM_WB_rd != 0) //from MEM_WB
        && (MEM_WB_rd == IF_ID_rs1))
        forwardD = 1'b1; //pass ID_EXE_rs1 from MEM_WB stage
     else
        forwardD = 1'b0;
        
     //forwardE:Pass rs2 from regfile or MEM_WB to pipeline register
     if(MEM_WB_reg_write && (MEM_WB_rd != 0) //from MEM_WB
        && (MEM_WB_rd == IF_ID_rs2))
        forwardE = 1'b1; //pass ID_EXE_rs2 from MEM_WB stage
     else
        forwardE = 1'b0;

end

endmodule




module hazard_detection_unit(
input [31:0] ins,
input [4:0] ID_EXE_rd,
input ID_EXE_mem_read, //for load only
input ID_EXE_mem_write, //for store only
output reg PC_write, IF_ID_write, control_stall
);

wire [4:0] IF_ID_rs1, IF_ID_rs2;
assign IF_ID_rs1 = ins[19:15];
assign IF_ID_rs2 = ins[24:20];

always @ (*)
begin
    if(ID_EXE_mem_read //current is load
    && (~ID_EXE_mem_write) //following is not store because we have forwarding to deal with that 
    &&((ID_EXE_rd == IF_ID_rs1) || (ID_EXE_rd == IF_ID_rs2) ))
        begin //stall
        PC_write = 0;
        IF_ID_write = 0;
        control_stall = 1;
        end
    else
        begin //normal operation
        PC_write = 1;
        IF_ID_write = 1;
        control_stall = 0;
        end


end

endmodule



