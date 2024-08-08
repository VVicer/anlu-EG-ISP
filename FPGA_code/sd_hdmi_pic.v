module sd_hdmi_pic( 


    input   wire            sys_clk     	,  //输入工作时钟,频率50MHz
    input   wire            sys_rst_n   	,  //输入复位信号,低电平有效
    //SD卡
    input   wire            sd_miso     	,  //主输入从输出信号
    output  wire            sd_clk      	,  //SD卡时钟信号
    output  wire            sd_cs_n     	,  //片选信号
    output  wire            sd_mosi     	,  //主输出从输入信号
	
    //LED
    output	wire			led_sd_init		,
    output	wire			led_sdram_init	,
    output	wire			led_80m			,
    output	wire			led_125m		,
    output	wire			led_5			,

    //HDMI
    output  wire            ddc_scl     	,
    output  wire            ddc_sda     	,
    output  wire            tmds_clk_p  	,
    output  wire    [2:0]   tmds_data_p 	,

   input                    clk_50m		 ,
   input                    clk_50m_shift,	
   input                    clk_125m	,	
   input                    clk_125m_shift,	

   input                    clk_74m		,
   input                    clk_370m		,

   input                    locked       ,  
   input                    locked2      
);
 


parameter  H_VALID  =   21'd1920;   //行有效数据
parameter  V_VALID  =   21'd1080 ;   //列有效数据

parameter	CNT_80M_MAX = 29'd74_000_000;
parameter	CNT_125M_MAX = 29'd125_000_000;

wire			clk_12_5m		;
wire			clk_62_5m		;

wire			clk_40m			;
wire			clk_200m		;

wire			clk_25m			;
// wire			clk_50m			;
// wire			clk_50m_shift	;
// wire			clk_125m		;
//wire			clk_125m_shift	;

wire			clk_80m			;
wire			clk_400m		;

wire			clk_130m		;
wire			clk_130m_shift	;

wire			clk_150m		;
wire			clk_150m_shift	;


wire			clk_65m			;
wire			clk_325m		;

wire			clk_148m		;
wire			clk_740m		;

// wire			clk_74m			;
// wire			clk_370m		;

wire			clk_78m			;
wire			clk_390m		;


// wire    		locked	        ;
// wire			locked2			;


//**************sd读数据控制模块输出端口**************
wire            sd_rd_en        ;//开始写SD卡数据信号
wire    [31:0]  sd_rd_addr      ;//读数据扇区地址 



//**************sd卡控制模块输出端口******************
wire            sd_rd_busy      ;//读忙信号
wire            sd_rd_data_en   ;//数据读取有效使能信号
wire    [15:0]  sd_rd_data      ;//读数据
wire            sd_init_end     ;//SD卡初始化完成信号


//**************sdram控制模块输出端口*****************
wire            wr_en           ;//sdram_ctrl模块写使能
wire    [15:0]  wr_data         ;//sdram_ctrl模块写数据
//wire    [15:0]  rd_data         ;//sdram_ctrl模块读数据
wire    [23:0]  rd_data         ;//sdram_ctrl模块读数据
wire            sdram_init_end  ;//SDRAM初始化完成
 
wire            sdram_clk   	;  //SDRAM 芯片时钟
wire            sdram_cke   	;  //SDRAM 时钟有效
wire            sdram_cs_n  	;  //SDRAM 片选
wire            sdram_ras_n 	;  //SDRAM 行有效
wire            sdram_cas_n 	;  //SDRAM 列有效
wire            sdram_we_n  	;  //SDRAM 写有效
wire    [1:0]   sdram_ba    	;  //SDRAM Bank地址
wire    [3:0]   sdram_dqm   	;  //SDRAM 数据掩码
wire    [10:0]  sdram_addr  	;  //SDRAM 行/列地址
wire    [31:0]  sdram_dq    	;  //SDRAM 数据

wire			vga_count_en	;
wire			one_pic_wr_end	;
wire			pic_c			;
wire			sdram_rd_flag	;
//wire	[27:0]	cnt_rd_ack		;

(*keep = "true"*)wire	[27:0]	cnt_rd_ack		;


//**************vga控制模块输出端口******************
wire			rgb_valid		;
wire			rd_en			;
wire			vga_hs			;
wire			vga_vs			;
//wire	[15:0]	vga_rgb			;
wire	[23:0]	vga_rgb			;


//----------------生成系统工作复位信号--------------------
wire	rst_n;

assign	rst_n = sys_rst_n && locked && locked2;

//---------------------led指示灯--------------------------
wire            sys_init_end    ;  //系统初始化完成
reg		[28:0]	cnt_80m			;
reg		[28:0]	cnt_125m		;

//sys_init_end:系统初始化完成,SD卡和SDRAM均完成初始化
assign  sys_init_end = sd_init_end && sdram_init_end;

//led
assign	led_sd_init = (sd_init_end == 1'b1)?1'b1:1'b0; //sd卡初始化完成指示灯
assign	led_sdram_init = (sdram_init_end == 1'b1)?1'b1:1'b0;//sdram初始化完成指示灯

assign  led_80m = ((cnt_80m >= CNT_80M_MAX/2)&&(cnt_80m <= CNT_80M_MAX-1'b1))?1'b1:1'b0;
assign  led_125m = ((cnt_125m >= CNT_125M_MAX/2)&&(cnt_125m <= CNT_125M_MAX-1'b1))?1'b1:1'b0;

always@(posedge clk_74m or negedge rst_n)begin
	if(~rst_n)
    	cnt_80m <= 1'b0;
    else if(cnt_80m == CNT_80M_MAX-1'b1)
    	cnt_80m <= 1'b0;
    else
    	cnt_80m <= cnt_80m + 1'b1;
end

always@(posedge clk_125m or negedge rst_n)begin
	if(~rst_n)
    	cnt_125m <= 1'b0;
    else if(cnt_125m == CNT_125M_MAX-1'b1)
    	cnt_125m <= 1'b0;
    else
    	cnt_125m <= cnt_125m + 1'b1;
end


//--------------- pll_inst ---------------
//clk_gen 	clk_gen_inst(
//	.sys_clk				(sys_clk		),//input
//	.sys_rst_n				(sys_rst_n		),//input
//	.clk_1x					(clk_1x			),//output
//	.clk_5x					(clk_5x			),//output
//	.clk_sdram				(clk_sdram		),//output
//	.clk_sdram_shift		(clk_sdram_shift),//output
//	.clk_sd					(clk_sd			),//output
//	.clk_sd_shift			(clk_sd_shift	),//output
//	.locked	                (locked	        ) //output

//);

// pll pll_inst
// (
//     .reset       		(~sys_rst_n       	),  //复位信号,高有效
//     .refclk       		(sys_clk          	),  //输入系统时钟,50MHz

//     .clk0_out           (          	),  
//     .clk1_out           (clk_74m      		),  //生成74MHz时钟
//     .clk2_out           (clk_370m   		),  //生成370MHz时钟
// //    .clk3_out           (clk_400m          	),  //生成400MHz时钟
// //    .clk4_out           (clk_50m_shift      ),  //生成50MHz时钟,相位偏移30度
//     .extlock       		(locked            	)   //时钟锁定信号
// );

// pll2 pll2_inst(
//     .reset       		(~sys_rst_n       	),  //复位信号,高有效
//     .refclk       		(sys_clk          	),  //输入系统时钟,50MHz
// 	.clk0_out			(clk_125m			),	//生成125MHz时钟
//     .clk1_out           (clk_125m_shift     ),  //生成125MHz时钟,相位偏移270度 
//     .clk2_out           (clk_50m     		),  //生成50MHz时钟
//  	.clk3_out           (clk_50m_shift      ),  //生成50MHz时钟，相位偏移180度
//     .extlock       		(locked2            )   //时钟锁定信号   	
    
// );



//------------- data_rd_ctrl_inst -------------
data_rd_ctrl    data_rd_ctrl_inst
(
    .sys_clk    	(clk_50m                ),//input 	     输入工作时钟,频率50MHz
    .sys_rst_n  	(rst_n & sys_init_end   ),//input 	     输入复位信号,低电平有效
    .rd_busy    	(sd_rd_busy             ),//input 	     读操作忙信号
    
	.pic_c			(pic_c					),//input
    .one_pic_wr_end	(one_pic_wr_end			),//input
	.sdram_rd_flag	(sdram_rd_flag			),//output

    .rd_en      	(sd_rd_en               ),//output	 	 数据读使能信号
    .rd_addr    	(sd_rd_addr             ) //output[31:0] 读数据扇区地址
);



//------------- sd_ctrl_inst -------------
sd_ctrl sd_ctrl_inst
(
    .sys_clk         (clk_50m        ),//input  输入工作时钟,频率50MHz
    .sys_clk_shift   (clk_50m_shift  ),//input  输入工作时钟,频率50MHz,相位偏移180度
    .sys_rst_n       (rst_n         ),//input  输入复位信号,低电平有效
    .sd_miso         (sd_miso       ),//input  	主输入从输出信号
    .sd_clk          (sd_clk        ),//output 	SD卡时钟信号
    .sd_cs_n         (sd_cs_n       ),//output 	片选信号
    .sd_mosi         (sd_mosi       ),//output 	主输出从输入信号
    
    .pic_c			 (pic_c			),
	.led_5			 (led_5),

    .rd_en           (sd_rd_en      ),//input		数据读使能信号
    .rd_addr         (sd_rd_addr    ),//input[31:0] 读数据扇区地址
    .rd_busy         (sd_rd_busy    ),//output		读操作忙信号
    .rd_data_en      (sd_rd_data_en ),//output		读数据标志信号
    .rd_data         (sd_rd_data    ),//output[15:0]读数据

    .init_end        (sd_init_end   ) //output		SD卡初始化完成信号
);

//------------- sdram_top_inst -------------
sdram_top   sdram_top_inst
( 
	.fifo_rst			(~sys_rst_n		),
    .sys_clk            (clk_125m      	),//input  //sdram 控制器参考时钟
    .clk_out            (clk_125m_shift	),//input  //用于输出的相位偏移时钟
    .sys_rst_n          (rst_n          ),//input  //系统复位
    
	.sdram_rd_flag		(sdram_rd_flag	),//input
    .pic_c				(pic_c			),//input
    .vga_count_en		(vga_count_en	),//output
    .one_pic_wr_end		(one_pic_wr_end	),//ouptut
	.cnt_rd_ack			(cnt_rd_ack		),//output[14:0]
    
//用户写端口
    .wr_fifo_wr_clk     (clk_50m         ),
    .wr_fifo_wr_req     (sd_rd_data_en  ),
    .wr_fifo_wr_data    (sd_rd_data     ),
    .sdram_wr_b_addr    (21'd0          ),
    .sdram_wr_e_addr    (H_VALID*V_VALID),
    .wr_burst_len       (10'd256        ),
	.wr_rst             (~sys_rst_n     ),
//用户读端口
    .rd_fifo_rd_clk     (clk_74m         ),
    .rd_fifo_rd_req     (rd_en          ),
    .rd_fifo_rd_data    (rd_data        ),
    .sdram_rd_b_addr    (21'd0          ),
    .sdram_rd_e_addr    (H_VALID*V_VALID),
    .rd_burst_len       (10'd256        ),

    .rd_rst             (~sys_rst_n     ),
//用户控制端口
    .read_valid         (1'b1           ),
    .pingpang_en        (1'b0           ),
    .init_end           (sdram_init_end ),
//SDRAM 芯片接口
    .sdram_clk          (sdram_clk      ),
    .sdram_cke          (sdram_cke      ),
    .sdram_cs_n         (sdram_cs_n     ),
    .sdram_ras_n        (sdram_ras_n    ),
    .sdram_cas_n        (sdram_cas_n    ),
    .sdram_we_n         (sdram_we_n     ),
    .sdram_ba           (sdram_ba       ),
    .sdram_addr         (sdram_addr     ),
    .sdram_dq           (sdram_dq       ),
    .sdram_dqm          (sdram_dqm      ) 
);

//------------vga_ctrl_inst---------------
vga_ctrl u_vga_ctrl(
	.vga_clk    		(clk_74m		),
	.sys_rst_n      	(rst_n			),
	.data_in 			(rd_data		),//input[15:0]
    .vga_count_en		(vga_count_en	),//input
	.sdram_rd_flag		(sdram_rd_flag	),//input

	.hsync     			(vga_hs			),//output
	.vsync     			(vga_vs			),//output
	.rgb     			(vga_rgb		),//output[15:0]
	.rgb_valid  		(rgb_valid		),//output
	.data_req			(rd_en			) //output
);





//------------- hdmi_top_inst -------------
hdmi_top 	hdmi_top_inst(
	.PXLCLK_I			(clk_74m				),//input
	.PXLCLK_5X_I		(clk_370m				),//input
	.RST_I				((~rst_n)				),//input
	.de					(rgb_valid				),//input
	.hsync				(vga_hs					),//input
	.vsync				(vga_vs					),//input
	

	
	
/*  	.rgb_blue  			({vga_rgb[4:0],3'b0}	),//input[7:0]
	.rgb_green          ({vga_rgb[10:5],2'b0}	),//input[7:0]
	.rgb_red            ({vga_rgb[15:11],3'b0}	),//input[7:0]  */
	
	
/*  	 .rgb_blue  		(8'd0),//input[7:0]
	.rgb_green          ({vga_rgb[15:8]}),//input[7:0]
	.rgb_red            (8'd0),//input[7:0] */   

 	.rgb_blue  			({vga_rgb[7:0]}),//input[7:0]
	.rgb_green          ({vga_rgb[15:8]}),//input[7:0]
	.rgb_red            ({vga_rgb[23:16]}),//input[7:0] 
						
                        
	.HDMI_CLK_P			(tmds_clk_p				),//output
	.HDMI_D2_P			(tmds_data_p[2]			),//output
	.HDMI_D1_P			(tmds_data_p[1]			),//output
    .HDMI_D0_P		    (tmds_data_p[0]			) //output
);



//------------- hdmi_top_inst -------------
sdram	u_sdram(
	.clk   	(sdram_clk		),
	.cke   	(sdram_cke		),
	.cs_n  	(sdram_cs_n		),
	.ras_n 	(sdram_ras_n	),
	.cas_n 	(sdram_cas_n	),
	.we_n  	(sdram_we_n		),
	.ba    	(sdram_ba		),
    .addr  	(sdram_addr		),
    .dq    	(sdram_dq		),
	.dm0	(sdram_dqm[0]	),
	.dm1    (sdram_dqm[1]	),
	.dm2    (sdram_dqm[2]	),
	.dm3    (sdram_dqm[3]	)
);






endmodule
