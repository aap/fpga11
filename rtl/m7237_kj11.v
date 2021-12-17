module m7237_kj11(
	input wire clk,
	input wire reset,

	input wire init,
	input wire [15:0] dmux,
	input wire [15:0] ba,
	output wire [15:0] bus_d_out,
	input wire bc1,
	input wire dout_high,
	input wire adrs_777774,
	input wire ckovf,
	input wire ba07_05_1,
	output wire eovfl,
	output wire eovfl_stop
);
	reg [15:8] slr;

	assign bus_d_out[15:8] = {8{(adrs_777774&~bc1)}} & slr;
	assign bus_d_out[7:0] = 0;
	wire eq = ba[15:8] == slr;
	wire lt = ba[15:8] < slr;
	assign eovfl = ckovf & eq & ba07_05_1;
	assign eovfl_stop = lt | eq & ~ba07_05_1;

	wire clk_slr;
	edgedet2 slr_clk(clk, reset, dout_high & adrs_777774, clk_slr);
	always @(posedge clk) begin
		if(clk_slr)
			slr <= dmux[15:8];
		if(init)
			slr <= 0;
	end

endmodule

