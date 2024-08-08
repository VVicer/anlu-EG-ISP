`timescale  1ns/1ns


module  sd_ctrl
(
    input   wire            sys_clk         ,   //输入工作时钟,频率50MHz
    input   wire            sys_clk_shift   ,   //输入工作时钟,频率50MHz,相位偏移90度
    input   wire            sys_rst_n       ,   //输入复位信号,低电平有效
    //SD卡接口
    input   wire            sd_miso         ,   //主输入从输出信号
    output  wire            sd_clk          ,   //SD卡时钟信号
    output  reg             sd_cs_n         ,   //片选信号
    output  reg             sd_mosi         ,   //主输出从输入信号
    //写SD卡接口
//    input   wire            wr_en           ,   //数据写使能信号
//    input   wire    [31:0]  wr_addr         ,   //写数据扇区地址
//    input   wire    [15:0]  wr_data         ,   //写数据
//    output  wire            wr_busy         ,   //写操作忙信号
//    output  wire            wr_req          ,   //写数据请求信号
    //读SD卡接口
    input   wire            rd_en           ,   //数据读使能信号
    input   wire    [31:0]  rd_addr         ,   //读数据扇区地址
    output  wire            rd_busy         ,   //读操作忙信号
    output  wire            rd_data_en      ,   //读数据标志信号
    output  wire    [15:0]  rd_data         ,   //读数据

	input	wire			pic_c			,

	output  wire			led_5			,
    output  wire            init_end            //SD卡初始化完成信号
);

//********************************************************************//
//****************** Parameter and Internal Signal *******************//
//********************************************************************//
//wire define
wire            init_cs_n   ;   //初始化阶段片选信号
wire            init_mosi   ;   //初始化阶段主输出从输入信号
wire            wr_cs_n     ;   //写数据阶段片选信号
wire            wr_mosi     ;   //写数据阶段主输出从输入信号
wire            rd_cs_n     ;   //读数据阶段片选信号
wire            rd_mosi     ;   //读数据阶段主输出从输入信号

wire			wr_busy = 1'b0;

//********************************************************************//
//***************************** Main Code ****************************//
//********************************************************************//
//sd_clk:SD卡时钟信号
assign  sd_clk = sys_clk_shift;

//SD卡接口信号选择
always@(*)
    if(init_end == 1'b0)
        begin
            sd_cs_n <=  init_cs_n;
            sd_mosi <=  init_mosi;
        end
    else    if(wr_busy == 1'b1)
        begin
            sd_cs_n <=  wr_cs_n;
            sd_mosi <=  wr_mosi;
        end
    else    if(rd_busy == 1'b1)
        begin
            sd_cs_n <= rd_cs_n;
            sd_mosi <= rd_mosi;
        end
    else
        begin
            sd_cs_n <=  1'b1;
            sd_mosi <=  1'b1;
        end

//********************************************************************//
//************************** Instantiation ***************************//
//********************************************************************//
//------------- sd_init_inst -------------
sd_init sd_init_inst
(
    .sys_clk        (sys_clk        ),  //输入工作时钟,频率50MHz
    .sys_clk_shift  (sys_clk_shift  ),  //输入工作时钟,频率50MHz,相位偏移90度
    .sys_rst_n      (sys_rst_n      ),  //输入复位信号,低电平有效
    .miso           (sd_miso        ),  //主输入从输出信号

    .cs_n           (init_cs_n      ),  //输出片选信号
    .mosi           (init_mosi      ),  //主输出从输入信号
    .init_end       (init_end       )   //初始化完成信号
);

//------------- sd_write_inst -------------
//sd_write    sd_write_inst
//(
//    .sys_clk        (sys_clk            ),  //输入工作时钟,频率50MHz
//    .sys_clk_shift  (sys_clk_shift      ),  //输入工作时钟,频率50MHz,相位偏移90度
//    .sys_rst_n      (sys_rst_n          ),  //输入复位信号,低电平有效
//    .miso           (sd_miso            ),  //主输入从输出信号
//    .wr_en          (wr_en && init_end  ),  //数据写使能信号
//    .wr_addr        (wr_addr            ),  //写数据扇区地址
//    .wr_data        (wr_data            ),  //写数据

//    .cs_n           (wr_cs_n            ),  //输出片选信号
//    .mosi           (wr_mosi            ),  //主输出从输入信号
//    .wr_busy        (wr_busy            ),  //写操作忙信号
//    .wr_req         (wr_req             )   //写数据请求信号
//);

//------------- sd_read_inst -------------
sd_read sd_read_inst
(
    .sys_clk        (sys_clk            ),  //输入工作时钟,频率50MHz
    .sys_clk_shift  (sys_clk_shift      ),  //输入工作时钟,频率50MHz,相位偏移90度
    .sys_rst_n      (sys_rst_n          ),  //输入复位信号,低电平有效
    .miso           (sd_miso            ),  //主输入从输出信号
    .rd_en          (rd_en & init_end   ),  //数据读使能信号
    .rd_addr        (rd_addr            ),  //读数据扇区地址

	.pic_c			(pic_c				),

	.led_5			(led_5),

    .rd_busy        (rd_busy            ),  //读操作忙信号
    .rd_data_en     (rd_data_en         ),  //读数据标志信号
    .rd_data        (rd_data            ),  //读数据
    .cs_n           (rd_cs_n            ),  //片选信号
    .mosi           (rd_mosi            )   //主输出从输入信号
);

endmodule