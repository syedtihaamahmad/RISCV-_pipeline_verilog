`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/13/2019 06:12:01 PM
// Design Name: 
// Module Name: IMEM_rom
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

module single_port_rom
#(parameter DATA_WIDTH=32, parameter ADDR_WIDTH=7)
(
	input [(ADDR_WIDTH-1):0] addr,
	input clk, 
	output reg [(DATA_WIDTH-1):0] q
);

	// Declare the ROM variable
	reg [DATA_WIDTH-1:0] rom[2**ADDR_WIDTH-1:0];

	initial
	begin
	   $display("Loading ROM");
		$readmemh("imem_init.mem",rom);
		$display("Load complete");
		
	end

	always @ (*)
	begin
		q <= rom[addr];
	end

endmodule



module IMEM_tb;
reg clk;
wire [31:0] q;
reg [6:0] addr;

//clock generator
initial
begin
clk = 0;
forever #5 clk = ~clk;
end

single_port_rom imem(.addr(addr),.clk(clk), .q(q));

//// Declare the ROM variable
//	reg [31:0] rom[0:2**7-1];
//	always @ (posedge clk)
//        begin
//            q <= rom[addr];
//        end

////ROM initializer block
//initial
//	begin
//	   $display("Loading ROM");
//		$readmemh("imem_init.mem",rom);
//		$display("Load complete");
//	end

integer k = 0;

initial 
begin
addr = 0;
    for(k = 0; k<5; k= k+1)
    begin
        # 10 $display("addr=%d, val=%d ",addr, q);
        addr = addr+1;
    end

$finish;

end
endmodule