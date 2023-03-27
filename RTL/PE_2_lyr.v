`timescale 1ns / 1ns
`define buffer_size  226 * 2 + 3
`define period          10
// 224 * 224 * 3
`define img_max_size    224*224*3+54
`define img_pixels      224 * 224
`define padding_size     (224 + 2) * (224 + 2)
//---------------------------------------------------------------
//You need specify the path of image in/out
//---------------------------------------------------------------
`define path_img_in     "./test_data/cat224.bmp"
`define path_conv1_kernel "./test_data/conv1_kernel_hex.txt"
`define path_conv1_bias "./test_data/conv1_bias_hex.txt"
`define path_img_out_H    "./test_data/cat_after_sobel_H.bmp"
`define path_img_out_V    "./test_data/cat_after_sobel_V.bmp"
`define path_img_gray   "./test_data/cat_gray.bmp"
module conv(
    output signed[35:0] lyr_2_sum,
    output  [7:0] bmp_lyr1_answer,
    output reg [18:0] pass_cnt,
    output write_flag,
    input [63:0] weight,
    input [8:0] padding_data_1,
    input [8:0] padding_data_2,
    input [8:0] padding_data_3,
    input [8:0] padding_data_4,
    input [15:0] bias,
    input clk,
    input rst
);

integer i;
reg  [15:0] R_weight [0:8];
reg  [15:0] G_weight [0:8];
reg  [15:0] B_weight [0:8];
reg  [15:0] D_weight [0:8];

reg [3:0] current_state;
reg [3:0] next_state;

reg signed[35:0] PE_result_1;
reg signed[35:0] PE_result_2;
reg signed[35:0] PE_result_3;
reg signed[35:0] PE_result_4;
 
// Define FSM states
localparam IDLE = 3'b000;
localparam load_buffer = 3'b001;
localparam convolution = 3'b010;
localparam lyr_2_init = 3'b011;
localparam ly2_load_buffer = 3'b100;
localparam ly2_conv = 3'b101;
localparam bias_relu = 3'b110;
localparam DONE = 3'b111;

reg [18:0] buffer_cnt;
reg [11:0] weight_bias_in_cnt;
reg [3:0]  lyr_2_cnt;
reg [5:0]  lyr_2_img_cnt;



reg [8:0] line_buffer_out;
reg signed [15:0] c1_bias;

wire [8:0] LB_1_out1, LB_1_out2, LB_1_out3, LB_1_out4, LB_1_out5, LB_1_out6, LB_1_out7, LB_1_out8, LB_1_out9;
wire [8:0] LB_2_out1, LB_2_out2, LB_2_out3, LB_2_out4, LB_2_out5, LB_2_out6, LB_2_out7, LB_2_out8, LB_2_out9;
wire [8:0] LB_3_out1, LB_3_out2, LB_3_out3, LB_3_out4, LB_3_out5, LB_3_out6, LB_3_out7, LB_3_out8, LB_3_out9;
wire [8:0] LB_4_out1, LB_4_out2, LB_4_out3, LB_4_out4, LB_4_out5, LB_4_out6, LB_4_out7, LB_4_out8, LB_4_out9;

line_buffer LB1( LB_1_out1, LB_1_out2, LB_1_out3, LB_1_out4, LB_1_out5, LB_1_out6, LB_1_out7, LB_1_out8, LB_1_out9, padding_data_1, current_state, clk, rst);
line_buffer LB2( LB_2_out1, LB_2_out2, LB_2_out3, LB_2_out4, LB_2_out5, LB_2_out6, LB_2_out7, LB_2_out8, LB_2_out9, padding_data_2, current_state, clk, rst);
line_buffer LB3( LB_3_out1, LB_3_out2, LB_3_out3, LB_3_out4, LB_3_out5, LB_3_out6, LB_3_out7, LB_3_out8, LB_3_out9, padding_data_3, current_state, clk, rst);
line_buffer LB4( LB_4_out1, LB_4_out2, LB_4_out3, LB_4_out4, LB_4_out5, LB_4_out6, LB_4_out7, LB_4_out8, LB_4_out9, padding_data_4, current_state, clk, rst);

wire signed[35:0] result_1, result_2, result_3, result_4;
wire signed[35:0] lyr_1_sum, lyr_1_sum_relu;

assign lyr_1_sum = result_1 + result_2 + result_3 + result_4 + c1_bias;
assign lyr_2_sum = result_1 + result_2 + result_3 + result_4;
assign lyr_1_sum_relu = (lyr_1_sum < 0) ? 0 :lyr_1_sum;
assign bmp_lyr1_answer = lyr_1_sum_relu[11:4];

PE PE_1(result_1, LB_1_out1, LB_1_out2, LB_1_out3, LB_1_out4, LB_1_out5, LB_1_out6, LB_1_out7, LB_1_out8, LB_1_out9
, R_weight[0], R_weight[1], R_weight[2], R_weight[3], R_weight[4], R_weight[5], R_weight[6], R_weight[7], R_weight[8]);

PE PE_2(result_2, LB_2_out1, LB_2_out2, LB_2_out3, LB_2_out4, LB_2_out5, LB_2_out6, LB_2_out7, LB_2_out8, LB_2_out9
, G_weight[0], G_weight[1], G_weight[2], G_weight[3], G_weight[4], G_weight[5], G_weight[6], G_weight[7], G_weight[8]);

PE PE_3(result_3, LB_3_out1, LB_3_out2, LB_3_out3, LB_3_out4, LB_3_out5, LB_3_out6, LB_3_out7, LB_3_out8, LB_3_out9
, B_weight[0], B_weight[1], B_weight[2], B_weight[3], B_weight[4], B_weight[5], B_weight[6], B_weight[7], B_weight[8]);

PE PE_4(result_4, LB_4_out1, LB_4_out2, LB_4_out3, LB_4_out4, LB_4_out5, LB_4_out6, LB_4_out7, LB_4_out8, LB_4_out9
, D_weight[0], D_weight[1], D_weight[2], D_weight[3], D_weight[4], D_weight[5], D_weight[6], D_weight[7], D_weight[8]);

assign write_flag = (pass_cnt==0 || pass_cnt % 225 == 0 || pass_cnt % 226 == 0) ? 0 : 1;

// Only control signal
always @(*) begin
    case (current_state)
        IDLE: next_state = load_buffer;//0
        load_buffer: //1
        begin
            if(buffer_cnt < `buffer_size) next_state = load_buffer;
            else next_state = convolution;
        end
        convolution: //2
        begin
            if(buffer_cnt < `padding_size) next_state = convolution;
            else next_state = lyr_2_init;
        end
        lyr_2_init: //3
        begin
            next_state = ly2_load_buffer;
        end
        ly2_load_buffer: //4
        begin
            if(buffer_cnt < `buffer_size) next_state = ly2_load_buffer;
            else next_state = ly2_conv;
        end
        ly2_conv: //5
        begin
            if(buffer_cnt < `padding_size) next_state = ly2_conv;
            else next_state = bias_relu;
        end
        bias_relu://6
        begin
            if(lyr_2_img_cnt < 64) next_state = lyr_2_init;
            else next_state = DONE;
        end
        DONE: //7
            next_state = DONE;
        default: next_state = IDLE;
    endcase
end

always @(posedge clk or negedge rst) begin
    if ( ~rst ) begin
        current_state <= IDLE;
    end
    else begin
        current_state <= next_state;
    end
end
// lyr_2 image counter 
always @(posedge clk or negedge rst) begin
    if( ~rst ) begin
        lyr_2_img_cnt <= 6'b0;
    end
    else begin
        if( current_state == bias_relu) begin
            lyr_2_img_cnt <= lyr_2_img_cnt + 1;
        end
        else if( next_state == lyr_2_init ) lyr_2_img_cnt <= 0;
        else lyr_2_img_cnt <= lyr_2_img_cnt;
    end
end


// Buffer counter
always @(posedge clk or negedge rst) begin
    if( ~rst ) begin
        buffer_cnt <= 19'b0;
    end
    else begin
        if( next_state == load_buffer || next_state == convolution) begin
            buffer_cnt <= buffer_cnt + 1;
        end
        else if( next_state == ly2_load_buffer || next_state == ly2_conv) begin
            buffer_cnt <= buffer_cnt + 1;
        end
        else if( next_state == lyr_2_init ) buffer_cnt <= 0;
        else buffer_cnt <= buffer_cnt;
    end
end

// Pass counter
always @(posedge clk or negedge rst) begin
    if( ~rst ) begin
        pass_cnt <= 19'b0;
    end
    else if (next_state == lyr_2_init) begin
        pass_cnt <= 19'b0;
    end
    else begin
        if( current_state == convolution || current_state == ly2_conv) begin
            if(pass_cnt == 226) pass_cnt <= 1;
            else pass_cnt <= pass_cnt + 1;
        end
        else pass_cnt <= pass_cnt; 
    end 
end

// Bias saving
always @(posedge clk or negedge rst) begin
    if( ~rst ) begin
        c1_bias <= 16'b0;
    end
    else if (next_state == lyr_2_init) begin
        c1_bias <= 16'b0;
    end
    else begin
        if( buffer_cnt == 2) begin
            c1_bias <= bias;
        end
        else c1_bias <= c1_bias; 
    end 
end

always @(posedge clk or negedge rst) begin
    if( ~rst ) begin
        for (i = 0 ; i < 9 ; i = i + 1) begin
            R_weight[i] <= 15'd0;
            G_weight[i] <= 15'd0;
            B_weight[i] <= 15'd0;
            D_weight[i] <= 15'd0;
        end
    end
    else if (buffer_cnt < 10 && buffer_cnt > 0) begin
        R_weight[buffer_cnt-1] <= weight[63:48];
        G_weight[buffer_cnt-1] <= weight[47:32];
        B_weight[buffer_cnt-1] <= weight[31:16];
        D_weight[buffer_cnt-1] <= weight[15:0];
    end
    else if (next_state == lyr_2_init) begin
         for (i = 0 ; i < 9 ; i = i + 1) begin
            R_weight[i] <= 15'd0;
            G_weight[i] <= 15'd0;
            B_weight[i] <= 15'd0;
            D_weight[i] <= 15'd0;
        end
    end
    else begin
        for (i = 0 ; i < 9 ; i = i + 1) begin
            R_weight[i] <= R_weight[i];
            G_weight[i] <= G_weight[i];
            B_weight[i] <= B_weight[i];
            D_weight[i] <= D_weight[i];
        end
    end
end
    
endmodule

module line_buffer (
    output reg signed [8:0] LB_out1, LB_out2, LB_out3, LB_out4, LB_out5, LB_out6, LB_out7, LB_out8, LB_out9,
    input [8:0] padding_data,
    input [3:0] current_state,
    input clk,
    input rst
); 

// Define FSM states
localparam IDLE = 3'b000;
localparam load_buffer = 3'b001;
localparam convolution = 3'b010;
localparam lyr_2_init = 3'b011;
localparam ly2_load_buffer = 3'b100;
localparam ly2_conv = 3'b101;
localparam bias_relu = 3'b110;
localparam DONE = 3'b111;

integer i;
reg signed[8:0] line_buffer [0 : `buffer_size - 1];
// Buffer input
always @(posedge clk or negedge rst) begin
    if( ~rst ) begin
        for (i = 0 ; i < `buffer_size ; i = i + 1) begin
            line_buffer[i] <= 8'd0;
        end
    end
    else if( current_state == load_buffer || current_state == convolution || current_state == ly2_load_buffer || current_state == ly2_conv) begin
        for (i = 0 ; i < `buffer_size - 1; i = i +1) begin
            line_buffer[i] <= line_buffer[ i + 1 ];
        end
        line_buffer[`buffer_size - 1] <= padding_data;
    end
    else begin
        for (i = 0 ; i < `buffer_size ; i = i + 1) begin
            line_buffer[i] <= 8'd0;
        end
    end
end

// Buffer output
always @(posedge clk or negedge rst) begin
    if( ~rst ) begin
        LB_out1 <= 9'b0;
        LB_out2 <= 9'b0;
        LB_out3 <= 9'b0;
        LB_out4 <= 9'b0;
        LB_out5 <= 9'b0;
        LB_out6 <= 9'b0;
        LB_out7 <= 9'b0;
        LB_out8 <= 9'b0;
        LB_out9 <= 9'b0;
    end
    else if( current_state == convolution || current_state == ly2_conv) begin
        LB_out1 <= line_buffer[0];
        LB_out2 <= line_buffer[1];
        LB_out3 <= line_buffer[2];
        LB_out4 <= line_buffer[0 + 226];
        LB_out5 <= line_buffer[1 + 226];
        LB_out6 <= line_buffer[2 + 226];
        LB_out7 <= line_buffer[0 + 226 * 2];
        LB_out8 <= line_buffer[1 + 226 * 2];
        LB_out9 <= line_buffer[2 + 226 * 2];
    end
    else begin
        LB_out1 <= 9'b0;
        LB_out2 <= 9'b0;
        LB_out3 <= 9'b0;
        LB_out4 <= 9'b0;
        LB_out5 <= 9'b0;
        LB_out6 <= 9'b0;
        LB_out7 <= 9'b0;
        LB_out8 <= 9'b0;
        LB_out9 <= 9'b0;
    end
end
    
endmodule

module PE (
    output signed [35:0] result,
    input signed [8:0] d1, d2, d3, d4, d5, d6, d7, d8, d9,
    input signed [15:0] w1,w2,w3,w4,w5,w6,w7,w8,w9
);

wire signed [35:0] sum_12, sum_34, sum_56, sum_78, sum_1234, sum_5678, sum_semi;
assign sum_12 = d1 * w1 + d2 * w2;
assign sum_34 = d3 * w3 + d4 * w4;
assign sum_56 = d5 * w5 + d6 * w6;
assign sum_78 = d7 * w7 + d8 * w8;
assign sum_1234 = sum_12 + sum_34;
assign sum_5678 = sum_56 + sum_78;
assign sum_semi = sum_1234 + sum_5678;

assign result = sum_semi + d9 * w9;

endmodule