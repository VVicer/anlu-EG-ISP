`timescale  1ns/1ns


module  sdram_write
(
    input   wire            sys_clk         ,   
    input   wire            sys_rst_n       ,   
    input   wire            init_end        ,   
    input   wire            wr_en           ,   
    input   wire    [20:0]  wr_addr         ,   
    input   wire    [31:0]  wr_data         ,   
    input   wire    [9:0]   wr_burst_len    ,   

    output  wire            wr_ack          ,   
    output  wire            wr_end          ,   
    output  reg     [3:0]   write_cmd       ,   
    output  reg     [1:0]   write_ba        ,   
    output  reg     [10:0]  write_addr      ,   
    output  reg             wr_sdram_en     ,   
    output  wire    [31:0]  wr_sdram_data       
);



//parameter     define
parameter   TRCD_CLK    =   10'd2   ,   
            TRP_CLK     =   10'd2   ;   
parameter   WR_IDLE     =   4'b0000 ,   
            WR_ACTIVE   =   4'b0001 ,   
            WR_TRCD     =   4'b0011 ,   
            WR_WRITE    =   4'b0010 ,   
            WR_DATA     =   4'b0100 ,   
            WR_PRE      =   4'b0101 ,   
            WR_TRP      =   4'b0111 ,   
            WR_END      =   4'b0110 ;   
parameter   NOP         =   4'b0111 ,   
            ACTIVE      =   4'b0011 ,   
            WRITE       =   4'b0100 ,   
            B_STOP      =   4'b0110 ,   
            P_CHARGE    =   4'b0010 ;   

//wire  define
wire            trcd_end    ;   
wire            twrite_end  ;   
wire            trp_end     ;   

//reg   define
reg     [3:0]   write_state ;   
reg     [9:0]   cnt_clk     ;   
reg             cnt_clk_rst ;   


assign  wr_end = (write_state == WR_END) ? 1'b1 : 1'b0;

//wr_ack:写SDRAM响应信号
assign  wr_ack = ( write_state == WR_WRITE)
                || ((write_state == WR_DATA) 
                && (cnt_clk <= (wr_burst_len - 2'd2)));

//cnt_clk:时钟周期计数,记录初始化各状态等待时间
always@(posedge sys_clk or negedge sys_rst_n)
    if(sys_rst_n == 1'b0)
        cnt_clk <=  10'd0;
    else    if(cnt_clk_rst == 1'b1)
        cnt_clk <=  10'd0;
    else
        cnt_clk <=  cnt_clk + 1'b1;

//trcd_end,twrite_end,trp_end:等待结束标志
assign  trcd_end    =   ((write_state == WR_TRCD)
                        &&(cnt_clk == TRCD_CLK        )) ? 1'b1 : 1'b0;    //激活周期结束
assign  twrite_end  =   ((write_state == WR_DATA)
                        &&(cnt_clk == wr_burst_len - 1)) ? 1'b1 : 1'b0;    //突发写结束
assign  trp_end     =   ((write_state == WR_TRP )
                        &&(cnt_clk == TRP_CLK         )) ? 1'b1 : 1'b0;    //预充电等待周期结束

//write_state:SDRAM的工作状态机
always@(posedge sys_clk or negedge sys_rst_n)
    if(sys_rst_n == 1'b0)
            write_state <=  WR_IDLE;
    else
        case(write_state)
            WR_IDLE:
                if((wr_en ==1'b1) && (init_end == 1'b1))
                        write_state <=  WR_ACTIVE;
                else
                        write_state <=  write_state;
            WR_ACTIVE:
                write_state <=  WR_TRCD;
            WR_TRCD:
                if(trcd_end == 1'b1)
                    write_state <=  WR_WRITE;
                else
                    write_state <=  write_state;
            WR_WRITE:
                write_state <=  WR_DATA;
            WR_DATA:
                if(twrite_end == 1'b1)
                    write_state <=  WR_PRE;
                else
                    write_state <=  write_state;
            WR_PRE:
                write_state <=  WR_TRP;
            WR_TRP:
                if(trp_end == 1'b1)
                    write_state <=  WR_END;
                else
                    write_state <=  write_state;

            WR_END:
                write_state <=  WR_IDLE;
            default:
                write_state <=  WR_IDLE;
        endcase

//计数器控制逻辑
always@(*)
    begin
        case(write_state)
            WR_IDLE:    cnt_clk_rst   <=  1'b1;
            WR_TRCD:    cnt_clk_rst   <=  (trcd_end == 1'b1) ? 1'b1 : 1'b0;
            WR_WRITE:   cnt_clk_rst   <=  1'b1;
            WR_DATA:    cnt_clk_rst   <=  (twrite_end == 1'b1) ? 1'b1 : 1'b0;
            WR_TRP:     cnt_clk_rst   <=  (trp_end == 1'b1) ? 1'b1 : 1'b0;
            WR_END:     cnt_clk_rst   <=  1'b1;
            default:    cnt_clk_rst   <=  1'b0;
        endcase
    end

//SDRAM操作指令控制
always@(posedge sys_clk or negedge sys_rst_n)
    if(sys_rst_n == 1'b0)
        begin
            write_cmd   <=  NOP;
            write_ba    <=  2'b11;
            write_addr  <=  11'h7ff;
        end
    else
        case(write_state)
            WR_IDLE,WR_TRCD,WR_TRP:
                begin
                    write_cmd   <=  NOP;
                    write_ba    <=  2'b11;
                    write_addr  <=  11'h7ff;
                end
            WR_ACTIVE:  //激活指令
                begin
                    write_cmd   <=  ACTIVE;
                    write_ba    <=  wr_addr[20:19];
                    write_addr  <=  wr_addr[18:8];
                end
            WR_WRITE:   //写操作指令
                begin
                    write_cmd   <=  WRITE;
                    write_ba    <=  wr_addr[20:19];
                    write_addr  <=  {3'b000,wr_addr[7:0]};
                end     
            WR_DATA:    //突发传输终止指令
                begin
                    if(twrite_end == 1'b1)
                        write_cmd <=  B_STOP;
                    else
                        begin
                            write_cmd   <=  NOP;
                            write_ba    <=  2'b11;
                            write_addr  <=  11'h7ff;
                        end
                end
            WR_PRE:     //预充电指令
                begin
                    write_cmd   <= P_CHARGE;
                    write_ba    <= wr_addr[20:19];
                    write_addr  <= 11'h400;
                end
            WR_END:
                begin
                    write_cmd   <=  NOP;
                    write_ba    <=  2'b11;
                    write_addr  <=  11'h7ff;
                end
            default:
                begin
                    write_cmd   <=  NOP;
                    write_ba    <=  2'b11;
                    write_addr  <=  11'h7ff;
                end
        endcase

//wr_sdram_en:数据总线输出使能
always@(posedge sys_clk or negedge sys_rst_n)
    if(sys_rst_n == 1'b0)
        wr_sdram_en <=  1'b0;
    else
        wr_sdram_en <=  wr_ack;

//wr_sdram_data:写入SDRAM的数据
assign  wr_sdram_data = (wr_sdram_en == 1'b1) ? wr_data : 32'd0;

endmodule
