// This is still WIP
// the goal is to make a fully functional WD1402

module clkdiv
#(parameter INCLK=50000000, OUTCLK=(2*9600))
(
	input wire inclk,
	output wire outclk
);
	reg [31:0] cnt = 0;
	assign outclk = cnt == INCLK/OUTCLK - 1;
	always @(posedge inclk)
		if(outclk)
			cnt <= 0;
		else
			cnt <= cnt + 32'b1;
endmodule

module uart(
	input wire clk,
	input wire reset,

	input wire uart_clk,
	input wire twostop,

	output wire tx,
	input wire [7:0] tx_data,
	input wire tx_data_clr,
	input wire tx_data_set,
	output wire tx_done,

	input wire rx,
	input wire rx_data_clr,
	output wire [7:0] rx_data,
	output wire rx_active,
	output wire rx_done
);

	reg [2:0] clkdiv;

	always @(posedge clk)
		if(reset)
			clkdiv <= 0;
		else if(uart_clk)
			clkdiv <= clkdiv + 1;

	wire clk_tx0 = clkdiv[2];
	wire clk_rx0 = clkdiv[0];
	reg clk_tx1;
	reg clk_rx1;

	wire tx_clock = ~clk_tx0 & clk_tx1;
	wire rx_clock = ~clk_rx0 & clk_rx1;
	always @(posedge clk) begin
		clk_tx1 <= clk_tx0;
		clk_rx1 <= clk_rx0;
	end

	uart_tx uart_tx(.clk(clk), .reset(reset),
		.tx_clock(tx_clock),
		.twostop(twostop),
		.tx(tx),
		.tx_data(tx_data),
		.tx_data_clr(tx_data_clr),
		.tx_data_set(tx_data_set),
		.tx_done(tx_done));
	uart_rx uart_rx(.clk(clk), .reset(reset),
		.rx_clock(rx_clock),
		.rx(rx),
		.rx_data_clr(rx_data_clr),
		.rx_data(rx_data),
		.rx_active(rx_active),
		.rx_done(rx_done));

endmodule
module uart_tx
(
	input wire clk,
	input wire reset,
	input wire tx_clock,
	input wire twostop,
	output reg tx,
	input wire [8:1] tx_data,
	input wire tx_data_clr,
	input wire tx_data_set,
	output reg tx_done
);
	reg [8:1] tx_buf;
	reg tx_enable = 0;
	reg tx_active = 0;
	reg tx_active0;
	reg tx_div2 = 0;
	reg tx_div20;
	wire stopdone;

	// shift at baudrate
	wire tx_shift = tx_div20 & ~tx_div2;

	// counter for stop bits
	wire [1:0] endcount;
	assign endcount[0] = 1;
	assign endcount[1] = twostop;
	reg [1:0] cnt = 0;
	always @(posedge clk)
		if(tx_active0 & ~tx_active)
			cnt <= 0;
		else if(tx_clock && cnt != endcount)
			cnt <= cnt + 2'b1;
	assign stopdone = cnt == endcount;

	always @(posedge clk) begin
		if(reset) begin
			tx_done <= 1;
		end else begin
			tx_active0 <= tx_active;
			tx_div20 <= tx_div2;

			if(tx_data_clr) begin
				tx_done <= 0;
			end
			if(tx_data_set) begin
				tx_buf <= tx_data;
				tx_enable <= 1;
			end
			if(tx_clock) begin
				if(tx_active)
					tx_div2 <= ~tx_div2;
				if(stopdone & tx_enable)
					tx_active <= 1;
			end
			if(tx_shift) begin
				tx_enable <= 0;
				{ tx_buf, tx } <= { tx_enable, tx_buf };
				if(~tx_enable & tx_buf[8:2] == 0) begin
					tx_active <= 0;
					tx_done <= 1;
				end
			end
			if(~tx_active)
				tx <= 1;
			else if(~tx_active0)
				tx <= 0;
		end
	end
endmodule

module uart_rx
(
	input wire clk,
	input wire reset,
	input wire rx_clock,
	input wire rx,
	input wire rx_data_clr,
	output reg rx_active,
	output reg rx_done,
	output reg [8:1] rx_data
);
	wire rx_shift = rx_4count_rise & ~rx_last_unit;
	reg rx_last_unit = 0;
	reg rx_active0;
	wire rx_4count;
	reg rx_4count0;

	wire rx_space = ~rx;
	wire rx_4count_rise = ~rx_4count0 & rx_4count;
	wire rx_set = ~rx_active0 & rx_active;

	div8 d(.clk(clk),
		.reset(rx_set),
		.cntclk(rx_clock & rx_active),
		.out(rx_4count));

	always @(posedge clk) begin
		if(reset) begin
			rx_active = 0;
			rx_done = 0;
			rx_data = 0;
		end else begin
			rx_4count0 <= rx_4count;
			rx_active0 <= rx_active;

			if(rx_set) begin
				rx_data <= 8'o377;
				rx_last_unit <= 0;
			end
			if(rx_4count_rise & rx_last_unit)
				rx_active <= 0;
			if(rx_shift) begin
				rx_data <= { rx, rx_data[8:2] };
				if(~rx_data[1]) begin
					rx_last_unit <= 1;
					rx_done <= 1;
				end
				if(rx_data[1])
					rx_done <= 0;
				if(~rx_space & (& rx_data))
					rx_active <= 0;
			end
			if(rx_clock)
				if(~rx_active & rx_space)
					rx_active <= 1;
			if(rx_data_clr)
				rx_done <= 0;
		end
	end
endmodule

/*
 * This module divides the clock cntclk by 8.
 */
module div8(
	input wire clk,
	input wire reset,
	input wire cntclk,
	output wire out
);
	reg [2:0] cnt;
	always @(posedge clk)
		if(reset)
			cnt <= 0;
		else if(cntclk)
			cnt <= cnt + 3'b1;
	assign out = cnt[2];
endmodule

