`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/13/2019 09:43:32 PM
// Design Name: 
// Module Name: regfile
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


module regfile(
input [4:0] addr1, addr2, rd_addr,
input reg_write,clk,
input [31:0] rd,
output [31:0] rs1, rs2
    );

reg [31:0] register[31:0];

initial
begin
$display("Initializing regfile");
$readmemh("reg_init.mem",register);
end


assign    rs1 = register[addr1];
assign    rs2 = register[addr2];


always @ (posedge clk)
begin    
    if(reg_write == 1 && (rd_addr != 0))
        register[rd_addr] <= rd;
end
    
    
endmodule



module reg_tb;
reg [4:0] addr1, addr2, rd_addr;
reg reg_write,clk;
wire [31:0] rs1, rs2;
reg [31:0] rd;


regfile register(.addr1(addr1), .addr2(addr2), .rd_addr(rd_addr),
.reg_write(reg_write),.clk(clk),
.rs1(rs1), .rs2(rs2), .rd(rd)
);

initial
begin
    clk = 0;
    forever #5 clk = ~clk;
end

integer k;
initial 
begin
#5;
reg_write = 0;
    for(k = 0; k<10; k=k+1)
    begin
        addr1 = k; addr2 = k+1;
        #10
        $display("pos %d = %d, pos %d = %d", addr1,rs1,addr2,rs2);
    end
    
    
//storing value
rd_addr = 5;
rd = 21;
reg_write = 1;
#10
addr1 = 5;
#10 $display("value at %d = %d", rd_addr, rs1);
    
$finish;
end
endmodule



