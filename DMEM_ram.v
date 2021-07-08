`timescale 1ns / 1ps

module single_port_ram_with_init
#(parameter DATA_WIDTH=8, parameter ADDR_WIDTH=9)
(
	input [31:0] data,
	input [(ADDR_WIDTH-1):0] addr,
	input we, clk,
	output reg [31:0] q,
	input [2:0] func3 //func3
);

	// Declare the RAM variable
	reg [DATA_WIDTH-1:0] ram[2**ADDR_WIDTH-1:0];

	// Variable to hold the registered read address
	reg [ADDR_WIDTH-1:0] addr_reg;

	initial
	begin
	   $display("Loading RAM");
		$readmemh("dmem_init.mem",ram);
		$display("Load complete");
		
	end
	
	
//	initial 
//	begin : INIT
//		integer i;
//		for(i = 0; i < 2**ADDR_WIDTH; i = i + 1)
//			ram[i] = {DATA_WIDTH{1'b1}};
//	end 

	always @ (posedge clk)
	begin
		// Write
		if (we)
			{ram[addr+3],ram[addr+2],ram[addr+1],ram[addr]} <= data;
//        if(re)
//            q <= ram[addr]
		//addr_reg <= addr;
	end

	// Continuous assignment implies read returns NEW data.
	// This is the natural behavior of the TriMatrix memory
	// blocks in Single Port mode.  
	//assign q = {ram[addr+3],ram[addr+2],ram[addr+1],ram[addr]};

    //To accommodate for LB, LBU, LH, LHU, LW 
    
    always @ (*)
    begin
        casex(func3)
        3'b000: q = {{24{ram[addr][7]}},ram[addr]}; //LB signed
        3'b001: q = {{16{ram[addr+1][7]}},ram[addr+1],ram[addr]}; //LH signed
        3'b010: q = {ram[addr+3],ram[addr+2],ram[addr+1],ram[addr]}; //LW
        3'b100: q = {24'd0,ram[addr]}; //LBU unsigned
        3'b101: q = {16'd0,ram[addr+1],ram[addr]}; //LHU unsigned
        default: q = {ram[addr+3],ram[addr+2],ram[addr+1],ram[addr]};
        endcase
    end

endmodule


module DMEM_tb;
reg clk, we;
wire [31:0] q;
reg [8:0] addr;
reg [31:0] data;
reg [2:0] load_b_w_h;

//clock generator
initial
begin
clk = 0;
forever #5 clk = ~clk;
end

single_port_ram_with_init dmem(.data(data),.addr(addr), .we(we),.clk(clk), .q(q), .load_b_w_h(load_b_w_h));

integer k =0;
initial
begin
# 5 we = 0;
addr = 0;
data = 32'hffffabcd;
we = 1;
#5 we = 0;
load_b_w_h = 0;
#10 $display("addr=%d, val=%d",addr, q);
load_b_w_h = 1;
#10 $display("addr=%d, val=%d",addr, q);
load_b_w_h = 2;
#10 $display("addr=%d, val=%d",addr, q);
load_b_w_h = 3;
#10 $display("addr=%d, val=%d",addr, q);
load_b_w_h = 4;
#10 $display("addr=%d, val=%d",addr, q);
load_b_w_h = 5;
#10 $display("addr=%d, val=%d",addr, q);


//    for(k = 0; k<10; k=k+1)
//    begin
        
//        #10 $display("addr=%d, val=%d",addr, q);
//        addr = addr+1;
//    end
    $finish;
end
endmodule




