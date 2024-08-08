
`timescale 1ps / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: anlgoic
// Author: 	xg 
//////////////////////////////////////////////////////////////////////////////////

/*
// 0x01 : red
// 0x02 : green
// 0x03 : blue
// 0x04 : white
// 0x05 : gray red
// 0x06 : gray green
// 0x07 : gray blue
// 0x08 : gray white
// 0x09 : mosaic
// 0x0A : diagonal gray scan
// 0x0B : grid scan
*/

//-------------------------------------------------------------------------------------------
module hdmi_top(   
		input   		PXLCLK_I	,
        input   		PXLCLK_5X_I	,
		input			RST_I		,
		input [7:0] 	rgb_blue 	,
        input [7:0]		rgb_green	,
        input [7:0]		rgb_red  	,
        input			hsync	 	,
		input			vsync    	,
		input			de   	 	,


		//HDMI
		output			HDMI_CLK_P	,
		output			HDMI_D2_P	,
		output			HDMI_D1_P	,
		output			HDMI_D0_P
		
);


	


	
	
	
hdmi_tx #(.FAMILY("EG4"))	//EF2、EF3、EG4、AL3、PH1
u3_hdmi_tx
(
	.PXLCLK_I(PXLCLK_I),
	.PXLCLK_5X_I(PXLCLK_5X_I),
	.RST_N (RST_I),
	
	//VGA
	.VGA_HS (hsync ),
	.VGA_VS (vsync ),
	.VGA_DE (de ),
	.VGA_RGB({rgb_red[7:0],rgb_green[7:0],rgb_blue[7:0]}),
	
	//HDMI
	.HDMI_CLK_P(HDMI_CLK_P),
	.HDMI_D2_P (HDMI_D2_P ),
	.HDMI_D1_P (HDMI_D1_P ),
	.HDMI_D0_P (HDMI_D0_P )	
		
);
	

endmodule
