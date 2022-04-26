`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/24/2022 12:49:20 AM
// Design Name: 
// Module Name: firFilter_tb
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


module firFilter_tb;
    parameter DATA_RATIO            = 2; // Ratio of data_clk to system_clk
    parameter FILTER_TYPE           = 0; // 0: SingleRate , 1:Decimation, 2:Interpolation
    parameter DECIMATION_NUMBER     = 2; // If this is a Decimation Filter
    parameter INTERPOLATION_NUMBER  = 1; // If this is an Interpolation Filter
    parameter FILTER_LENGTH         = 31;
    parameter FILTER_IS_SYMMETRIC   = 0;
    parameter A_WIDTH               = 16;
    parameter B_WIDTH               = 16;
    parameter O_WIDTH               = A_WIDTH+B_WIDTH;
    

integer i=0,s_axis_data_tdata_file;
localparam SampleNumber = 2 ** 14;
logic [A_WIDTH-1:0] s_axis_data_tdata_set [SampleNumber-1:0];


    
logic a_clk=0,a_resetn=1;    
    
logic signed [A_WIDTH-1:0]  s_axis_data_tdata;
logic signed                s_axis_data_tready;
logic signed                s_axis_data_tvalid;

logic signed [O_WIDTH-1:0]  m_axis_data_tdata;
logic                       m_axis_data_tvalid;


firFilter#(
    .DATA_RATIO(DATA_RATIO),            
    .FILTER_TYPE(FILTER_TYPE),           
    .DECIMATION_NUMBER(DECIMATION_NUMBER),     
    .INTERPOLATION_NUMBER(INTERPOLATION_NUMBER),  
    .FILTER_LENGTH(FILTER_LENGTH),         
    .FILTER_IS_SYMMETRIC(FILTER_IS_SYMMETRIC),   
    .A_WIDTH(A_WIDTH),               
    .B_WIDTH(B_WIDTH),               
    .O_WIDTH(O_WIDTH)            
)
uut
(
    .s_axis_data_tdata(s_axis_data_tdata),
    .s_axis_data_tready(s_axis_data_tready),
    .s_axis_data_tvalid(s_axis_data_tvalid),
    
    .a_clk(a_clk),
    .a_resetn(a_resetn),
    
    .m_axis_data_tdata(m_axis_data_tdata),
    .m_axis_data_tvalid(m_axis_data_tvalid)
    );

logic data_enable;
initial
begin

    s_axis_data_tdata_file = $fopen("/home/soganli/MATLABFiles/firFilter/s_axis_data_tdata.txt", "r");

    while (! $feof(s_axis_data_tdata_file)) begin //read until an "end of file" is reached.
        $fscanf(s_axis_data_tdata_file,"%d\n",s_axis_data_tdata_set[i]); 
        i = i + 1;
    end 
    
    $fclose(s_axis_data_tdata_file);

    data_enable = 0;
    #30;
    data_enable = 1;
    
    #20000;
    $stop;
end   

logic [14-1:0]  data_count=0;
generate
if(DATA_RATIO == 1)

    always_ff@(posedge a_clk)
    begin
        if(data_enable)
        begin
            data_count          <= data_count + 1;
            s_axis_data_tdata   <= s_axis_data_tdata + 1; //s_axis_data_tdata_set[data_count];
            s_axis_data_tvalid  <= 1;
        end
        else
        begin
            data_count          <= 0;
            s_axis_data_tdata   <= 0;
            s_axis_data_tvalid  <= 0;
        end
    end
else
    always_ff@(posedge a_clk)
    begin
        if(data_enable)
        begin
            data_count          <= data_count + 1;
            s_axis_data_tdata   <= data_count[14-1:1]; // s_axis_data_tdata_set[data_count[14-1:1]];
            s_axis_data_tvalid  <= ~data_count[0];
        end
        else
        begin
            data_count          <= 0;
            s_axis_data_tdata   <= 0;
            s_axis_data_tvalid  <= 0;
        end
    end
endgenerate
        
always 
   #2.5 a_clk = ~a_clk;  
    
endmodule

