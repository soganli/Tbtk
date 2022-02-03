`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/03/2022 03:46:13 PM
// Design Name: 
// Module Name: timeSynchronizer_tb
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


module timeSynchronizer_tb;

localparam TOA_SIZE = 45;
localparam SECOND_CYCLE_NUM = 2500000;
localparam CNTR_SIZE = 29;


logic rst_on_next_pps;
logic one_pps;
logic clk,rstn;

logic [45-1:0]  toa_counter;

timeSynchronizer#(
    .TOA_SIZE         (TOA_SIZE),
    .SECOND_CYCLE_NUM (SECOND_CYCLE_NUM), 
    .CNTR_SIZE        (CNTR_SIZE)
    )
    uut (
    .rst_on_next_pps(rst_on_next_pps),
    .one_pps(one_pps),
    
    .clk(clk),
    .rstn(rstn),
    
    .toa_counter(toa_counter)
    );



initial
begin
clk = 0;
rstn = 0;
one_pps = 0;
rst_on_next_pps = 0;

#100;

#1000;
one_pps = 1;
#1000;
one_pps = 0;
#10000000;
one_pps = 1;
#1000;
one_pps = 0;
#10000000;
one_pps = 1;
#1000;
one_pps = 0;
#10000000;
one_pps = 1;
#1000;
one_pps = 0;
#10000000;
one_pps = 1;
#1000;
one_pps = 0;
#10000000;
$stop;

end

logic [45-1:0]  diff;

always_comb diff = toa_counter - (uut.time_counter-9);

always 
   #2.0 clk = ~clk;  


endmodule
