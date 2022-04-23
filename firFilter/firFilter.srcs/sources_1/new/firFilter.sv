`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/23/2022 10:34:29 PM
// Design Name: 
// Module Name: firFilter
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

module firFilter#(
    parameter DATA_RATIO            = 1,           // Ratio of data_clk to system_clk
    parameter FILTER_TYPE           = 0,          // 0: SingleRate , 1:Decimation, 2:Interpolation
    parameter DECIMATION_NUMBER     = 1, // If this is a Decimation Filter
    parameter INTERPOLATION_NUMBER  = 1, // If this is an Interpolation Filter
    parameter FILTER_LENGTH         = 31,
    parameter FILTER_IS_SYMMETRIC   = 1,
    parameter A_WIDTH               = 16,
    parameter B_WIDTH               = 16,
    parameter O_WIDTH               = A_WIDTH+B_WIDTH
)(
    input   signed [A_WIDTH-1:0]   s_axis_data_tdata,
    output                         s_axis_data_tready,
    input                          s_axis_data_tvalid,
    
    input                          a_clk,
    input                          a_resetn,
    
    output  signed [O_WIDTH-1:0]   m_axis_data_tdata,
    output                         m_axis_data_tvalid
    );
    
    localparam DSP_NUMBER = (FILTER_LENGTH/2+1);

    logic   [B_WIDTH-1:0]    COEF_MEM  [FILTER_LENGTH-1:0];
    
    initial
    begin
        $readmemb("firCoefficients.mem", COEF_MEM);
    end
    

    
    logic signed [(FILTER_LENGTH/2+1)*A_WIDTH-1:0]  tdata_buffer;
    always_ff@(posedge a_clk)
        if(s_axis_data_tvalid)
            tdata_buffer    <= {tdata_buffer[(FILTER_LENGTH/2)*A_WIDTH-1:0],s_axis_data_tdata};
    
    
    logic signed [DSP_NUMBER*(A_WIDTH+B_WIDTH)-1:0] mac_buffer;
    genvar i;
    generate
    for(i=0;i<DSP_NUMBER; i=i+1)
    if(i==0)
        mac#
        (
            .PRE_ADDITION(FILTER_IS_SYMMETRIC),
            .POST_ADDITION(0),
            .REGISTER_INPUT(1),
            .REGISTER_OUTPUT(1),
            .A_WIDTH(A_WIDTH),
            .B_WIDTH(B_WIDTH),
            .C_WIDTH(A_WIDTH+B_WIDTH),
            .D_WIDTH(A_WIDTH),
            .P_WIDTH(A_WIDTH+B_WIDTH)        
        ) 
        DSP_MAC_MODULE_0 
        (
            .a(tdata_buffer[A_WIDTH*i+:A_WIDTH]),                       // First  data  to be multiplied
            .b(COEF_MEM[i]),                                                      // Second data to be multiplied
            .c(0),                                                      // Data for the post accumulation
            .d(tdata_buffer[A_WIDTH*(DSP_NUMBER-i)-1-:A_WIDTH]),          // Data for the pre addition
            .clk(a_clk),
            .rstn(a_resetn),
            .p(mac_buffer[(A_WIDTH+B_WIDTH)*i+:(A_WIDTH+B_WIDTH)])
        );    
    else
        mac#
        (
            .PRE_ADDITION(FILTER_IS_SYMMETRIC),
            .POST_ADDITION(1),
            .REGISTER_INPUT(1),
            .REGISTER_OUTPUT(1),
            .A_WIDTH(A_WIDTH),
            .B_WIDTH(B_WIDTH),
            .C_WIDTH(A_WIDTH+B_WIDTH),
            .D_WIDTH(A_WIDTH),
            .P_WIDTH(A_WIDTH+B_WIDTH)        
        ) 
        DSP_MAC_MODULE_I 
        (
            .a(tdata_buffer[A_WIDTH*i+:A_WIDTH]),                       // First  data  to be multiplied
            .b(COEF_MEM[i]),                                                      // Second data to be multiplied
            .c(mac_buffer[(A_WIDTH+B_WIDTH)*(i-1)+:(A_WIDTH+B_WIDTH)]), // Data for the post accumulation
            .d(tdata_buffer[A_WIDTH*(DSP_NUMBER-i)-1-:A_WIDTH]),          // Data for the pre addition
            .clk(a_clk),
            .rstn(a_resetn),
            .p(mac_buffer[(A_WIDTH+B_WIDTH)*i+:(A_WIDTH+B_WIDTH)])
        );
    endgenerate        
    
    logic signed [(A_WIDTH+B_WIDTH)-1:0]    filter_out;
    always_ff@(posedge a_clk)
        filter_out   <= mac_buffer[DSP_NUMBER*(A_WIDTH+B_WIDTH)-1-:(A_WIDTH+B_WIDTH)];
        
    assign  m_axis_data_tdata = filter_out;
endmodule
