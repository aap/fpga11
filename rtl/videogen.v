/* Generate a 800x600@60hz VGA signal
 * The screen memory is 80x24 bytes.
 * Also blink the cursor.
 */
module videogen(
	input clock, reset,

	input wire [6:0] curX,
	input wire [4:0] curY,
	input wire [4:0] topline,
	input wire invert,
	output wire [10:0] screenmem_addr,
	input wire [7:0] screenmem_data,

	output wire hsync, vsync,
	output wire dataEnable,
	output reg vclk,
	output [23:0] RGBchannel
);

	reg [10:0] pixelH;
	reg [9:0] pixelV;

	initial begin
		pixelH     = 0;
		pixelV     = 0;
	end
	always @(posedge clock or posedge reset) begin
		if(reset) begin
			pixelH <= 0;
			pixelV <= 0;
		end else if(~vclk) begin
			if(pixelH==857) begin
				pixelH <= 0;
				if(pixelV==524)
					pixelV <= 0;
				else
					pixelV <= pixelV + 1;
			end else
				pixelH <= pixelH + 1;
		end
	end
	assign hsync = pixelH>=736 && pixelH<798;
	assign vsync = pixelV>=489 && pixelV<495;
	wire validH = pixelH<720;
	wire validV = pixelV<480;
	assign dataEnable = validH && validV;

	initial vclk = 0;
	always @(posedge clock or posedge reset) begin
		if(reset) vclk <= 0;
		else      vclk <= ~vclk;
	end

	addressmap addrmap(screenX, screenY, screenmem_addr);

	reg [6:0] chars[0:1024-1];
	reg [8:0] vsr;	// video shift reg

	reg [6:0] lastX;
	reg [6:0] screenX;
	reg [4:0] screenY;
	reg [3:0] charX;
	reg [4:0] charY;
	reg [7:0] membuf;
	wire hsync_start = pixelH == 736;
	wire hsync_mid = pixelH == 760;
	wire hsync_end = pixelH == 790;
	initial begin
//		$readmemh("chars.rom", chars);
		$readmemh("vt52char.rom", chars);
	end
	wire [10:0] charaddr = {membuf[6:0], charY[3:1]};
//	wire [9:0] charline = {chars[charaddr], 2'b0} | {chars[charaddr], 1'b0};
	wire [8:0] charline = charY[4] ? 0 : {1'b0, chars[charaddr], 1'b0};
	wire fetch = dataEnable && charX==8 || hsync_mid || hsync_end;
	wire doblink = blinkcnt[4] && (charY[4:1] == 8) && lastX == curX && screenY == curY;
	reg [4:0] blinkcnt;
	always @(posedge clock or posedge reset) begin
		if(reset) begin
			charX <= 0;
			charY <= 0;
			screenX <= 0;
			screenY <= 0;
			blinkcnt <= 0;
		end else if(~vclk) begin
			if(dataEnable) begin
				if(~fetch) begin
					charX <= charX + 1;
					vsr <= {vsr[7:0], 1'b0};
				end
			end

			// end of scanline, setup next one
			if(hsync_start) begin
				screenX <= 0;
				if(validV) begin
					// move down one scanline
					if(charY == 19) begin
						charY <= 0;
						if(screenY == 23)
							screenY <= 0;
						else
							screenY <= screenY + 1;
					end else begin
						charY <= charY + 1;
					end
				end else begin
					charY <= 0;
					screenY <= topline;
				end

				if(pixelV == 480)
					blinkcnt <= blinkcnt + 1;
			end

			if(fetch) begin
				charX <= 0;
				if(doblink)
					vsr <= 9'b011111111;
				else
					vsr <= charline;
				membuf <= screenmem_data;
				lastX <= screenX;
				screenX <= screenX + 1;
			end
		end
	end

	assign RGBchannel[23:16] = vsr[8]==invert ? 0 : 255;
	assign RGBchannel [15:8] = vsr[8]==invert ? 0 : 255;
	assign RGBchannel  [7:0] = vsr[8]==invert ? 0 : 255;
endmodule

// address mapping like VT52
module addressmap(
	input wire [6:0] X,
	input wire [4:0] Y,
	output wire [10:0] address
);
	wire outside = (&Y[4:3]) | X[6];
	assign address = outside ? {Y[0], 2'b11, Y[2:1], Y[4:3], X[3:0]} : { Y[0], Y[4:1], X[5:0]};
endmodule

