`default_nettype none

module pseudo_vt52(
	input wire clk,
	input wire reset,
	input wire invert_video,
	input wire bell_inverts,

	output wire HDMI_TX_CLK,
	output wire [23:0] HDMI_TX_D,
	output wire HDMI_TX_DE,
	output wire HDMI_TX_HS,
	input  wire HDMI_TX_INT,
	output wire HDMI_TX_VS,
	output wire hdmi_ready,

	output wire I2C_SCL,
	inout  wire I2C_SDA,

	input  wire UART_RX,
	output wire UART_TX,

	input wire ps2_clk,
	input wire ps2_data
);
	wire clock50 = clk;

	wire [10:0] screenaddr;
	addressmap addrmap(screenX, screenY, screenaddr);

	reg [7:0] wrdata;
	wire [7:0] data_a;
	wire [7:0] data_b;
	reg wren = 0;

	/* VT52-like terminal */
	reg [6:0] curX = 0;
	reg [4:0] curY = 0;
	reg [6:0] screenX = 0;
	reg [4:0] screenY = 0;
	reg [4:0] topline = 0;
	/* states */
	reg cadX = 0;
	reg cadY = 0;
	reg esc = 0;
	reg scroll = 0;
	reg clrline = 1;
	reg clrscreen = 1;
	reg bell = 0;

	wire [6:0] curXINC = curX == 79 ? curX : curX+1;
	wire [4:0] curYINC = curY == 23 ? curY : curY+1;
	wire [6:0] curXDEC = curX == 0 ? curX : curX-1;
	wire [4:0] curYDEC = curY == 0 ? curY : curY-1;
	wire [6:0] curY_mem = curY+topline <= 23 ? curY+topline : curY+topline-24;
	wire [4:0] screenYINC = screenY == 23 ? 0 : screenY + 1;
	always @(posedge clk or posedge reset) begin
		if(reset) begin
			curX <= 0;
			curY <= 0;
			screenX <= 0;
			screenY <= 0;
			topline <= 0;
			cadX <= 0;
			cadY <= 0;
			esc <= 0;
			scroll <= 0;
			clrline <= 1;
			clrscreen <= 1;
			bell <= 0;
		end else begin
			if(gotchar) begin
				if(cadY) begin
					// TODO: figure out the real logic
					if(rx_data >= 'o40 && rx_data < 'o70)
						curY <= rx_data[4:0];
					cadY <= 0;
					cadX <= 1;
				end else if(cadX) begin
					// TODO: figure out the real logic
					if(rx_data >= 'o40)
						curX <= rx_data - 'o40;
					if(rx_data >= 'o160)
						curX <= 79;
					cadX <= 0;
				end else if(esc) begin
					case(rx_data)
					8'o101: curY <= curYDEC;
					8'o102: curY <= curYINC;
					8'o103: curX <= curXINC;
					8'o104: curX <= curXDEC;
					8'o110: begin
						curX <= 0;
						curY <= 0;
					end
					8'o111: begin
						curY <= curYDEC;
						if(curY == 0) begin
							scroll <= 1;
							topline <= topline == 0 ? 23 : topline-1;
						end
					end
					8'o112: begin
						screenX <= curX;
						screenY <= curY_mem;
						clrline <= 1;
						clrscreen <= 1;
					end
					8'o113: begin
						screenX <= curX;
						screenY <= curY_mem;
						clrline <= 1;
					end
					8'o131: cadY <= 1;
					endcase
					esc <= 0;
				end else if(rx_data <'o40) begin
					case(rx_data)
					8'o007: bell <= ~bell;
					8'o010: curX <= curXDEC;
					8'o011:
						if(curX < 72)
							curX <= {curX[6:3], 3'b000} + 8;
						else
							curX <= curXINC;
					8'o012: begin
						curY <= curYINC;
						// scroll down
						if(curY == 23) begin
							scroll <= 1;
							topline <= topline == 23 ? 0 : topline+1;
						end
					end
					8'o015: curX <= 0;
					8'o033: esc <= 1;
					endcase
				end else if(rx_data != 'o177) begin
					wren <= 1;
					wrdata <= rx_data;
					screenX <= curX;
					screenY <= curY_mem;
					curX <= curXINC;
				end
			end

			if(scroll) begin
				scroll <= 0;
				screenX <= 0;
				screenY <= curY_mem;
				clrline <= 1;
			end

			// clear screen by clearing successive lines
			if(clrscreen & ~clrline) begin
				screenX <= 0;
				screenY <= screenYINC;
				if(screenYINC == topline)
					clrscreen <= 0;
				else
					clrline <= 1;
			end

			// clear line
			if(clrline) begin
				if(wren) begin
					// clr done, increment or stop
					screenX <= screenX + 1;
					if(screenX == 79)
						clrline <= 0;
				end else begin
					wren <= 1;
					wrdata <= 0;
				end
			end

			if(wren)
				wren <= 0;
		end
	end
	/* TODO: this probably doesn't have to be dual ported */
	wire	[10:0]  address_b;
	mem screenmem(.address_a(screenaddr),
		.address_b(address_b),
		.clock(clk),
		.data_a(wrdata),
		.data_b(0),
		.wren_a(wren),
		.wren_b(0),
		.q_a(data_a),
		.q_b(data_b));

	/* need 54mhz clock for 720x480@60hz */
	wire clock54, locked;
	pll54 pll54(
	  .refclk(clock50),
	  .rst(reset),

	  .outclk_0(clock54),
	  .locked(locked)
	);
	/* video signal generator */
	videogen videogen(
		.clock      (clock54),
		.reset      (~locked),

		// terminal screen
		.curX(curX),
		.curY(curY_mem),
		.topline(topline),
		.invert(invert_video ^ (bell & bell_inverts)),
		.screenmem_addr(address_b),
		.screenmem_data(data_b),

		// HDMI output
		.hsync      (HDMI_TX_HS),
		.vsync      (HDMI_TX_VS),
		.dataEnable (HDMI_TX_DE),
		.vclk       (HDMI_TX_CLK),
		.RGBchannel (HDMI_TX_D)
	);

	/* HDMI config */
	I2C_HDMI_Config #(
	  .CLK_Freq (50000000), // 50MHz
	  .I2C_Freq (20000)    // 20kHz for i2c clock
	)
	I2C_HDMI_Config (
	  .iCLK        (clock50),
	  .iRST_N      (~reset),
	  .I2C_SCLK    (I2C_SCL),
	  .I2C_SDAT    (I2C_SDA),
	  .HDMI_TX_INT (HDMI_TX_INT),
	  .READY       (hdmi_ready)
	);







	/* UART */
	wire uart_clk;
	wire tx_send;
	wire tx_clr = 0;
	wire tx_done;
	wire [7:0] rx_data_8b;
	wire [7:0] rx_data = rx_data_8b[6:0];
	wire rx_active;
	wire rx_done;
	clkdiv #(50000000, 9600*16) uart_clkdiv(clock50, uart_clk);
	uart uart(.clk(clock50), .reset(reset),
		.uart_clk(uart_clk),
		.twostop(1'b0),

		.tx(UART_TX),
		.tx_data(kbd_ascii),
		.tx_data_clr(tx_clr),
		.tx_data_set(tx_send),
		.tx_done(tx_done),

		.rx(UART_RX),
		.rx_data_clr(1'b0),
		.rx_data(rx_data_8b),
		.rx_active(rx_active),
		.rx_done(rx_done)
	);

	wire gotchar;
	edgedet recv(clk, reset, rx_done, gotchar);




	/* PS/2 keyboard */
	wire [7:0] kbd_data;
	wire kbd_done;
	ps2_rx ps2_rx(.clk(clk), .reset(reset),
		.ps2_clk(ps2_clk),
		.ps2_data(ps2_data),
		.data(kbd_data),
		.done(kbd_done));

	wire [6:0] kbd_ascii;
	kbdhandler kbdhandler(
		.clk(clk),
		.reset(reset),
		.newdata(kbd_done),
		.scancode(kbd_data),
		.sendchar(tx_send),
		.ascii(kbd_ascii));

endmodule
