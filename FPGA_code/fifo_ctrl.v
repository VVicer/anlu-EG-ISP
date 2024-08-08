`timescale  1ns/1ns


module  fifo_ctrl
(
    input	wire			fifo_rst		,
    input   wire            sys_clk         ,
    input   wire            sys_rst_n       ,
    
	input	wire			sdram_rd_flag	,
    output  wire			vga_count_en	,
	output	wire			one_pic_wr_end	,
    output	wire			one_pic_rd_end	,
	
	output  reg	[27:0]		cnt_rd_ack		,

    
//写fifo信号
    input   wire            wr_fifo_wr_clk  ,
    input   wire            wr_fifo_wr_req  ,
    input   wire    [15:0]  wr_fifo_wr_data ,
    input   wire    [20:0]  sdram_wr_b_addr ,
    input   wire    [20:0]  sdram_wr_e_addr ,
    input   wire    [9:0]   wr_burst_len    ,
    input   wire            wr_rst          ,
//读fifo信号
    input   wire            rd_fifo_rd_clk  ,
    input   wire            rd_fifo_rd_req  ,
    input   wire    [20:0]  sdram_rd_b_addr ,
    input   wire    [20:0]  sdram_rd_e_addr ,
    input   wire    [9:0]   rd_burst_len    ,
    input   wire            rd_rst          ,
    //output  wire    [15:0]  rd_fifo_rd_data
	output  wire    [23:0]  rd_fifo_rd_data ,

    input   wire            read_valid      ,   //SDRAM读使能
    input   wire            init_end        ,   //SDRAM初始化完成标志
    input   wire            pingpang_en     ,   //SDRAM乒乓操作使能
//SDRAM写信号
    (*keep = "true"*)input   wire            sdram_wr_ack    ,   //SDRAM写响应
	//input   wire            sdram_wr_ack    ,   //SDRAM写响应
    output  reg             sdram_wr_req    ,   //SDRAM写请求
    output  reg     [20:0]  sdram_wr_addr   ,   //SDRAM写地址
    (*keep = "true"*)output  wire    [15:0]  sdram_data_in   ,   //写入SDRAM的数据
	//output  wire    [15:0]  sdram_data_in   ,   //写入SDRAM的数据
//SDRAM读信号
    (*keep = "true"*)input   wire            sdram_rd_ack    ,   //SDRAM读相应
    (*keep = "true"*)input   wire    [15:0]  sdram_data_out  ,   //读出SDRAM数据
    output  reg             sdram_rd_req    ,   //SDRAM读请求
    (*keep = "true"*)output  reg     [20:0]  sdram_rd_addr,       //SDRAM读地址
	//output  reg     [20:0]  sdram_rd_addr   ,   //SDRAM读地址

//去马赛克信号
	input	wire			out_valid		,
	input	wire	[23:0]	out_color		

);



//wire define
wire            wr_ack_fall ;   //写响应信号下降沿
wire            rd_ack_fall ;   //读相应信号下降沿


wire    [9:0]   wr_fifo_num ;   //写fifo中的数据量
wire    [9:0]   rd_fifo_num ;   //读fifo中的数据量



//reg define
reg        wr_ack_dly       ;   //写响应打拍
reg        rd_ack_dly       ;   //读响应打拍



wire			rd_ack_pos		;


//assign rd_ack_pos = (~rd_ack_dly) && sdram_rd_ack;
always@(posedge sys_clk or negedge sys_rst_n)
	begin
		if(~sys_rst_n)
			cnt_rd_ack <= 28'd0;
		else if(sdram_rd_ack)
			cnt_rd_ack <= cnt_rd_ack + 1'b1;
		else
			cnt_rd_ack <= cnt_rd_ack;
	end


//wr_ack_dly:写响应信号打拍
always@(posedge sys_clk or negedge sys_rst_n)
    if(sys_rst_n == 1'b0)
        wr_ack_dly  <=  1'b0;
    else
        wr_ack_dly  <=  sdram_wr_ack;

//rd_ack_dly:读响应信号打拍
always@(posedge sys_clk or negedge sys_rst_n)
    if(sys_rst_n == 1'b0)
        rd_ack_dly  <=  1'b0;
    else
        rd_ack_dly <=  sdram_rd_ack;


//wr_ack_fall,rd_ack_fall:检测读写响应信号下降沿
assign  wr_ack_fall = (wr_ack_dly & ~sdram_wr_ack);
assign  rd_ack_fall = (rd_ack_dly & ~sdram_rd_ack);



reg	[1:0]	addr_cnt;

//sdram_wr_addr:sdram写地址
always@(posedge sys_clk or negedge sys_rst_n)
    if(sys_rst_n == 1'b0)
    	begin
        	sdram_wr_addr   <=  21'd0;
            addr_cnt <= 2'd0;
        end   
    else    if(wr_rst == 1'b1)
        sdram_wr_addr   <=  sdram_wr_b_addr;
    else    if(wr_ack_fall == 1'b1) //一次突发写结束,更改写地址
        begin
			 if(sdram_wr_addr < (sdram_wr_e_addr - wr_burst_len))
                sdram_wr_addr   <=  sdram_wr_addr + wr_burst_len;
            else
            	begin
                	sdram_wr_addr   <=  sdram_wr_b_addr;
                	if(addr_cnt == 2'd3)
                    	addr_cnt <= addr_cnt;
                	else
                    	addr_cnt <= addr_cnt + 1'b1;
                end
                
        end


//vga计数使能信号

assign vga_count_en = (addr_cnt == 1'b0) ? 1'b0 : 1'b1;


reg	[21:0]	cnt;
reg	[1:0]	state; 

assign one_pic_wr_end = ((cnt >= 22'd1)&&(cnt <=22'd125_000))?1'b1:1'b0;



always@(posedge sys_clk or negedge sys_rst_n)
	begin
		if(~sys_rst_n)
			begin
				cnt <= 22'd0;
				state <= 2'd0;
			end
		else
			begin
				case(state)
					2'd0:begin
							cnt <= 22'd0;
							if((sdram_wr_addr == (sdram_wr_e_addr - wr_burst_len)) &&(wr_ack_fall == 1'b1))
								state <= 2'd1;
							else
								state <= 2'd0;
						 end
					2'd1:begin
							cnt <= cnt + 1'b1;
							if(cnt == 22'd125_000)
								state <= 2'd0;
							else
								state <= 2'd1;
						end
					default:state <= 2'd0;
				endcase
			end
	end


//sdram_rd_addr:sdram读地址
always@(posedge sys_clk or negedge sys_rst_n)
    if(sys_rst_n == 1'b0)
        sdram_rd_addr   <=  21'd0;
    else    if(rd_rst == 1'b1)
        sdram_rd_addr   <=  sdram_rd_b_addr;
    else    if(rd_ack_fall == 1'b1) //一次突发读结束,更改读地址
        begin
            if(sdram_rd_addr < (sdram_rd_e_addr - rd_burst_len))                   
                sdram_rd_addr   <=  sdram_rd_addr + rd_burst_len;
            else    
                sdram_rd_addr   <=  sdram_rd_b_addr;    
        end

assign one_pic_rd_end = ((sdram_rd_addr == (sdram_rd_e_addr - rd_burst_len)) &&(rd_ack_fall == 1'b1))?1'b1:1'b0;



//sdram_wr_req,sdram_rd_req:读写请求信号
always@(posedge sys_clk or negedge sys_rst_n)
    if(sys_rst_n == 1'b0)
        begin
            sdram_wr_req    <=  1'b0;
            sdram_rd_req    <=  1'b0;
        end
    else    if(init_end == 1'b1)   //初始化完成后响应读写请求
        begin   //优先执行写操作，防止写入SDRAM中的数据丢失
            if(wr_fifo_num >= wr_burst_len)
                begin   //写FIFO中的数据量达到写突发长度
                    sdram_wr_req    <=  1'b1;   //写请求有效
                    sdram_rd_req    <=  1'b0;
                end
            else    if((rd_fifo_num < rd_burst_len) && (read_valid == 1'b1) && (vga_count_en == 1'b1))
                begin //读FIFO中的数据量小于读突发长度,读使能信号有效,且一张图片已经全部写进sdram里
                    sdram_wr_req    <=  1'b0;
                    sdram_rd_req    <=  1'b1;   //读请求有效
                end
            else
                begin
                    sdram_wr_req    <=  1'b0;
                    sdram_rd_req    <=  1'b0;
                end
        end
    else
        begin
            sdram_wr_req    <=  1'b0;
            sdram_rd_req    <=  1'b0;
        end


wire			demosaic_out_valid;
wire	[23:0]	demosaic_out_color;





//白平衡
// isp_awb_
//#(
//	.BITS			(8					),
//	.WIDTH			(1920				),
//	.HEIGHT			(1080				)
//)
//u_isp_awb	
//(	
//	.pclk			(sys_clk			),//input
//    .rst_n			(sys_rst_n			),//input
//	.data_valid		(wr_fifo_wr_req		),//input
//	.in_raw			(wr_fifo_wr_data[15:8]),//input[7:0]
	
//	.data_valid_3	(data_valid			),//output
//	.out_raw_2		(data_out			) //output[7:0]
	
//);

//---------------------去码---------------------------
/*isp_demosaic2 
#(
	.BITS			(8					),
	.WIDTH			(1920				),
	.HEIGHT			(1080				)
)
u_isp_demosaic	
(	
	.pclk			(sys_clk			),//input
    .rst_n			(sys_rst_n			),//input
	.data_valid		(sdram_rd_ack		),//input
	.in_raw			(sdram_data_out[15:8]),//input[7:0]

	.out_valid		(demosaic_out_valid			),//output
	.out_color		(demosaic_out_color			) //output[23:0]

);
*/





//------------- wr_fifo_data -------------
fifo_data   wr_fifo_data(
    //用户接口
    .clkw      	(wr_fifo_wr_clk ),  //写时钟 50mhz
    .we      	(wr_fifo_wr_req ),  //写请求
    .di       	(wr_fifo_wr_data),  //写数据 
    //SDRAM接口
    .clkr      	(sys_clk        ),  //读时钟 125mhz
    .re      	(sdram_wr_ack   ),  //读请求
    .dout       (sdram_data_in  ),  //读数据


    .rdusedw    (wr_fifo_num	),
    //.rst       	(~sys_rst_n || wr_rst)  //清零信号
    .rst       	(fifo_rst)  //清零信号
    );

//------------- rd_fifo_data -------------
fifo_data2   rd_fifo_data(
    //sdram接口
    .clkw      	(sys_clk        ),  //写时钟 125mhz
/*     .we      	(sdram_rd_ack   ),  //写请求
    .di       	({8'd0,sdram_data_out} ),  //写数据  */
	
    .we      	(out_valid   	),  //写请求
    .di       	(out_color 		),  //写数据	

    //用户接口
    .clkr      	(rd_fifo_rd_clk ),  //读时钟 
    .re      	(rd_fifo_rd_req ),  //读请求
    .dout       (rd_fifo_rd_data),  //读数据

    .rdusedw    (rd_fifo_num    ),  //FIFO中的数据量
    //.rst       	(~sys_rst_n || rd_rst)  //清零信号
    .rst       	(fifo_rst		)  //清零信号
    );

endmodule
