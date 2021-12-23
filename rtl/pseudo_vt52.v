`default_nettype none

module pseudo_vt52(
	input wire clock50,
	input wire async_reset,
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
	/* need 54mhz clock for 720x480@60hz */
	wire clock54, locked;
	pll54 pll54(
	  .refclk(clock50),
	  .rst(async_reset),

	  .outclk_0(clock54),
	  .locked(locked)
	);
	wire reset;
	syncreset syncreset(clock54, async_reset | ~locked, reset);
	wire rx;
	syncsignal rxsyn(clock54, UART_RX, rx);

	wire [10:0] screenaddr;
	addressmap addrmap(screenX, screenY, screenaddr);

	reg [6:0] wrdata;
	wire [6:0] data_a;
	wire [6:0] data_b;
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
	reg graph = 0;
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
	always @(posedge clock54) begin
		if(reset) begin
			curX <= 0;
			curY <= 0;
			screenX <= 0;
			screenY <= 0;
			topline <= 0;
			cadX <= 0;
			cadY <= 0;
			esc <= 0;
			graph <= 0;
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
					7'o101: curY <= curYDEC;
					7'o102: curY <= curYINC;
					7'o103: curX <= curXINC;
					7'o104: curX <= curXDEC;
					7'o106: graph <= 1;
					7'o107: graph <= 0;
					7'o110: begin
						curX <= 0;
						curY <= 0;
					end
					7'o111: begin
						curY <= curYDEC;
						if(curY == 0) begin
							scroll <= 1;
							topline <= topline == 0 ? 23 : topline-1;
						end
					end
					7'o112: begin
						screenX <= curX;
						screenY <= curY_mem;
						clrline <= 1;
						clrscreen <= 1;
					end
					7'o113: begin
						screenX <= curX;
						screenY <= curY_mem;
						clrline <= 1;
					end
					7'o131: cadY <= 1;
					endcase
					esc <= 0;
				end else if(rx_data <'o40) begin
					case(rx_data)
					7'o007: bell <= ~bell;
					7'o010: curX <= curXDEC;
					7'o011:
						if(curX < 72)
							curX <= {curX[6:3], 3'b000} + 8;
						else
							curX <= curXINC;
					7'o012: begin
						curY <= curYINC;
						// scroll down
						if(curY == 23) begin
							scroll <= 1;
							topline <= topline == 23 ? 0 : topline+1;
						end
					end
					7'o015: curX <= 0;
					7'o033: esc <= 1;
					endcase
				end else if(rx_data != 'o177) begin
					wren <= 1;
					if(graph & (rx_data >= 'o136))
						wrdata <= rx_data - 'o137;
					else
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
		.clock(clock54),
		.data_a(wrdata),
		.data_b(0),
		.wren_a(wren),
		.wren_b(0),
		.q_a(data_a),
		.q_b(data_b));

	/* video signal generator */
	videogen videogen(
		.clock      (clock54),
		.reset      (reset),

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
	  .CLK_Freq (54000000), // 54MHz
	  .I2C_Freq (20000)    // 20kHz for i2c clock
	)
	I2C_HDMI_Config (
	  .iCLK        (clock54),
	  .iRST_N      (~reset),
	  .I2C_SCLK    (I2C_SCL),
	  .I2C_SDAT    (I2C_SDA),
	  .HDMI_TX_INT (HDMI_TX_INT),
	  .READY       (hdmi_ready)
	);







	/* UART */
	wire uart_clk;
	wire tx_send;
	wire [7:0] rx_data_8b;
	wire [6:0] rx_data = rx_data_8b[6:0];
	wire rx_done;
	clkdiv #(54000000, 9600*16) uart_clkdiv(clock54, uart_clk);
	wire tx_done;
	wire tre;
	uart1402 uart1402(.clk(clock54), .reset(reset),
		.tr(kbd_ascii),
		.thrl(tx_send),
		.tro(UART_TX),
		.trc(uart_clk),
		.thre(tx_done),
		.tre(tre),

		.rr(rx_data_8b),
		.rrd(1'b0),
		.ri(rx),
		.rrc(uart_clk),
		.dr(rx_done),
		.drr(gotchar),
//		.oe(or_err),
//		.fe(fr_err),
//		.pe(p_err),
		.sfd(1'b0),

		.crl(1'b1),
		// jumpers
		.pi(1'b1),	// no parity
		.epe(1'b1),	// even parity
		.sbs(1'b0),	// one stop bit
		.wls1(1'b1),	// 8 data bits
		.wls2(1'b1)
	);

	wire gotchar;
	edgedet2 recv(clock54, reset, rx_done, gotchar);


	/* PS/2 keyboard */
	wire [7:0] kbd_data;
	wire kbd_done;
	ps2_rx ps2_rx(.clk(clock54), .reset(reset),
		.ps2_clk(ps2_clk),
		.ps2_data(ps2_data),
		.data(kbd_data),
		.done(kbd_done));

	wire [6:0] kbd_ascii;
	kbdhandler kbdhandler(
		.clk(clock54),
		.reset(reset),
		.newdata(kbd_done),
		.scancode(kbd_data),
		.sendchar(tx_send),
		.ascii(kbd_ascii));

endmodule
