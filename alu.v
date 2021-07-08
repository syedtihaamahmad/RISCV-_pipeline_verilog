`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/13/2019 03:58:15 PM
// Design Name: 
// Module Name: ALU
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

module ALU_tb;
    reg [1:0] alu_op;
    reg [2:0] func3;
    reg func7;
    
    //ALU in outs
    reg [31:0] a,b;
    wire [31:0] out;
    wire [31:0] ff_out;
    
    reg en, clk, rstn;
  
  wire [3:0] ALU_sel;
  
  ALU_control_unit DUT(
  .alu_op(alu_op),
  .func3(func3),
  .func7(func7),
  .ALU_sel(ALU_sel));
  
  ALU  DUT2(
  .a(a),
  .b(b),
  .out(out),
  .sel(ALU_sel)
  );
  
  DFF #(.N(32)) alu_ff(.D(out), .en(en), .rstn(rstn), .clk(clk), .Q(ff_out));
  
  initial
  begin
    clk = 0;
      forever #5 clk = ~clk;
  end
  
  initial 
    begin
    func7 = 0;
    rstn = 1;
    en = 1;
    
    a = 4; b = 4;
      $display("Hello, World");
      alu_op = 2'b10; func3 = 3'b000; #10 
        $display("add sel=%d, res=%d, ff=%d", ALU_sel,out, ff_out);
        a = -3; b = 0;#10;
        #5 $display("add sel=%d, res=%d, ff=%d", ALU_sel,out, ff_out);
        
        
        func7 = 1;
        func3 = 3'b000; #10
        $display("sub sel=%d, res=%d, ff=%d", ALU_sel,out, ff_out);
        
        func7 = 0;
        func3 = 3'b001; #10
        $display("sll sel=%d, res=%d, ff=%d", ALU_sel,out, ff_out);
        
        func3 = 3'b010; #10 
        $display("slt sel=%d, res=%d, ff=%d", ALU_sel,out, ff_out);
        
        func3 = 3'b011; #10 
        $display("sltu sel=%d, res=%d, ff=%d", ALU_sel,out, ff_out);
        
        func3 = 3'b100; #10 
        $display("xor sel=%d, res=%d, ff=%d", ALU_sel,out, ff_out);
      
        func3 = 3'b101; #10 
        $display("srl sel=%d, res=%d, ff=%d", ALU_sel,out, ff_out);
        
        func7 = 1;
        func3 = 3'b101; #10 
        $display("sra sel=%d, res=%d, ff=%d", ALU_sel,out, ff_out);
        
        
        func7 = 0;
        func3 = 3'b110; #10 
        $display("or sel=%d, res=%d, ff=%d", ALU_sel,out, ff_out);
        
        func3 = 3'b111; #10 
        $display("and sel=%d, res=%d, ff=%d", ALU_sel,out, ff_out);
        

      
      $finish ;
    end
endmodule



module ALU_control_unit(
input [1:0] alu_op,
input [2:0] func3,
input func7,
output reg [3:0] ALU_sel
);

wire [5:0] concat = {alu_op,func7,func3}; 

always@(*)
begin
    casex(concat)
    6'b00xxxx: ALU_sel = 4'b0001; //for loads and stores: add
    //6'b01xxxx:    //for branch. Not supported
    6'b10_0000: ALU_sel = 4'b0001; //add
    6'b10_1000: ALU_sel = 4'b0010; //sub
    6'b10_0001: ALU_sel = 4'b0011; //shift left logical
    6'b10_0010: ALU_sel = 4'b0100; //set less than
    6'b10_0011: ALU_sel = 4'b0101; //set less than unsigned
    6'b10_0100: ALU_sel = 4'b0110; //xor
    6'b10_0101: ALU_sel = 4'b0111; //shift right logical
    6'b10_1101: ALU_sel = 4'b1000; //shift right arithmetic
    6'b10_0110: ALU_sel = 4'b1001; //or
    6'b10_0111: ALU_sel = 4'b1010; //and
    
    //select line for immediate instructions(for I format, func7 doesn't exist for most)
    6'b11_x000: ALU_sel = 4'b0001; //add
    6'b11_x010: ALU_sel = 4'b0100; //slti
    6'b11_x011: ALU_sel = 4'b0101; //sltiu
    6'b11_x100: ALU_sel = 4'b0110; //xori
    6'b11_x110: ALU_sel = 4'b1001; //ori    
    6'b11_x111: ALU_sel = 4'b1010; //andi
    //**different sel from others
    6'b11_0001: ALU_sel = 4'b1011; //slli**
    6'b11_0101: ALU_sel = 4'b1100; //srli**
    6'b11_1101: ALU_sel = 4'b1101; //srai**
    
                
    
    default: ALU_sel = 4'b0000; // reset, nop
    endcase

// alu_op generator. If 
end
endmodule

//ALU out , a, b
module ALU
(input [31:0] a,b,
input [3:0] sel,
output reg [31:0] out
);
//shift amount value for I format
wire [4:0] shamt = b[4:0];


always @ (*)
begin
    case(sel)
    4'b0000: out = 0;   //zero
    4'b0001: out = a+b; //add
    4'b0010: out = a-b; //sub
    4'b0011: out = a<<b; //shift "a" left logical by "b" 
    4'b0100: out = ($signed(a)<$signed(b)? 32'd1: 32'd0); //set less than
    4'b0101: out = (a<b? 32'd1: 32'd0); //set less than unsigned: a and b are unsigned by default
    4'b0110: out = a^b; //xor
    4'b0111: out = a>>b; //shift right logical
    4'b1000: out = $signed(a)>>>b; //shift right arithmetic ***$signed is necesscary
    4'b1001: out = a|b; //or
    4'b1010: out = a&b; //and && is used in if condition
    //SHAMT instructions
    4'b1011: out = a<<shamt; //slli** shift amount(shamt) is unsigned 5 bit
    4'b1100: out = a>>shamt;//srli
    4'b1101: out = $signed(a)>>>shamt;//srai
    default: out = 32'hxxxx;
    endcase


end
endmodule



module DFF
#(parameter N = 32)
(
input [N-1:0] D,
input clk, en, rstn,
output reg [N-1:0] Q
);
initial begin
Q = 0;
end


always @ (posedge clk, negedge rstn)
begin
    if(rstn == 0)
        Q <= 0;
    else if (en)
        Q <= D;
    
end
endmodule









