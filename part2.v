// Part 2 skeleton

module part2
	(
		CLOCK_50,						//	On Board 50 MHz
		// Your inputs and outputs here
        KEY,
        SW,
		  LEDR,
		// The ports below are for the VGA output.  Do not change.
		VGA_CLK,   						//	VGA Clock
		VGA_HS,							//	VGA H_SYNC
		VGA_VS,							//2q3	VGA V_SYNC
		VGA_BLANK_N,						//	VGA BLANK
		VGA_SYNC_N,						//	VGA SYNC
		VGA_R,   						//	VGA Red[9:0]
		VGA_G,	 						//	VGA Green[9:0]
		VGA_B   						//	VGA Blue[9:0]
	);

	input			CLOCK_50;				//	50 MHz
	input   [9:0]   SW;
	input   [3:0]   KEY;
	output  [3:0] 	LEDR;

	// Declare your inputs and outputs here
	// Do not change the following outputs
	output			VGA_CLK;   				//	VGA Clock
	output			VGA_HS;					//	VGA H_SYNC
	output			VGA_VS;					//	VGA V_SYNC
	output			VGA_BLANK_N;				//	VGA BLANK
	output			VGA_SYNC_N;				//	VGA SYNC
	output	[9:0]	VGA_R;   				//	VGA Red[9:0]
	output	[9:0]	VGA_G;	 				//	VGA Green[9:0]
	output	[9:0]	VGA_B;   				//	VGA Blue[9:0]

	wire resetn;
	assign resetn = KEY[2];

	// Create the colour, x, y and writeEn wires that are inputs to the controller.
	wire [2:0] colour;
	wire [7:0] x;
	wire [6:0] y;
	wire writeEn;
	assign colour = SW[9:7];
	assign writeEn = KEY[3];
	wire ld_x, ld_y, ld_r;
	assign LEDR[1] = ld_y;
	assign LEDR[2] = ld_r;
	wire [6:0] out_x, out_y;
	wire [2:0] out_colour;
	wire go, go_swap;


	// Create an Instance of a VGA controller - there can be only one!
	// Define the number of colours as well as the initial background
	// image file (.MIF) for the controller.
	vga_adapter VGA(
			.resetn(resetn),
			.clock(CLOCK_50),
			.colour(out_colour),
			.x(out_x),
			.y(out_y),
			.plot(writeEn),
			/* Signals for the DAC to drive the monitor. */
			.VGA_R(VGA_R),
			.VGA_G(VGA_G),
			.VGA_B(VGA_B),
			.VGA_HS(VGA_HS),
			.VGA_VS(VGA_VS),
			.VGA_BLANK(VGA_BLANK_N),
			.VGA_SYNC(VGA_SYNC_N),
			.VGA_CLK(VGA_CLK));
		defparam VGA.RESOLUTION = "160x120";
		defparam VGA.MONOCHROME = "FALSE";
		defparam VGA.BITS_PER_COLOUR_CHANNEL = 1;
		defparam VGA.BACKGROUND_IMAGE = "black.mif";



	// Put your code here. Your code should produce signals x,y,colour and writeEn/plot
	// for the VGA controller, in addition to any other functionality your design may require.
	wire [17:0] row_l_1, row_l_2, row_l_3, row_l_4, row_l_5, row_l_6;
	wire [17:0] row_r_1, row_r_2, row_r_3, row_r_4, row_r_5, row_r_6;

	// Destination grid, grid that we want the user to match
	// The row is stored such that it goes from least significant to most significant.. 
	// 4, 5, 1, 4, 5, 4
	assign row_r_1 = 18'b100101100001101100;
	// 3, 2, 5, 2, 0, 0
	assign row_r_2 = 18'b000000010101010011;
	// 5, 1, 2, 5, 2, 0
	assign row_r_3 = 18'b000010101010001101;
	// 0, 5, 1, 2, 5, 2
	assign row_r_4 = 18'b010101010001101000;
	// 0, 0, 5, 1, 2, 5
	assign row_r_5 = 18'b101010001101000000;
	// 3, 2, 3, 1, 1, 2
	assign row_r_6 = 18'b010001001011010011;
	
	// current coordinates
	wire [3:0] c_x, c_y;
	
	wire [2:0] sel_pipe, inv_pipe;
	
	// move and swap keys
	assign go = ~KEY[0];
	assign go_swap = ~KEY[1];
	reg victory;
	
	// Determine whether the current state is a victory state.
	always@(*)
	begin
		victory = ((row_l_1 == row_r_1) && (row_l_2 == row_r_2) && (row_l_3 == row_r_3) && (row_l_4 == row_r_4) && (row_l_5 == row_r_5) && (row_l_6 == row_r_6));
	end
	
	assign LEDR[0] = victory;
	
	// module to control pipe movement.
	move m(
		.clk(CLOCK_50),
		.out_x(c_x),
		.out_y(c_y),
		.SW(SW[3:0]),
		.adv(go),
		.swap(go_swap),
		.selected_pipe(sel_pipe),
		.inventory_pipe(inv_pipe),
		.r0(row_l_1),
		.r1(row_l_2),
		.r2(row_l_3),
		.r3(row_l_4),
		.r4(row_l_5),
		.r5(row_l_6)
	);

	// module to control UI generation.
	control_ui c_ui(
		.clk(CLOCK_50),
		.out_x(out_x),
		.out_y(out_y),
		.out_colour(out_colour),
		.sel_x(c_x),
		.sel_y(c_y),
		.row_i_1(row_r_1),
		.row_i_2(row_r_2),
		.row_i_3(row_r_3),
		.row_i_4(row_r_4),
		.row_i_5(row_r_5),
		.row_i_6(row_r_6),
		.row1(row_l_1),
		.row2(row_l_2),
		.row3(row_l_3),
		.row4(row_l_4),
		.row5(row_l_5),
		.row6(row_l_6),
		.i_p(inv_pipe)
   );
endmodule


module control_ui(
	input clk,
	output reg [7:0] out_x,
	output reg [6:0] out_y,
	output reg [3:0] out_colour,
	input [7:0] sel_x,
	input [6:0] sel_y,
	input [17:0] row_i_1, row_i_2, row_i_3, row_i_4, row_i_5, row_i_6,
	input [17:0] row1, row2, row3, row4, row5, row6,
	input [2:0] i_p
    );

    // 7 bits to hold states, can have 128 states.
    reg [6:0] current_state, next_state;

    localparam  LOAD_SQ_0        = 7'd0,  // White UI Background
                LOAD_SQ_1        = 7'd1,  // Red border for grid
		LOAD_SQ_2        = 7'd2,  // Black background for grid
		LOAD_SQ_3        = 7'd3,  // First row of squares on grid (states S3-S8)
		LOAD_SQ_4        = 7'd4,
		LOAD_SQ_5        = 7'd5,
		LOAD_SQ_6        = 7'd6,
		LOAD_SQ_7        = 7'd7,
		LOAD_SQ_8        = 7'd8,
		LOAD_SQ_9        = 7'd9,  // Second row of squares on grid (states S9-S14)
		LOAD_SQ_10       = 7'd10,
		LOAD_SQ_11       = 7'd11,
		LOAD_SQ_12       = 7'd12,
		LOAD_SQ_13       = 7'd13,
		LOAD_SQ_14       = 7'd14,
		LOAD_SQ_15       = 7'd15, // Third row of squares on grid (states S15-S20)
		LOAD_SQ_16       = 7'd16,
		LOAD_SQ_17       = 7'd17,
		LOAD_SQ_18       = 7'd18,
		LOAD_SQ_19       = 7'd19,
		LOAD_SQ_20       = 7'd20,
		LOAD_SQ_21       = 7'd21, // Fourth row of squares on grid (states S21-S26)
		LOAD_SQ_22       = 7'd22,
		LOAD_SQ_23       = 7'd23,
		LOAD_SQ_24       = 7'd24,
		LOAD_SQ_25       = 7'd25,
		LOAD_SQ_26       = 7'd26,
		LOAD_SQ_27       = 7'd27, // Fifth row of squares on grid (states S27-S32)
		LOAD_SQ_28       = 7'd28,
		LOAD_SQ_29       = 7'd29,
		LOAD_SQ_30       = 7'd30,
		LOAD_SQ_31       = 7'd31,
		LOAD_SQ_32       = 7'd32,
		LOAD_SQ_33       = 7'd33, // Sixth row of squares on grid (states S33-S38)
		LOAD_SQ_34       = 7'd34,
		LOAD_SQ_35       = 7'd35,
		LOAD_SQ_36       = 7'd36,
		LOAD_SQ_37       = 7'd37,
		LOAD_SQ_38       = 7'd38,
		LOAD_SQ_39       = 7'd39, // Second grid First row of squares on grid (states S39-S44)
		LOAD_SQ_40       = 7'd40,
		LOAD_SQ_41       = 7'd41,
		LOAD_SQ_42       = 7'd42,
		LOAD_SQ_43       = 7'd43,
		LOAD_SQ_44       = 7'd44,
		LOAD_SQ_45       = 7'd45, // Second row of squares on grid (states S45-S50)
		LOAD_SQ_46       = 7'd46,
		LOAD_SQ_47       = 7'd47,
		LOAD_SQ_48       = 7'd48,
		LOAD_SQ_49       = 7'd49,
		LOAD_SQ_50       = 7'd50,
		LOAD_SQ_51       = 7'd51, // Third row of squares on grid (states S51-S56)
		LOAD_SQ_52       = 7'd52,
		LOAD_SQ_53       = 7'd53,
		LOAD_SQ_54       = 7'd54,
		LOAD_SQ_55       = 7'd55,
		LOAD_SQ_56       = 7'd56,
		LOAD_SQ_57       = 7'd57, // Fourth row of squares on grid (states S57-S62)
		LOAD_SQ_58       = 7'd58,
		LOAD_SQ_59       = 7'd59,
		LOAD_SQ_60       = 7'd60,
		LOAD_SQ_61       = 7'd61,
		LOAD_SQ_62       = 7'd62,
		LOAD_SQ_63       = 7'd63, // Fifth row of squares on grid (states S63-S68)
		LOAD_SQ_64       = 7'd64,
		LOAD_SQ_65       = 7'd65,
		LOAD_SQ_66       = 7'd66,
		LOAD_SQ_67       = 7'd67,
		LOAD_SQ_68       = 7'd68,
		LOAD_SQ_69       = 7'd69, // Sixth row of squares on grid (states S69-S74 )
		LOAD_SQ_70       = 7'd70,
		LOAD_SQ_71       = 7'd71,
		LOAD_SQ_72       = 7'd72,
		LOAD_SQ_73       = 7'd73,
		LOAD_SQ_74       = 7'd74,
		LOAD_SQ_75       = 7'd75,
		LOAD_SQ_76       = 7'd76,
		LOAD_SQ_77       = 7'd77,

		/*
		LOAD_SQ_39       = 7'd39, // pipe select border+box
		LOAD_SQ_40       = 7'd40,
		LOAD_BD_1		  = 7'd41,
		*/
		DEAD		 = 7'd127;

	// holds (x, y) coordinates for specific objects to draw.
	wire [7:0] out_x0, out_x1, out_x2;
	wire [7:0] out_x3, out_x4, out_x5, out_x6, out_x7, out_x8;		// First row of squares on FIRST grid.
	wire [7:0] out_x9, out_x10, out_x11, out_x12, out_x13, out_x14;		// Second row of squares on grid.
	wire [7:0] out_x15, out_x16, out_x17, out_x18, out_x19, out_x20;	// Third row of squares on grid.
	wire [7:0] out_x21, out_x22, out_x23, out_x24, out_x25, out_x26;	// Fourth row of squares on grid.
	wire [7:0] out_x27, out_x28, out_x29, out_x30, out_x31, out_x32;	// Fifth row of squares on grid.
	wire [7:0] out_x33, out_x34, out_x35, out_x36, out_x37, out_x38;	// Sixth row of squares on grid.

	wire [7:0] out_x39, out_x40, out_x41, out_x42, out_x43, out_x44;	// First row of squares on SECOND grid.
	wire [7:0] out_x45, out_x46, out_x47, out_x48, out_x49, out_x50;	// Second row of squares on grid.
	wire [7:0] out_x51, out_x52, out_x53, out_x54, out_x55, out_x56;	// Third row of squares on grid.
	wire [7:0] out_x57, out_x58, out_x59, out_x60, out_x61, out_x62;	// Fourth row of squares on grid.
	wire [7:0] out_x63, out_x64, out_x65, out_x66, out_x67, out_x68;	// Fifth row of squares on grid.
	wire [7:0] out_x69, out_x70, out_x71, out_x72, out_x73, out_x74;	// Sixth row of squares on grid.

	wire [7:0] out_x75; // pipe
	wire [7:0] out_x76; // inventory
	wire [6:0] out_x77; // inventory 

	wire [6:0] out_y0, out_y1, out_y2;
	wire [6:0] out_y3, out_y4, out_y5, out_y6, out_y7, out_y8;		// First row of squares on FIRST grid.
	wire [6:0] out_y9, out_y10, out_y11, out_y12, out_y13, out_y14;		// Second row of squares on grid.
	wire [6:0] out_y15, out_y16, out_y17, out_y18, out_y19, out_y20;	// Third row of squares on grid.
	wire [6:0] out_y21, out_y22, out_y23, out_y24, out_y25, out_y26;	// Fourth row of squares on grid.
	wire [6:0] out_y27, out_y28, out_y29, out_y30, out_y31, out_y32;	// Fifth row of squares on grid.
	wire [6:0] out_y33, out_y34, out_y35, out_y36, out_y37, out_y38;	// Sixth row of squares on grid.

	wire [6:0] out_y39, out_y40, out_y41, out_y42, out_y43, out_y44;	// First row of squares on SECOND grid.
	wire [6:0] out_y45, out_y46, out_y47, out_y48, out_y49, out_y50;	// Second row of squares on grid.
	wire [6:0] out_y51, out_y52, out_y53, out_y54, out_y55, out_y56;	// Third row of squares on grid.
	wire [6:0] out_y57, out_y58, out_y59, out_y60, out_y61, out_y62;	// Fourth row of squares on grid.
	wire [6:0] out_y63, out_y64, out_y65, out_y66, out_y67, out_y68;	// Fifth row of squares on grid.
	wire [6:0] out_y69, out_y70, out_y71, out_y72, out_y73, out_y74;	// Sixth row of squares on grid.

	wire [6:0] out_y75; // pipe
	wire [6:0] out_y76; // inventory 
	wire [6:0] out_y77; // inventory 

	// holds colour of pixel to draw (RGB).
	wire [3:0] out_colour0, out_colour1, out_colour2;
	wire [3:0] out_colour3, out_colour4, out_colour5, out_colour6, out_colour7, out_colour8;	// First row of squares on grid
	wire [3:0] out_colour9, out_colour10, out_colour11, out_colour12, out_colour13, out_colour14;	// Second row of squares on grid
	wire [3:0] out_colour15, out_colour16, out_colour17, out_colour18, out_colour19, out_colour20;	// Third row of squares on grid
	wire [3:0] out_colour21, out_colour22, out_colour23, out_colour24, out_colour25, out_colour26;	// Fourth row of squares on grid
	wire [3:0] out_colour27, out_colour28, out_colour29, out_colour30, out_colour31, out_colour32;	// Fifth row of squares on grid
	wire [3:0] out_colour33, out_colour34, out_colour35, out_colour36, out_colour37, out_colour38;	// Sixth row of squares on grid

	wire [3:0] out_colour39, out_colour40, out_colour41, out_colour42, out_colour43, out_colour44;	// First row of squares on SECOND grid.
	wire [3:0] out_colour45, out_colour46, out_colour47, out_colour48, out_colour49, out_colour50;	// Second row of squares on grid.
	wire [3:0] out_colour51, out_colour52, out_colour53, out_colour54, out_colour55, out_colour56;	// Third row of squares on grid.
	wire [3:0] out_colour57, out_colour58, out_colour59, out_colour60, out_colour61, out_colour62;	// Fourth row of squares on grid.
	wire [3:0] out_colour63, out_colour64, out_colour65, out_colour66, out_colour67, out_colour68;	// Fifth row of squares on grid.
	wire [3:0] out_colour69, out_colour70, out_colour71, out_colour72, out_colour73, out_colour74;	// Sixth row of squares on grid.

	wire [3:0] out_colour75; // pipe
	wire [3:0] out_colour76; // inventory color
	wire [3:0] out_colour77; // inventory color

	// Signal for finished drawing.
	wire f0, f1, f2;
	wire f3, f4, f5, f6, f7, f8;		// First row of squares on grid
	wire f9, f10, f11, f12, f13, f14;	// Second row of squares on grid
	wire f15, f16, f17, f18, f19, f20;	// Third row of squares on grid
	wire f21, f22, f23, f24, f25, f26;	// Fourth row of squares on grid
	wire f27, f28, f29, f30, f31, f32;	// Fifth row of squares on grid
	wire f33, f34, f35, f36, f37, f38;	// Sixth row of squares on grid

	wire f39, f40, f41, f42, f43, f44;	// First row of squares on SECOND grid.
	wire f45, f46, f47, f48, f49, f50;	// Second row of squares on grid.
	wire f51, f52, f53, f54, f55, f56;	// Third row of squares on grid.
	wire f57, f58, f59, f60, f61, f62;	// Fourth row of squares on grid.
	wire f63, f64, f65, f66, f67, f68;	// Fifth row of squares on grid.
	wire f69, f70, f71, f72, f73, f74;	// Sixth row of squares on grid.

	wire f75; 	//pipes
	
	wire f76;   // inventory
	wire f77;   // inventory

	// Constants to control colour selection for squares in grid.
	wire [3:0] square_colour;
	assign square_colour = 3'b000;

	// square dimensions for grid
	wire [7:0] square_width;
	wire [6:0] square_height;

	assign square_width = 8'd7;
	assign square_height = 7'd7 + 7'd3;

	// top left dimensions of grid initial square
	wire [7:0] i_x;
	wire [6:0] i_y;

	assign i_x = 8'd3;
	assign i_y = 7'd3;

	// top left dimensions of grid target initial square
	wire [7:0] i_x2;
	wire [6:0] i_y2;

	assign i_x2 = 8'd65;
	assign i_y2 = 7'd3;

	// x and y offset space between grid squares
	wire [7:0] sq_offset_x;
	wire [6:0] sq_offset_y;

	assign sq_offset_x = square_width + 8'd3;
	assign sq_offset_y = square_height + 7'd2; //7'd4;

	// white box variables.
	wire [7:0] white_bg_width;
	wire [6:0] white_bg_height;

	assign white_bg_width = 8'd59;
	assign white_bg_height = 7'd75;


    // Next state logic aka our state table
    always@(*)
    begin: state_table
            case (current_state)
                LOAD_SQ_0: next_state = f0 ? LOAD_SQ_1 : LOAD_SQ_0; 			// White ui background
		LOAD_SQ_1: next_state = f1 ? LOAD_SQ_2 : LOAD_SQ_1;			// Red border for grid
		LOAD_SQ_2: next_state = f2 ? LOAD_SQ_3 : LOAD_SQ_2;			// Black bg for grid
		LOAD_SQ_3: next_state = f3 ? LOAD_SQ_4 : LOAD_SQ_3;			// First row of squares on grid
		LOAD_SQ_4: next_state = f4 ? LOAD_SQ_5 : LOAD_SQ_4;
		LOAD_SQ_5: next_state = f5 ? LOAD_SQ_6 : LOAD_SQ_5;
		LOAD_SQ_6: next_state = f6 ? LOAD_SQ_7 : LOAD_SQ_6;
		LOAD_SQ_7: next_state = f7 ? LOAD_SQ_8 : LOAD_SQ_7;
		LOAD_SQ_8: next_state = f8 ? LOAD_SQ_9 : LOAD_SQ_8;
		LOAD_SQ_9: next_state = f9 ? LOAD_SQ_10 : LOAD_SQ_9;			// Second row of squares on grid
		LOAD_SQ_10: next_state = f10 ? LOAD_SQ_11 : LOAD_SQ_10;
		LOAD_SQ_11: next_state = f11 ? LOAD_SQ_12 : LOAD_SQ_11;
		LOAD_SQ_12: next_state = f12 ? LOAD_SQ_13 : LOAD_SQ_12;
		LOAD_SQ_13: next_state = f13 ? LOAD_SQ_14 : LOAD_SQ_13;
		LOAD_SQ_14: next_state = f14 ? LOAD_SQ_15 : LOAD_SQ_14;
		LOAD_SQ_15: next_state = f15 ? LOAD_SQ_16 : LOAD_SQ_15;			// Third row of squares on grid
		LOAD_SQ_16: next_state = f16 ? LOAD_SQ_17 : LOAD_SQ_16;
		LOAD_SQ_17: next_state = f17 ? LOAD_SQ_18 : LOAD_SQ_17;
		LOAD_SQ_18: next_state = f18 ? LOAD_SQ_19 : LOAD_SQ_18;
		LOAD_SQ_19: next_state = f19 ? LOAD_SQ_20 : LOAD_SQ_19;
		LOAD_SQ_20: next_state = f20 ? LOAD_SQ_21 : LOAD_SQ_20;
		LOAD_SQ_21: next_state = f21 ? LOAD_SQ_22 : LOAD_SQ_21;			// Fourth row of squares on grid
		LOAD_SQ_22: next_state = f22 ? LOAD_SQ_23 : LOAD_SQ_22;
		LOAD_SQ_23: next_state = f23 ? LOAD_SQ_24 : LOAD_SQ_23;
		LOAD_SQ_24: next_state = f24 ? LOAD_SQ_25 : LOAD_SQ_24;
		LOAD_SQ_25: next_state = f25 ? LOAD_SQ_26 : LOAD_SQ_25;
		LOAD_SQ_26: next_state = f26 ? LOAD_SQ_27 : LOAD_SQ_26;
		LOAD_SQ_27: next_state = f27 ? LOAD_SQ_28 : LOAD_SQ_27;			// Fifth row of squares on grid
		LOAD_SQ_28: next_state = f28 ? LOAD_SQ_29 : LOAD_SQ_28;
		LOAD_SQ_29: next_state = f29 ? LOAD_SQ_30 : LOAD_SQ_29;
		LOAD_SQ_30: next_state = f30 ? LOAD_SQ_31 : LOAD_SQ_30;
		LOAD_SQ_31: next_state = f31 ? LOAD_SQ_32 : LOAD_SQ_31;
		LOAD_SQ_32: next_state = f32 ? LOAD_SQ_33 : LOAD_SQ_32;
		LOAD_SQ_33: next_state = f33 ? LOAD_SQ_34 : LOAD_SQ_33;			// Sixth row of squares on grid
		LOAD_SQ_34: next_state = f34 ? LOAD_SQ_35 : LOAD_SQ_34;
		LOAD_SQ_35: next_state = f35 ? LOAD_SQ_36 : LOAD_SQ_35;
		LOAD_SQ_36: next_state = f36 ? LOAD_SQ_37 : LOAD_SQ_36;
		LOAD_SQ_37: next_state = f37 ? LOAD_SQ_38 : LOAD_SQ_37;
		LOAD_SQ_38: next_state = f38 ? LOAD_SQ_76 : LOAD_SQ_38;
		LOAD_SQ_39: next_state = f39 ? LOAD_SQ_40 : LOAD_SQ_39;			// Second grid ---- First row
		LOAD_SQ_40: next_state = f40 ? LOAD_SQ_41 : LOAD_SQ_40;
		LOAD_SQ_41: next_state = f41 ? LOAD_SQ_42 : LOAD_SQ_41;
		LOAD_SQ_42: next_state = f42 ? LOAD_SQ_43 : LOAD_SQ_42;
		LOAD_SQ_43: next_state = f43 ? LOAD_SQ_44 : LOAD_SQ_43;
		LOAD_SQ_44: next_state = f44 ? LOAD_SQ_45 : LOAD_SQ_44;
		LOAD_SQ_45: next_state = f45 ? LOAD_SQ_46 : LOAD_SQ_45;			// Second row of grid
		LOAD_SQ_46: next_state = f46 ? LOAD_SQ_47 : LOAD_SQ_46;
		LOAD_SQ_47: next_state = f47 ? LOAD_SQ_48 : LOAD_SQ_47;
		LOAD_SQ_48: next_state = f48 ? LOAD_SQ_49 : LOAD_SQ_48;
		LOAD_SQ_49: next_state = f49 ? LOAD_SQ_50 : LOAD_SQ_49;
		LOAD_SQ_50: next_state = f50 ? LOAD_SQ_51 : LOAD_SQ_50;
		LOAD_SQ_51: next_state = f51 ? LOAD_SQ_52 : LOAD_SQ_51;			// Third row of grid
		LOAD_SQ_52: next_state = f52 ? LOAD_SQ_53 : LOAD_SQ_52;
		LOAD_SQ_53: next_state = f53 ? LOAD_SQ_54 : LOAD_SQ_53;
		LOAD_SQ_54: next_state = f54 ? LOAD_SQ_55 : LOAD_SQ_54;
		LOAD_SQ_55: next_state = f55 ? LOAD_SQ_56 : LOAD_SQ_55;
		LOAD_SQ_56: next_state = f56 ? LOAD_SQ_57 : LOAD_SQ_56;
		LOAD_SQ_57: next_state = f57 ? LOAD_SQ_58 : LOAD_SQ_57;			// Fourth row of grid
		LOAD_SQ_58: next_state = f58 ? LOAD_SQ_59 : LOAD_SQ_58;
		LOAD_SQ_59: next_state = f59 ? LOAD_SQ_60 : LOAD_SQ_59;
		LOAD_SQ_60: next_state = f60 ? LOAD_SQ_61 : LOAD_SQ_60;
		LOAD_SQ_61: next_state = f61 ? LOAD_SQ_62 : LOAD_SQ_61;
		LOAD_SQ_62: next_state = f62 ? LOAD_SQ_63 : LOAD_SQ_62;
		LOAD_SQ_63: next_state = f63 ? LOAD_SQ_64 : LOAD_SQ_63;			// Fifth row of squares on grid
		LOAD_SQ_64: next_state = f64 ? LOAD_SQ_65 : LOAD_SQ_64;
		LOAD_SQ_65: next_state = f65 ? LOAD_SQ_66 : LOAD_SQ_65;
		LOAD_SQ_66: next_state = f66 ? LOAD_SQ_67 : LOAD_SQ_66;
		LOAD_SQ_67: next_state = f67 ? LOAD_SQ_68 : LOAD_SQ_67;
		LOAD_SQ_68: next_state = f68 ? LOAD_SQ_69 : LOAD_SQ_68;
		LOAD_SQ_69: next_state = f69 ? LOAD_SQ_70 : LOAD_SQ_69;			// Sixth row of squares on grid
		LOAD_SQ_70: next_state = f70 ? LOAD_SQ_71 : LOAD_SQ_70;
		LOAD_SQ_71: next_state = f71 ? LOAD_SQ_72 : LOAD_SQ_71;
		LOAD_SQ_72: next_state = f72 ? LOAD_SQ_73 : LOAD_SQ_72;
		LOAD_SQ_73: next_state = f73 ? LOAD_SQ_74 : LOAD_SQ_73;
		LOAD_SQ_74: next_state = f74 ? LOAD_SQ_75 : LOAD_SQ_74;
		LOAD_SQ_75: next_state = f75 ? LOAD_SQ_77 : LOAD_SQ_75;
		LOAD_SQ_76: next_state = f76 ? LOAD_SQ_39 : LOAD_SQ_76;
		LOAD_SQ_77: next_state = f77 ? LOAD_SQ_39 : LOAD_SQ_77;
		DEAD: next_state = DEAD;
            default:     next_state = LOAD_SQ_0;
        endcase
    end // state_table

	// red border.
	square s0(
		.clk(clk),
		.colour(3'b110),
		.in_x(8'd0),
		.in_y(7'd0),
		.width(8'd159),
		.height(7'd80),
		.go_draw(1'b1),
		.finish_draw(f0),
		.out_x(out_x0),
		.out_y(out_y0),
		.out_colour(out_colour0)
	);

	// white border for grid1.
	square s1(
		.clk(clk),
		.colour(3'b111),
		.in_x(8'd2),
		.in_y(7'd2),
		.width(white_bg_width),
		.height(white_bg_height),
		.go_draw(f0),
		.finish_draw(f1),
		.out_x(out_x1),
		.out_y(out_y1),
		.out_colour(out_colour1)
	);

	// White background for grid ontop of red boarder.
	square s2(
		.clk(clk),
		.colour(3'b111),
		.in_x(8'd64),
		.in_y(7'd2),
		.width(white_bg_width),
		.height(white_bg_height),
		.go_draw(f1),
		.finish_draw(f2),
		.out_x(out_x2),
		.out_y(out_y2),
		.out_colour(out_colour2)
	);

	// s3-s38 are all squares for the grid.
	// Squares are each 15x15, with 2 pixel gaps between each square, and 3 pixel gap from boarder edge.
	// First row.
	pipe_make p3(
		.clk(clk),
		.colour(square_colour),
		.in_x(i_x),
		.in_y(i_y),
		.width(square_width),
		.height(square_height),
		.go_draw(f2),
		.type(row_i_1[2:0]),
		.finish_draw(f3),
		.out_x(out_x3),
		.out_y(out_y3),
		.out_colour(out_colour3)
	);

	pipe_make p4(
		.clk(clk),
		.colour(square_colour),
		.in_x(i_x+sq_offset_x),
		.in_y(i_y),
		.width(square_width),
		.height(square_height),
		.go_draw(f3),
		.type(row_i_1[5:3]),
		.finish_draw(f4),
		.out_x(out_x4),
		.out_y(out_y4),
		.out_colour(out_colour4)
	);

	pipe_make p5(
		.clk(clk),
		.colour(square_colour),
		.in_x(i_x+2*sq_offset_x),
		.in_y(i_y),
		.width(square_width),
		.height(square_height),
		.go_draw(f4),
		.type(row_i_1[8:6]),
		.finish_draw(f5),
		.out_x(out_x5),
		.out_y(out_y5),
		.out_colour(out_colour5)
	);

	pipe_make p6(
		.clk(clk),
		.colour(square_colour),
		.in_x(i_x+3*sq_offset_x),
		.in_y(i_y),
		.width(square_width),
		.height(square_height),
		.go_draw(f5),
		.type(row_i_1[11:9]),
		.finish_draw(f6),
		.out_x(out_x6),
		.out_y(out_y6),
		.out_colour(out_colour6)
	);

	pipe_make p7(
		.clk(clk),
		.colour(square_colour),
		.in_x(i_x+4*sq_offset_x),
		.in_y(i_y),
		.width(square_width),
		.height(square_height),
		.go_draw(f6),
		.type(row_i_1[14:12]),
		.finish_draw(f7),
		.out_x(out_x7),
		.out_y(out_y7),
		.out_colour(out_colour7)
	);

	pipe_make p8(
		.clk(clk),
		.colour(square_colour),
		.in_x(i_x+5*sq_offset_x),
		.in_y(i_y),
		.width(square_width),
		.height(square_height),
		.go_draw(f7),
		.type(row_i_1[17:15]),
		.finish_draw(f8),
		.out_x(out_x8),
		.out_y(out_y8),
		.out_colour(out_colour8)
	);

	// Second row of squares.
	pipe_make p9(
		.clk(clk),
		.colour(square_colour),
		.in_x(i_x),
		.in_y(i_y+sq_offset_y),
		.width(square_width),
		.height(square_height),
		.go_draw(f8),
		.type(row_i_2[2:0]),
		.finish_draw(f9),
		.out_x(out_x9),
		.out_y(out_y9),
		.out_colour(out_colour9)
	);

	pipe_make p10(
		.clk(clk),
		.colour(square_colour),
		.in_x(i_x+sq_offset_x),
		.in_y(i_y+sq_offset_y),
		.width(square_width),
		.height(square_height),
		.go_draw(f9),
		.type(row_i_2[5:3]),
		.finish_draw(f10),
		.out_x(out_x10),
		.out_y(out_y10),
		.out_colour(out_colour10)
	);

	pipe_make p11(
		.clk(clk),
		.colour(square_colour),
		.in_x(i_x+2*sq_offset_x),
		.in_y(i_y+sq_offset_y),
		.width(square_width),
		.height(square_height),
		.go_draw(f10),
		.type(row_i_2[8:6]),
		.finish_draw(f11),
		.out_x(out_x11),
		.out_y(out_y11),
		.out_colour(out_colour11)
	);

	pipe_make p12(
		.clk(clk),
		.colour(square_colour),
		.in_x(i_x+3*sq_offset_x),
		.in_y(i_y+sq_offset_y),
		.width(square_width),
		.height(square_height),
		.go_draw(f11),
		.type(row_i_2[11:9]),
		.finish_draw(f12),
		.out_x(out_x12),
		.out_y(out_y12),
		.out_colour(out_colour12)
	);

	pipe_make p13(
		.clk(clk),
		.colour(square_colour),
		.in_x(i_x+4*sq_offset_x),
		.in_y(i_y+sq_offset_y),
		.width(square_width),
		.height(square_height),
		.go_draw(f12),
		.type(row_i_2[14:12]),
		.finish_draw(f13),
		.out_x(out_x13),
		.out_y(out_y13),
		.out_colour(out_colour13)
	);

	pipe_make p14(
		.clk(clk),
		.colour(square_colour),
		.in_x(i_x+5*sq_offset_x),
		.in_y(i_y+sq_offset_y),
		.width(square_width),
		.height(square_height),
		.go_draw(f13),
		.type(row_i_2[17:15]),
		.finish_draw(f14),
		.out_x(out_x14),
		.out_y(out_y14),
		.out_colour(out_colour14)
	);

	// Third row of squares.
	pipe_make p15(
		.clk(clk),
		.colour(square_colour),
		.in_x(i_x),
		.in_y(i_y+2*sq_offset_y),
		.width(square_width),
		.height(square_height),
		.go_draw(f14),
		.type(row_i_3[2:0]),
		.finish_draw(f15),
		.out_x(out_x15),
		.out_y(out_y15),
		.out_colour(out_colour15)
	);

	pipe_make p16(
		.clk(clk),
		.colour(square_colour),
		.in_x(i_x+sq_offset_x),
		.in_y(i_y+2*sq_offset_y),
		.width(square_width),
		.height(square_height),
		.go_draw(f15),
		.type(row_i_3[5:3]),
		.finish_draw(f16),
		.out_x(out_x16),
		.out_y(out_y16),
		.out_colour(out_colour16)
	);

	pipe_make p17(
		.clk(clk),
		.colour(square_colour),
		.in_x(i_x+2*sq_offset_x),
		.in_y(i_y+2*sq_offset_y),
		.width(square_width),
		.height(square_height),
		.go_draw(f16),
		.type(row_i_3[8:6]),
		.finish_draw(f17),
		.out_x(out_x17),
		.out_y(out_y17),
		.out_colour(out_colour17)
	);

	pipe_make p18(
		.clk(clk),
		.colour(square_colour),
		.in_x(i_x+3*sq_offset_x),
		.in_y(i_y+2*sq_offset_y),
		.width(square_width),
		.height(square_height),
		.go_draw(f17),
		.type(row_i_3[11:9]),
		.finish_draw(f18),
		.out_x(out_x18),
		.out_y(out_y18),
		.out_colour(out_colour18)
	);

	pipe_make p19(
		.clk(clk),
		.colour(square_colour),
		.in_x(i_x+4*sq_offset_x),
		.in_y(i_y+2*sq_offset_y),
		.width(square_width),
		.height(square_height),
		.go_draw(f18),
		.type(row_i_3[14:12]),
		.finish_draw(f19),
		.out_x(out_x19),
		.out_y(out_y19),
		.out_colour(out_colour19)
	);

	pipe_make p20(
		.clk(clk),
		.colour(square_colour),
		.in_x(i_x+5*sq_offset_x),
		.in_y(i_y+2*sq_offset_y),
		.width(square_width),
		.height(square_height),
		.go_draw(f19),
		.type(row_i_3[17:15]),
		.finish_draw(f20),
		.out_x(out_x20),
		.out_y(out_y20),
		.out_colour(out_colour20)
	);

	// Fourth row of squares.
	pipe_make p21(
		.clk(clk),
		.colour(square_colour),
		.in_x(i_x),
		.in_y(i_y+3*sq_offset_y),
		.width(square_width),
		.height(square_height),
		.go_draw(f20),
		.type(row_i_4[2:0]),
		.finish_draw(f21),
		.out_x(out_x21),
		.out_y(out_y21),
		.out_colour(out_colour21)
	);

	pipe_make p22(
		.clk(clk),
		.colour(square_colour),
		.in_x(i_x+sq_offset_x),
		.in_y(i_y+3*sq_offset_y),
		.width(square_width),
		.height(square_height),
		.go_draw(f21),
		.type(row_i_4[5:3]),
		.finish_draw(f22),
		.out_x(out_x22),
		.out_y(out_y22),
		.out_colour(out_colour22)
	);

	pipe_make p23(
		.clk(clk),
		.colour(square_colour),
		.in_x(i_x+2*sq_offset_x),
		.in_y(i_y+3*sq_offset_y),
		.width(square_width),
		.height(square_height),
		.go_draw(f22),
		.type(row_i_4[8:6]),
		.finish_draw(f23),
		.out_x(out_x23),
		.out_y(out_y23),
		.out_colour(out_colour23)
	);

	pipe_make p24(
		.clk(clk),
		.colour(square_colour),
		.in_x(i_x+3*sq_offset_x),
		.in_y(i_y+3*sq_offset_y),
		.width(square_width),
		.height(square_height),
		.go_draw(f23),
		.type(row_i_4[11:9]),
		.finish_draw(f24),
		.out_x(out_x24),
		.out_y(out_y24),
		.out_colour(out_colour24)
	);

	pipe_make p25(
		.clk(clk),
		.colour(square_colour),
		.in_x(i_x+4*sq_offset_x),
		.in_y(i_y+3*sq_offset_y),
		.width(square_width),
		.height(square_height),
		.go_draw(f24),
		.type(row_i_4[14:12]),
		.finish_draw(f25),
		.out_x(out_x25),
		.out_y(out_y25),
		.out_colour(out_colour25)
	);

	pipe_make p26(
		.clk(clk),
		.colour(square_colour),
		.in_x(i_x+5*sq_offset_x),
		.in_y(i_y+3*sq_offset_y),
		.width(square_width),
		.height(square_height),
		.go_draw(f25),
		.type(row_i_4[17:15]),
		.finish_draw(f26),
		.out_x(out_x26),
		.out_y(out_y26),
		.out_colour(out_colour26)
	);

	// Fifth Row of squares.
	pipe_make p27(
		.clk(clk),
		.colour(square_colour),
		.in_x(i_x),
		.in_y(i_y+4*sq_offset_y),
		.width(square_width),
		.height(square_height),
		.go_draw(f26),
		.type(row_i_5[2:0]),
		.finish_draw(f27),
		.out_x(out_x27),
		.out_y(out_y27),
		.out_colour(out_colour27)
	);

	pipe_make p28(
		.clk(clk),
		.colour(square_colour),
		.in_x(i_x+sq_offset_x),
		.in_y(i_y+4*sq_offset_y),
		.width(square_width),
		.height(square_height),
		.go_draw(f27),
		.type(row_i_5[5:3]),
		.finish_draw(f28),
		.out_x(out_x28),
		.out_y(out_y28),
		.out_colour(out_colour28)
	);

	pipe_make p29(
		.clk(clk),
		.colour(square_colour),
		.in_x(i_x+2*sq_offset_x),
		.in_y(i_y+4*sq_offset_y),
		.width(square_width),
		.height(square_height),
		.go_draw(f28),
		.type(row_i_5[8:6]),
		.finish_draw(f29),
		.out_x(out_x29),
		.out_y(out_y29),
		.out_colour(out_colour29)
	);

	pipe_make p30(
		.clk(clk),
		.colour(square_colour),
		.in_x(i_x+3*sq_offset_x),
		.in_y(i_y+4*sq_offset_y),
		.width(square_width),
		.height(square_height),
		.go_draw(f29),
		.type(row_i_5[11:9]),
		.finish_draw(f30),
		.out_x(out_x30),
		.out_y(out_y30),
		.out_colour(out_colour30)
	);

	pipe_make p31(
		.clk(clk),
		.colour(square_colour),
		.in_x(i_x+4*sq_offset_x),
		.in_y(i_y+4*sq_offset_y),
		.width(square_width),
		.height(square_height),
		.go_draw(f30),
		.type(row_i_5[14:12]),
		.finish_draw(f31),
		.out_x(out_x31),
		.out_y(out_y31),
		.out_colour(out_colour31)
	);

	pipe_make p32(
		.clk(clk),
		.colour(square_colour),
		.in_x(i_x+5*sq_offset_x),
		.in_y(i_y+4*sq_offset_y),
		.width(square_width),
		.height(square_height),
		.go_draw(f31),
		.type(row_i_5[17:15]),
		.finish_draw(f32),
		.out_x(out_x32),
		.out_y(out_y32),
		.out_colour(out_colour32)
	);

	// Sixth Row of squares.

	pipe_make p33(
		.clk(clk),
		.colour(square_colour),
		.in_x(i_x),
		.in_y(i_y+5*sq_offset_y),
		.width(square_width),
		.height(square_height),
		.go_draw(f32),
		.type(row_i_6[2:0]),
		.finish_draw(f33),
		.out_x(out_x33),
		.out_y(out_y33),
		.out_colour(out_colour33)
	);

	pipe_make p34(
		.clk(clk),
		.colour(square_colour),
		.in_x(i_x+sq_offset_x),
		.in_y(i_y+5*sq_offset_y),
		.width(square_width),
		.height(square_height),
		.go_draw(f33),
		.type(row_i_6[5:3]),
		.finish_draw(f34),
		.out_x(out_x34),
		.out_y(out_y34),
		.out_colour(out_colour34)
	);

	pipe_make p35(
		.clk(clk),
		.colour(square_colour),
		.in_x(i_x+2*sq_offset_x),
		.in_y(i_y+5*sq_offset_y),
		.width(square_width),
		.height(square_height),
		.go_draw(f34),
		.type(row_i_6[8:6]),
		.finish_draw(f35),
		.out_x(out_x35),
		.out_y(out_y35),
		.out_colour(out_colour35)
	);

	pipe_make p36(
		.clk(clk),
		.colour(square_colour),
		.in_x(i_x+3*sq_offset_x),
		.in_y(i_y+5*sq_offset_y),
		.width(square_width),
		.height(square_height),
		.go_draw(f35),
		.type(row_i_6[11:9]),
		.finish_draw(f36),
		.out_x(out_x36),
		.out_y(out_y36),
		.out_colour(out_colour36)
	);

	pipe_make p37(
		.clk(clk),
		.colour(square_colour),
		.in_x(i_x+4*sq_offset_x),
		.in_y(i_y+5*sq_offset_y),
		.width(square_width),
		.height(square_height),
		.go_draw(f36),
		.type(row_i_6[14:12]),
		.finish_draw(f37),
		.out_x(out_x37),
		.out_y(out_y37),
		.out_colour(out_colour37)
	);

	pipe_make p38(
		.clk(clk),
		.colour(square_colour),
		.in_x(i_x+5*sq_offset_x),
		.in_y(i_y+5*sq_offset_y),
		.width(square_width),
		.height(square_height),
		.go_draw(f37),
		.type(row_i_6[17:15]),
		.finish_draw(f38),
		.out_x(out_x38),
		.out_y(out_y38),
		.out_colour(out_colour38)
	);


	// Second Grid
	// s3-s38 are all squares for the grid.
	// Squares are each 15x15, with 2 pixel gaps between each square, and 3 pixel gap from boarder edge.
	// First row.
	pipe_make p39(
		.clk(clk),
		.colour(square_colour),
		.in_x(i_x2),
		.in_y(i_y2),
		.width(square_width),
		.height(square_height),
		.go_draw(f38),
		.type(row1[2:0]),
		.finish_draw(f39),
		.out_x(out_x39),
		.out_y(out_y39),
		.out_colour(out_colour39)
	);

	pipe_make p40(
		.clk(clk),
		.colour(square_colour),
		.in_x(i_x2+sq_offset_x),
		.in_y(i_y2),
		.width(square_width),
		.height(square_height),
		.go_draw(f39),
		.type(row1[5:3]),
		.finish_draw(f40),
		.out_x(out_x40),
		.out_y(out_y40),
		.out_colour(out_colour40)
	);

	pipe_make p41(
		.clk(clk),
		.colour(square_colour),
		.in_x(i_x2+2*sq_offset_x),
		.in_y(i_y2),
		.width(square_width),
		.height(square_height),
		.go_draw(f40),
		.type(row1[8:6]),
		.finish_draw(f41),
		.out_x(out_x41),
		.out_y(out_y41),
		.out_colour(out_colour41)
	);

	pipe_make p42(
		.clk(clk),
		.colour(square_colour),
		.in_x(i_x2+3*sq_offset_x),
		.in_y(i_y2),
		.width(square_width),
		.height(square_height),
		.go_draw(f41),
		.type(row1[11:9]),
		.finish_draw(f42),
		.out_x(out_x42),
		.out_y(out_y42),
		.out_colour(out_colour42)
	);

	pipe_make p43(
		.clk(clk),
		.colour(square_colour),
		.in_x(i_x2+4*sq_offset_x),
		.in_y(i_y2),
		.width(square_width),
		.height(square_height),
		.go_draw(f42),
		.type(row1[14:12]),
		.finish_draw(f43),
		.out_x(out_x43),
		.out_y(out_y43),
		.out_colour(out_colour43)
	);

	pipe_make p44(
		.clk(clk),
		.colour(square_colour),
		.in_x(i_x2+5*sq_offset_x),
		.in_y(i_y2),
		.width(square_width),
		.height(square_height),
		.go_draw(f43),
		.type(row1[17:15]),
		.finish_draw(f44),
		.out_x(out_x44),
		.out_y(out_y44),
		.out_colour(out_colour44)
	);

	// Second row of squares.
	pipe_make p45(
		.clk(clk),
		.colour(square_colour),
		.in_x(i_x2),
		.in_y(i_y2+sq_offset_y),
		.width(square_width),
		.height(square_height),
		.go_draw(f44),
		.type(row2[2:0]),
		.finish_draw(f45),
		.out_x(out_x45),
		.out_y(out_y45),
		.out_colour(out_colour45)
	);

	pipe_make p46(
		.clk(clk),
		.colour(square_colour),
		.in_x(i_x2+sq_offset_x),
		.in_y(i_y2+sq_offset_y),
		.width(square_width),
		.height(square_height),
		.go_draw(f45),
		.type(row2[5:3]),
		.finish_draw(f46),
		.out_x(out_x46),
		.out_y(out_y46),
		.out_colour(out_colour46)
	);

	pipe_make p47(
		.clk(clk),
		.colour(square_colour),
		.in_x(i_x2+2*sq_offset_x),
		.in_y(i_y2+sq_offset_y),
		.width(square_width),
		.height(square_height),
		.go_draw(f46),
		.type(row2[8:6]),
		.finish_draw(f47),
		.out_x(out_x47),
		.out_y(out_y47),
		.out_colour(out_colour47)
	);

	pipe_make p48(
		.clk(clk),
		.colour(square_colour),
		.in_x(i_x2+3*sq_offset_x),
		.in_y(i_y2+sq_offset_y),
		.width(square_width),
		.height(square_height),
		.go_draw(f47),
		.type(row2[11:9]),
		.finish_draw(f48),
		.out_x(out_x48),
		.out_y(out_y48),
		.out_colour(out_colour48)
	);

	pipe_make p49(
		.clk(clk),
		.colour(square_colour),
		.in_x(i_x2+4*sq_offset_x),
		.in_y(i_y2+sq_offset_y),
		.width(square_width),
		.height(square_height),
		.go_draw(f48),
		.type(row2[14:12]),
		.finish_draw(f49),
		.out_x(out_x49),
		.out_y(out_y49),
		.out_colour(out_colour49)
	);

	pipe_make p50(
		.clk(clk),
		.colour(square_colour),
		.in_x(i_x2+5*sq_offset_x),
		.in_y(i_y2+sq_offset_y),
		.width(square_width),
		.height(square_height),
		.go_draw(f49),
		.type(row2[17:15]),
		.finish_draw(f50),
		.out_x(out_x50),
		.out_y(out_y50),
		.out_colour(out_colour50)
	);

	// Third row of squares.
	pipe_make p51(
		.clk(clk),
		.colour(square_colour),
		.in_x(i_x2),
		.in_y(i_y2+2*sq_offset_y),
		.width(square_width),
		.height(square_height),
		.go_draw(f50),
		.type(row3[2:0]),
		.finish_draw(f51),
		.out_x(out_x51),
		.out_y(out_y51),
		.out_colour(out_colour51)
	);

	pipe_make p52(
		.clk(clk),
		.colour(square_colour),
		.in_x(i_x2+sq_offset_x),
		.in_y(i_y2+2*sq_offset_y),
		.width(square_width),
		.height(square_height),
		.go_draw(f51),
		.type(row3[5:3]),
		.finish_draw(f52),
		.out_x(out_x52),
		.out_y(out_y52),
		.out_colour(out_colour52)
	);

	pipe_make p53(
		.clk(clk),
		.colour(square_colour),
		.in_x(i_x2+2*sq_offset_x),
		.in_y(i_y2+2*sq_offset_y),
		.width(square_width),
		.height(square_height),
		.go_draw(f52),
		.type(row3[8:6]),
		.finish_draw(f53),
		.out_x(out_x53),
		.out_y(out_y53),
		.out_colour(out_colour53)
	);

	pipe_make p54(
		.clk(clk),
		.colour(square_colour),
		.in_x(i_x2+3*sq_offset_x),
		.in_y(i_y2+2*sq_offset_y),
		.width(square_width),
		.height(square_height),
		.go_draw(f53),
		.type(row3[11:9]),
		.finish_draw(f54),
		.out_x(out_x54),
		.out_y(out_y54),
		.out_colour(out_colour54)
	);

	pipe_make p55(
		.clk(clk),
		.colour(square_colour),
		.in_x(i_x2+4*sq_offset_x),
		.in_y(i_y2+2*sq_offset_y),
		.width(square_width),
		.height(square_height),
		.go_draw(f54),
		.type(row3[14:12]),
		.finish_draw(f55),
		.out_x(out_x55),
		.out_y(out_y55),
		.out_colour(out_colour55)
	);

	pipe_make p56(
		.clk(clk),
		.colour(square_colour),
		.in_x(i_x2+5*sq_offset_x),
		.in_y(i_y2+2*sq_offset_y),
		.width(square_width),
		.height(square_height),
		.go_draw(f55),
		.type(row3[17:15]),
		.finish_draw(f56),
		.out_x(out_x56),
		.out_y(out_y56),
		.out_colour(out_colour56)
	);

	// Fourth row of squares.
	pipe_make p57(
		.clk(clk),
		.colour(square_colour),
		.in_x(i_x2),
		.in_y(i_y2+3*sq_offset_y),
		.width(square_width),
		.height(square_height),
		.go_draw(f56),
		.type(row4[2:0]),
		.finish_draw(f57),
		.out_x(out_x57),
		.out_y(out_y57),
		.out_colour(out_colour57)
	);

	pipe_make p58(
		.clk(clk),
		.colour(square_colour),
		.in_x(i_x2+sq_offset_x),
		.in_y(i_y2+3*sq_offset_y),
		.width(square_width),
		.height(square_height),
		.go_draw(f57),
		.type(row4[5:3]),
		.finish_draw(f58),
		.out_x(out_x58),
		.out_y(out_y58),
		.out_colour(out_colour58)
	);

	pipe_make p59(
		.clk(clk),
		.colour(square_colour),
		.in_x(i_x2+2*sq_offset_x),
		.in_y(i_y2+3*sq_offset_y),
		.width(square_width),
		.height(square_height),
		.go_draw(f58),
		.type(row4[8:6]),
		.finish_draw(f59),
		.out_x(out_x59),
		.out_y(out_y59),
		.out_colour(out_colour59)
	);

	pipe_make p60(
		.clk(clk),
		.colour(square_colour),
		.in_x(i_x2+3*sq_offset_x),
		.in_y(i_y2+3*sq_offset_y),
		.width(square_width),
		.height(square_height),
		.go_draw(f59),
		.type(row4[11:9]),
		.finish_draw(f60),
		.out_x(out_x60),
		.out_y(out_y60),
		.out_colour(out_colour60)
	);

	pipe_make p61(
		.clk(clk),
		.colour(square_colour),
		.in_x(i_x2+4*sq_offset_x),
		.in_y(i_y2+3*sq_offset_y),
		.width(square_width),
		.height(square_height),
		.go_draw(f60),
		.type(row4[14:12]),
		.finish_draw(f61),
		.out_x(out_x61),
		.out_y(out_y61),
		.out_colour(out_colour61)
	);

	pipe_make p62(
		.clk(clk),
		.colour(square_colour),
		.in_x(i_x2+5*sq_offset_x),
		.in_y(i_y2+3*sq_offset_y),
		.width(square_width),
		.height(square_height),
		.go_draw(f61),
		.type(row4[17:15]),
		.finish_draw(f62),
		.out_x(out_x62),
		.out_y(out_y62),
		.out_colour(out_colour62)
	);

	// Fifth Row of squares.
	pipe_make p63(
		.clk(clk),
		.colour(square_colour),
		.in_x(i_x2),
		.in_y(i_y2+4*sq_offset_y),
		.width(square_width),
		.height(square_height),
		.go_draw(f62),
		.type(row5[2:0]),
		.finish_draw(f63),
		.out_x(out_x63),
		.out_y(out_y63),
		.out_colour(out_colour63)
	);

	pipe_make p64(
		.clk(clk),
		.colour(square_colour),
		.in_x(i_x2+sq_offset_x),
		.in_y(i_y2+4*sq_offset_y),
		.width(square_width),
		.height(square_height),
		.go_draw(f63),
		.type(row5[5:3]),
		.finish_draw(f64),
		.out_x(out_x64),
		.out_y(out_y64),
		.out_colour(out_colour64)
	);

	pipe_make p65(
		.clk(clk),
		.colour(square_colour),
		.in_x(i_x2+2*sq_offset_x),
		.in_y(i_y2+4*sq_offset_y),
		.width(square_width),
		.height(square_height),
		.go_draw(f64),
		.type(row5[8:6]),
		.finish_draw(f65),
		.out_x(out_x65),
		.out_y(out_y65),
		.out_colour(out_colour65)
	);

	pipe_make p66(
		.clk(clk),
		.colour(square_colour),
		.in_x(i_x2+3*sq_offset_x),
		.in_y(i_y2+4*sq_offset_y),
		.width(square_width),
		.height(square_height),
		.go_draw(f65),
		.type(row5[11:9]),
		.finish_draw(f66),
		.out_x(out_x66),
		.out_y(out_y66),
		.out_colour(out_colour66)
	);

	pipe_make p67(
		.clk(clk),
		.colour(square_colour),
		.in_x(i_x2+4*sq_offset_x),
		.in_y(i_y2+4*sq_offset_y),
		.width(square_width),
		.height(square_height),
		.go_draw(f66),
		.type(row5[14:12]),
		.finish_draw(f67),
		.out_x(out_x67),
		.out_y(out_y67),
		.out_colour(out_colour67)
	);

	pipe_make p68(
		.clk(clk),
		.colour(square_colour),
		.in_x(i_x2+5*sq_offset_x),
		.in_y(i_y2+4*sq_offset_y),
		.width(square_width),
		.height(square_height),
		.go_draw(f67),
		.type(row5[17:15]),
		.finish_draw(f68),
		.out_x(out_x68),
		.out_y(out_y68),
		.out_colour(out_colour68)
	);

	// Sixth Row of squares.

	pipe_make p69(
		.clk(clk),
		.colour(square_colour),
		.in_x(i_x2),
		.in_y(i_y2+5*sq_offset_y),
		.width(square_width),
		.height(square_height),
		.go_draw(f68),
		.type(row6[2:0]),
		.finish_draw(f69),
		.out_x(out_x69),
		.out_y(out_y69),
		.out_colour(out_colour69)
	);

	pipe_make p70(
		.clk(clk),
		.colour(square_colour),
		.in_x(i_x2+sq_offset_x),
		.in_y(i_y2+5*sq_offset_y),
		.width(square_width),
		.height(square_height),
		.go_draw(f69),
		.type(row6[5:3]),
		.finish_draw(f70),
		.out_x(out_x70),
		.out_y(out_y70),
		.out_colour(out_colour70)
	);

	pipe_make p71(
		.clk(clk),
		.colour(square_colour),
		.in_x(i_x2+2*sq_offset_x),
		.in_y(i_y2+5*sq_offset_y),
		.width(square_width),
		.height(square_height),
		.go_draw(f70),
		.type(row6[8:6]),
		.finish_draw(f71),
		.out_x(out_x71),
		.out_y(out_y71),
		.out_colour(out_colour71)
	);

	pipe_make p72(
		.clk(clk),
		.colour(square_colour),
		.in_x(i_x2+3*sq_offset_x),
		.in_y(i_y2+5*sq_offset_y),
		.width(square_width),
		.height(square_height),
		.go_draw(f71),
		.type(row6[11:9]),
		.finish_draw(f72),
		.out_x(out_x72),
		.out_y(out_y72),
		.out_colour(out_colour72)
	);

	pipe_make p73(
		.clk(clk),
		.colour(square_colour),
		.in_x(i_x2+4*sq_offset_x),
		.in_y(i_y2+5*sq_offset_y),
		.width(square_width),
		.height(square_height),
		.go_draw(f72),
		.type(row6[14:12]),
		.finish_draw(f73),
		.out_x(out_x73),
		.out_y(out_y73),
		.out_colour(out_colour73)
	);

	pipe_make p74(
		.clk(clk),
		.colour(square_colour),
		.in_x(i_x2+5*sq_offset_x),
		.in_y(i_y2+5*sq_offset_y),
		.width(square_width),
		.height(square_height),
		.go_draw(f73),
		.type(row6[17:15]),
		.finish_draw(f74),
		.out_x(out_x74),
		.out_y(out_y74),
		.out_colour(out_colour74)
	);
	
	square2 p75(
		.clk(clk),
		.colour(3'b110),
		.in_x(i_x2+sq_offset_x*sel_x),
		.in_y(i_y2+sq_offset_y*sel_y),
		.width(8'd1),
		.height(7'd2),
		.go_draw(f74),
		.finish_draw(f75),
		.out_x(out_x75),
		.out_y(out_y75),
		.out_colour(out_colour75)
	);
	
	square2 p76(
		.clk(clk),
		.colour(3'b111),
		.in_x(8'd48),
		.in_y(8'd96),
		.width(square_width+8'd4),
		.height(square_height+7'd8),
		.go_draw(f75),
		.finish_draw(f76),
		.out_x(out_x76),
		.out_y(out_y76),
		.out_colour(out_colour76)
	);
	
	pipe_make p77(
		.clk(clk),
		.colour(square_colour),
		.in_x(8'd50),
		.in_y(8'd100),
		.width(square_width),
		.height(square_height),
		.go_draw(f76),
		.type(i_p),
		.finish_draw(f77),
		.out_x(out_x77),
		.out_y(out_y77),
		.out_colour(out_colour77)
	);

    // Output logic aka all of our datapath control signals
    always @(*)
    begin: enable_signals
        case (current_state)
		LOAD_SQ_0: begin
			out_x = out_x0;
			out_y = out_y0;
			out_colour = out_colour0;
		end
		LOAD_SQ_1: begin
			out_x = out_x1;
			out_y = out_y1;
			out_colour = out_colour1;
		end
		LOAD_SQ_2: begin
			out_x = out_x2;
			out_y = out_y2;
			out_colour = out_colour2;
		end
		// first row
		LOAD_SQ_3: begin
			out_x = out_x3;
			out_y = out_y3;
			out_colour = out_colour3;
		end
		LOAD_SQ_4: begin
			out_x = out_x4;
			out_y = out_y4;
			out_colour = out_colour4;
		end
		LOAD_SQ_5: begin
			out_x = out_x5;
			out_y = out_y5;
			out_colour = out_colour5;
		end
		LOAD_SQ_6: begin
			out_x = out_x6;
			out_y = out_y6;
			out_colour = out_colour6;
		end
		LOAD_SQ_7: begin
			out_x = out_x7;
			out_y = out_y7;
			out_colour = out_colour7;
		end
		LOAD_SQ_8: begin
			out_x = out_x8;
			out_y = out_y8;
			out_colour = out_colour8;
		end
		// second row
		LOAD_SQ_9: begin
			out_x = out_x9;
			out_y = out_y9;
			out_colour = out_colour9;
		end
		LOAD_SQ_10: begin
			out_x = out_x10;
			out_y = out_y10;
			out_colour = out_colour10;
		end
		LOAD_SQ_11: begin
			out_x = out_x11;
			out_y = out_y11;
			out_colour = out_colour11;
		end
		LOAD_SQ_12: begin
			out_x = out_x12;
			out_y = out_y12;
			out_colour = out_colour12;
		end
		LOAD_SQ_13: begin
			out_x = out_x13;
			out_y = out_y13;
			out_colour = out_colour13;
		end
		LOAD_SQ_14: begin
			out_x = out_x14;
			out_y = out_y14;
			out_colour = out_colour14;
		end
		LOAD_SQ_15: begin
			out_x = out_x15;
			out_y = out_y15;
			out_colour = out_colour15;
		end
		LOAD_SQ_16: begin
			out_x = out_x16;
			out_y = out_y16;
			out_colour = out_colour16;
		end
		LOAD_SQ_17: begin
			out_x = out_x17;
			out_y = out_y17;
			out_colour = out_colour17;
		end
		LOAD_SQ_18: begin
			out_x = out_x18;
			out_y = out_y18;
			out_colour = out_colour18;
		end
		LOAD_SQ_19: begin
			out_x = out_x19;
			out_y = out_y19;
			out_colour = out_colour19;
		end
		LOAD_SQ_20: begin
			out_x = out_x20;
			out_y = out_y20;
			out_colour = out_colour20;
		end
		LOAD_SQ_21: begin
			out_x = out_x21;
			out_y = out_y21;
			out_colour = out_colour21;
		end
		LOAD_SQ_22: begin
			out_x = out_x22;
			out_y = out_y22;
			out_colour = out_colour22;
		end
		LOAD_SQ_23: begin
			out_x = out_x23;
			out_y = out_y23;
			out_colour = out_colour23;
		end
		LOAD_SQ_24: begin
			out_x = out_x24;
			out_y = out_y24;
			out_colour = out_colour24;
		end
		LOAD_SQ_25: begin
			out_x = out_x25;
			out_y = out_y25;
			out_colour = out_colour25;
		end
		LOAD_SQ_26: begin
			out_x = out_x26;
			out_y = out_y26;
			out_colour = out_colour26;
		end
		LOAD_SQ_27: begin
			out_x = out_x27;
			out_y = out_y27;
			out_colour = out_colour27;
		end
		LOAD_SQ_28: begin
			out_x = out_x28;
			out_y = out_y28;
			out_colour = out_colour28;
		end
		LOAD_SQ_29: begin
			out_x = out_x29;
			out_y = out_y29;
			out_colour = out_colour29;
		end
		LOAD_SQ_30: begin
			out_x = out_x30;
			out_y = out_y30;
			out_colour = out_colour30;
		end
		LOAD_SQ_31: begin
			out_x = out_x31;
			out_y = out_y31;
			out_colour = out_colour31;
		end
		LOAD_SQ_32: begin
			out_x = out_x32;
			out_y = out_y32;
			out_colour = out_colour32;
		end
		LOAD_SQ_33: begin
			out_x = out_x33;
			out_y = out_y33;
			out_colour = out_colour33;
		end
		LOAD_SQ_34: begin
			out_x = out_x34;
			out_y = out_y34;
			out_colour = out_colour34;
		end
		LOAD_SQ_35: begin
			out_x = out_x35;
			out_y = out_y35;
			out_colour = out_colour35;
		end
		LOAD_SQ_36: begin
			out_x = out_x36;
			out_y = out_y36;
			out_colour = out_colour36;
		end
		LOAD_SQ_37: begin
			out_x = out_x37;
			out_y = out_y37;
			out_colour = out_colour37;
		end
		LOAD_SQ_38: begin
			out_x = out_x38;
			out_y = out_y38;
			out_colour = out_colour38;
		end
		LOAD_SQ_39: begin
			out_x = out_x39;
			out_y = out_y39;
			out_colour = out_colour39;
		end
		LOAD_SQ_40: begin
			out_x = out_x40;
			out_y = out_y40;
			out_colour = out_colour40;
		end
		LOAD_SQ_41: begin
			out_x = out_x41;
			out_y = out_y41;
			out_colour = out_colour41;
		end
		LOAD_SQ_42: begin
			out_x = out_x42;
			out_y = out_y42;
			out_colour = out_colour42;
		end
		LOAD_SQ_43: begin
			out_x = out_x43;
			out_y = out_y43;
			out_colour = out_colour43;
		end
		LOAD_SQ_44: begin
			out_x = out_x44;
			out_y = out_y44;
			out_colour = out_colour44;
		end
		LOAD_SQ_45: begin
			out_x = out_x45;
			out_y = out_y45;
			out_colour = out_colour45;
		end
		LOAD_SQ_46: begin
			out_x = out_x46;
			out_y = out_y46;
			out_colour = out_colour46;
		end
		LOAD_SQ_47: begin
			out_x = out_x47;
			out_y = out_y47;
			out_colour = out_colour47;
		end
		LOAD_SQ_48: begin
			out_x = out_x48;
			out_y = out_y48;
			out_colour = out_colour48;
		end
		LOAD_SQ_49: begin
			out_x = out_x49;
			out_y = out_y49;
			out_colour = out_colour49;
		end
		LOAD_SQ_50: begin
			out_x = out_x50;
			out_y = out_y50;
			out_colour = out_colour50;
		end
		LOAD_SQ_51: begin
			out_x = out_x51;
			out_y = out_y51;
			out_colour = out_colour51;
		end
		LOAD_SQ_52: begin
			out_x = out_x52;
			out_y = out_y52;
			out_colour = out_colour52;
		end
		LOAD_SQ_53: begin
			out_x = out_x53;
			out_y = out_y53;
			out_colour = out_colour53;
		end
		LOAD_SQ_54: begin
			out_x = out_x54;
			out_y = out_y54;
			out_colour = out_colour54;
		end
		LOAD_SQ_55: begin
			out_x = out_x55;
			out_y = out_y55;
			out_colour = out_colour55;
		end
		LOAD_SQ_56: begin
			out_x = out_x56;
			out_y = out_y56;
			out_colour = out_colour56;
		end
		LOAD_SQ_57: begin
			out_x = out_x57;
			out_y = out_y57;
			out_colour = out_colour57;
		end
		LOAD_SQ_58: begin
			out_x = out_x58;
			out_y = out_y58;
			out_colour = out_colour58;
		end
		LOAD_SQ_59: begin
			out_x = out_x59;
			out_y = out_y59;
			out_colour = out_colour59;
		end
		LOAD_SQ_60: begin
			out_x = out_x60;
			out_y = out_y60;
			out_colour = out_colour60;
		end
		LOAD_SQ_61: begin
			out_x = out_x61;
			out_y = out_y61;
			out_colour = out_colour61;
		end
		LOAD_SQ_62: begin
			out_x = out_x62;
			out_y = out_y62;
			out_colour = out_colour62;
		end
		LOAD_SQ_63: begin
			out_x = out_x63;
			out_y = out_y63;
			out_colour = out_colour63;
		end
		LOAD_SQ_64: begin
			out_x = out_x64;
			out_y = out_y64;
			out_colour = out_colour64;
		end
		LOAD_SQ_65: begin
			out_x = out_x65;
			out_y = out_y65;
			out_colour = out_colour65;
		end
		LOAD_SQ_66: begin
			out_x = out_x66;
			out_y = out_y66;
			out_colour = out_colour66;
		end
		LOAD_SQ_67: begin
			out_x = out_x67;
			out_y = out_y67;
			out_colour = out_colour67;
		end
		LOAD_SQ_68: begin
			out_x = out_x68;
			out_y = out_y68;
			out_colour = out_colour68;
		end
		LOAD_SQ_69: begin
			out_x = out_x69;
			out_y = out_y69;
			out_colour = out_colour69;
		end
		LOAD_SQ_70: begin
			out_x = out_x70;
			out_y = out_y70;
			out_colour = out_colour70;
		end
		LOAD_SQ_71: begin
			out_x = out_x71;
			out_y = out_y71;
			out_colour = out_colour71;
		end
		LOAD_SQ_72: begin
			out_x = out_x72;
			out_y = out_y72;
			out_colour = out_colour72;
		end
		LOAD_SQ_73: begin
			out_x = out_x73;
			out_y = out_y73;
			out_colour = out_colour73;
		end
		LOAD_SQ_74: begin
			out_x = out_x74;
			out_y = out_y74;
			out_colour = out_colour74;
		end
		LOAD_SQ_75: begin
			out_x = out_x75;
			out_y = out_y75;
			out_colour = out_colour75;
		end
		LOAD_SQ_76: begin
			out_x = out_x76;
			out_y = out_y76;
			out_colour = out_colour76;
		end
		LOAD_SQ_77: begin
			out_x = out_x77;
			out_y = out_y77;
			out_colour = out_colour77;
		end

		// DO LOGIC FOR ADDITIONAL SQUARES.
		DEAD: begin
			out_x = 8'd0;
			out_y = 7'd0;
			out_colour = 3'b000;
		end

        // default:    // don't need default since we already made sure all of our outputs were assigned a value at the start of the always block
        endcase
    end // enable_signals

    // current_state registers
    always@(posedge clk)
    begin: state_FFs
         current_state <= next_state;
    end // state_FFS
endmodule

module square(
		input clk,
		input [2:0] colour,
		input [7:0] in_x,
		input [6:0] in_y,
		input [7:0] width,
		input [6:0] height,
		input go_draw,
		output reg finish_draw,
		output reg [7:0] out_x,
		output reg [6:0] out_y,
		output reg [2:0] out_colour
	);
	reg [9:0] draw_twice;
	reg [7:0] offset_x;
	reg [6:0] offset_y;
	reg continue_draw; // Added


	// Output result register
	always@(posedge clk) begin

		// Make sure that the drawing is done at the correct times.
		if (go_draw) begin
			continue_draw <= go_draw;
		end
		if(continue_draw) begin
			// Draw the square one pixel at a time.
			finish_draw <= 1'b0;
			out_x <= in_x + offset_x[7:0];
			out_y <= in_y + offset_y[6:0];
			out_colour <= colour;
			offset_x <= offset_x + 1'b1;
			if(offset_x == width)begin
				offset_x <= 8'b0;
				offset_y <= offset_y + 1'b1;
			end
			if(offset_y == height) begin //+7'd3
				offset_y <= 7'b0;
				draw_twice <= draw_twice + 1'b1;
				if(draw_twice == 10'd700)
					finish_draw <= 1'b1;
				out_x <= in_x;
				out_y <= in_y;
			end

		end
	end

endmodule

module square2(
		input clk,
		input [2:0] colour,
		input [7:0] in_x,
		input [6:0] in_y,
		input [7:0] width,
		input [6:0] height,
		input go_draw,
		output reg finish_draw,
		output reg [7:0] out_x,
		output reg [6:0] out_y,
		output reg [2:0] out_colour
	);
	reg [4:0] draw_twice;
	reg [7:0] offset_x;
	reg [6:0] offset_y;
	reg continue_draw; // Added


	// Output result register
	always@(posedge clk) begin

		// Make sure that the drawing is done at the correct times.
		if (go_draw) begin
			continue_draw <= go_draw;		// Added
		end
		if(continue_draw) begin // Changed
			finish_draw <= 1'b0;
			out_x <= in_x + offset_x[7:0];
			out_y <= in_y + offset_y[6:0];
			out_colour <= colour;
			offset_x <= offset_x + 1'b1;
			if(offset_x == width)begin
				offset_x <= 8'b0;
				offset_y <= offset_y + 1'b1;
			end
			if(offset_y == height) begin //+7'd3
				offset_y <= 7'b0;
				draw_twice <= draw_twice + 1'b1;
				if(draw_twice == 5'd16)
					finish_draw <= 1'b1;
				out_x <= in_x;
				out_y <= in_y;
			end

		end
	end

endmodule

module border(
		input clk,
		input [2:0] colour,
		input [7:0] in_x,
		input [6:0] in_y,
		input [7:0] width,
		input [6:0] height,
		input go_draw,
		output reg finish_draw,
		output reg [7:0] out_x,
		output reg [6:0] out_y,
		output reg [2:0] out_colour
	);

	// Signals for finished drawing each edge of border.
	wire f1, f2, f3, f4;

	// Output variables for each border module instance.
	wire [7:0] out_x1, out_x2, out_x3, out_x4;
	wire [6:0] out_y1, out_y2, out_y3, out_y4;
	wire [2:0] out_colour1, out_colour2, out_colour3, out_colour4;

	// Counter to control FSM state.
	reg [2:0] counter;

	// Control value of counter.
	always@(posedge clk) begin
		// Set finish_draw to be 0 so that we can use this as a singleton.
		finish_draw = 1'b0;

		if (go_draw && (counter == 3'b000)) begin
			counter <= counter + 1'b1;
		end

		// Finished drawing top edge.
		if (f1 && (counter == 3'b001)) begin
			counter <= counter + 1'b1;
		end

		// Finished drawing bottom edge.
		if (f2 && (counter == 3'b10)) begin
			counter <= counter + 1'b1;
		end

		// Finished drawing left edge.
		if (f3 && (counter == 3'b011)) begin
			counter <= counter + 1'b1;
		end

		// Finished drawing right edge.
		if (f4 && (counter == 3'b100)) begin
			finish_draw <= 1'b1;
			// Keep drawing the border
			counter <= 3'b000;
		end
	end

	// Determine the output x/y value based on the state.
	always @(*)
	begin: display
		case (counter)
			3'b001: begin // Top edge.
				out_x = out_x1;
				out_y = out_y1;
				out_colour = out_colour1;
			end
			3'b010: begin // Bottom edge.
				out_x = out_x2;
				out_y = out_y2;
				out_colour = out_colour2;
			end
			3'b011: begin // Left edge.
				out_x = out_x3;
				out_y = out_y3;
				out_colour = out_colour3;
			end
			3'b100: begin // Right edge.
				out_x = out_x4;
				out_y = out_y4;
				out_colour = out_colour4;
			end
			default: begin // Black pixel at top left corner of screen.
				out_x = 7'd10;
				out_y = 6'd10;
				out_colour = 3'd0;
			end
		endcase
	end
	// top edge
	square ss1(
		.clk(clk),
		.colour(colour),
		.in_x(in_x),
		.in_y(in_y),
		.width(width),
		.height(7'd1),
		.go_draw(go_draw),
		.finish_draw(f1),
		.out_x(out_x1),
		.out_y(out_y1),
		.out_colour(out_colour1)
	);
	// bottom edge
	square ss2(
		.clk(clk),
		.colour(colour),
		.in_x(in_x),
		.in_y(in_y + height - 7'd1),
		.width(width),
		.height(7'd1),
		.go_draw(f1),
		.finish_draw(f2),
		.out_x(out_x2),
		.out_y(out_y2),
		.out_colour(out_colour2)
	);
	// left edge
	square ss3(
		.clk(clk),
		.colour(colour),
		.in_x(in_x),
		.in_y(in_y),
		.width(8'd0),
		.height(height),
		.go_draw(f2),
		.finish_draw(f3),
		.out_x(out_x3),
		.out_y(out_y3),
		.out_colour(out_colour3)
	);
	// right edge
	square ss4(
		.clk(clk),
		.colour(colour),
		.in_x(in_x + width),
		.in_y(in_y),
		.width(8'd0),
		.height(height),
		.go_draw(f3),
		.finish_draw(f4),
		.out_x(out_x4),
		.out_y(out_y4),
		.out_colour(out_colour4)
	);

endmodule

module down_right_pipe(
		input clk,
		input [2:0] colour,
		input [7:0] in_x,
		input [6:0] in_y,
		input go_draw,
		output reg finish_draw,
		output reg [7:0] out_x,
		output reg [6:0] out_y,
		output reg [2:0] out_colour
	);

	// Signals for finished drawing each part of pipe.
	wire f1, f2, f3, f4;

	// Output variables for each border module instance.
	wire [7:0] out_x1, out_x2, out_x3;
	wire [6:0] out_y1, out_y2, out_y3;
	wire [2:0] out_colour1, out_colour2, out_colour3;

	// Counter to control FSM state.
	reg [1:0] counter;

	// Control value of counter.
	always@(posedge clk) begin
		// Set finish_draw to be 0 so that we can use this as a singleton.
		finish_draw = 1'b0;

		if (go_draw && (counter == 2'b000)) begin
			counter <= counter + 1'b1;
		end

		// Finished drawing black background.
		if (f1 && (counter == 2'b001)) begin
			counter <= counter + 1'b1;
		end
		
		// Finished drawing Green box.
		if (f2 && (counter == 2'b010)) begin
			counter <= counter + 1'b1;
		end
		// Finished drawing black box.
		if (f3 && (counter == 2'b11)) begin
			finish_draw <= 1'b1;
			// Keep drawing the pipe
			counter <= 2'b00;
		end
	end

	// Determine the output x/y value based on the state.
	always @(*)
	begin: display
		case (counter)
			2'b01: begin // Black bg.
				out_x = out_x1;
				out_y = out_y1;
				out_colour = out_colour1;
			end
			2'b10: begin // Green box.
				out_x = out_x2;
				out_y = out_y2;
				out_colour = out_colour2;
			end
			2'b11: begin // Black box.
				out_x = out_x3;
				out_y = out_y3;
				out_colour = out_colour3;
			end
			default: begin // Black pixel at top left corner of screen.
				out_x = in_x+7'd4;
				out_y = in_y+7'd4;
				out_colour = colour;
			end
		endcase
	end
	// black bg
	square2 bg(
		.clk(clk),
		.colour(3'b000),
		.in_x(in_x),
		.in_y(in_y),
		.width(8'd7),
		.height(7'd10),
		.go_draw(go_draw),
		.finish_draw(f1),
		.out_x(out_x1),
		.out_y(out_y1),
		.out_colour(out_colour1)
	);
	// green box
	square dr1(
		.clk(clk),
		.colour(colour),
		.in_x(in_x+7'd2),
		.in_y(in_y+7'd3),
		.width(8'd5),
		.height(7'd7),
		.go_draw(f1),
		.finish_draw(f2),
		.out_x(out_x2),
		.out_y(out_y2),
		.out_colour(out_colour2)
	);
	
	// black box
	square dr2(
		.clk(clk),
		.colour(3'b000),
		.in_x(in_x+7'd6),
		.in_y(in_y+7'd7),
		.width(8'd1),
		.height(7'd3),
		.go_draw(f2),
		.finish_draw(f3),
		.out_x(out_x3),
		.out_y(out_y3),
		.out_colour(out_colour3)
	);

endmodule

module up_right_pipe(
		input clk,
		input [2:0] colour,
		input [7:0] in_x,
		input [6:0] in_y,
		input go_draw,
		output reg finish_draw,
		output reg [7:0] out_x,
		output reg [6:0] out_y,
		output reg [2:0] out_colour
	);

	// Signals for finished drawing each part of pipe.
	wire f1, f2, f3;

	// Output variables for each border module instance.
	wire [7:0] out_x1, out_x2, out_x3;
	wire [6:0] out_y1, out_y2, out_y3;
	wire [2:0] out_colour1, out_colour2, out_colour3;

	// Counter to control FSM state.
	reg [2:0] counter;

	// Control value of counter.
	always@(posedge clk) begin
		// Set finish_draw to be 0 so that we can use this as a singleton.
		finish_draw = 1'b0;

		if (go_draw && (counter == 3'b000)) begin
			counter <= counter + 1'b1;
		end

		// Finished drawing black background.
		if (f1 && (counter == 3'b001)) begin
			counter <= counter + 1'b1;
		end
		
		// Finished drawing green box.
		if (f2 && (counter == 3'b010)) begin
			counter <= counter + 1'b1;
		end

		// Finished drawing black box.
		if (f3 && (counter == 3'b011)) begin
			finish_draw <= 1'b1;
			counter <= 3'd0;
		end
	end

	// Determine the output x/y value based on the state.
	always @(*)
	begin: display
		case (counter)
			3'b001: begin // Black bg.
				out_x = out_x1;
				out_y = out_y1;
				out_colour = out_colour1;
			end
			3'b010: begin // Green box.
				out_x = out_x2;
				out_y = out_y2;
				out_colour = out_colour2;
			end
			3'b011: begin // Black box.
				out_x = out_x3;
				out_y = out_y3;
				out_colour = out_colour3;
			end
			default: begin // Black pixel at top left corner of screen.
				out_x = in_x+7'd4;
				out_y = in_y+7'd4;
				out_colour = colour;
			end
		endcase
	end
	// black bg
	square2 bg(
		.clk(clk),
		.colour(3'b000),
		.in_x(in_x),
		.in_y(in_y),
		.width(8'd7),
		.height(7'd10),
		.go_draw(go_draw),
		.finish_draw(f1),
		.out_x(out_x1),
		.out_y(out_y1),
		.out_colour(out_colour1)
	);
	// green box
	square ur1(
		.clk(clk),
		.colour(colour),
		.in_x(in_x+7'd2),
		.in_y(in_y),
		.width(8'd5),
		.height(7'd7),
		.go_draw(f1),
		.finish_draw(f2),
		.out_x(out_x2),
		.out_y(out_y2),
		.out_colour(out_colour2)
	);
	// black box
	square ur2(
		.clk(clk),
		.colour(3'b000),
		.in_x(in_x+7'd6),
		.in_y(in_y),
		.width(8'd1),
		.height(7'd3),
		.go_draw(f2),
		.finish_draw(f3),
		.out_x(out_x3),
		.out_y(out_y3),
		.out_colour(out_colour3)
	);

endmodule

module down_left_pipe(
		input clk,
		input [2:0] colour,
		input [7:0] in_x,
		input [6:0] in_y,
		input go_draw,
		output reg finish_draw,
		output reg [7:0] out_x,
		output reg [6:0] out_y,
		output reg [2:0] out_colour
	);

	// Signals for finished drawing each part of pipe.
	wire f1, f2, f3;

	// Output variables for each border module instance.
	wire [7:0] out_x1, out_x2, out_x3;
	wire [6:0] out_y1, out_y2, out_y3;
	wire [2:0] out_colour1, out_colour2, out_colour3;

	// Counter to control FSM state.		
	reg [1:0] counter;

	// Control value of counter.
	always@(posedge clk) begin
		// Set finish_draw to be 0 so that we can use this as a singleton.
		finish_draw = 1'b0;

		if (go_draw && (counter == 2'b00)) begin
			counter <= counter + 1'b1;
		end

		// Finished black bg.
		if (f1 && (counter == 2'b01)) begin
			counter <= counter + 1'b1;
		end
		
		// Finished drawing green box.
		if (f2 && (counter == 2'b10)) begin
			counter <= counter + 1'b1;
		end

		// Finished drawing black box.
		if (f3 && (counter == 2'b11)) begin
			finish_draw <= 1'b1;
			// Keep drawing the pipe
			counter <= 2'b00;
		end
	end

	// Determine the output x/y value based on the state.
	always @(*)
	begin: display
		case (counter)
			2'b01: begin // Black bg.
				out_x = out_x1;
				out_y = out_y1;
				out_colour = out_colour1;
			end
			2'b10: begin // green box.
				out_x = out_x2;
				out_y = out_y2;
				out_colour = out_colour2;
			end
			2'b11: begin // black box.
				out_x = out_x3;
				out_y = out_y3;
				out_colour = out_colour3;
			end
			default: begin // Black pixel at top left corner of screen.
				out_x = in_x+7'd4;
				out_y = in_y+7'd4;
				out_colour = colour;
			end
		endcase
	end
	// black bg
	square2 bg(
		.clk(clk),
		.colour(3'b000),
		.in_x(in_x),
		.in_y(in_y),
		.width(8'd7),
		.height(7'd10),
		.go_draw(go_draw),
		.finish_draw(f1),
		.out_x(out_x1),
		.out_y(out_y1),
		.out_colour(out_colour1)
	);
	// green box
	square dl1(
		.clk(clk),
		.colour(colour),
		.in_x(in_x),
		.in_y(in_y+7'd3),
		.width(8'd5),
		.height(7'd7),
		.go_draw(f1),
		.finish_draw(f2),
		.out_x(out_x2),
		.out_y(out_y2),
		.out_colour(out_colour2)
	);
	// black box
	square dl2(
		.clk(clk),
		.colour(3'b000),
		.in_x(in_x),
		.in_y(in_y+7'd7),
		.width(8'd1),
		.height(7'd3),
		.go_draw(f2),
		.finish_draw(f3),
		.out_x(out_x3),
		.out_y(out_y3),
		.out_colour(out_colour3)
	);

endmodule

module up_left_pipe(
		input clk,
		input [2:0] colour,
		input [7:0] in_x,
		input [6:0] in_y,
		input go_draw,
		output reg finish_draw,
		output reg [7:0] out_x,
		output reg [6:0] out_y,
		output reg [2:0] out_colour
	);

	// Signals for finished drawing each part of pipe.
	wire f1, f2, f3;

	// Output variables for each border module instance.
	wire [7:0] out_x1, out_x2, out_x3;
	wire [6:0] out_y1, out_y2, out_y3;
	wire [2:0] out_colour1, out_colour2, out_colour3;

	// Counter to control FSM state.
	reg [1:0] counter;

	// Control value of counter.
	always@(posedge clk) begin
		// Set finish_draw to be 0 so that we can use this as a singleton.
		finish_draw = 1'b0;

		if (go_draw && (counter == 2'b00)) begin
			counter <= counter + 1'b1;
		end

		// Finished drawing black bg.
		if (f1 && (counter == 2'b01)) begin
			counter <= counter + 1'b1;
		end
		
		// Finished drawing green box.
		if (f2 && (counter == 2'b10)) begin
			counter <= counter + 1'b1;
		end

		// Finished drawing black box.
		if (f3 && (counter == 2'b11)) begin
			finish_draw <= 1'b1;
			// Keep drawing the pipe
			counter <= 2'b00;
		end
	end

	// Determine the output x/y value based on the state.
	always @(*)
	begin: display
		case (counter)
			2'b01: begin // Black bg.
				out_x = out_x1;
				out_y = out_y1;
				out_colour = out_colour1;
			end
			2'b10: begin // Green box.
				out_x = out_x2;
				out_y = out_y2;
				out_colour = out_colour2;
			end
			2'b11: begin // Black box.
				out_x = out_x3;
				out_y = out_y3;
				out_colour = out_colour3;
			end
			default: begin // Black pixel at top left corner of screen.
				out_x = in_x+7'd4;
				out_y = in_y+7'd4;
				out_colour = colour;
			end
		endcase
	end
	// black bg
	square2 bg(
		.clk(clk),
		.colour(3'b000),
		.in_x(in_x),
		.in_y(in_y),
		.width(8'd7),
		.height(7'd10),
		.go_draw(go_draw),
		.finish_draw(f1),
		.out_x(out_x1),
		.out_y(out_y1),
		.out_colour(out_colour1)
	);
	// green box
	square ul1(
		.clk(clk),
		.colour(colour),
		.in_x(in_x),
		.in_y(in_y),
		.width(8'd5),
		.height(7'd7),
		.go_draw(f1),
		.finish_draw(f2),
		.out_x(out_x2),
		.out_y(out_y2),
		.out_colour(out_colour2)
	);
	// black box
	square ul2(
		.clk(clk),
		.colour(3'b000),
		.in_x(in_x),
		.in_y(in_y),
		.width(8'd1),
		.height(7'd3),
		.go_draw(f2),
		.finish_draw(f3),
		.out_x(out_x3),
		.out_y(out_y3),
		.out_colour(out_colour3)
	);

endmodule

module hor_pipe(
		input clk,
		input [2:0] colour,
		input [7:0] in_x,
		input [6:0] in_y,
		input go_draw,
		output reg finish_draw,
		output reg [7:0] out_x,
		output reg [6:0] out_y,
		output reg [2:0] out_colour
	);

	// Signals for finished drawing each part of pipe.
	wire f1, f2, f3;

	// Output variables for each border module instance.
	wire [7:0] out_x1, out_x2, out_x3;
	wire [6:0] out_y1, out_y2, out_y3;
	wire [2:0] out_colour1, out_colour2, out_colour3;

	// Counter to control FSM state.
	reg [1:0] counter;

	// Control value of counter.
	always@(posedge clk) begin
		// Set finish_draw to be 0 so that we can use this as a singleton.
		finish_draw = 1'b0;

		if (go_draw && (counter == 2'b00)) begin
			counter <= counter + 1'b1;
		end

		// Finished drawing black bg.
		if (f1 && (counter == 2'b01)) begin
			counter <= counter + 1'b1;
		end
		
		// Finished drawing green box.
		if (f2 && (counter == 2'b10)) begin
			counter <= counter + 1'b1;
		end

		// Finished drawing black box.
		if (f3 && (counter == 2'b11)) begin
			finish_draw <= 1'b1;
			// Keep drawing the pipe
			counter <= 2'b00;
		end
	end

	// Determine the output x/y value based on the state.
	always @(*)
	begin: display
		case (counter)
			2'b01: begin // black bg.
				out_x = out_x1;
				out_y = out_y1;
				out_colour = out_colour1;
			end
			2'b10: begin // Green box.
				out_x = out_x2;
				out_y = out_y2;
				out_colour = out_colour2;
			end
			2'b11: begin // Black box.
				out_x = out_x3;
				out_y = out_y3;
				out_colour = out_colour3;
			end
			default: begin // Black pixel at top left corner of screen.
				out_x = in_x+7'd4;
				out_y = in_y+7'd4;
				out_colour = colour;
			end
		endcase
	end
	// black bg
	square2 bg(
		.clk(clk),
		.colour(3'b000),
		.in_x(in_x),
		.in_y(in_y),
		.width(8'd7),
		.height(7'd10),
		.go_draw(go_draw),
		.finish_draw(f1),
		.out_x(out_x1),
		.out_y(out_y1),
		.out_colour(out_colour1)
	);
	// green box
	square h1(
		.clk(clk),
		.colour(colour),
		.in_x(in_x),
		.in_y(in_y+7'd3),
		.width(8'd7),
		.height(7'd4),
		.go_draw(f1),
		.finish_draw(f2),
		.out_x(out_x2),
		.out_y(out_y2),
		.out_colour(out_colour2)
	);
	// black box
	square h2(
		.clk(clk),
		.colour(3'b000),
		.in_x(in_x),
		.in_y(in_y),
		.width(8'd1),
		.height(7'd1),
		.go_draw(f2),
		.finish_draw(f3),
		.out_x(out_x3),
		.out_y(out_y3),
		.out_colour(out_colour3)
	);

endmodule

module ver_pipe(
		input clk,
		input [2:0] colour,
		input [7:0] in_x,
		input [6:0] in_y,
		input go_draw,
		output reg finish_draw,
		output reg [7:0] out_x,
		output reg [6:0] out_y,
		output reg [2:0] out_colour
	);

	// Signals for finished drawing each part of pipe.
	wire f1, f2, f3;

	// Output variables for each border module instance.
	wire [7:0] out_x1, out_x2, out_x3;
	wire [6:0] out_y1, out_y2, out_y3;
	wire [2:0] out_colour1, out_colour2, out_colour3;

	// Counter to control FSM state.
	reg [1:0] counter;

	// Control value of counter.
	always@(posedge clk) begin
		// Set finish_draw to be 0 so that we can use this as a singleton.
		finish_draw = 1'b0;

		if (go_draw && (counter == 2'b00)) begin
			counter <= counter + 1'b1;
		end

		// Finished drawing black bg.
		if (f1 && (counter == 2'b01)) begin
			counter <= counter + 1'b1;
		end
		
		// Finished drawing green box.
		if (f2 && (counter == 2'b10)) begin
			counter <= counter + 1'b1;
		end

		// Finished drawing black box.
		if (f3 && (counter == 2'b11)) begin
			finish_draw <= 1'b1;
			// Keep drawing the pipe
			counter <= 2'b00;
		end
	end

	// Determine the output x/y value based on the state.
	always @(*)
	begin: display
		case (counter)
			2'b01: begin // black bg.
				out_x = out_x1;
				out_y = out_y1;
				out_colour = out_colour1;
			end
			2'b10: begin // green box.
				out_x = out_x2;
				out_y = out_y2;
				out_colour = out_colour2;
			end
			2'b11: begin // black box.
				out_x = out_x3;
				out_y = out_y3;
				out_colour = out_colour3;
			end
			default: begin // Black pixel at top left corner of screen.
				out_x = in_x+7'd4;
				out_y = in_y+7'd4;
				out_colour = colour;
			end
		endcase
	end
	// black bg
	square2 bg(
		.clk(clk),
		.colour(3'b000),
		.in_x(in_x),
		.in_y(in_y),
		.width(8'd7),
		.height(7'd10),
		.go_draw(go_draw),
		.finish_draw(f1),
		.out_x(out_x1),
		.out_y(out_y1),
		.out_colour(out_colour1)
	);
	// green box
	square v1(
		.clk(clk),
		.colour(colour),
		.in_x(in_x+7'd2),
		.in_y(in_y),
		.width(8'd3),
		.height(7'd10),
		.go_draw(f1),
		.finish_draw(f2),
		.out_x(out_x2),
		.out_y(out_y2),
		.out_colour(out_colour2)
	);
	// black box
	square v2(
		.clk(clk),
		.colour(3'b000),
		.in_x(in_x),
		.in_y(in_y),
		.width(8'd1),
		.height(7'd1),
		.go_draw(f2),
		.finish_draw(f3),
		.out_x(out_x3),
		.out_y(out_y3),
		.out_colour(out_colour3)
	);

endmodule

module pipe_make(
		input clk,
		input [2:0] colour,
		input [7:0] in_x,
		input [6:0] in_y,
		input [7:0] width,
		input [6:0] height,
		input go_draw,
		input [3:0] type,
		output reg finish_draw,
		output reg [7:0] out_x,
		output reg [6:0] out_y,
		output reg [2:0] out_colour
	);
	reg g0, g1, g2, g3 ,g4, g5; // Start/Go signal
	wire f0, f1, f2, f3 ,f4, f5; // Finish signal

	// Store X val
	wire [7:0] out_x0, out_x1, out_x2, out_x3, out_x4, out_x5;

	// Store Y val
	wire [6:0] out_y0, out_y1, out_y2, out_y3, out_y4, out_y5;

	// Store colour
	wire [2:0] out_colour0, out_colour1, out_colour2, out_colour3, out_colour4, out_colour5;

	always @(*)
	begin: display
		case (type)
			3'd0: begin // Vertical pipe.
				g0 = go_draw;
				out_x = out_x0;
				out_y = out_y0;
				out_colour = out_colour0;
				finish_draw = f0;
			end
			3'd1: begin // Horizontal pipe.
				g1 = go_draw;
				out_x = out_x1;
				out_y = out_y1;
				out_colour = out_colour1;
				finish_draw = f1;
			end
			3'd2: begin // up left pipe.
				g2 = go_draw;
				out_x = out_x2;
				out_y = out_y2;
				out_colour = out_colour2;
				finish_draw = f2;
			end
			3'd3: begin // up right pipe.
				g3 = go_draw;
				out_x = out_x3;
				out_y = out_y3;
				out_colour = out_colour3;
				finish_draw = f3;
			end
			3'd4: begin // down left pipe.
				g4 = go_draw;
				out_x = out_x4;
				out_y = out_y4;
				out_colour = out_colour4;
				finish_draw = f4;
			end
			3'd5: begin // down right pipe.
				g5 = go_draw;
				out_x = out_x5;
				out_y = out_y5;
				out_colour = out_colour5;
				finish_draw = f5;
			end
			default: begin // Black pixel at top left corner of screen.
				g0 = go_draw;
				out_x = out_x0;
				out_y = out_y0;
				out_colour = out_colour0;
				finish_draw = f0;
			end
		endcase
	end

	ver_pipe vp(
		.clk(clk),
		.colour(3'b010),
		.in_x(in_x),
		.in_y(in_y),
		.go_draw(g0),
		.finish_draw(f0),
		.out_x(out_x0),
		.out_y(out_y0),
		.out_colour(out_colour0)
	);

	hor_pipe hp(
		.clk(clk),
		.colour(3'b010),
		.in_x(in_x),
		.in_y(in_y),
		.go_draw(g1),
		.finish_draw(f1),
		.out_x(out_x1),
		.out_y(out_y1),
		.out_colour(out_colour1)
	);

	up_left_pipe ulp(
		.clk(clk),
		.colour(3'b010),
		.in_x(in_x),
		.in_y(in_y),
		.go_draw(g2),
		.finish_draw(f2),
		.out_x(out_x2),
		.out_y(out_y2),
		.out_colour(out_colour2)
	);

	up_right_pipe urp(
		.clk(clk),
		.colour(3'b010),
		.in_x(in_x),
		.in_y(in_y),
		.go_draw(g3),
		.finish_draw(f3),
		.out_x(out_x3),
		.out_y(out_y3),
		.out_colour(out_colour3)
	);

	down_left_pipe dlp(
		.clk(clk),
		.colour(3'b010),
		.in_x(in_x),
		.in_y(in_y),
		.go_draw(g4),
		.finish_draw(f4),
		.out_x(out_x4),
		.out_y(out_y4),
		.out_colour(out_colour4)
	);

	down_right_pipe drp(
		.clk(clk),
		.colour(3'b010),
		.in_x(in_x),
		.in_y(in_y),
		.go_draw(g5),
		.finish_draw(f5),
		.out_x(out_x5),
		.out_y(out_y5),
		.out_colour(out_colour5)
	);

endmodule
