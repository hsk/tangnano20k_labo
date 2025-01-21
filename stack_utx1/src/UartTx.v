`ifndef INCLUDE
module UartTx(input clk, [7:0] din,input wr_en, output tx_busy, reg tx_p);
  initial begin tx_p = 1; cnt = 0; st = IDLE; end
  parameter clk_freq = 27000000, uart_freq = 115200;
  localparam TX_CLK_MAX = clk_freq / uart_freq - 1;
  localparam IDLE = 0, START = 1, DATA = 2, STOP = 3;
  reg [7:0] din1, din2; reg wr_en1; reg [2:0] p; reg [1:0] st;
  reg [$clog2(TX_CLK_MAX+1)+1:0] cnt;
  wire tx; assign tx = cnt == 0;
  assign tx_busy = st != IDLE;
  always @(posedge clk) begin
    din1 <= din; wr_en1 <= wr_en;
    cnt <= cnt>=TX_CLK_MAX ? 0 : cnt+1;
    case (st)
    IDLE: if (wr_en1) begin st <= START; din2 <= din1; p <= 0; end
    START:if (tx) begin tx_p <= 0; st <= DATA; end
    DATA: if (tx) begin tx_p <= din2[p];
                        if (p==7) st <= STOP; else p <= p+1; end
    STOP: if (tx) begin tx_p <= 1; st <= IDLE; end
    endcase
  end
endmodule
`else
	parameter STR = 0;
	parameter HEX = 1;

	wire print_clk;

	reg[7:0] print_seq[255:0];
	reg[7:0] seq_head=8'd0;
	reg[7:0] seq_tail=8'd0;

	reg[1023:0] print_buffer=1024'h0;
	reg[6:0] print_buffer_pointer = 7'd0;

	reg last_spin_state=0;
	reg spin_state=0;
	reg[6:0] print_length;
	reg print_type;

	parameter PRINT_IDLE_STATE = 0;
	parameter PRINT_WAIT_STATE = 1;
	parameter PRINT_WORK_STATE = 2;
	parameter PRINT_CONV_STATE = 3;
	reg[1:0] print_state=PRINT_IDLE_STATE;

	wire[7:0] hex_lib[15:0];
	assign hex_lib[4'h0] = 8'h30;
	assign hex_lib[4'h1] = 8'h31;
	assign hex_lib[4'h2] = 8'h32;
	assign hex_lib[4'h3] = 8'h33;
	assign hex_lib[4'h4] = 8'h34;
	assign hex_lib[4'h5] = 8'h35;
	assign hex_lib[4'h6] = 8'h36;
	assign hex_lib[4'h7] = 8'h37;
	assign hex_lib[4'h8] = 8'h38;
	assign hex_lib[4'h9] = 8'h39;
	assign hex_lib[4'hA] = 8'h61;
	assign hex_lib[4'hB] = 8'h62;
	assign hex_lib[4'hC] = 8'h63;
	assign hex_lib[4'hD] = 8'h64;
	assign hex_lib[4'hE] = 8'h65;
	assign hex_lib[4'hF] = 8'h66;

	//always block to handle the print task
	always@(posedge print_clk)begin
		last_spin_state<=spin_state;

		case(print_state)
			PRINT_IDLE_STATE:begin//IDLE, check if spin_state is changed
				if(spin_state!=last_spin_state)begin
					print_state<=PRINT_WAIT_STATE;
				end
			end
			PRINT_WAIT_STATE:begin//WAIT, wait 1 clk then start to fill print_seq
				print_state<=PRINT_WORK_STATE;
				if(print_type==STR)
					print_buffer_pointer<=7'd127;
				else
					print_buffer_pointer<=7'd127;
			end
			PRINT_WORK_STATE:begin//WORK, fill print_seq
				if(print_type==STR)begin//type is string, fill as it is
					if(print_buffer[
						print_buffer_pointer*8+7 -: 8
					]!=8'd0)begin
						print_seq[seq_tail]<=print_buffer[
							print_buffer_pointer*8+7 -: 8
						];
						seq_tail<=seq_tail+8'd1;
					end else begin
						print_state<=PRINT_IDLE_STATE;
					end

					print_buffer_pointer<=print_buffer_pointer-7'd1;

					if(print_buffer_pointer==7'd0)begin
						print_state<=PRINT_IDLE_STATE;
					end
				end else begin //type is data, fill as hex
					print_seq[seq_tail]<=hex_lib[print_buffer[
						print_buffer_pointer*8+7 -: 4
					]];
					seq_tail<=seq_tail+8'd1;

					//another convert clock cycle is needed
					print_state<=PRINT_CONV_STATE;
				end
			end
			PRINT_CONV_STATE:begin//CONV, convert data to hex
				print_seq[seq_tail]<=hex_lib[print_buffer[
					print_buffer_pointer*8+3 -: 4
				]];
				seq_tail<=seq_tail+8'd1;
				print_state<=PRINT_WORK_STATE;

				print_buffer_pointer<=print_buffer_pointer-7'd1;

				if(print_buffer_pointer==print_length)
					print_state<=PRINT_IDLE_STATE;
			end
		endcase
	end

	reg uart_en;
	wire uart_bz;
	wire uart_txp;
	UartTx tx(print_clk, print_seq[seq_head], uart_en, uart_bz, uart_txp);

	//always block to send the data via UART
	always@(posedge print_clk)begin
		uart_en<=1'b0;
		if(uart_en && uart_bz)
			seq_head<=seq_head+8'd1;
		if(seq_head!=seq_tail && !uart_bz)
			uart_en<=1'b1;
	end

	task int_print(
		input[1023:0] strin,//max 128 characters
		input[7:0] type_length //8bit width to show 128 characters
	);
	begin
		if(print_state==PRINT_IDLE_STATE)begin//print when busy will be ignored
			spin_state<=~spin_state;

			if(type_length==STR)begin
				print_type<=STR;
			end else begin
				print_type<=HEX;
				print_length<=8'd128-type_length;
			end

			print_buffer<=strin;
		end
	end

	`define print(a,b) int_print({>>{a}},b)
	endtask
	function [15:0] hexf ([7:0] data);
		hexf = {hex_lib[data[7:4]],hex_lib[data[3:0]]};
	endfunction
`endif
