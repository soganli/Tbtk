`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/03/2022 02:28:19 PM
// Design Name: 
// Module Name: memoryGenerator
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


module memoryGenerator#(
        parameter DATA_WIDTH = 32,
        parameter ADDR_REG  = 1,
        parameter OUTPUT_REG= 1,
        parameter MEMORY_SIZE = 2048 
    )
    (
        input   [11-1:0]  ADDR,
        input             CLK,
    
        output  logic [DATA_WIDTH-1:0]    DATA_OUT
    );
    
    logic   [DATA_WIDTH-1:0]    ROM_MEMORY  [MEMORY_SIZE-1:0];
    
    initial
    begin
        $readmemb("toaCoefficients.mem", ROM_MEMORY);
    end
    
    logic   [11-1:0]            ADDR_S;
    logic   [DATA_WIDTH-1:0]    DATA_OUT_PRE,DATA_OUT_INTER;
    
    always@(posedge CLK)
        DATA_OUT_INTER  <=  ROM_MEMORY[ADDR_S];
    generate
        if(ADDR_REG)
            always_ff@(posedge CLK)        
                ADDR_S  <= ADDR;
        else
            always_comb ADDR_S  = ADDR;   
        
        if(OUTPUT_REG)
            always_ff@(posedge CLK)        
                DATA_OUT_PRE  <= DATA_OUT_INTER;
        else
            always_comb DATA_OUT_PRE  = DATA_OUT_INTER;
                                             
    endgenerate    
    
    always_comb   DATA_OUT = DATA_OUT_PRE;
    
endmodule
