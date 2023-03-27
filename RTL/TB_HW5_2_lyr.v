`timescale 1ns / 1ns
`define period          10
// 224 * 224 * 3
`define img_max_size    224*224*3+54
`define img_pixels      224 * 224
`define padding_size     (224 + 2) * (224 + 2)
// //---------------------------------------------------------------
// //You need specify the path of image in/out
// //---------------------------------------------------------------
`define path_img_in     "./test_data/cat224.bmp"
`define path_conv1_kernel "./test_data/conv1_kernel_hex.txt"
`define path_conv1_bias "./test_data/conv1_bias_hex.txt"
`define path_conv2_kernel "./test_data/conv2_kernel_hex.txt"
`define path_conv2_bias "./test_data/conv2_bias_hex.txt"
`define path_img_gray   "./test_data/cat_gray.bmp"
`define path_img_out_H    "./ly2_result/cat_after_sobel_H.bmp"
`define path_img_out_V    "./ly2_result/cat_after_sobel_V.bmp"

module HDL_HW4_TB;
    integer img_in;
    integer img_gray;
    integer offset;
    integer img_h;
    integer img_w;
    integer img_out_V;
    integer img_out_H;
    integer idx;
    integer header;
    integer i, j, k, h;
    integer cnt = 0;
    integer trans_cnt = 0;
    integer fp_r_C1W, fp_r_C1B, fp_r_C2W, fp_r_C2B;
    integer zzz;

    integer test_cnt;

    reg         clk;
    reg         rst;
    reg  [7:0]  img_data [0:`img_max_size-1];
    // Generate Grayscale data
    reg  [7:0]  gray_data [0:480*360 - 1];
    // Paddding the gray_data
    reg  [7:0]  gray_padding [0: `padding_size - 1];

    // Paddding the RBG data
    reg  [8:0]  R_padding [0: `padding_size - 1];
    reg  [8:0]  G_padding [0: `padding_size - 1];
    reg  [8:0]  B_padding [0: `padding_size - 1];
    // RGB Data
    reg  [7:0]  R [0:`img_pixels - 1];
    reg  [7:0]  G [0:`img_pixels - 1];
    reg  [7:0]  B [0:`img_pixels - 1];

    // Paddding the Layer_1 data
    reg  [8:0]  lyr1_1_padding [0:`padding_size - 1];
    reg  [8:0]  lyr1_2_padding [0:`padding_size - 1];
    reg  [8:0]  lyr1_3_padding [0:`padding_size - 1];
    reg  [8:0]  lyr1_4_padding [0:`padding_size - 1];
    // Layer_1 data
    reg  [7:0]  lyr1_1_img_data [0:`img_max_size - 1];
    reg  [7:0]  lyr1_2_img_data [0:`img_max_size - 1];
    reg  [7:0]  lyr1_3_img_data [0:`img_max_size - 1];
    reg  [7:0]  lyr1_4_img_data [0:`img_max_size - 1];
    // Place data
    reg  [7:0]  lyr2_image_mem [0:(`img_pixels * 64) - 1];

    // RGB Data
    reg  [7:0]  lyr1_1_origin [0:`img_pixels - 1];
    reg  [7:0]  lyr1_2_origin [0:`img_pixels - 1];
    reg  [7:0]  lyr1_3_origin [0:`img_pixels - 1];
    reg  [7:0]  lyr1_4_origin [0:`img_pixels - 1];

    reg  [15:0] R_weight [0:575];
    reg  [15:0] G_weight [0:575];
    reg  [15:0] B_weight [0:575];

    reg  [15:0] lyr2_1_weight [0:9215];
    reg  [15:0] lyr2_2_weight [0:9215];
    reg  [15:0] lyr2_3_weight [0:9215];
    reg  [15:0] lyr2_4_weight [0:9215];

    // Convolution filter
    reg  [15:0] c1_weight [0:1727];
    reg  [15:0] c1_bias [0:63];
    reg  [15:0] c2_weight [0:36863];
    reg  [15:0] c2_bias [0:63];
    
    integer weight_cnt = 0;

    integer w_cnt = 0;
    integer w_cnt2 = 0;
    // Convolution Module
    reg  [7:0] sobel_data_V;
    reg  [7:0] sobel_data_H;
    reg  [8:0] padding_data_1;
    reg  [8:0] padding_data_2;
    reg  [8:0] padding_data_3;
    reg  [8:0] padding_data_4;
    wire  [18:0] pass_cnt;
    wire write_flag;
    wire [7:0] bmp_lyr1_answer;
    wire signed[35:0] lyr_2_sum;
    reg [63:0] weight;
    reg [15:0] rt;
    reg [15:0] bias;

    // Generate direction 
    parameter NUM_PU = 64;
    integer file [0:NUM_PU-1];
    integer file_2 [0:NUM_PU-1];
    reg [999:0] filename;

    // Generate 
    parameter NUM_L1_img = 64;
    integer l1_file [0:NUM_L1_img-1];
    integer L1_img1;
    integer L1_img2;
    integer L1_img3;
    integer L1_img4;
    reg [999:0] l1_img_filename;

    reg signed[35:0] ly2_temp [0:`img_pixels - 1];
    conv convolution( lyr_2_sum, bmp_lyr1_answer, pass_cnt, write_flag, weight,padding_data_1,padding_data_2,padding_data_3,padding_data_4
    , bias,clk, rst);


//---------------------------------------------------------------------------------------Take out the color image(cat) of RGB----------------------------------------------
    //---------------------------------------------------------------
    //This initial block write the pixel 
    //---------------------------------------------------------------

    // Dump fsdb wavefile
    // initial begin
    //     $fsdbDumpfile("L2_conv.fsdb");
    //     $fsdbDumpvars;
    //     // Dump all the memory
    //     $fsdbDumpMDA();
    // end


    initial begin
        rst = 1'b1;
        clk = 1'b1;
    #(`period)
        for(idx = 0; idx < img_h*img_w; idx = idx+1) begin
            R[idx] = img_data[idx*3 + offset + 2];
            G[idx] = img_data[idx*3 + offset + 1];
            B[idx] = img_data[idx*3 + offset + 0];
            
            $fwrite(img_gray, "%c%c%c", B[idx], G[idx], R[idx]);
            w_cnt2 = w_cnt2 + 1;
        #(`period);
        end

        //-------------------------padding--------------------------------
        for(i = 0; i < 226 ; i = i + 1) begin
            for(j = 0 ; j < 226; j = j + 1) begin
                if( i == 0 || i == 225 || j == 0 || j == 225) begin
                    R_padding[cnt] = 0;
                    G_padding[cnt] = 0;
                    B_padding[cnt] = 0;
                end
                else begin
                    R_padding[cnt] = {1'b0, R[trans_cnt]};
                    G_padding[cnt] = {1'b0, G[trans_cnt]};
                    B_padding[cnt] = {1'b0, B[trans_cnt]};
                    trans_cnt = trans_cnt + 1;
                end
                cnt = cnt + 1;
            end
        end
        // Generate Weight
        for(i = 0; i <64 ; i = i + 1) begin
            for (j = 0; j < 27; j = j + 1) begin
                if(j<9) R_weight[j % 9 + i * 9] = c1_weight[i * 27 + j];
                else if( j >= 9 && j < 18) G_weight[j % 9 + i * 9] = c1_weight[i * 27 + j];
                else  B_weight[j % 9 + i * 9] = c1_weight[i * 27 + j];
            end
        end

        for(i = 0; i <1024 ; i = i + 1) begin
            for (j = 0; j < 36; j = j + 1) begin
                if(j<9) lyr2_1_weight[j % 9 + i * 9] = c2_weight[i * 36 + j];
                else if( j >= 9 && j < 18) lyr2_2_weight[j % 9 + i * 9] = c2_weight[i * 36 + j];
                else if( j >= 18 && j <27) lyr2_3_weight[j % 9 + i * 9] = c2_weight[i * 36 + j];
                else lyr2_4_weight[j % 9 + i * 9] = c2_weight[i * 36 + j];
            end
        end


        // ==================================== Layer 1 ========================================
        // Convolution
        #(`period/2);
        for (k = 0; k < NUM_PU ; k = k+1 ) begin
            w_cnt = 0;
            weight_cnt = 0;
            rst = ~ rst;
            # 3;
            rst = ~ rst;
            # 2;

            #(`period/2);
            for(i = 0; i < 226 ; i = i + 1) begin
                for(j = 0 ; j < 226; j = j + 1) begin
                    if (weight_cnt == 1) begin
                        bias = c1_bias[k];
                    end
                    if (weight_cnt < 9) begin
                    weight = {R_weight[k*9 + weight_cnt], G_weight[k*9 + weight_cnt], B_weight[k*9 + weight_cnt], 16'b0};
                    rt = R_weight[k*9 + weight_cnt];
                    // $display("%d %h", k, rt);
                    end
                    weight_cnt = weight_cnt + 1;

                    padding_data_1 = R_padding[i*226 + j];
                    padding_data_2 = G_padding[i*226 + j];
                    padding_data_3 = B_padding[i*226 + j];
                    padding_data_4 = 9'b0;
                    if(write_flag == 1) begin 
                        lyr2_image_mem[k*(224*224) + w_cnt] = bmp_lyr1_answer;
                        $display("Layer1 img layer %d = %d",k*(224*224) + w_cnt, bmp_lyr1_answer);
                        w_cnt = w_cnt + 1;
                        $fwrite(file[k], "%c%c%c", bmp_lyr1_answer, bmp_lyr1_answer, bmp_lyr1_answer);
                    end
                    #(`period);
                end
            end
            $fwrite(file[k], "%c%c%c",8'b0 , 8'b0, 8'b0);
            $fwrite(file[k], "%c%c%c",8'b0 , 8'b0, 8'b0);
            $fwrite(file[k], "%c%c%c",8'b0 , 8'b0, 8'b0);
            $display("Layer1: Conv %d : Total wrtie: %d %d", k+1 ,w_cnt, w_cnt2);
        end

        // Close layer 1 imgs
        for(i = 0; i < NUM_PU ; i = i + 1 ) begin
            $fclose(file[i]);
        end

        // ==================================== Layer 2 ========================================
        for (k = 0 ; k < 64 ;k = k + 1) begin
            // for(i=0;i<NUM_L1_img;i=i+1) begin
            //     $sformat(l1_img_filename, "./ly2_result/ly1_%0d.bmp", i + 1);
            //     l1_file[i] = $fopen(l1_img_filename, "rb");
            // end
            for(i = 0 ; i < `img_pixels ; i = i + 1) begin
                ly2_temp[i] = 0;
            end
            for(h = 0 ; h < 16 ; h = h + 1) begin
            $sformat(l1_img_filename, "./ly2_result/ly1_%0d.bmp", h*4 + 1);
            L1_img1 = $fopen(l1_img_filename, "rb");

            $sformat(l1_img_filename, "./ly2_result/ly1_%0d.bmp", h*4 + 2);
            L1_img2 = $fopen(l1_img_filename, "rb");

            $sformat(l1_img_filename, "./ly2_result/ly1_%0d.bmp", h*4 + 3);
            L1_img3 = $fopen(l1_img_filename, "rb");
            
            $sformat(l1_img_filename, "./ly2_result/ly1_%0d.bmp", h*4 + 4);
            L1_img4 = $fopen(l1_img_filename, "rb");
            // Test Block============================================================================================================
                // k = 0;
                cnt = 0;
                trans_cnt = 0;
                w_cnt = 0;
                weight_cnt = 0;
                // $display("k=%d, h=%d", k, h);
                if(k == 0 && h == 0) begin
                    # 0;
                end
                else begin
                    # 10;
                end
                # 5;

                // $display("----%d %d----\n", k,h);
                $fread(lyr1_1_img_data, L1_img1);
                $fread(lyr1_2_img_data, L1_img2);
                $fread(lyr1_3_img_data, L1_img3);
                $fread(lyr1_4_img_data, L1_img4);
                $fclose(L1_img1);
                $fclose(L1_img2);
                $fclose(L1_img3);
                $fclose(L1_img4);
                for(idx = 0; idx < img_h*img_w; idx = idx+1) begin
                    lyr1_1_origin[idx] = lyr2_image_mem[k*(224*224) + w_cnt];
                    lyr1_2_origin[idx] = lyr2_image_mem[k*(224*224) + w_cnt];
                    lyr1_3_origin[idx] = lyr2_image_mem[k*(224*224) + w_cnt];
                    lyr1_4_origin[idx] = lyr2_image_mem[k*(224*224) + w_cnt];
                end 
      
                
            //-------------------------padding--------------------------------
                for(i = 0; i < 226 ; i = i + 1) begin
                    for(j = 0 ; j < 226; j = j + 1) begin
                        if( i == 0 || i == 225 || j == 0 || j == 225) begin
                            lyr1_1_padding[cnt] = 0;
                            lyr1_2_padding[cnt] = 0;
                            lyr1_3_padding[cnt] = 0;
                            lyr1_4_padding[cnt] = 0;
                        end
                        else begin
                            lyr1_1_padding[cnt] = {1'b0, lyr1_1_origin[trans_cnt]};
                            lyr1_2_padding[cnt] = {1'b0, lyr1_2_origin[trans_cnt]};
                            lyr1_3_padding[cnt] = {1'b0, lyr1_3_origin[trans_cnt]};
                            lyr1_4_padding[cnt] = {1'b0, lyr1_4_origin[trans_cnt]};
                            trans_cnt = trans_cnt + 1;
                        end
                        cnt = cnt + 1;
                    end
                end

                #(`period/2);
                for(i = 0; i < 226 ; i = i + 1) begin
                    for(j = 0 ; j < 226; j = j + 1) begin
                        if (weight_cnt == 1) begin
                            bias = c2_bias[k];
                        end
                        if (weight_cnt < 9) begin
                        weight = {lyr2_1_weight[(k*16+h)*9 + weight_cnt], lyr2_2_weight[(k*16+h)*9 + weight_cnt]
                        , lyr2_3_weight[(k*16+h)*9 + weight_cnt],  lyr2_4_weight[(k*16+h)*9 + weight_cnt]};
                        rt = R_weight[k*9 + weight_cnt];
                        // $display("%d %h", k, rt);
                        end
                        weight_cnt = weight_cnt + 1;

                        padding_data_1 = lyr1_1_padding[i*226 + j];
                        padding_data_2 = lyr1_2_padding[i*226 + j];
                        padding_data_3 = lyr1_3_padding[i*226 + j];
                        padding_data_4 = lyr1_4_padding[i*226 + j];
                        if(write_flag == 1) begin 
                            ly2_temp[w_cnt] = ly2_temp[w_cnt] + lyr_2_sum;
                            w_cnt = w_cnt + 1;
                            $display("Layer2 temp1 %d %d %d %d", ly2_temp[w_cnt], lyr_2_sum, k ,h);
                            // $fwrite(img_out_H, "%c%c%c", bmp_lyr1_answer, bmp_lyr1_answer, bmp_lyr1_answer);
                        end
                        #(`period);
                    end
                end
                $display("\nLayer2: Conv %d : Total wrtie: %d %d", k+1 ,w_cnt, w_cnt2);
            // Test Block============================================================================================================
            end
            // if(k == 1) begin
            //     for(i=0;i<NUM_L1_img;i=i+1) begin
            //         $fclose(file_2[i]);
            //     end
            // end
        
            test_cnt = 0;
            // Output image -> bias and relu
            for(i = 0; i < 224 ; i = i + 1) begin
                for(j = 0 ; j < 224; j = j + 1) begin
                    ly2_temp[i*224 + j] = ly2_temp[i*224 + j] + c2_bias[k];
                    if(ly2_temp[i*224 + j] <= 0) ly2_temp[i*224 + j] = 0;
                    else ly2_temp[i*224 + j] = ly2_temp[i*224 + j];
                    test_cnt = test_cnt + 1;
                    $fwrite(file_2[k], "%c%c%c",ly2_temp[i*224 + j][14:7] ,ly2_temp[i*224 + j][14:7], ly2_temp[i*224 + j][14:7]);
                    // $fwrite(file_2[k], "%c%c%c",8'b0 ,8'b0, 8'b0);
                end
            end
            for(i=0;i<NUM_L1_img;i=i+1) begin
                $fclose(l1_file[i]);
            end
            $fclose(file_2[k]);
        end
        
    #(`period)
        $fclose(img_out_H);
        $fclose(img_out_V);
        $fclose(img_in);
        $finish;
    end

    //---------------------------------------------------------------
    //This initial block read the pixel 
    //---------------------------------------------------------------
    initial begin
        img_out_V = $fopen(`path_img_out_V, "wb");
        img_out_H = $fopen(`path_img_out_H, "wb");
        img_in  = $fopen(`path_img_in, "rb");
        img_gray = $fopen(`path_img_gray, "wb");

        fp_r_C1W = $fopen(`path_conv1_kernel, "r");
        fp_r_C1B = $fopen(`path_conv1_bias, "r");
        fp_r_C2W = $fopen(`path_conv2_kernel, "r");
        fp_r_C2B = $fopen(`path_conv2_bias, "r");


        for(i=0;i<NUM_PU;i=i+1) begin
            $sformat(filename, "./ly2_result/ly1_%0d.bmp", i + 1);
            file[i] = $fopen(filename, "wb");
        end

        for(i=0;i<NUM_PU;i=i+1) begin
            $sformat(filename, "./ly2_result/ly2_%0d.bmp", i + 1);
            file_2[i] = $fopen(filename, "wb");
        end

        for(i=0; i<`img_pixels * 64 i=i+1) begin
            lyr2_image_mem [i] = 0;
        end


    // reg  [15:0] c1_weight [0:1727];
    // reg  [15:0] c1_bias [0:63];

    for( i = 0; i < 1728 ; i = i + 1) begin
        zzz = $fscanf(fp_r_C1W, "%x\n", c1_weight[i]);
    end

    for( i = 0; i < 64 ; i = i + 1) begin
        zzz = $fscanf(fp_r_C1B, "%x\n", c1_bias[i]);
    end

    for( i = 0; i < 36864 ; i = i + 1) begin
        zzz = $fscanf(fp_r_C2W, "%x\n", c2_weight[i]);
    end

    for( i = 0; i < 64 ; i = i + 1) begin
        zzz = $fscanf(fp_r_C2B, "%x\n", c2_bias[i]);
    end

        $fread(img_data, img_in);

        img_w   = {img_data[21],img_data[20],img_data[19],img_data[18]};
        img_h   = {img_data[25],img_data[24],img_data[23],img_data[22]};
        offset  = {img_data[13],img_data[12],img_data[11],img_data[10]};

        // Copy the header to img_out
        for(header = 0; header < 54; header = header + 1) begin
            for (i = 0; i < NUM_PU ; i = i+1) begin
                $fwrite(file[i], "%c", img_data[header]);
                $fwrite(file_2[i], "%c", img_data[header]);
            end
            $fwrite(img_gray, "%c", img_data[header]);
            $fwrite(img_out_H, "%c", img_data[header]);
            $fwrite(img_out_V, "%c", img_data[header]);
        end
    end
//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

    always begin
		#(`period/2.0) clk <= ~clk;
	end

    /*
    initial begin
		$sdf_annotate (`path_sdf, <your instance name>);
	end
    */
endmodule