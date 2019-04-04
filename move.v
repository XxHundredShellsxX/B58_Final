module move(
	input clk,
	output [3:0] out_x,
	output [3:0] out_y,
	input [3:0] SW,
	input adv,
	input swap,
	output [2:0] selected_pipe,
	output [2:0] inventory_pipe,
	output [17:0] r0,
	output [17:0] r1,
	output [17:0] r2,
	output [17:0] r3,
	output [17:0] r4,
	output [17:0] r5
 );

	wire ld_increment, ld_init, ld_move, ld_r, ld_swap, ld_tmp, ld_parm;

	movecontrol c0(
		.clk(clk), // CLOCK_50
		.go(adv), //KEY[0]
		.go2(swap),
		.ld_move(ld_move),
		.ld_increment(ld_increment),
		.ld_r(ld_r),
		.ld_init(ld_init),
		.ld_tmp(ld_tmp),
		.ld_swap(ld_swap),
		.ld_parm(ld_parm)
	);

	datapath d0(
		.clk(clk),
		.data_in(SW),
		.r_x(out_x),
		.r_y(out_y),
		.r_sp(selected_pipe),
		.r_ip(inventory_pipe),
		.r0(r0),
		.r1(r1),
		.r2(r2),
		.r3(r3),
		.r4(r4),
		.r5(r5),
		.ld_move(ld_move), .ld_increment(ld_increment), .ld_init(ld_init), .ld_r(ld_r), .ld_tmp(ld_tmp), .ld_swap(ld_swap), .ld_parm(ld_parm)
    );

endmodule


module movecontrol(
	input clk, // CLOCK_50
   input go, //KEY[0]
	input go2, //KEY[1]
   output reg ld_move,
	output reg ld_increment,
	output reg ld_r,
	output reg ld_init,
	output reg ld_tmp,
	output reg ld_swap,
	output reg ld_parm
);
	reg [5:0] current_state, next_state; 

	localparam  S_INIT 			 = 4'd0,
				S_LOAD_MOVE        = 4'd1,
				S_LOAD_MOVE_WAIT   = 4'd2,
				S_CYCLE_0		    = 4'd3,
				S_CYCLE_1		    = 4'd4,
				S_LOAD_SWAP_WAIT   = 4'd5,
				S_CYCLE_2          = 4'd6,
				S_CYCLE_3          = 4'd7,
				S_CYCLE_4			 = 4'd8;
	
	// Next state logic aka our state table
	always@(*)
	begin: state_table 
			case (current_state)
				S_INIT: next_state = S_LOAD_MOVE;
				S_LOAD_MOVE:begin
					if(go)
						next_state = S_LOAD_MOVE_WAIT;
					else if(go2)
						next_state = S_LOAD_SWAP_WAIT;
					else
						next_state = S_LOAD_MOVE;
				end
				S_LOAD_MOVE_WAIT: next_state = go ? S_LOAD_MOVE_WAIT : S_CYCLE_0; // Loop in current state until go signal goes low
				S_CYCLE_0: next_state = S_CYCLE_1;
				S_CYCLE_1: next_state = S_LOAD_MOVE;
				S_LOAD_SWAP_WAIT: next_state = go2 ? S_LOAD_SWAP_WAIT : S_CYCLE_2;
				S_CYCLE_2: next_state = S_CYCLE_3;
				S_CYCLE_3: next_state = S_CYCLE_4;
				S_CYCLE_4: next_state = S_LOAD_MOVE;
			default:     next_state = S_LOAD_MOVE;
		endcase
	end // state_table

	always @(*)
    begin: enable_signals
		// By default make all our signals 0
		ld_move = 1'b0;
		ld_increment = 1'b0;
		ld_init = 1'b0;
		ld_r = 1'b0;
		ld_tmp = 1'b0;
		ld_swap = 1'b0;
		ld_parm = 1'b0;

        case (current_state)
			S_INIT: begin
				ld_init = 1'b1;
			end
			S_LOAD_MOVE: begin
				ld_move = 1'b1;
			end
			S_CYCLE_0: begin
				ld_increment = 1'b1;
			end
			S_CYCLE_1: begin
				ld_r = 1'b1;
			end
			S_CYCLE_2: begin
				ld_tmp = 1'b1;
			end
			S_CYCLE_3: begin
				ld_swap = 1'b1;
			end
			S_CYCLE_4: begin
				ld_parm = 1'b1;
			end
		endcase
	end


	always@(posedge clk)
    begin: state_FFs
        current_state <= next_state;
    end 
endmodule

module datapath(
   input clk,
   input [3:0] data_in,
	output reg [3:0] r_x,
	output reg [3:0] r_y,
	output reg [2:0] r_sp,
	output reg [2:0] r_ip,
	output reg [17:0] r0,
	output reg [17:0] r1,
	output reg [17:0] r2,
	output reg [17:0] r3,
	output reg [17:0] r4,
	output reg [17:0] r5,
	input ld_move, ld_increment, ld_init, ld_r, ld_tmp, ld_swap, ld_parm
    );

	reg [3:0] initial_x;
	reg [3:0] initial_y;
	reg [2:0] dir;
	reg [5:0] index;
	reg [17:0] row0, row1, row2, row3, row4, row5, curr_row;
	reg [2:0] tmp, invent_pipe;
	wire [2:0] curr_pipe;


	always @(*)
	  case (initial_y[3:0])
			4'd0: curr_row = row0;
			4'd1: curr_row = row1;
			4'd2: curr_row = row2;
			4'd3: curr_row = row3;
			4'd4: curr_row = row4;
			4'd5: curr_row = row5;
			default: curr_row = row0;
	  endcase

	take_sig sig(
		.x(initial_x[3:0]), 
		.row(curr_row),
		.val(curr_pipe)
	);

	// Output result register
    always@(posedge clk) begin
		if(ld_init) begin
			initial_x <= 3'd0;
			initial_y <= 3'd0;
			r_sp <= 3'd5;
			r_x <= initial_x;
			r_y <= initial_y;
			invent_pipe <= 3'd2;
			// The row is stored such that it goes from least significant to most significant.
			// 4, 5, 4, 1, 5, 2
			row0 <= 18'b100101100001101010;
			// 0, 0, 2, 5, 4, 3
			row1 <= 18'b000000010101100011;
			// 0, 2, 5, 2, 1, 0
			row2 <= 18'b000010101010001000;
			// 1, 5, 2, 5, 0, 5
			row3 <= 18'b001101010101000101;
			// 5, 2, 1, 1, 5, 3
			row4 <= 18'b101010001001101011;
			// 2, 1, 1, 3, 2, 0
			row5 <= 18'b010001001011010000;
		end
		if(ld_increment) begin
			case (dir)
				// up
				2'b00:
					initial_y <= initial_y - 1;
				// right
				2'b10:
					initial_x <= initial_x + 1;
				// down
				2'b01:
					initial_y <= initial_y + 1;
				// left
				2'b11:
					initial_x <= initial_x - 1;
			endcase
		end
		if(ld_r) begin
			// output x,y,selected and inv pipes
			r_x <= initial_x;
			r_y <= initial_y;
			r_sp <= curr_pipe;
			r_ip <= invent_pipe;
			r0 <= row0;
			r1 <= row1;
			r2 <= row2;
			r3 <= row3;
			r4 <= row4;
			r5 <= row5;
		end
		if(ld_tmp)begin
			// store previous inventory
			tmp <= invent_pipe;
			// set current inventory to selected pipe
			invent_pipe <= curr_pipe;
		end
		if(ld_swap)begin
			// set the grid value to the prev inventory
			case ({initial_y,initial_x}) 
				8'b00000000: row0[2:0] <= tmp; 
				8'b00000001: row0[5:3] <= tmp;
				8'b00000010: row0[8:6] <= tmp; 
				8'b00000011: row0[11:9] <= tmp;
				8'b00000100: row0[14:12] <= tmp; 
				8'b00000101: row0[17:15] <= tmp;
				
				8'b00010000: row1[2:0] <= tmp; 
				8'b00010001: row1[5:3] <= tmp;
				8'b00010010: row1[8:6] <= tmp; 
				8'b00010011: row1[11:9] <= tmp;
				8'b00010100: row1[14:12] <= tmp; 
				8'b00010101: row1[17:15] <= tmp;
				
				8'b00100000: row2[2:0] <= tmp; 
				8'b00100001: row2[5:3] <= tmp;
				8'b00100010: row2[8:6] <= tmp; 
				8'b00100011: row2[11:9] <= tmp;
				8'b00100100: row2[14:12] <= tmp; 
				8'b00100101: row2[17:15] <= tmp;
				
				8'b00110000: row3[2:0] <= tmp; 
				8'b00110001: row3[5:3] <= tmp;
				8'b00110010: row3[8:6] <= tmp; 
				8'b00110011: row3[11:9] <= tmp;
				8'b00110100: row3[14:12] <= tmp; 
				8'b00110101: row3[17:15] <= tmp;
				
				8'b01000000: row4[2:0] <= tmp; 
				8'b01000001: row4[5:3] <= tmp;
				8'b01000010: row4[8:6] <= tmp; 
				8'b01000011: row4[11:9] <= tmp;
				8'b01000100: row4[14:12] <= tmp; 
				8'b01000101: row4[17:15] <= tmp;
				
				8'b01010000: row5[2:0] <= tmp; 
				8'b01010001: row5[5:3] <= tmp;
				8'b01010010: row5[8:6] <= tmp; 
				8'b01010011: row5[11:9] <= tmp;
				8'b01010100: row5[14:12] <= tmp; 
				8'b01010101: row5[17:15] <= tmp;
			endcase
		end
		if(ld_parm)begin
			// ouput inventory and selected after swap
			r_ip <= invent_pipe;
			r_sp <= curr_pipe;
			r0 <= row0;
			r1 <= row1;
			r2 <= row2;
			r3 <= row3;
			r4 <= row4;
			r5 <= row5;
		end
		
    end

	// Registers move with respective input logic
    always@(posedge clk) begin
		if(ld_move) begin
			case (data_in)
				// up
				4'b0001:begin
					dir <= 2'b00;
				end
				// down
				4'b0010:begin
					dir <= 2'b01;
				end
				// right
				4'b0100:begin
					dir <= 2'b10;
				end
				// left
				4'b1000:begin
					dir <= 2'b11;
				end
				default: dir <= 2'b00;
			endcase
		end

    end

endmodule


module take_sig(x, row, val);
	input [3:0] x;
	input [17:0] row;
	output reg [2:0] val;
	
	always @(*)
        case (x)
            4'd0: val = row[2:0];
            4'd1: val = row[5:3];
            4'd2: val = row[8:6];
            4'd3: val = row[11:9];
            4'd4: val = row[14:12];
            4'd5: val = row[17:15];
            default: val = row[2:0];
    endcase
	
endmodule
 
 
 module hex_decoder(hex_digit, segments);
    input [3:0] hex_digit;
    output reg [6:0] segments;
   
    always @(*)
        case (hex_digit)
            4'h0: segments = 7'b100_0000;
            4'h1: segments = 7'b111_1001;
            4'h2: segments = 7'b010_0100;
            4'h3: segments = 7'b011_0000;
            4'h4: segments = 7'b001_1001;
            4'h5: segments = 7'b001_0010;
            4'h6: segments = 7'b000_0010;
            4'h7: segments = 7'b111_1000;
            4'h8: segments = 7'b000_0000;
            4'h9: segments = 7'b001_1000;
            4'hA: segments = 7'b000_1000;
            4'hB: segments = 7'b000_0011;
            4'hC: segments = 7'b100_0110;
            4'hD: segments = 7'b010_0001;
            4'hE: segments = 7'b000_0110;
            4'hF: segments = 7'b000_1110;   
            default: segments = 7'h7f;
        endcase
endmodule