`timescale  1ns/1ns


module  sd_init
(
    input   wire    sys_clk         ,   //输入工作时钟,频率50MHz
    input   wire    sys_clk_shift   ,   //输入工作时钟,频率50MHz,相位偏移90度
    input   wire    sys_rst_n       ,   //输入复位信号,低电平有效
    input   wire    miso            ,   //主输入从输出信号

    output  reg     cs_n            ,   //输出片选信号
    output  reg     mosi            ,   //主输出从输入信号
    output  reg     init_end            //初始化完成信号
);

//********************************************************************//
//****************** Parameter and Internal Signal *******************//
//********************************************************************//
//parameter define
parameter   CMD0    =   {8'h40,8'h00,8'h00,8'h00,8'h00,8'h95},  //复位指令
            CMD8    =   {8'h48,8'h00,8'h00,8'h01,8'haa,8'h87},  //查询电压指令
            CMD55   =   {8'h77,8'h00,8'h00,8'h00,8'h00,8'hff},  //应用指令告知指令
            ACMD41  =   {8'h69,8'h40,8'h00,8'h00,8'h00,8'hff};  //应用指令
parameter   CNT_WAIT_MAX    =   8'd100; //上电后同步过程等待时钟计数最大值
parameter   IDLE        =   4'b0000,    //初始状态
            SEND_CMD0   =   4'b0001,    //CMD0发送状态
            CMD0_ACK    =   4'b0011,    //CMD0响应状态
            SEND_CMD8   =   4'b0010,    //CMD8发送状态
            CMD8_ACK    =   4'b0110,    //CMD8响应状态
            SEND_CMD55  =   4'b0111,    //CMD55发送状态
            CMD55_ACK   =   4'b0101,    //CMD55响应状态
            SEND_ACMD41 =   4'b0100,    //ACMD41发送状态
            ACMD41_ACK  =   4'b1100,    //ACMD41响应状态
            INIT_END    =   4'b1101;    //初始化完成状态

//reg   define
reg     [7:0]   cnt_wait        ;   //上电同步时钟计数器
reg     [3:0]   state           ;   //状态机状态
reg     [7:0]   cnt_cmd_bit     ;   //指令比特计数器
reg             miso_dly        ;   //主输入从输出信号打一拍
reg             ack_en          ;   //响应使能信号
reg     [39:0]  ack_data        ;   //响应数据
reg     [7:0]   cnt_ack_bit     ;   //响应数据字节计数

//********************************************************************//
//***************************** Main Code ****************************//
//********************************************************************//
//cnt_wait:上电同步时钟计数器
always@(posedge sys_clk or negedge sys_rst_n)
    if(sys_rst_n == 1'b0)
        cnt_wait    <=  8'd0;
    else    if(cnt_wait >= CNT_WAIT_MAX)
        cnt_wait    <=  CNT_WAIT_MAX;
    else
        cnt_wait    <=  cnt_wait + 1'b1;

//state:状态机状态跳转
always@(posedge sys_clk or negedge sys_rst_n)
    if(sys_rst_n == 1'b0)
        state   <=  IDLE;
    else
        case(state)
            IDLE:
                if(cnt_wait == CNT_WAIT_MAX)
                    state   <=  SEND_CMD0;
                else
                    state   <=  state;
            SEND_CMD0:
                if(cnt_cmd_bit == 8'd48)
                    state   <=  CMD0_ACK;
                else
                    state   <=  state;
            CMD0_ACK:
                if(cnt_ack_bit == 8'd48)
                    if(ack_data[39:32] == 8'h01)
                        state   <=  SEND_CMD8;
                    else
                        state   <=  SEND_CMD0;
                else
                    state   <=  state;
            SEND_CMD8:
                if(cnt_cmd_bit == 8'd48)
                    state   <=  CMD8_ACK;
                else
                    state   <=  state;
            CMD8_ACK:
                if(cnt_ack_bit == 8'd48)
                    if(ack_data[11:8] == 4'b0001)
                        state   <=  SEND_CMD55;
                    else
                        state   <=  SEND_CMD8;
                else
                    state   <=  state;
            SEND_CMD55:
                if(cnt_cmd_bit == 8'd48)
                    state   <=  CMD55_ACK;
                else
                    state   <=  state;
            CMD55_ACK:
                if(cnt_ack_bit == 8'd48)
                    if(ack_data[39:32] == 8'h01)
                        state   <=  SEND_ACMD41;
                    else
                        state   <=  SEND_CMD55;
                else
                    state   <=  state;
            SEND_ACMD41:
                if(cnt_cmd_bit == 8'd48)
                    state   <=  ACMD41_ACK;
                else
                    state   <=  state;
            ACMD41_ACK:
                if(cnt_ack_bit == 8'd48)
                    if(ack_data[39:32] == 8'h00)
                        state   <=  INIT_END;
                    else
                        state   <=  SEND_CMD55;
                else
                    state   <=  state;
            INIT_END:
                state   <=  state;
            default:
                state   <=  IDLE;
        endcase

//cs_n,mosi,init_end,cnt_cmd_bit
//片选信号,主输出从输入信号,初始化结束信号,指令比特计数器
always@(posedge sys_clk or negedge sys_rst_n)
    if(sys_rst_n == 1'b0)
        begin
            cs_n            <=  1'b1;
            mosi            <=  1'b1;
            init_end        <=  1'b0;
            cnt_cmd_bit     <=  8'd0;
        end
    else
        case(state)
            IDLE:
                begin
                    cs_n            <=  1'b1;
                    mosi            <=  1'b1;
                    init_end        <=  1'b0;
                    cnt_cmd_bit     <=  8'd0;
                end
            SEND_CMD0:
                if(cnt_cmd_bit == 8'd48)
                    cnt_cmd_bit     <=  8'd0;
                else
                    begin
                        cs_n            <=  1'b0;
                        mosi            <=  CMD0[8'd47 - cnt_cmd_bit];
                        init_end        <=  1'b0;
                        cnt_cmd_bit     <=  cnt_cmd_bit + 8'd1;
                    end
            CMD0_ACK:
                if(cnt_ack_bit == 8'd47)
                    cs_n    <=  1'b1;
                else
                    cs_n    <=  1'b0;
            SEND_CMD8:
                if(cnt_cmd_bit == 8'd48)
                    cnt_cmd_bit     <=  8'd0;
                else
                    begin
                        cs_n            <=  1'b0;
                        mosi            <=  CMD8[8'd47 - cnt_cmd_bit];
                        init_end        <=  1'b0;
                        cnt_cmd_bit     <=  cnt_cmd_bit + 8'd1;
                    end
            CMD8_ACK:
                if(cnt_ack_bit == 8'd47)
                    cs_n    <=  1'b1;
                else
                    cs_n    <=  1'b0;
            SEND_CMD55:
                if(cnt_cmd_bit == 8'd48)
                    cnt_cmd_bit     <=  8'd0;
                else
                    begin
                        cs_n            <=  1'b0;
                        mosi            <=  CMD55[8'd47 - cnt_cmd_bit];
                        init_end        <=  1'b0;
                        cnt_cmd_bit     <=  cnt_cmd_bit + 8'd1;
                    end
            CMD55_ACK:
                if(cnt_ack_bit == 8'd47)
                    cs_n    <=  1'b1;
                else
                    cs_n    <=  1'b0;
            SEND_ACMD41:
                if(cnt_cmd_bit == 8'd48)
                    cnt_cmd_bit     <=  8'd0;
                else
                    begin
                        cs_n            <=  1'b0;
                        mosi            <=  ACMD41[8'd47 - cnt_cmd_bit];
                        init_end        <=  1'b0;
                        cnt_cmd_bit     <=  cnt_cmd_bit + 8'd1;
                    end
            ACMD41_ACK:
                if(cnt_ack_bit < 8'd47)
                    cs_n    <=  1'b0;
                else
                    cs_n    <=  1'b1;
            INIT_END:
                begin
                    cs_n        <=  1'b1;
                    mosi        <=  1'b1;
                    init_end    <=  1'b1;
                end
            default:
                begin
                    cs_n    <=  1'b1;
                    mosi    <=  1'b1;
                end
        endcase

//miso_dly:主输入从输出信号打一拍
always@(posedge sys_clk_shift or negedge sys_rst_n)
    if(sys_rst_n == 1'b0)
        miso_dly    <=  1'b0;
    else
        miso_dly    <=  miso;

//ack_en:响应使能信号
always@(posedge sys_clk_shift or negedge sys_rst_n)
    if(sys_rst_n == 1'b0)
        ack_en  <=  1'b0;
    else    if(cnt_ack_bit == 8'd47)
        ack_en  <=  1'b0;
    else    if((miso == 1'b0) && (miso_dly == 1'b1) && (cnt_ack_bit == 8'd0))
        ack_en  <=  1'b1;
    else
        ack_en  <=  ack_en;

//ack_data:响应数据
//cnt_ack_bit:响应数据字节计数
always@(posedge sys_clk_shift or negedge sys_rst_n)
    if(sys_rst_n == 1'b0)
        begin
            ack_data    <=  8'b0;
            cnt_ack_bit <=  8'd0;
        end
    else    if(ack_en == 1'b1)
        begin
            cnt_ack_bit     <=  cnt_ack_bit + 8'd1;
            if(cnt_ack_bit < 8'd40)
                ack_data    <=  {ack_data[38:0],miso_dly};
            else
                ack_data    <=  ack_data;
        end
    else
        cnt_ack_bit <=  8'd0;

endmodule
