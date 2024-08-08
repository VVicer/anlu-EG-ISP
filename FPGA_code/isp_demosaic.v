`timescale 1 ns / 1 ps

/*
 * ISP - Demosaic (RAW -> RGB)
 */

/* @Deprecated 双线性插值*/
module isp_demosaic 
#(
	parameter BITS = 8,
	parameter WIDTH = 1920,
	parameter HEIGHT = 1080
)
(
	input pclk,
	input rst_n,

	//从这个时候开始输入的数据有效
	input data_valid,
	input [7:0] in_raw,     

	output  reg out_valid,
	output reg [23:0] out_color,
	output [7:0] out_r,
	output [7:0] out_g,
	output [7:0] out_b
);

localparam B_long = 11;

wire [1:0] p22_fmt;
reg  [1:0] p22_fmt_reg1;
reg  [1:0] p22_fmt_reg2;

wire [10:0] wrusedw;
wire [10:0] rdusedw;

wire [BITS-1:0] out1, out2;
wire 			fifo1_re,fifo2_re;
wire			fifo1_wr,fifo2_wr;

//输出有效信号
reg valid_1;
reg valid_2;

reg valid_3;
reg valid_4;
reg valid_5;


reg [B_long-1:0] row_cnt = 0;
reg [B_long-1:0] col_cnt = 0;

reg [B_long-1:0] row_cnt2 = 0;
reg [B_long-1:0] col_cnt2 = 0;

reg [BITS+1:0] r_now_1=0, g_now_1=0, b_now_1=0;
reg [BITS-1:0] r_now_2=0, g_now_2=0, b_now_2=0;

reg [BITS-1:0] in_raw_r;
reg [BITS-1:0] p11,p12,p13;
reg [BITS-1:0] p21,p22,p23;
reg [BITS-1:0] p31,p32,p33;
always @ (posedge pclk) begin
	if (!rst_n) begin
		in_raw_r <= 0;
		p13 <= 0; p12 <= 0; p11 <= 0;
		p23 <= 0; p22 <= 0; p21 <= 0;
		p33 <= 0; p32 <= 0; p31 <= 0;
	end
	else begin
		if(data_valid) begin
			in_raw_r <= in_raw;
		end
		if(valid_1) begin
			p11 <= p12; p12 <= p13; p13 <= out2;
			p21 <= p22; p22 <= p23; p23 <= out1;
			p31 <= p32; p32 <= p33; p33 <= in_raw_r;
		end
	end
end



always @ (posedge pclk) begin
	r_now_1<= raw2r(p22_fmt_reg2,p11,p12,p13,p21,p22,p23,p31,p32,p33);
	g_now_1<= raw2g(p22_fmt_reg2,p11,p12,p13,p21,p22,p23,p31,p32,p33);
	b_now_1<= raw2b(p22_fmt_reg2,p11,p12,p13,p21,p22,p23,p31,p32,p33);
end

always @(posedge pclk) begin
	r_now_2 <= (r_now_1 > {BITS{1'b1}}) ? {BITS{1'b1}} : r_now_1[BITS-1:0];
	g_now_2 <= (g_now_1 > {BITS{1'b1}}) ? {BITS{1'b1}} : g_now_1[BITS-1:0];
	b_now_2 <= (b_now_1 > {BITS{1'b1}}) ? {BITS{1'b1}} : b_now_1[BITS-1:0];
end


//对输入的第一个FIFO计数
always @(posedge pclk) begin
	if(data_valid) begin
		col_cnt <=(col_cnt==WIDTH-1)?0:(col_cnt+1);
	end
end

always @(posedge pclk) begin
	if(col_cnt==WIDTH-1) begin
		row_cnt <=(row_cnt==HEIGHT-1)?0:(row_cnt+1);
	end
end

//对输入第二个FIFO进行计数
always @(posedge pclk) begin
	if(valid_1) begin
		col_cnt2 <=(col_cnt2==WIDTH-1)?0:(col_cnt2+1);
	end
end

always @(posedge pclk) begin
	if(col_cnt2==WIDTH-1) begin
		row_cnt2 <=(row_cnt2==HEIGHT-1)?0:(row_cnt2+1);
	end
end


//一帧存完之后，将关闭第一个FIFO读取
assign p22_fmt = {row_cnt[0], col_cnt[0]};

always @(posedge pclk) begin
	p22_fmt_reg1 <= p22_fmt;
	p22_fmt_reg2 <= (2'b01^p22_fmt_reg1);
end

//控制第一个FIFO的读和写
assign fifo1_wr = (row_cnt<HEIGHT-1)?data_valid:0;
// assign fifo1_wr = (row_cnt<HEIGHT)?1:0;
assign fifo1_re = (row_cnt>0)?data_valid:0;
assign fifo2_wr = (row_cnt<HEIGHT-2)?data_valid:0;
assign fifo2_re = (row_cnt>1)?data_valid:0;

//例化FIFO 两个

myfifo u_fifo1(
	.rst		(!rst_n),
	.di			(in_raw),
	.clk		(pclk), 
	.we			(fifo1_wr),
	.re			(fifo1_re),

	.do			(out1),
	.empty_flag (),
	.full_flag  (),
	.rdusedw    (),
	.wrusedw	()

);

myfifo u_fifo2(
	.rst		(!rst_n),
	.di			(in_raw),
	.clk		(pclk), 
	.we			(fifo2_wr),
	.re			(fifo2_re),

	.do			(out2),
	.empty_flag (),
	.full_flag  (),
	.rdusedw    (),
	.wrusedw	()

);




always @(posedge pclk ) begin
	if(fifo1_re) begin
		valid_1 <= 1;
	end
	else begin
		valid_1 <= 0;
	end
end

always @(posedge pclk ) begin
	if(fifo2_re) begin
		valid_2 <= 1;
	end
	else begin
		valid_2 <= 0;
	end
end

always @(posedge pclk) begin
	valid_3 <= valid_2;
	valid_4 <= valid_3;
	valid_5 <= valid_4;
end


	
//数据有效值
always@(*) begin
	if(row_cnt==11'd0) begin
		out_valid = valid_5 || data_valid;
	end
	else if(row_cnt==11'd1) begin
		out_valid = data_valid;
	end
	else begin
		out_valid = valid_5;
	end

end

always@(*) begin
	if(valid_5) begin
		out_color = {r_now_2, g_now_2, b_now_2};
	end
	else begin
		out_color = 0;
	end

end

assign out_r = out_valid ? r_now_2 : {BITS{1'b0}};
assign out_g = out_valid ? g_now_2 : {BITS{1'b0}};
assign out_b = out_valid ? b_now_2 : {BITS{1'b0}};
	

function [BITS+1:0] raw2r;
	input [1:0] format;
	input [BITS-1:0] p11,p12,p13;
	input [BITS-1:0] p21,p22,p23;
	input [BITS-1:0] p31,p32,p33;
	reg [BITS+1:0] r;
	begin
		case (format)
			2'b00: raw2r = p22;
			2'b01: raw2r = (p21 + p23) >> 1;
			2'b10: raw2r = (p12 + p32) >> 1;
			2'b11: raw2r = (p11 + p13 + p31 + p33) >> 2;
			default: r = {BITS{1'b0}};
		endcase
	end
endfunction

function [BITS+1:0] raw2g;
	input [1:0] format;
	input [BITS-1:0] p11,p12,p13;
	input [BITS-1:0] p21,p22,p23;
	input [BITS-1:0] p31,p32,p33;
	reg [BITS+1:0] g;
	begin
		case (format)
			2'b00: raw2g = (p12 + p32 + p21 + p23) >> 2;
			2'b01: raw2g = p22;
			2'b10: raw2g = p22;
			2'b11: raw2g = (p12 + p32 + p21 + p23) >> 2;
			default: g = {BITS{1'b0}};
		endcase
	end
endfunction

function [BITS+1:0] raw2b;
	input [1:0] format;
	input [BITS-1:0] p11,p12,p13;
	input [BITS-1:0] p21,p22,p23;
	input [BITS-1:0] p31,p32,p33;
	reg [BITS+1:0] b;
	begin
		case (format)
			2'b00: raw2b = (p11 + p13 + p31 + p33) >> 2;
			2'b01: raw2b = (p12 + p32) >> 1;
			2'b10: raw2b = (p21 + p23) >> 1;
			2'b11: raw2b = p22;
			default: b = {BITS{1'b0}};
		endcase
	end
endfunction

endmodule

