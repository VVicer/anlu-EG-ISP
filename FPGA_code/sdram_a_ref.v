`timescale  1ns/1ns


module  sdram_a_ref
(
    input   wire            sys_clk     ,   
    input   wire            sys_rst_n   ,   
    input   wire            init_end    ,   
    input   wire            aref_en     ,   

    output  reg             aref_req    ,   
    output  reg     [3:0]   aref_cmd    ,   
    output  reg     [1:0]   aref_ba     ,   
    output  reg     [10:0]  aref_addr   ,   
    output  wire            aref_end        
);


//parameter     define
parameter   CNT_REF_MAX =   11'd1875     ;  
parameter   TRP_CLK     =   3'd2        ,   
            TRC_CLK     =   3'd7        ;   
parameter   P_CHARGE    =   4'b0010     ,   
            A_REF       =   4'b0001     ,   
            NOP         =   4'b0111     ;   
parameter   AREF_IDLE   =   3'b000      ,   
            AREF_PCHA   =   3'b001      ,   
            AREF_TRP    =   3'b011      ,   
            AUTO_REF    =   3'b010      ,   
            AREF_TRF    =   3'b100      ,   
            AREF_END    =   3'b101      ;   

//wire  define
wire            trp_end     ;   
wire            trc_end     ;   
wire            aref_ack    ;   

//reg   define
reg     [10:0]   cnt_aref        ;  
reg     [2:0]   aref_state      ;   
reg     [2:0]   cnt_clk         ;   
reg             cnt_clk_rst     ;   
reg     [1:0]   cnt_aref_aref   ;   


//cnt_ref:刷新计数器
always@(posedge sys_clk or negedge sys_rst_n)
    if(sys_rst_n == 1'b0)
        cnt_aref    <=  11'd0;
    else    if(cnt_aref >= CNT_REF_MAX)
        cnt_aref    <=  11'd0;
    else    if(init_end == 1'b1)
        cnt_aref    <=  cnt_aref + 1'b1;

//aref_req:自动刷新请求
always@(posedge sys_clk or negedge sys_rst_n)
    if(sys_rst_n == 1'b0)
        aref_req    <=  1'b0;
    else    if(cnt_aref == (CNT_REF_MAX - 1'b1))
        aref_req    <=  1'b1;
    else    if(aref_ack == 1'b1)
        aref_req    <=  1'b0;

//aref_ack:自动刷新应答信号
assign  aref_ack = (aref_state == AREF_PCHA ) ? 1'b1 : 1'b0;

//aref_end:自动刷新结束标志
assign  aref_end = (aref_state == AREF_END  ) ? 1'b1 : 1'b0;

//cnt_clk:时钟周期计数,记录初始化各状态等待时间
always@(posedge sys_clk or negedge sys_rst_n)
    if(sys_rst_n == 1'b0)
        cnt_clk <=  3'd0;
    else    if(cnt_clk_rst == 1'b1)
        cnt_clk <=  3'd0;
    else
        cnt_clk <=  cnt_clk + 1'b1;

//trp_end,trc_end,tmrd_end:等待结束标志
assign  trp_end = ((aref_state == AREF_TRP)
                    && (cnt_clk == TRP_CLK )) ? 1'b1 : 1'b0;
assign  trc_end = ((aref_state == AREF_TRF)
                    && (cnt_clk == TRC_CLK )) ? 1'b1 : 1'b0;

//cnt_aref_aref:初始化过程自动刷新次数计数器
always@(posedge sys_clk or negedge sys_rst_n)
    if(sys_rst_n == 1'b0)
        cnt_aref_aref   <=  2'd0;
    else    if(aref_state == AREF_IDLE)
        cnt_aref_aref   <=  2'd0;
    else    if(aref_state == AUTO_REF)
        cnt_aref_aref   <=  cnt_aref_aref + 1'b1;
    else
        cnt_aref_aref   <=  cnt_aref_aref;

//SDRAM自动刷新状态机
always@(posedge sys_clk or negedge sys_rst_n)
    if(sys_rst_n == 1'b0)
        aref_state  <=  AREF_IDLE;
    else
        case(aref_state)
            AREF_IDLE:
                if((aref_en == 1'b1) && (init_end == 1'b1))
                    aref_state  <=  AREF_PCHA;
                else
                    aref_state  <=  aref_state;
            AREF_PCHA:
                aref_state  <=  AREF_TRP;
            AREF_TRP:
                if(trp_end == 1'b1)
                    aref_state  <=  AUTO_REF;
                else
                    aref_state  <=  aref_state;
            AUTO_REF:
                aref_state  <=  AREF_TRF;
            AREF_TRF:
                if(trc_end == 1'b1)
                    if(cnt_aref_aref == 2'd2)
                        aref_state  <=  AREF_END;
                    else
                        aref_state  <=  AUTO_REF;
                else
                    aref_state  <=  aref_state;
            AREF_END:
                aref_state  <=  AREF_IDLE;
            default:
                aref_state  <=  AREF_IDLE;
        endcase

//cnt_clk_rst:时钟周期计数复位标志
always@(*)
    begin
        case (aref_state)
            AREF_IDLE:  cnt_clk_rst <=  1'b1;   //时钟周期计数器清零
            AREF_TRP:   cnt_clk_rst <=  (trp_end == 1'b1) ? 1'b1 : 1'b0;
                                                //等待结束标志有效,计数器清零
            AREF_TRF:   cnt_clk_rst <=  (trc_end == 1'b1) ? 1'b1 : 1'b0;
                                                //等待结束标志有效,计数器清零
            AREF_END:   cnt_clk_rst <=  1'b1;
            default:    cnt_clk_rst <=  1'b0;
        endcase
    end

//SDRAM操作指令控制
always@(posedge sys_clk or negedge sys_rst_n)
    if(sys_rst_n == 1'b0)
        begin
            aref_cmd    <=  NOP;
            aref_ba     <=  2'b11;
            aref_addr   <=  11'h7ff;
        end
    else
        case(aref_state)
            AREF_IDLE,AREF_TRP,AREF_TRF:    //执行空操作指令
                begin
                    aref_cmd    <=  NOP;
                    aref_ba     <=  2'b11;
                    aref_addr   <=  11'h7ff;
                end
            AREF_PCHA:  //预充电指令
                begin
                    aref_cmd    <=  P_CHARGE;
                    aref_ba     <=  2'b11;
                    aref_addr   <=  11'h7ff;
                end 
            AUTO_REF:   //自动刷新指令
                begin
                    aref_cmd    <=  A_REF;
                    aref_ba     <=  2'b11;
                    aref_addr   <=  11'h7ff;
                end
            AREF_END:   //一次自动刷新完成
                begin
                    aref_cmd    <=  NOP;
                    aref_ba     <=  2'b11;
                    aref_addr   <=  11'h7ff;
                end    
            default:
                begin
                    aref_cmd    <=  NOP;
                    aref_ba     <=  2'b11;
                    aref_addr   <=  11'h7ff;
                end    
        endcase

endmodule
