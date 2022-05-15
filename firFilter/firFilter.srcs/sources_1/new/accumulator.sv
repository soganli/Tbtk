`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/15/2022 10:42:47 PM
// Design Name: 
// Module Name: accumulator
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


module accumulator#(
    parameter   A_WIDTH = 16
)(
    input   signed  [A_WIDTH-1:0]   data_in,
    input                           data_in_v,
    
    input                           rstn,
    input                           clk,
    output logic signed   [A_WIDTH-1:0]   data_out
    );
    
    
logic   signed  [A_WIDTH  -1:0] data_accum;
logic   signed  [A_WIDTH  -1:0] data_out_pre;

always_ff@(posedge clk)
begin
    if(data_in_v)
    begin
        data_out_pre    <= data_accum;
        data_accum      <= data_in;
    end
    else
    begin
        data_out_pre    <= data_out_pre;
        data_accum      <= data_accum + data_in;    
    end
end    
    
always_comb
    data_out    = data_out_pre;    
    
    
endmodule
