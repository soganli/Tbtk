`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Abdurrahim Soğanlı
// 
// Create Date: 04/23/2022 02:49:29 PM
// Design Name: 
// Module Name: mac
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


module mac#(
    parameter PRE_ADDITION    = 1,
    parameter POST_ADDITION   = 1,
    parameter REGISTER_INPUT  = 1,
    parameter REGISTER_OUTPUT = 1,
    parameter A_WIDTH         = 16,
    parameter B_WIDTH         = 16,
    parameter C_WIDTH         = 32,
    parameter D_WIDTH         = 16,
    parameter P_WIDTH         = 32    
    )(
    input   signed  [A_WIDTH-1:0]   a,  // First  data  to be multiplied
    input   signed  [B_WIDTH-1:0]   b,  // Second data to be multiplied
    input   signed  [C_WIDTH-1:0]   c,  // Data for the post accumulation
    input   signed  [D_WIDTH-1:0]   d,  // Data for the pre addition
    
    input                           clk,
    input                           rstn,
    
    output  signed  [P_WIDTH-1:0]   p
    );
    
    
    localparam PRE_ADD_SIZE = max(A_WIDTH,D_WIDTH) + 1;
    localparam PRODUCT_SIZE = PRE_ADD_SIZE + B_WIDTH;
    
    logic signed [A_WIDTH-1:0]  a_reg;
    logic signed [B_WIDTH-1:0]  b_reg;
    logic signed [C_WIDTH-1:0]  c_reg;
    logic signed [D_WIDTH-1:0]  d_reg;
    
    generate
        if(REGISTER_INPUT)
            always_ff@(posedge clk)
            begin
                a_reg   <= a;
                b_reg   <= b;
                c_reg   <= c;
                d_reg   <= d;                
            end
        else
            always_comb
            begin
                a_reg    <= a;
                b_reg    <= b;
                c_reg    <= c;
                d_reg    <= d;
            end
    endgenerate
    
    logic signed [PRE_ADD_SIZE-1 :0]  pre_add;
    logic signed [B_WIDTH-1:0]        b_reg_s;
    logic signed [C_WIDTH-1:0]        c_reg_s;
    generate
        if(PRE_ADDITION)
            always_ff@(posedge clk)
            begin
                b_reg_s   <= b_reg;
                c_reg_s   <= c_reg;
                pre_add   <= a_reg + d_reg;
            end
        else
            always_comb
            begin
                b_reg_s  <= b_reg;
                c_reg_s  <= c_reg;
                pre_add  <= a_reg;
            end                        
    endgenerate    
    
    logic signed [PRODUCT_SIZE-1:0] p_mid;
    always_ff@(posedge clk)
        p_mid   <= b_reg_s * pre_add;
    
    logic signed [PRODUCT_SIZE-1:0] p_pre,p_reg;
    generate
        if(POST_ADDITION)
        always_ff@(posedge clk)
            p_pre   <= p_mid + c_reg_s;
        else
        always_comb
            p_pre   <= p_mid;
    endgenerate
            
    generate
        if(REGISTER_OUTPUT)
            always_ff@(posedge clk)
                p_reg   <= p_pre;
        else
            always_comb
                p_reg   <= p_pre;
    endgenerate 
    
    assign p = p_reg;  
        
function int max;
    input int a,b;
    max = (a>b) ? a : b; 
endfunction
    
endmodule





