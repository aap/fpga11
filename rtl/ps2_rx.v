module ps2_rx(
	input wire clk,
	input wire reset,
	input wire ps2_clk,
	input wire ps2_data,
	output wire [7:0] data,
	output wire done
);

	reg [7:0] clkhist;
	wire clklow = ~(|clkhist);
	reg prev_clklow = 0;

	reg active = 0;
	reg [10:0] buffer;

	wire falling_edge;
	edgedet clkedge(clk, reset, clklow, falling_edge);
	always @(posedge clk or posedge reset) begin
		if(reset) begin
			buffer <= 0;
			active <= 0;
		end else begin
			clkhist <= {clkhist[6:0], ps2_clk};

			if(falling_edge) begin
				if(~active) begin
					buffer <= 'o2000;
					active <= 1;
				end else begin
					buffer <= {ps2_data, buffer[10:1]};
				end
			end else if(done)
				active <= 0;
		end
	end

	assign data = buffer[8:1];
	assign done = buffer[0];
endmodule

