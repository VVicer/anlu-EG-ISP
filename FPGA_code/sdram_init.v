`timescale  1ns/1ns


module  sdram_init
(
    input   wire            sys_clk     ,   
    input   wire            sys_rst_n   ,   

    output  reg     [3:0]   init_cmd    ,   
    output  reg     [1:0]   init_ba     ,   
    output  reg     [10:0]  init_addr   ,   
                                            
    output  wire            init_end        
);


// parameter    define
parameter   T_POWER     =   16'd20_000  ;  
//SDRAM初始化用到的控制信号命令
parameter   P_CHARGE    =   4'b0010     ,  
            AUTO_REF    =   4'b0001     ,  
            NOP         =   4'b0111     ,  
            M_REG_SET   =   4'b0000     ;  
//SDRAM初始化过程各个状态
parameter   INIT_IDLE   =   3'b000      ,  
            INIT_PRE    =   3'b001      ,  
            INIT_TRP    =   3'b011      ,  
            INIT_AR     =   3'b010      ,  
            INIT_TRF    =   3'b100      ,  
            INIT_MRS    =   3'b101      ,  
            INIT_TMRD   =   3'b111      ,  
            INIT_END    =   3'b110      ;  
parameter   TRP_CLK     =   3'd2        ,  
            TRC_CLK     =   3'd7        ,  
            TMRD_CLK    =   3'd3        ;  

// wire define
wire            wait_end        ;   
wire            trp_end         ;   
wire            trc_end         ;   
wire            tmrd_end        ;   

// reg  define
reg     [15:0]  cnt_200us       ;   
reg     [2:0]   init_state      ;   
reg     [2:0]   cnt_clk         ;   
reg             cnt_clk_rst     ;   
reg     [3:0]   cnt_init_aref   ;   

//cnt_200us:SDRAM上电后200us稳定期计数器
always@(posedge sys_clk or negedge sys_rst_n)
    if(sys_rst_n == 1'b0)
        cnt_200us   <=  16'd0;
    else    if(cnt_200us == T_POWER)
        cnt_200us   <=  T_POWER;
    else
        cnt_200us   <=  cnt_200us + 1'b1;

//wait_end:上电后200us等待结束标志
assign  wait_end = (cnt_200us == (T_POWER - 1'b1)) ? 1'b1 : 1'b0;

//init_end:SDRAM初始化完毕信号
assign  init_end = (init_state == INIT_END) ? 1'b1 : 1'b0;

//cnt_clk:时钟周期计数,记录初始化各状态等待时间
always@(posedge sys_clk or negedge sys_rst_n)
    if(sys_rst_n == 1'b0)
        cnt_clk <=  3'd0;
    else    if(cnt_clk_rst == 1'b1)
        cnt_clk <=  3'd0;
    else
        cnt_clk <=  cnt_clk + 1'b1;

//cnt_init_aref:初始化过程自动刷新次数计数器
always@(posedge sys_clk or negedge sys_rst_n)
    if(sys_rst_n == 1'b0)
        cnt_init_aref   <=  4'd0;
    else    if(init_state == INIT_IDLE)
        cnt_init_aref   <=  4'd0;
    else    if(init_state == INIT_AR)
        cnt_init_aref   <=  cnt_init_aref + 1'b1;
    else
        cnt_init_aref   <=  cnt_init_aref;

//trp_end,trc_end,tmrd_end:等待结束标志
assign  trp_end     =   ((init_state == INIT_TRP )
                        && (cnt_clk == TRP_CLK )) ? 1'b1 : 1'b0;
assign  trc_end     =   ((init_state == INIT_TRF )
                        && (cnt_clk == TRC_CLK )) ? 1'b1 : 1'b0;
assign  tmrd_end    =   ((init_state == INIT_TMRD)
                        && (cnt_clk == TMRD_CLK)) ? 1'b1 : 1'b0;

//SDRAM的初始化状态机
always@(posedge sys_clk or negedge sys_rst_n)
    if(sys_rst_n == 1'b0)
        init_state  <=  INIT_IDLE;
    else
        case(init_state)
            INIT_IDLE:  //系统上电后,在初始状态等待200us跳转到预充电状态
                if(wait_end == 1'b1)
                    init_state  <=  INIT_PRE;
                else
                    init_state  <=  init_state;
            INIT_PRE:   //预充电状态，直接跳转到预充电等待状态
                init_state  <=  INIT_TRP;
            INIT_TRP:   //预充电等待状态,等待结束,跳转到自动刷新状态
                if(trp_end == 1'b1)
                    init_state  <=  INIT_AR;
                else
                    init_state  <=  init_state;
            INIT_AR :   //自动刷新状态,直接跳转到自动刷新等待状态
                init_state  <=  INIT_TRF;
            INIT_TRF:   //自动刷新等待状态,等待结束,自动跳转到模式寄存器设置状态
                if(trc_end == 1'b1)
                    if(cnt_init_aref == 4'd8)
                        init_state  <=  INIT_MRS;
                    else
                        init_state  <=  INIT_AR;
                else
                    init_state  <=  init_state;
            INIT_MRS:   //模式寄存器设置状态,直接跳转到模式寄存器设置等待状态
                init_state  <=  INIT_TMRD;
            INIT_TMRD:  //模式寄存器设置等待状态,等待结束,跳到初始化完成状态
                if(tmrd_end == 1'b1)
                    init_state  <=  INIT_END;
                else
                    init_state  <=  init_state;
            INIT_END:   //初始化完成状态,保持此状态
                init_state  <=  INIT_END;
            default:    init_state  <=  INIT_IDLE;
        endcase

//cnt_clk_rst:时钟周期计数复位标志
always@(*)
    begin
        case (init_state)
            INIT_IDLE:  cnt_clk_rst <=  1'b1;   //时钟周期计数复位信号,高有效,时钟周期计数清零
            INIT_TRP:   cnt_clk_rst <= (trp_end == 1'b1) ? 1'b1 : 1'b0;
                                                //等待结束标志有效,计数器清零
            INIT_TRF:   cnt_clk_rst <=  (trc_end == 1'b1) ? 1'b1 : 1'b0; 
                                                //等待结束标志有效,计数器清零
            INIT_TMRD:  cnt_clk_rst <=  (tmrd_end == 1'b1) ? 1'b1 : 1'b0;
                                                //等待结束标志有效,计数器清零
            INIT_END:   cnt_clk_rst <=  1'b1;   //初始化完成,计数器清零
            default:    cnt_clk_rst <=  1'b0;
        endcase
    end

//SDRAM操作指令控制
always@(posedge sys_clk or negedge sys_rst_n)
    if(sys_rst_n == 1'b0)
        begin
            init_cmd    <=  NOP;
            init_ba     <=  2'b11;
            init_addr   <=  11'h7ff;
        end
    else
        case(init_state)
            INIT_IDLE,INIT_TRP,INIT_TRF,INIT_TMRD:  //执行空操作指令
                begin
                    init_cmd    <=  NOP;
                    init_ba     <=  2'b11;
                    init_addr   <=  11'h7ff;
                end
            INIT_PRE:   //预充电指令
                begin
                    init_cmd    <=  P_CHARGE;
                    init_ba     <=  2'b11;
                    init_addr   <=  11'h7ff;
                end 
            INIT_AR:    //自动刷新指令
                begin
                    init_cmd    <=  AUTO_REF;
                    init_ba     <=  2'b11;
                    init_addr   <=  11'h7ff;
                end
            INIT_MRS:   //模式寄存器设置指令
                begin
                    init_cmd    <=  M_REG_SET;
                    init_ba     <=  2'b00;
                    init_addr   <=
                    {    //地址辅助配置模式寄存器,参数不同,配置的模式不同
                        1'b0,     //A12-A10:预留
                        1'b0,       //A9=0:读写方式,0:突发读&突发写,1:突发读&单写
                        2'b00,      //{A8,A7}=00:标准模式,默认
                        3'b011,     //{A6,A5,A4}=011:CAS潜伏期,010:2,011:3,其他:保留
                        1'b0,       //A3=0:突发传输方式,0:顺序,1:隔行
                        3'b111      //{A2,A1,A0}=111:突发长度,000:单字节,001:2字节
                                    //010:4字节,011:8字节,111:整页,其他:保留
                    };
                end 
            INIT_END:   //SDRAM初始化完成
                begin
                    init_cmd    <=  NOP;
                    init_ba     <=  2'b11;
                    init_addr   <=  11'h7ff;
                end
            default:
                begin
                    init_cmd    <=  NOP;
                    init_ba     <=  2'b11;
                    init_addr   <=  11'h7ff;
                end    
        endcase

endmodule
