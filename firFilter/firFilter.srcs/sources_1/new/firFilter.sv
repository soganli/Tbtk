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
    parameter DATA_RATIO            = 1,    // Ratio of data_clk to system_clk
    parameter FILTER_TYPE           = 0,    // 0: SingleRate , 1:Decimation, 2:Interpolation
    parameter DECIMATION_NUMBER     = 2,    // If this is a Decimation Filter
    parameter INTERPOLATION_NUMBER  = 1,    // If this is an Interpolation Filter
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
    
    
    localparam DSP_DECIM  = (FILTER_TYPE == 0) ? 1 : ((FILTER_TYPE==1) ? DECIMATION_NUMBER : INTERPOLATION_NUMBER);
    localparam DSP_NUMBER = numDsp(DATA_RATIO,FILTER_IS_SYMMETRIC,FILTER_TYPE,DECIMATION_NUMBER,INTERPOLATION_NUMBER,FILTER_LENGTH);
    localparam BUFFER_LEN = FILTER_LENGTH+1;
    genvar i;


    logic   [B_WIDTH-1:0]    COEF_MEM  [FILTER_LENGTH-1:0];
    
    initial
    begin
        $readmemb("firCoefficients.mem", COEF_MEM);
    end
    
    logic   [8-1:0] data_cntr;
    logic           mac_data_v;
    always_ff@(posedge a_clk)
    begin
        if(!a_resetn)
            data_cntr   <= 0;
        else if(s_axis_data_tvalid)
            data_cntr   <= 0;
        else
            data_cntr   <= data_cntr + 1;
            
        mac_data_v      <= ~|data_cntr;        
    end    
    
    logic signed [BUFFER_LEN*A_WIDTH-1:0]  tdata_buffer;
    logic                                  s_axis_data_tvalid_s;
    always_ff@(posedge a_clk)
    begin
        if(s_axis_data_tvalid)
            tdata_buffer    <= {tdata_buffer[(BUFFER_LEN-1)*A_WIDTH-1:0],s_axis_data_tdata};
        s_axis_data_tvalid_s    <= s_axis_data_tvalid;
    end 
    
    logic signed [2*FILTER_LENGTH*A_WIDTH-1:0]  mac_data_in;

    generate
    if(DATA_RATIO == 1)
    always_comb
        mac_data_in <= tdata_buffer;
    else if(DATA_RATIO == 2)
        always_ff@(posedge a_clk)
            mac_data_in                 <= {(BUFFER_LEN/DATA_RATIO-1){tdata_buffer[(BUFFER_LEN-data_cntr*(BUFFER_LEN/DATA_RATIO))*A_WIDTH-1-:A_WIDTH]}};    
    else if(DATA_RATIO == 4)
        for(i=0; i<BUFFER_LEN; i=i+1)
            always_ff@(posedge a_clk)
                    mac_data_in[BUFFER_LEN*A_WIDTH-A_WIDTH*i-1-:A_WIDTH] <= tdata_buffer[(BUFFER_LEN - data_cntr*(BUFFER_LEN/DATA_RATIO))*A_WIDTH-1-:A_WIDTH];                                            
    endgenerate

   
    
    
    logic signed [DSP_NUMBER*(A_WIDTH+B_WIDTH)-1:0] mac_buffer;
    generate
    for(i=0;i<DSP_NUMBER; i=i+1)
    if(i==0)
        mac#
        (
            .DATA_RATIO(DATA_RATIO),
            .PRE_ADDITION(FILTER_IS_SYMMETRIC),
            .POST_ADDITION(0),
            .REGISTER_INPUT(1),
            .REGISTER_OUTPUT(1),
            .MAC_INDEX(DSP_NUMBER-1-i),
            .A_WIDTH(A_WIDTH),
            .B_WIDTH(B_WIDTH),
            .C_WIDTH(A_WIDTH+B_WIDTH),
            .D_WIDTH(A_WIDTH),
            .P_WIDTH(A_WIDTH+B_WIDTH)        
        ) 
        DSP_MAC_MODULE_0 
        (
            .a(mac_data_in[A_WIDTH*(0*FILTER_LENGTH+i)+:A_WIDTH]),       // First  data  to be multiplied
            .b(COEF_MEM[i]),                                           // Second data to be multiplied
            .c(0),                                                     // Data for the post accumulation
            .d(mac_data_in[A_WIDTH*(3*i+1)+:A_WIDTH]),        // Data for the pre addition
            .clk(a_clk),
            .rstn(a_resetn),
            .p(mac_buffer[(A_WIDTH+B_WIDTH)*i+:(A_WIDTH+B_WIDTH)])
        );    
    else if((i == (DSP_NUMBER-1)) && (FILTER_LENGTH%2))
        mac#
        (
            .DATA_RATIO(DATA_RATIO),        
            .PRE_ADDITION(FILTER_IS_SYMMETRIC),
            .POST_ADDITION(1),
            .REGISTER_INPUT(1),
            .REGISTER_OUTPUT(0),
            .MAC_INDEX(DSP_NUMBER-1-i),
            .A_WIDTH(A_WIDTH),
            .B_WIDTH(B_WIDTH),
            .C_WIDTH(A_WIDTH+B_WIDTH),
            .D_WIDTH(A_WIDTH),
            .P_WIDTH(A_WIDTH+B_WIDTH)        
        ) 
        DSP_MAC_MODULE_I 
        (
            .a(mac_data_in[A_WIDTH*(0*FILTER_LENGTH+i)+:A_WIDTH]),       // First  data  to be multiplied
            .b(COEF_MEM[i]),                                            // Second data to be multiplied
            .c(mac_buffer[(A_WIDTH+B_WIDTH)*(i-1)+:(A_WIDTH+B_WIDTH)]), // Data for the post accumulation
            .d(0),                                                      // Data for the pre addition
            .clk(a_clk),
            .rstn(a_resetn),
            .p(mac_buffer[(A_WIDTH+B_WIDTH)*i+:(A_WIDTH+B_WIDTH)])
        );
    else
        mac#
        (
            .DATA_RATIO(DATA_RATIO),        
            .PRE_ADDITION(FILTER_IS_SYMMETRIC),
            .POST_ADDITION(1),
            .REGISTER_INPUT(1),
            .REGISTER_OUTPUT(0),
            .MAC_INDEX(DSP_NUMBER-1-i),
            .A_WIDTH(A_WIDTH),
            .B_WIDTH(B_WIDTH),
            .C_WIDTH(A_WIDTH+B_WIDTH),
            .D_WIDTH(A_WIDTH),
            .P_WIDTH(A_WIDTH+B_WIDTH)        
        ) 
        DSP_MAC_MODULE_I 
        (
            .a(mac_data_in[A_WIDTH*(0*FILTER_LENGTH+i)+:A_WIDTH]),       // First  data  to be multiplied
            .b(COEF_MEM[i]),                                                      // Second data to be multiplied
            .c(mac_buffer[(A_WIDTH+B_WIDTH)*(i-1)+:(A_WIDTH+B_WIDTH)]), // Data for the post accumulation
            .d(mac_data_in[A_WIDTH*(3*i+1)+:A_WIDTH]),        // Data for the pre addition
            .clk(a_clk),
            .rstn(a_resetn),
            .p(mac_buffer[(A_WIDTH+B_WIDTH)*i+:(A_WIDTH+B_WIDTH)])
        );
    endgenerate        
    
    logic signed [(A_WIDTH+B_WIDTH)-1:0]    mac_data;
    always_ff@(posedge a_clk)
        mac_data   <= mac_buffer[DSP_NUMBER*(A_WIDTH+B_WIDTH)-1-:(A_WIDTH+B_WIDTH)];
    
    
    logic signed [(A_WIDTH+B_WIDTH)-1:0]    accum_out;    
    accumulator#
    (
        .A_WIDTH(A_WIDTH+B_WIDTH)       
    ) 
    MacAccumulator 
    (
        .data_in(mac_data),       // First  data  to be multiplied
        .data_in_v(mac_data_v),                                                      // Second data to be multiplied
        .clk(a_clk),
        .rstn(a_resetn),
        .data_out(accum_out)
    );    
    
    
        
    assign  m_axis_data_tdata = accum_out;
    
function int numDsp;
    input int DATA_RATIO,FILTER_IS_SYMMETRIC,FILTER_TYPE,DECIMATION_NUMBER,INTERPOLATION_NUMBER,FILTER_LENGTH;    
        if(FILTER_IS_SYMMETRIC)
        begin
            if(FILTER_TYPE == 0)
                if(FILTER_LENGTH%2)
                    numDsp = (1 + FILTER_LENGTH/(2*DATA_RATIO));
                else
                    numDsp = (FILTER_LENGTH/(2*DATA_RATIO));
            else if(FILTER_TYPE == 1)
                if(FILTER_LENGTH%2)
                    numDsp = (1 + FILTER_LENGTH/(2*DATA_RATIO*DECIMATION_NUMBER));
                else
                    numDsp = (FILTER_LENGTH/(2*DATA_RATIO*DECIMATION_NUMBER));
            else if(FILTER_TYPE == 2)
                if(FILTER_LENGTH%2)
                    numDsp = (1 + FILTER_LENGTH/(2*DATA_RATIO*DECIMATION_NUMBER));
                else
                    numDsp = (FILTER_LENGTH/(2*DATA_RATIO*DECIMATION_NUMBER));            
        end
        else
        begin
             if(FILTER_TYPE == 0)
                if(FILTER_LENGTH%2)
                    numDsp = (1 + FILTER_LENGTH/(DATA_RATIO));
                else
                    numDsp = (FILTER_LENGTH/(DATA_RATIO));
            else if(FILTER_TYPE == 1)
                if(FILTER_LENGTH%2)
                    numDsp = (1 + FILTER_LENGTH/(DATA_RATIO*DECIMATION_NUMBER));
                else
                    numDsp = (FILTER_LENGTH/(DATA_RATIO*DECIMATION_NUMBER));
            else if(FILTER_TYPE == 2)
                if(FILTER_LENGTH%2)
                    numDsp = (1 + FILTER_LENGTH/(DATA_RATIO*DECIMATION_NUMBER));
                else
                    numDsp = (FILTER_LENGTH/(DATA_RATIO*DECIMATION_NUMBER));         
        end    
endfunction
    
endmodule
