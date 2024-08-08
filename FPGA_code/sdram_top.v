`timescale  1ns/1ns


module  sdram_top
(
	input	wire			fifo_rst		,
    input   wire            sys_clk         ,   
    input   wire            clk_out         ,   
    input   wire            sys_rst_n       ,   
    
	input	wire			sdram_rd_flag	,
    input	wire			pic_c			,
    output	wire			vga_count_en	,
    output	wire			one_pic_wr_end	,
	output	wire	[27:0]	cnt_rd_ack		,
    
//写FIFO信号
    input   wire            wr_fifo_wr_clk  ,   
    input   wire            wr_fifo_wr_req  ,   
    input   wire    [15:0]  wr_fifo_wr_data ,   
    input   wire    [20:0]  sdram_wr_b_addr ,   
    input   wire    [20:0]  sdram_wr_e_addr ,   
    input   wire    [9:0]   wr_burst_len    ,   
    input   wire            wr_rst          ,   
//读FIFO信号
    input   wire            rd_fifo_rd_clk  ,   
    input   wire            rd_fifo_rd_req  ,   
    input   wire    [20:0]  sdram_rd_b_addr ,   
    input   wire    [20:0]  sdram_rd_e_addr ,   
    input   wire    [9:0]   rd_burst_len    ,   
    input   wire            rd_rst          ,   
    //output  wire    [15:0]  rd_fifo_rd_data , 
	output  wire    [23:0]  rd_fifo_rd_data ,   

    input   wire            read_valid      ,   
    input   wire            pingpang_en     ,   
    output  wire            init_end        ,   
//SDRAM接口信号
    output  wire            sdram_clk       ,   
    output  wire            sdram_cke       ,   
    output  wire            sdram_cs_n      ,   
    output  wire            sdram_ras_n     ,   
    output  wire            sdram_cas_n     ,   
    output  wire            sdram_we_n      ,   
    output  wire    [1:0]   sdram_ba        ,   
    output  wire    [10:0]  sdram_addr      ,   
    output  reg    [3:0]   sdram_dqm       ,   
    inout   wire    [31:0]  sdram_dq            
);


//wire  define
wire            sdram_wr_req    ;   
wire            sdram_wr_ack    ;   
wire    [20:0]  sdram_wr_addr   ;   
wire    [15:0]  sdram_data_in   ;   

wire            sdram_rd_req    ;   
wire            sdram_rd_ack    ;   
wire    [20:0]  sdram_rd_addr   ;   
wire    [31:0]  sdram_data_out  ;   


wire	[23:0]	out_color		;
wire			out_valid		;


	
wire			one_pic_rd_end	;

wire			rd_en			;
wire			wr_en			;


wire	[31:0]	wr_sdram_data_piangpang;
wire	[15:0]	rd_sdram_data_piangpang;


reg			rd_daram_pingpang_falg;

//sdram_clk:SDRAM芯片时钟
assign  sdram_clk = clk_out;
//sdram_dqm:SDRAM数据掩码


//assign	sdram_dqm = 4'b0000;

    always@(posedge sys_clk or negedge sys_rst_n)begin
	if(~sys_rst_n)
		sdram_dqm <= 4'b0000;
	else if(wr_en)
		begin
			if(pic_c == 1'b0)
				sdram_dqm <= 4'b0000;
			else
				sdram_dqm <= 4'b0010;
		end
	else if(rd_en)
		sdram_dqm <= 4'b0000;
	else
		sdram_dqm <= sdram_dqm;
		
end    



/* always@(posedge sys_clk)begin
	if(sdram_rd_flag == 1'b1)
		sdram_dqm <= 4'b0000;
	else
		begin
			if(pic_c == 1'b0)
				sdram_dqm <= 4'b1100;
			else
				sdram_dqm <= 4'b0010;
		end
end */
//assign sdram_dqm = (pic_c == 1'b0) ? 4'b1100:4'b0011;


assign wr_sdram_data_piangpang = (pic_c == 1'b0) ? ({16'd0,sdram_data_in}):({sdram_data_in,16'd0});
//assign wr_sdram_data_piangpang = {16'd0,sdram_data_in};



 reg	[1:0]	state;

always@(posedge sys_clk or negedge sys_rst_n)begin
	if(~sys_rst_n)
		begin
			rd_daram_pingpang_falg <= 1'b0;
		end
    else 
		begin
			if(one_pic_rd_end)			
				rd_daram_pingpang_falg <= ~rd_daram_pingpang_falg;
			else
				rd_daram_pingpang_falg <= rd_daram_pingpang_falg;							
		end
end 

assign rd_sdram_data_piangpang = (rd_daram_pingpang_falg == 1'b0) ? sdram_data_out[15:0] : sdram_data_out[31:16];


//------------- fifo_ctrl_inst -------------
fifo_ctrl   fifo_ctrl_inst(

//system    signal
	.fifo_rst		(fifo_rst		),
    .sys_clk        (sys_clk        ),
    .sys_rst_n      (sys_rst_n      ),
    
    
	.sdram_rd_flag	(sdram_rd_flag	),
    .vga_count_en	(vga_count_en	),
    .one_pic_rd_end	(one_pic_rd_end	),
	.one_pic_wr_end	(one_pic_wr_end	),
	.cnt_rd_ack		(cnt_rd_ack		),
    
    
//write fifo signal
    .wr_fifo_wr_clk (wr_fifo_wr_clk ),
    .wr_fifo_wr_req (wr_fifo_wr_req ),
    .wr_fifo_wr_data(wr_fifo_wr_data),
    .sdram_wr_b_addr(sdram_wr_b_addr),
    .sdram_wr_e_addr(sdram_wr_e_addr),
    .wr_burst_len   (wr_burst_len   ),
    .wr_rst         (wr_rst         ),
//read fifo signal
    .rd_fifo_rd_clk (rd_fifo_rd_clk ),
    .rd_fifo_rd_req (rd_fifo_rd_req ),
    .rd_fifo_rd_data(rd_fifo_rd_data),
    .sdram_rd_b_addr(sdram_rd_b_addr),
    .sdram_rd_e_addr(sdram_rd_e_addr),
    .rd_burst_len   (rd_burst_len   ),
    .rd_rst         (rd_rst         ),
//USER ctrl signal
    .read_valid     (read_valid     ),
    .pingpang_en    (pingpang_en    ),
    .init_end       (init_end       ),
//SDRAM ctrl of write
    .sdram_wr_ack   (sdram_wr_ack   ),
    .sdram_wr_req   (sdram_wr_req   ),
    .sdram_wr_addr  (sdram_wr_addr  ),
    .sdram_data_in  (sdram_data_in  ),
//SDRAM ctrl of read
    .sdram_rd_ack   (sdram_rd_ack   ),
    .sdram_data_out (rd_sdram_data_piangpang ),
    .sdram_rd_req   (sdram_rd_req   ),
    .sdram_rd_addr  (sdram_rd_addr  ),
	
//去马赛克端口
	.out_valid		(out_valid		),
	.out_color		(out_color		) 


);

//------------- sdram_ctrl_inst -------------
sdram_ctrl  sdram_ctrl_inst(

    .sys_clk        (sys_clk        ),
    .sys_rst_n      (sys_rst_n      ),
	
	.wr_en			(wr_en			),
	.rd_en			(rd_en			),
	
//SDRAM 控制器写端口
    .sdram_wr_req   (sdram_wr_req   ),
    .sdram_wr_addr  (sdram_wr_addr  ),
    .wr_burst_len   (wr_burst_len   ),
    .sdram_data_in  (wr_sdram_data_piangpang  ),
    .sdram_wr_ack   (sdram_wr_ack   ),
//SDRAM 控制器读端口
    .sdram_rd_req   (sdram_rd_req   ),
    .sdram_rd_addr  (sdram_rd_addr  ),
    .rd_burst_len   (rd_burst_len   ),
    .sdram_data_out (sdram_data_out ),
    .init_end       (init_end       ),
    .sdram_rd_ack   (sdram_rd_ack   ),
//FPGA与SDRAM硬件接口
    .sdram_cke      (sdram_cke      ),
    .sdram_cs_n     (sdram_cs_n     ),
    .sdram_ras_n    (sdram_ras_n    ),
    .sdram_cas_n    (sdram_cas_n    ),
    .sdram_we_n     (sdram_we_n     ),
    .sdram_ba       (sdram_ba       ),
    .sdram_addr     (sdram_addr     ),
    .sdram_dq       (sdram_dq       ),

//去马赛克端口
	.out_color		(out_color		),//output[23:0]
	.out_valid		(out_valid		) //output

);

endmodule
