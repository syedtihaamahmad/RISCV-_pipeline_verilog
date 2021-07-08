`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/13/2019 07:29:48 PM
// Design Name: 
// Module Name: pc
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


module pc(
input clk,
input rstn, halt,
output reg[6:0] pc_out

);
initial
begin
pc_out = 32'd0;
end

always @ (posedge clk, negedge rstn) begin
	if(rstn == 0)
	       pc_out <= 32'd0;
	else 
	begin
	   if(halt == 0)
	       pc_out <= pc_out + 32'd1;
	   else pc_out <= pc_out;
	 
	end
end
endmodule



module pc_tb;
reg clk, pc_halt;
wire [31:0] pc_out;

pc pc_instance(.pc_out(pc_out), .clk(clk), .halt(pc_halt));

initial
begin
    clk = 0;
    forever #5 clk = ~clk;
end


integer k;
initial
begin
    pc_halt=0;
    for(k=0; k<10; k=k+1)
    begin
        #10 $display("pc = %d",pc_out);
    end

    pc_halt=1;
    for(k=0; k<10; k=k+1)
    begin
        #10 $display("pc = %d",pc_out);
    end

$finish;
end


endmodule
