`timescale  1ns/1ns


module  sdram_read
(
    input   wire            sys_clk         ,   
    input   wire            sys_rst_n       ,   
    input   wire            init_end        ,   
    input   wire            rd_en           ,   
    input   wire    [20:0]  rd_addr         ,   
    input   wire    [31:0]  rd_data         ,   
    input   wire    [9:0]   rd_burst_len    ,   

    output  wire            rd_ack          ,   
    output  wire            rd_end          ,   
    output  reg     [3:0]   read_cmd        ,   
    output  reg     [1:0]   read_ba         ,   
    output  reg     [10:0]  read_addr       ,   
    output  wire    [31:0]  rd_sdram_data       
);


//parameter     define
parameter   TRCD_CLK    =   10'd2   ,   
            TCL_CLK     =   10'd3   ,   
            TRP_CLK     =   10'd2   ;   
parameter   RD_IDLE     =   4'b0000 ,   
            RD_ACTIVE   =   4'b0001 ,   
            RD_TRCD     =   4'b0011 ,   
            RD_READ     =   4'b0010 ,   
            RD_CL       =   4'b0100 ,   
            RD_DATA     =   4'b0101 ,   
            RD_PRE      =   4'b0111 ,   
            RD_TRP      =   4'b0110 ,   
            RD_END      =   4'b1100 ;   
parameter   NOP         =   4'b0111 ,   
            ACTIVE      =   4'b0011 ,   
            READ        =   4'b0101 ,   
            B_STOP      =   4'b0110 ,   
            P_CHARGE    =   4'b0010 ;   

//wire  define
wire            trcd_end    ;   //激活等待周期结束
wire            trp_end     ;   //预充电等待周期结束
wire            tcl_end     ;   //潜伏期结束标志
wire            tread_end   ;   //突发读结束
wire            rdburst_end ;   //读突发终止

//reg   define
reg     [3:0]   read_state  ;   //SDRAM写状态
reg     [9:0]   cnt_clk     ;   //时钟周期计数,记录初始化各状态等待时间
reg             cnt_clk_rst ;   //时钟周期计数复位标志
(*keep = "true"*)reg     [31:0]  rd_data_reg ;


//rd_data_reg
always@(posedge sys_clk or negedge sys_rst_n)
    if(sys_rst_n == 1'b0)
        rd_data_reg <=  32'd0;
    else
        rd_data_reg <=  rd_data;

//rd_end:一次突发读结束
assign  rd_end = (read_state == RD_END) ? 1'b1 : 1'b0;

//rd_ack:读SDRAM响应信号
assign  rd_ack = (read_state == RD_DATA)
                && (cnt_clk >= 10'd1)
                && (cnt_clk < (rd_burst_len + 2'd1));

//cnt_clk:时钟周期计数,记录初始化各状态等待时间
always@(posedge sys_clk or negedge sys_rst_n)
    if(sys_rst_n == 1'b0)
        cnt_clk <=  10'd0;
    else    if(cnt_clk_rst == 1'b1)
        cnt_clk <=  10'd0;
    else
        cnt_clk <=  cnt_clk + 1'b1;

//trcd_end,trp_end,tcl_end,tread_end,rdburst_end:等待结束标志
assign  trcd_end    =   ((read_state == RD_TRCD)
                        && (cnt_clk == TRCD_CLK        )) ? 1'b1 : 1'b0;    //行选通周期结束
assign  trp_end     =   ((read_state == RD_TRP )
                        && (cnt_clk == TRP_CLK         )) ? 1'b1 : 1'b0;    //预充电有效周期结束
assign  tcl_end     =   ((read_state == RD_CL  )
                        && (cnt_clk == TCL_CLK - 1     )) ? 1'b1 : 1'b0;    //潜伏期结束
assign  tread_end   =   ((read_state == RD_DATA)
                        && (cnt_clk == rd_burst_len + 2)) ? 1'b1 : 1'b0;    //突发读结束
assign  rdburst_end =   ((read_state == RD_DATA)
                        && (cnt_clk == rd_burst_len - 4)) ? 1'b1 : 1'b0;    //读突发终止

//read_state:SDRAM的工作状态机
always@(posedge sys_clk or negedge sys_rst_n)
    if(sys_rst_n == 1'b0)
            read_state  <=  RD_IDLE;
    else
        case(read_state)
            RD_IDLE:
                if((rd_en ==1'b1) && (init_end == 1'b1))
                        read_state <=  RD_ACTIVE;
                else
                        read_state <=  RD_IDLE;
            RD_ACTIVE:
                read_state <=  RD_TRCD;
            RD_TRCD:
                if(trcd_end == 1'b1)
                    read_state <=  RD_READ;
                else
                    read_state <=  RD_TRCD;
            RD_READ:
                read_state <=  RD_CL;
            RD_CL:
                read_state <=  (tcl_end == 1'b1) ? RD_DATA : RD_CL;
            RD_DATA:
                read_state <=  (tread_end == 1'b1) ? RD_PRE : RD_DATA;
            RD_PRE:
                read_state  <=  RD_TRP;
            RD_TRP:
                read_state  <=  (trp_end == 1'b1) ? RD_END : RD_TRP;
            RD_END:
                read_state  <=  RD_IDLE;
            default:
                read_state  <=  RD_IDLE;
        endcase

//计数器控制逻辑
always@(*)
    begin
        case(read_state)
            RD_IDLE:    cnt_clk_rst   <=  1'b1;
            RD_TRCD:    cnt_clk_rst   <=  (trcd_end == 1'b1) ? 1'b1 : 1'b0;
            RD_READ:    cnt_clk_rst   <=  1'b1;
            RD_CL:      cnt_clk_rst   <=  (tcl_end == 1'b1) ? 1'b1 : 1'b0;
            RD_DATA:    cnt_clk_rst   <=  (tread_end == 1'b1) ? 1'b1 : 1'b0;
            RD_TRP:     cnt_clk_rst   <=  (trp_end == 1'b1) ? 1'b1 : 1'b0;
            RD_END:     cnt_clk_rst   <=  1'b1;
            default:    cnt_clk_rst   <=  1'b0;
        endcase
    end

//SDRAM操作指令控制
always@(posedge sys_clk or negedge sys_rst_n)
    if(sys_rst_n == 1'b0)
        begin
            read_cmd    <=  NOP;
            read_ba     <=  2'b11;
            read_addr   <=  11'h7ff;
        end
    else
        case(read_state)
            RD_IDLE,RD_TRCD,RD_TRP:
                begin
                    read_cmd    <=  NOP;
                    read_ba     <=  2'b11;
                    read_addr   <=  11'h7ff;
                end
            RD_ACTIVE:  //激活指令
                begin
                    read_cmd    <=  ACTIVE;
                    read_ba     <=  rd_addr[20:19];
                    read_addr   <=  rd_addr[18:8];
                end
            RD_READ:    //读操作指令
                begin
                    read_cmd    <=  READ;
                    read_ba     <=  rd_addr[20:19];
                    read_addr   <=  {3'b000,rd_addr[7:0]};
                end
            RD_DATA:    //突发传输终止指令
                begin
                    if(rdburst_end == 1'b1)
                        read_cmd <=  B_STOP;
                    else
                        begin
                            read_cmd    <=  NOP;
                            read_ba     <=  2'b11;
                            read_addr   <=  11'h7ff;
                        end
                end
            RD_PRE:     //预充电指令
                begin
                    read_cmd    <= P_CHARGE;
                    read_ba     <= rd_addr[20:19];
                    read_addr   <= 11'h400;
                end
            RD_END:
                begin
                    read_cmd    <=  NOP;
                    read_ba     <=  2'b11;
                    read_addr   <=  11'h7ff;
                end
            default:
                begin
                    read_cmd    <=  NOP;
                    read_ba     <=  2'b11;
                    read_addr   <=  11'h7ff;
                end
        endcase

//rd_sdram_data:SDRAM读出的数据
assign  rd_sdram_data = (rd_ack == 1'b1) ? rd_data_reg : 32'b0;

endmodule
