`timescale  1ns/1ns

module  sdram_ctrl
(
    input   wire            sys_clk         ,   
    input   wire            sys_rst_n       ,   
	
	output	wire			wr_en			,
	output	wire			rd_en			,
	
//SDRAM写端口
    input   wire            sdram_wr_req    ,   
    input   wire    [20:0]  sdram_wr_addr   ,   
    input   wire    [9:0]   wr_burst_len    ,   
    input   wire    [31:0]  sdram_data_in   ,   
    output  wire            sdram_wr_ack    ,   
//    output	wire			wr_end			
//SDRAM读端口
    input   wire            sdram_rd_req    ,   
    input   wire    [20:0]  sdram_rd_addr   ,   
    input   wire    [9:0]   rd_burst_len    ,   
    output  wire    [31:0]  sdram_data_out  ,   
    output  wire            init_end        ,   
    output  wire            sdram_rd_ack    ,   
//FPGA与SDRAM硬件接口
    output  wire            sdram_cke       ,   
    output  wire            sdram_cs_n      ,   
    output  wire            sdram_ras_n     ,   
    output  wire            sdram_cas_n     ,   
    output  wire            sdram_we_n      ,   
    output  wire    [1:0]   sdram_ba        ,   
    output  wire    [10:0]  sdram_addr      ,   
    inout   wire    [31:0]  sdram_dq        ,   

//去马赛克端口
	output	wire	[23:0]	out_color		,
	output	wire			out_valid		

);


//wire  define
//sdram_init
wire    [3:0]   init_cmd    ;   
wire    [1:0]   init_ba     ;   
wire    [10:0]  init_addr   ;   
//sdram_a_ref
 wire            aref_req    ;  
wire            aref_end    ;   
wire    [3:0]   aref_cmd    ;   
wire    [1:0]   aref_ba     ;   
wire    [10:0]  aref_addr   ;   
wire            aref_en     ;   
//sdram_write
//wire            wr_en       ; 
wire            wr_end      ;   
wire    [3:0]   write_cmd   ;   
wire    [1:0]   write_ba    ;   
wire    [10:0]  write_addr  ;   
wire            wr_sdram_en ;   
wire    [31:0]  wr_sdram_data;  
//sdram_read
//wire            rd_en       ; 
wire            rd_end      ;   
wire    [3:0]   read_cmd    ;   
wire    [1:0]   read_ba     ;   
wire    [10:0]  read_addr   ;   


//白平衡
wire	[7:0]	data_out	;
wire			data_valid	;


sdram_init  sdram_init_inst
(
    .sys_clk    (sys_clk    ),  
    .sys_rst_n  (sys_rst_n  ),  

    .init_cmd   (init_cmd   ),  
    .init_ba    (init_ba    ),  
    .init_addr  (init_addr  ),  
    .init_end   (init_end   )   
);

//------------- sdram_arbit_inst -------------
sdram_arbit sdram_arbit_inst
(
    .sys_clk    (sys_clk        ),  
    .sys_rst_n  (sys_rst_n      ),  
//sdram_init
    .init_cmd   (init_cmd       ),  
    .init_end   (init_end       ),  
    .init_ba    (init_ba        ),  
    .init_addr  (init_addr      ),  
//sdram_auto_ref
     .aref_req   (aref_req       ), 
    .aref_end   (aref_end       ),  
    .aref_cmd   (aref_cmd       ),  
    .aref_ba    (aref_ba        ),  
    .aref_addr  (aref_addr      ),  
//sdram_write
    .wr_req     (sdram_wr_req   ),  
    .wr_end     (wr_end         ),  
    .wr_cmd     (write_cmd      ),  
    .wr_ba      (write_ba       ),  
    .wr_addr    (write_addr     ),  
    .wr_sdram_en(wr_sdram_en    ),  
    .wr_data    (wr_sdram_data  ),  
//sdram_read
    .rd_req     (sdram_rd_req   ),  
    .rd_end     (rd_end         ),  
    .rd_cmd     (read_cmd       ),  
    .rd_addr    (read_addr      ),  
    .rd_ba      (read_ba        ),  

     .aref_en    (aref_en        ), 
    .wr_en      (wr_en          ),  
    .rd_en      (rd_en          ),  

    .sdram_cke  (sdram_cke      ),  
    .sdram_cs_n (sdram_cs_n     ),  
    .sdram_ras_n(sdram_ras_n    ),  
    .sdram_cas_n(sdram_cas_n    ),  
    .sdram_we_n (sdram_we_n     ),  
    .sdram_ba   (sdram_ba       ),  
    .sdram_addr (sdram_addr     ),  
    .sdram_dq   (sdram_dq       )   
);

//------------- sdram_a_ref_inst ---
  sdram_a_ref sdram_a_ref_inst
(
    .sys_clk     (sys_clk   ), 
    .sys_rst_n   (sys_rst_n ), 
    .init_end    (init_end  ), 
    .aref_en     (aref_en   ), 

    .aref_req    (aref_req  ), 
    .aref_cmd    (aref_cmd  ), 
    .aref_ba     (aref_ba   ), 
    .aref_addr   (aref_addr ), 
    .aref_end    (aref_end  )  
);  

//------------- sdram_write_inst -------------
sdram_write sdram_write_inst
(
    .sys_clk        (sys_clk        ),  
    .sys_rst_n      (sys_rst_n      ),  
    .init_end       (init_end       ),  
    .wr_en          (wr_en          ),  

    .wr_addr        (sdram_wr_addr  ),  
    .wr_data        (sdram_data_in  ),  
    .wr_burst_len   (wr_burst_len   ),  

    .wr_ack         (sdram_wr_ack   ),  
    .wr_end         (wr_end         ),  
    .write_cmd      (write_cmd      ),  
    .write_ba       (write_ba       ),  
    .write_addr     (write_addr     ),  
    .wr_sdram_en    (wr_sdram_en    ),  
    .wr_sdram_data  (wr_sdram_data  )   
);

//------------- sdram_read_inst -------------
sdram_read  sdram_read_inst
(
    .sys_clk        (sys_clk        ),  
    .sys_rst_n      (sys_rst_n      ),  
    .init_end       (init_end       ),  
    .rd_en          (rd_en          ),  

    .rd_addr        (sdram_rd_addr  ),  
    .rd_data        (sdram_dq       ),  
    .rd_burst_len   (rd_burst_len   ),  

    .rd_ack         (sdram_rd_ack   ),  
    .rd_end         (rd_end         ),  
    .read_cmd       (read_cmd       ),  
    .read_ba        (read_ba        ),  
    .read_addr      (read_addr      ),  
    .rd_sdram_data  (sdram_data_out )   
);

//去码
 isp_demosaic2 
#(
	.BITS			(8					),
	.WIDTH			(1920				),
	.HEIGHT			(1080				)
)
u_isp_demosaic	
(	
	.pclk			(sys_clk			),
    .rst_n			(sys_rst_n			),
	.data_valid		(data_valid		),
	.in_raw			(data_out),
	
	.out_valid		(out_valid			),
	.out_color		(out_color			) 
	
);  


//白平衡
  isp_awb_lastest
#(
	.BITS			(8					),
	.WIDTH			(1920				),
	.HEIGHT			(1080				)
)
u_isp_awb	
(	
	.pclk			(sys_clk			),//input
    .rst_n			(sys_rst_n			),//input
	.data_valid		(sdram_rd_ack		),//input
	.in_raw			(sdram_data_out[15:8]),//input[7:0]

	.data_valid_3	(data_valid			),//output
	.out_raw_2		(data_out			) //output[7:0]

); 

endmodule

