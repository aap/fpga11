/* This translates PS/2 scancodes to ASCII characters.
 * It is rather barebones right now but sufficient for now. */
module kbdhandler(
	input wire clk,
	input wire reset,

	input wire newdata,
	input wire [7:0] scancode,

	output reg sendchar,
	output wire [6:0] ascii
);

	wire scanpulse;
	edgedet data_edge(clk, reset, newdata, scanpulse);

	reg ext = 0;
	reg down = 1;
	reg shift = 0;
	reg ctrl = 0;
	reg alt = 0;

	always @(posedge clk or posedge reset) begin
		if(reset) begin
			sendchar <= 0;

			ext = 0;
			down = 1;
			shift = 0;
			ctrl = 0;
			alt = 0;
		end else begin
			if(scanpulse) begin
				if(scancode == 'hF0) begin
					down <= 0;
				end else if(scancode == 'hE0) begin
					ext <= 1;
				end else begin
					down <= 1;
					ext <= 0;
					if(scancode == 'h12 || scancode == 'h59)
						shift <= down;
					else if(scancode == 'h14 || scancode == 'h58)
						ctrl <= down;
					else if(scancode == 'h11)
						alt <= down;

					if(~invalid)
						sendchar <= down;
				end
			end
			if(sendchar)
				sendchar <= 0;
		end
	end

	wire invalid;
	scan2ascii scan2ascii(.scan(scancode),
		.shift(shift), .ctrl(ctrl), .ascii(ascii), .invalid(invalid));
endmodule

module scan2ascii(
	input wire [7:0] scan,
	input wire shift,
	input wire ctrl,
	output wire [6:0] ascii,
	output reg invalid
);
	reg [7:0] base;
	always @(*) begin
		invalid <= 0;
		base <= 0;
		if(shift) begin
			case(scan)
			8'h0E: base <= 8'h7E;	// `~
			8'h4E: base <= 8'h5F;	// -_
			8'h55: base <= 8'h2B;	// =+
			8'h66: base <= 8'h7F;	// BS	TODO: probably get rid of this
			8'h0D: base <= 8'h09;	// TAB
			8'h54: base <= 8'h7B;	// [{
			8'h5B: base <= 8'h7D;	// ]}
			8'h5D: base <= 8'h7C;	// \|
			8'h4C: base <= 8'h3A;	// ;:
			8'h52: base <= 8'h22;	// '"
			8'h5A: base <= 8'h0D;	// CR
			8'h41: base <= 8'h3C;	// ,<
			8'h49: base <= 8'h3E;	// .>
			8'h4A: base <= 8'h3F;	// /?
			8'h76: base <= 8'h1B;	// ESC
			8'h29: base <= 8'h20;	// space
			// 0-9
			8'h45: base <= 8'h29;
			8'h16: base <= 8'h21;
			8'h1E: base <= 8'h40;
			8'h26: base <= 8'h23;
			8'h25: base <= 8'h24;
			8'h2E: base <= 8'h25;
			8'h36: base <= 8'h5E;
			8'h3D: base <= 8'h26;
			8'h3E: base <= 8'h2A;
			8'h46: base <= 8'h28;
			// A-Z
			8'h1C: base <= 8'h41;
			8'h32: base <= 8'h42;
			8'h21: base <= 8'h43;
			8'h23: base <= 8'h44;
			8'h24: base <= 8'h45;
			8'h2B: base <= 8'h46;
			8'h34: base <= 8'h47;
			8'h33: base <= 8'h48;
			8'h43: base <= 8'h49;
			8'h3B: base <= 8'h4A;
			8'h42: base <= 8'h4B;
			8'h4B: base <= 8'h4C;
			8'h3A: base <= 8'h4D;
			8'h31: base <= 8'h4E;
			8'h44: base <= 8'h4F;
			8'h4D: base <= 8'h50;
			8'h15: base <= 8'h51;
			8'h2D: base <= 8'h52;
			8'h1B: base <= 8'h53;
			8'h2C: base <= 8'h54;
			8'h3C: base <= 8'h55;
			8'h2A: base <= 8'h56;
			8'h1D: base <= 8'h57;
			8'h22: base <= 8'h58;
			8'h35: base <= 8'h59;
			8'h1A: base <= 8'h5A;
			default:
				invalid <= 1;
			endcase
		end else begin
			case(scan)
			8'h0E: base <= 8'h60;	// `~
			8'h4E: base <= 8'h2D;	// -_
			8'h55: base <= 8'h3D;	// =+
			8'h66: base <= 8'h08;	// BS
			8'h0D: base <= 8'h09;	// TAB
			8'h54: base <= 8'h5B;	// [{
			8'h5B: base <= 8'h5D;	// ]}
			8'h5D: base <= 8'h5C;	// \|
			8'h4C: base <= 8'h3B;	// ;:
			8'h52: base <= 8'h27;	// '"
			8'h5A: base <= 8'h0D;	// CR
			8'h41: base <= 8'h2C;	// ,<
			8'h49: base <= 8'h2E;	// .>
			8'h4A: base <= 8'h2F;	// /?
			8'h76: base <= 8'h1B;	// ESC
			8'h29: base <= 8'h20;	// space
			// 0-9
			8'h45: base <= 8'h30;
			8'h16: base <= 8'h31;
			8'h1E: base <= 8'h32;
			8'h26: base <= 8'h33;
			8'h25: base <= 8'h34;
			8'h2E: base <= 8'h35;
			8'h36: base <= 8'h36;
			8'h3D: base <= 8'h37;
			8'h3E: base <= 8'h38;
			8'h46: base <= 8'h39;
			// A-Z
			8'h1C: base <= 8'h61;
			8'h32: base <= 8'h62;
			8'h21: base <= 8'h63;
			8'h23: base <= 8'h64;
			8'h24: base <= 8'h65;
			8'h2B: base <= 8'h66;
			8'h34: base <= 8'h67;
			8'h33: base <= 8'h68;
			8'h43: base <= 8'h69;
			8'h3B: base <= 8'h6A;
			8'h42: base <= 8'h6B;
			8'h4B: base <= 8'h6C;
			8'h3A: base <= 8'h6D;
			8'h31: base <= 8'h6E;
			8'h44: base <= 8'h6F;
			8'h4D: base <= 8'h70;
			8'h15: base <= 8'h71;
			8'h2D: base <= 8'h72;
			8'h1B: base <= 8'h73;
			8'h2C: base <= 8'h74;
			8'h3C: base <= 8'h75;
			8'h2A: base <= 8'h76;
			8'h1D: base <= 8'h77;
			8'h22: base <= 8'h78;
			8'h35: base <= 8'h79;
			8'h1A: base <= 8'h7A;
			default:
				invalid <= 1;
			endcase
		end
	end
	assign ascii = ctrl ? base[4:0] : base[6:0];
endmodule
