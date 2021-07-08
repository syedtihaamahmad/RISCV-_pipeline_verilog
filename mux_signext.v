`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/13/2019 09:02:43 PM
// Design Name: 
// Module Name: mux_signext
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

//A0 when sel=0
module mux_2x1
#(parameter N = 32)
(
input [N-1:0] A0,A1,
input  sel,
output reg [N-1:0] out
);

always @ (*)
begin
    if(sel == 0)
        out = A0;
    else
        out = A1;
        
end
endmodule

//A0 when sel=0
module mux_4x2
#(parameter N = 32)
(
input [N-1:0] A0,A1,A2,A3,
input [1:0] sel,
output reg [N-1:0] out
);

always @ (*)
begin
    case(sel)
    2'b00: out = A0;
    2'b01: out = A1;
    2'b10: out = A2;
    2'b11: out = A3;
    endcase
        
end
endmodule




module sign_extend(
input [11:0] in,
output [31:0] out
);

assign out = {{20{in[11]}},in};

endmodule


module imm_generator(
input [31:0] ins,
input sw,
output [31:0] imm
);

wire [6:0] top7 = ins[31:25]; //common in store and I-format
wire [4:0] low5_sw = ins[11:7];
wire [4:0] low5_Iformat = ins[24:20];

wire [4:0] low5;

mux_2x1 #(.N(5)) imm_mux(.A0(low5_Iformat), .A1(low5_sw), .sel(sw), .out(low5));
sign_extend sign_ext(.in({top7,low5}), .out(imm));

endmodule


module imm_gen_tb;
reg [31:0] ins;
reg sw;
wire [31:0] imm;

imm_generator imm_gen(.ins(ins), .sw(sw), .imm(imm));

initial
begin
    sw = 0;
    ins = 32'h00410113;
    #10
    ins = 32'h00a10113;
    #10
    
    $finish;



end


endmodule


