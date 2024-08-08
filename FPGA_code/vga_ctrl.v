`timescale  1ns/1ns


module  vga_ctrl
(
    input   wire            vga_clk     ,   //输入工作时钟,频率25MHz
    input   wire            sys_rst_n   ,   //输入复位信号,低电平有效
    input   wire    [23:0]  data_in     ,   //待显示数据输入
    
	input	wire			sdram_rd_flag,
    input	wire			vga_count_en,

    output  wire            rgb_valid   ,   //VGA有效显示区域
    output  wire            data_req    ,   //数据请求信号
    output  wire            hsync       ,   //输出行同步信号
    output  wire            vsync       ,   //输出场同步信号
    output  wire    [23:0]  rgb             //输出像素信息
);

//********************************************************************//
//****************** Parameter and Internal Signal *******************//
//********************************************************************//
//parameter define

//--------------------640x480@60hz
//parameter   H_SYNC    = 11'd96  , //行同步
//            H_BACK    = 11'd40  , //行时序后沿
//            H_LEFT    = 11'd8   , //行时序左边框
//            H_VALID   = 11'd640 , //行有效数据
//            H_RIGHT   = 11'd8   , //行时序右边框
//            H_FRONT   = 11'd8   , //行时序前沿
//            H_TOTAL   = 11'd800 ; //行扫描周期
//parameter   V_SYNC    = 11'd2   , //场同步
//            V_BACK    = 11'd25  , //场时序后沿
//            V_TOP     = 11'd8   , //场时序左边框
//            V_VALID   = 11'd480 , //场有效数据
//            V_BOTTOM  = 11'd8   , //场时序右边框
//            V_FRONT   = 11'd2   , //场时序前沿
//            V_TOTAL   = 11'd525 ; //场扫描周期


//--------------------640x480@75hz
//parameter   H_SYNC    = 11'd64  , //行同步
//            H_BACK    = 11'd120  , //行时序后沿
//            H_LEFT    = 11'd0   , //行时序左边框
//            H_VALID   = 11'd640 , //行有效数据
//            H_RIGHT   = 11'd0   , //行时序右边框
//            H_FRONT   = 11'd16   , //行时序前沿
//            H_TOTAL   = 11'd840 ; //行扫描周期
//parameter   V_SYNC    = 11'd3   , //场同步
//            V_BACK    = 11'd16  , //场时序后沿
//            V_TOP     = 11'd0   , //场时序左边框
//            V_VALID   = 11'd480 , //场有效数据
//            V_BOTTOM  = 11'd0   , //场时序右边框
//            V_FRONT   = 11'd1   , //场时序前沿
//            V_TOTAL   = 11'd500 ; //场扫描周期

//----------------------800x600@60hz
//parameter   H_SYNC    = 11'd128  , //行同步
//            H_BACK    = 11'd88  , //行时序后沿
//            H_LEFT    = 11'd0   , //行时序左边框
//            H_VALID   = 11'd800 , //行有效数据
//            H_RIGHT   = 11'd0   , //行时序右边框
//            H_FRONT   = 11'd40   , //行时序前沿
//            H_TOTAL   = 11'd1056 ; //行扫描周期
//parameter   V_SYNC    = 11'd4   , //场同步
//            V_BACK    = 11'd23  , //场时序后沿
//            V_TOP     = 11'd0   , //场时序左边框
//            V_VALID   = 11'd600 , //场有效数据
//            V_BOTTOM  = 11'd0   , //场时序右边框
//            V_FRONT   = 11'd1   , //场时序前沿
//            V_TOTAL   = 11'd628 ; //场扫描周期




//--------------------1024x768@60hz
/*  parameter   H_SYNC    = 11'd136  , //行同步
            H_BACK    = 11'd160  , //行时序后沿
            H_LEFT    = 11'd0   , //行时序左边框
            H_VALID   = 11'd1024 , //行有效数据
            H_RIGHT   = 11'd0   , //行时序右边框
            H_FRONT   = 11'd24   , //行时序前沿
            H_TOTAL   = 11'd1344 ; //行扫描周期
parameter   V_SYNC    = 11'd6   , //场同步
            V_BACK    = 11'd29  , //场时序后沿
            V_TOP     = 11'd0   , //场时序左边框
            V_VALID   = 11'd768 , //场有效数据
            V_BOTTOM  = 11'd0   , //场时序右边框
            V_FRONT   = 11'd3   , //场时序前沿
            V_TOTAL   = 11'd806 ; //场扫描周期  */
			
			
/* parameter   H_SYNC    = 12'd44  , //行同步
            H_BACK    = 12'd148  , //行时序后沿
            H_LEFT    = 12'd0   , //行时序左边框
            H_VALID   = 12'd1920 , //行有效数据
            H_RIGHT   = 12'd0   , //行时序右边框
            H_FRONT   = 12'd88   , //行时序前沿
            H_TOTAL   = 12'd2200 ; //行扫描周期
parameter   V_SYNC    = 12'd5   , //场同步
            V_BACK    = 12'd36  , //场时序后沿
            V_TOP     = 12'd0   , //场时序左边框
            V_VALID   = 12'd1080 , //场有效数据
            V_BOTTOM  = 12'd0   , //场时序右边框
            V_FRONT   = 12'd4   , //场时序前沿
            V_TOTAL   = 12'd1125 ; //场扫描周期	 */		


			
			
		

//--------------------1024x768@75hz
//parameter   H_SYNC    = 11'd176  , //行同步
//            H_BACK    = 11'd176  , //行时序后沿
//            H_LEFT    = 11'd0   , //行时序左边框
//            H_VALID   = 11'd1024 , //行有效数据
//            H_RIGHT   = 11'd0   , //行时序右边框
//            H_FRONT   = 11'd16   , //行时序前沿
//            H_TOTAL   = 11'd1312 ; //行扫描周期
//parameter   V_SYNC    = 11'd3   , //场同步
//            V_BACK    = 11'd28  , //场时序后沿
//            V_TOP     = 11'd0   , //场时序左边框
//            V_VALID   = 11'd768 , //场有效数据
//            V_BOTTOM  = 11'd0   , //场时序右边框
//            V_FRONT   = 11'd1   , //场时序前沿
//            V_TOTAL   = 11'd800 ; //场扫描周期


//--------------------1920x1080@60hz
parameter   H_SYNC    = 12'd44  , //行同步
            H_BACK    = 12'd148  , //行时序后沿
            H_LEFT    = 12'd0   , //行时序左边框
            H_VALID   = 12'd1920 , //行有效数据
            H_RIGHT   = 12'd0   , //行时序右边框
            H_FRONT   = 12'd88   , //行时序前沿
            H_TOTAL   = 12'd2200 ; //行扫描周期
parameter   V_SYNC    = 12'd5   , //场同步
            V_BACK    = 12'd36  , //场时序后沿
            V_TOP     = 12'd0   , //场时序左边框
            V_VALID   = 12'd1080 , //场有效数据
            V_BOTTOM  = 12'd0   , //场时序右边框
            V_FRONT   = 12'd4   , //场时序前沿
            V_TOTAL   = 12'd1125 ; //场扫描周期



//reg   define
reg   [11:0]     cnt_h       ; //行同步信号计数器
reg   [11:0]     cnt_v       ; //场同步信号计数器

//********************************************************************//
//***************************** Main Code ****************************//
//********************************************************************//



//cnt_h:行同步信号计数器
always@(posedge vga_clk or  negedge sys_rst_n)
    if((sys_rst_n == 1'b0) || (vga_count_en == 1'b0))
        cnt_h <=  12'd0 ;
    else    if(cnt_h == (H_TOTAL-1'b1))
        cnt_h <=  12'd0 ;
    else
        cnt_h <=  cnt_h + 1'b1 ;

//hsync:行同步信号
assign  hsync = (cnt_h <= H_SYNC-1) ? 1'b1 : 1'b0  ;

//cnt_v:场同步信号计数器
always@(posedge vga_clk or  negedge sys_rst_n)
    if(sys_rst_n == 1'b0 || (vga_count_en == 1'b0))
        cnt_v <=  12'd0 ;
    else    if((cnt_v == V_TOTAL- 1'b1)&&(cnt_h == H_TOTAL - 1'b1))
        cnt_v <=  12'd0 ;
    else    if(cnt_h == H_TOTAL - 1'b1)
        cnt_v <=  cnt_v + 1'b1 ;
    else
        cnt_v <=  cnt_v ;

//vsync:场同步信号
assign  vsync = (cnt_v <= V_SYNC - 1'b1) ? 1'b1 : 1'b0  ;

//data_valid:有效显示区域标志
assign  rgb_valid = ((cnt_h >= (H_SYNC + H_BACK + H_LEFT)) && (cnt_h < (H_SYNC + H_BACK + H_LEFT + H_VALID)))
                    &&((cnt_v >= (V_SYNC + V_BACK + V_TOP)) && (cnt_v < (V_SYNC + V_BACK + V_TOP + V_VALID)));
//data_req:数据请求信号
assign  data_req = ((cnt_h >= (H_SYNC + H_BACK + H_LEFT) - 2'd2) && (cnt_h < ((H_SYNC + H_BACK + H_LEFT + H_VALID) - 2'd2)))
                    &&((cnt_v >= ((V_SYNC + V_BACK + V_TOP))) && (cnt_v < ((V_SYNC + V_BACK + V_TOP + V_VALID))));

//rgb:输出像素信息
assign  rgb = (rgb_valid == 1'b1) ? data_in : 24'b0 ;

endmodule
