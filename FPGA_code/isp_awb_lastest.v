`timescale 1 ns / 1 ps

/*
 * 白平衡算法
 */

module isp_awb_lastest
#(
	parameter BITS = 8,
	parameter WIDTH = 1936,
	parameter HEIGHT = 1088
)
(
	input pclk,
	input rst_n,
	
	//从SDRAM中读出来的数据有效
	input data_valid,
	input [BITS-1:0] in_raw,
	output reg data_valid_3,

	output reg [BITS-1:0] out_raw_2      

);
localparam gain_b = 8'h1c; //1.75
localparam gain_r = 8'h1e; //1.875
localparam gain_g = 8'h10;
reg [7:0] gain;

reg [1:0] pix_sel_reg;

// reg [BITS-1:0] data_r;
// reg [BITS-1:0] data_g;
// reg [BITS-1:0] data_b;

wire [BITS-1+8:0] out_raw_1;

reg [10:0] row_cnt = 0;
reg [10:0] col_cnt = 0;

reg [BITS-1:0] in_raw_1 = 0;

reg data_valid_1;
reg data_valid_2;
                      

always @(posedge pclk) begin
	in_raw_1 <= in_raw;
end

always @ (*) begin
	if (!rst_n) begin
		gain <= 0;
	end
	else begin
		case(pix_sel_reg)
			2'b00:gain <= gain_b;
			2'b01:gain <= gain_g;
			2'b10:gain <= gain_g;
			2'b11:gain <= gain_r;
		endcase
	end
end

mul_dsp u_dsp( 
	.p     (out_raw_1), 
	.a     (in_raw_1), 
	.b     (gain), 
	.cepd  (1), 
	.clk   (pclk), 
	.rstpdn(rst_n)
);

always @ (posedge pclk) begin
	if (!rst_n) begin
		out_raw_2 <= 0;
	end
	else begin
		out_raw_2 <= (out_raw_1[BITS-1+8:4] > {BITS{1'b1}} ) ? {BITS{1'b1}} : out_raw_1[BITS-1+4:4];
	end
end

always @(posedge pclk) begin
	if(!rst_n) begin
		col_cnt <= 0;
	end
	else begin
		if(data_valid) begin
			col_cnt <=(col_cnt==WIDTH-1)?0:(col_cnt+1);
		end
	end
end

always @(posedge pclk) begin
	if(!rst_n) begin
		row_cnt <= 0;
	end
	else begin
		if(col_cnt==WIDTH-1) begin
			row_cnt <=(row_cnt==HEIGHT-1)?0:(row_cnt+1);
		end
	end
end

always @(posedge pclk) begin
	if(!rst_n) begin
		pix_sel_reg <= 0;
	end
	else begin
		pix_sel_reg <= {row_cnt[0],col_cnt[0]};
	end
end


always @(posedge pclk) begin
	if(!rst_n) begin
		data_valid_1 <= 0;  
		data_valid_2 <= 0;
		data_valid_3 <= 0;
	end
	else begin
		data_valid_1 <= data_valid;
		data_valid_2 <= data_valid_1;
		data_valid_3 <= data_valid_2;
	end
	
end

endmodule