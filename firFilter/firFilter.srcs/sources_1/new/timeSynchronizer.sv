`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/03/2022 01:54:39 PM
// Design Name: 
// Module Name: timeSynchronizer
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
module timeSynchronizer#(
    parameter   TOA_SIZE        = 45,
    parameter   SECOND_CYCLE_NUM= 250000000, 
    parameter   CNTR_SIZE       = 29
    )(
    input   rst_on_next_pps,
    input   one_pps,
    
    input   clk,
    input   rstn,
    
    output  logic   [TOA_SIZE-1:0]  toa_counter
    );
    
    logic   rst_on_next_pps_reg, one_pps_reg1, one_pps_reg2, one_pps_reg3, one_pps_rise;
    always_ff@(posedge clk)
    begin
        one_pps_reg1        <= one_pps;
        one_pps_reg2        <= one_pps_reg1;
        one_pps_reg3        <= one_pps_reg2;
        one_pps_rise        <= one_pps_reg2 && (~one_pps_reg3);
        rst_on_next_pps_reg <= rst_on_next_pps; 
    end      

    logic       toa_rst;   
    logic       [CNTR_SIZE-1:0]    second_counter=0; 
    logic   signed  [CNTR_SIZE-1:0]    cycle_diff;
    always_ff@(posedge clk)
    begin
        toa_rst <= rst_on_next_pps_reg &&  one_pps_rise;   
        
        if(one_pps_rise)
        begin
            second_counter  <= 0;   
            cycle_diff      <= second_counter - SECOND_CYCLE_NUM;
        end
        else
        begin
            second_counter  <= second_counter + 1;
            cycle_diff      <= cycle_diff;
        end
    end    

    logic   [TOA_SIZE-1:0]  time_counter=0;
    always_ff@(posedge clk)
    begin
        if(toa_rst)
            time_counter    <= 0;
        else
            time_counter    <= time_counter + 1;    
    end
        
    logic   [11-1:0]    coeff_addr;
    always_ff@(posedge clk)
    begin
        if(cycle_diff > 1023)
            coeff_addr  <= 1023;
        else if(cycle_diff < -1024)
            coeff_addr  <= -1024;
        else
            coeff_addr  <= cycle_diff[11-1:0];
    end    
    
    logic   [CNTR_SIZE-1:0] time_coefficient;
    memoryGenerator #(
        .DATA_WIDTH(CNTR_SIZE), 
        .ADDR_REG(1), 
        .OUTPUT_REG(1), 
        .MEMORY_SIZE(2048)
        ) coefficientMemory(.ADDR(coeff_addr), .CLK(clk), .DATA_OUT(time_coefficient));

    logic   [TOA_SIZE+1:0]    time_corrected;
    //mulNM#(.N(TOA_SIZE),.M(CNTR_SIZE)) timeMultiplier (.A(time_counter) , .B(time_coefficient) , .clk(clk), .P(time_corrected));

    timeMultplier toaMultiplication (
        .CLK(clk),             // input wire CLK
        .A(time_counter),      // input wire [44 : 0] A
        .B(time_coefficient),  // input wire [28 : 0] B
        .P(time_corrected)     // output wire [46 : 0] P
    );
    
    always_ff@(posedge clk)
        toa_counter <= (time_corrected + (1'b1)) >> 1;
       
endmodule
