`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/23/2022 09:55:52 PM
// Design Name: 
// Module Name: mac_tb
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


module mac_tb;
    parameter PRE_ADDITION    = 0;
    parameter POST_ADDITION   = 0;
    parameter REGISTER_INPUT  = 1;
    parameter REGISTER_OUTPUT = 1;
    parameter A_WIDTH         = 16;
    parameter B_WIDTH         = 16;
    parameter C_WIDTH         = 32;
    parameter D_WIDTH         = 16;
    parameter P_WIDTH         = 32;
    
    
logic clk=0,rstn=1;    
    
logic signed [A_WIDTH-1:0]  a;
logic signed [B_WIDTH-1:0]  b;
logic signed [C_WIDTH-1:0]  c;
logic signed [D_WIDTH-1:0]  d;

logic signed [P_WIDTH-1:0]  p;

mac#
(
    .PRE_ADDITION(PRE_ADDITION),
    .POST_ADDITION(POST_ADDITION),
    .REGISTER_INPUT(REGISTER_INPUT),
    .REGISTER_OUTPUT(REGISTER_OUTPUT),
    .A_WIDTH(A_WIDTH),
    .B_WIDTH(B_WIDTH),
    .C_WIDTH(C_WIDTH),
    .D_WIDTH(D_WIDTH),
    .P_WIDTH(P_WIDTH)        
) uut 
(
    .a(a),           // First  data  to be multiplied
    .b(b),           // Second data to be multiplied
    .c(c),           // Data for the post accumulation
    .d(d),           // Data for the pre addition
    .clk(clk),
    .rstn(rstn),
    .p(p)
);


initial
begin
    #30;
    $stop;
end   

always_ff@(posedge clk)
begin
    a <= 66;
    b <= 77;
    c <= 155;
    d <= 200;
end
        
always 
   #2.5 clk = ~clk;  
    
endmodule
