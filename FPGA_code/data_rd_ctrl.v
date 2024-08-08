`timescale  1ns/1ns

module  data_rd_ctrl
(
    input   wire            sys_clk     ,   //输入工作时钟,频率50MHz
    input   wire            sys_rst_n   ,   //输入复位信号,低电平有效
    input   wire            rd_busy     ,   //读操作忙信号
    
    input	wire			one_pic_wr_end	, 
    output	reg             pic_c       ,   //图片切换标志
	
	output	reg				sdram_rd_flag,

    output  reg             rd_en       ,   //数据读使能信号
    output  reg     [31:0]  rd_addr         //读数据扇区地址
);

//********************************************************************//
//****************** Parameter and Internal Signal *******************//
//********************************************************************//
//parameter define
parameter   IDLE    =   3'b001, //初始状态
            READ    =   3'b010, //读数据状态
            WAIT    =   3'b100; //等待状态


//1920x1080
 parameter   IMG_SEC_ADDR0   =   32'd24832;  //图片1扇区起始地址
            //IMG_SEC_ADDR1   =   32'd32960;  //图片2扇区起始地址 

//1024x768
/* parameter   IMG_SEC_ADDR0   =   32'd24832,  //图片1扇区起始地址
            IMG_SEC_ADDR1   =   32'd27904;  //图片2扇区起始地址 */
            
//1024x768
//parameter   IMG_SEC_ADDR0   =   32'd41088,  //图片1扇区起始地址
//            IMG_SEC_ADDR1   =   32'd44160;  //图片2扇区起始地址
                    

parameter   RD_NUM  =   14'd8228  ;       //单张图片读取次数
parameter   WAIT_MAX=   26'd100_000  ;   //图片切换时间间隔计数最大值

//wire  define
wire            rd_busy_fall;   //读操作忙信号下降沿

//reg   defien
reg             rd_busy_dly ;   //读操作忙信号打一拍
reg     [2:0]   state       ;   //状态机状态
reg     [13:0]  cnt_rd      ;   //单张图片读取次数计数

reg				one_pic_wr_end_reg0;
reg				one_pic_wr_end_reg1;
wire			one_pic_wr_end_pos;

//reg     [25:0]  cnt_wait    ;   //图片切换时间间隔计数

//********************************************************************//
//***************************** Main Code ****************************//
//********************************************************************//
assign	one_pic_wr_end_pos = (~one_pic_wr_end_reg0)&&one_pic_wr_end_reg1;

always@(posedge sys_clk or negedge sys_rst_n)begin
	if(~sys_rst_n)
		begin
			one_pic_wr_end_reg0 <= 1'b0;
			one_pic_wr_end_reg1 <= 1'b0;
		end
	else
		begin
			one_pic_wr_end_reg0 <= one_pic_wr_end;
			one_pic_wr_end_reg1 <= one_pic_wr_end_reg0;
		end		
end



//rd_busy_dly:读操作忙信号打一拍
always@(posedge sys_clk or negedge sys_rst_n)
    if(sys_rst_n == 1'b0)
        rd_busy_dly <=  1'b0;
    else
        rd_busy_dly <=  rd_busy;

//rd_busy_fall:读操作忙信号下降沿
assign  rd_busy_fall = ((rd_busy == 1'b0) && (rd_busy_dly == 1'b1))
                        ? 1'b1 : 1'b0;

reg [4:0] cnt_pic_c;
//state:状态机状态
always@(posedge sys_clk or negedge sys_rst_n)
    if(sys_rst_n == 1'b0)
    	begin
        	state   <=  IDLE;
            pic_c 	<= 1'b0;
			sdram_rd_flag <= 1'b0;
			cnt_pic_c <= 5'd0;
        end
        
    else
        case(state)
            IDLE:   state   <=  READ;
            READ:
                if(cnt_rd == (RD_NUM - 1'b1))
                    state   <=  WAIT;
                else
                    state   <=  state;
            WAIT:
            	begin
                    //if(one_pic_wr_end)
                    	//begin
                    		state <= IDLE;
                        	pic_c <= ~pic_c;
							cnt_pic_c <= cnt_pic_c + 1'b1;
                        //end
                   // else      
                    	//state <= state;
                end
               
            default:    state   <=  IDLE;
        endcase

//pic_c:图片切换
/* always@(posedge sys_clk or negedge sys_rst_n)
    if(sys_rst_n == 1'b0)
        pic_c   <=  1'b0;
    else    if(state == IDLE)
        pic_c   <=  ~pic_c;
    else
        pic_c   <=  pic_c; */

//cnt_rd:单张图片读取次数计数
always@(posedge sys_clk or negedge sys_rst_n)
    if(sys_rst_n == 1'b0)
        cnt_rd  <=  14'd0;
    else    if(state == READ)
		begin
			if(cnt_rd == RD_NUM - 1'b1)
				cnt_rd  <=  14'd0;
			else    if(rd_busy_fall == 1'b1)
				cnt_rd  <=  cnt_rd + 1'b1;
			else
				cnt_rd  <=  cnt_rd;
		end

//rd_en:数据读使能信号
always@(posedge sys_clk or negedge sys_rst_n)
    if(sys_rst_n == 1'b0)
        rd_en   <=  1'b0;
    else    if(state == IDLE)
        rd_en   <=  1'b1;
    else    if(state == READ)
        if(rd_busy_fall == 1'b1)
            rd_en   <=  1'b1;
        else
            rd_en   <=  1'b0;
    else
        rd_en   <=  1'b0;

reg	first_disp;

//rd_addr:读数据扇区地址
always@(posedge sys_clk or negedge sys_rst_n)
    if(sys_rst_n == 1'b0)
    	begin
        	first_disp <= 1'b0;
        	rd_addr <=  32'd0;
        end
    else
        case(state)
            IDLE:
				begin
					if(~first_disp)
						begin
							rd_addr <= IMG_SEC_ADDR0;
							first_disp <= 1'b1;
						end
					else
						begin
							//rd_addr <= IMG_SEC_ADDR0 + cnt_pic_c*RD_NUM;
							rd_addr <= rd_addr + 1'b1;
							first_disp <= first_disp;
						end
				end

            READ:
				begin
					if(rd_busy_fall == 1'b1)
						rd_addr <=  rd_addr + 1'd1;
					else
						rd_addr <=  rd_addr;
				end

            default:rd_addr <=  rd_addr;
        endcase

//cnt_wait:图片切换时间间隔计数
//always@(posedge sys_clk or negedge sys_rst_n)
//    if(sys_rst_n == 1'b0)
//        cnt_wait    <=  26'd0;
//    else    if(state == WAIT)
//        if(cnt_wait == (WAIT_MAX - 1'b1))
//            cnt_wait    <=  26'd0;
//        else
//            cnt_wait    <=  cnt_wait + 1'b1;
//    else
//        cnt_wait    <=  26'd0;

endmodule
