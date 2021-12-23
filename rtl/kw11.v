/*
 * This is not an accurate transcription of the KW11-L
 * but hopefully it's compatible
 */

module kw11
#(parameter ADDR='o777546, VEC='o100, FREQ=60)
(
	input wire clk,
	input wire reset,

	input wire bus_init,
	input wire [15:0] bus_d,
	input wire [17:0] bus_addr,
	input wire bus_c0,
	input wire bus_c1,
	input wire bus_bbsy,
	input wire bus_msyn,
	input wire bus_intr,
	output wire [7:4] bus_br,
	input wire bus_ssyn,
	input wire bus_sack,
	input wire [7:4] bus_bg_in,

	output wire bus_ssyn_out,
	output wire bus_sack_out,
	output wire bus_bbsy_out,
	output wire bus_intr_out,
	output wire [15:0] bus_d_out,
	output wire [7:4] bus_bg_out
);

	wire select = bus_msyn & (bus_addr[17:1] == ADDR[17:1]);
	reg [15:0] ssyndly;	// TODO: SENSITIVE to clock
	always @(posedge clk) ssyndly <= {ssyndly[14:0], select};
	assign bus_ssyn_out = ssyndly[14];
	wire in = ~bus_c1;
	wire out_low = ~in & (~bus_c0 | ~bus_addr[0]);
	wire out_high = ~in & (~bus_c0 | bus_addr[0]);

	wire bg_in = bus_bg_in[6];
	wire bg_out;
	wire br_a, br_b;
	wire bus_int_out;
	wire master_a, master_b;
	wire intr_done_a, intr_done_b;
	wire [7:2] bus_d_vec;
	assign bus_bg_out[7] = bus_bg_in[7];
	assign bus_bg_out[6] = bg_out;
	assign bus_bg_out[5:4] = bus_bg_in[5:4];
	// I really hope this behaves right
	m782_intctl #(VEC) intctl(
		.clk(clk),
		.reset(reset),

		.vector_bit2(1'b0),

		.int_a(flag),
		.int_enb_a(int_enb),
		.bg_in_a(bg_in),
		.bg_out_a(bg_out),
		.master_clear_a(intr_done_a),
		.br_a(br_a),
		.master_a(master_a),
		.start_intr_a(master_a),
		.intr_done_a(intr_done_a),

		// need at least these if we're not using it
		.int_b(1'b0),
		.int_enb_b(1'b0),
		.start_intr_b(1'b0),

		.bus_bbsy(bus_bbsy),
		.bus_ssyn(bus_ssyn),
		.bus_sack_out(bus_sack_out),
		.bus_bbsy_out(bus_bbsy_out),
		.bus_intr_out(bus_intr_out),
		.bus_d_out(bus_d_vec)
	);
	assign bus_br[7] = 0;
	assign bus_br[6] = br_a;
	assign bus_br[5:4] = 0;

	reg flag;
	reg int_enb;

	assign bus_d_out[15:8] = 0;
	assign bus_d_out[7] = select & in & flag | bus_d_vec[7];
	assign bus_d_out[6] = select & in & int_enb | bus_d_vec[6];
	assign bus_d_out[5:2] = bus_d_vec[5:2];
	assign bus_d_out[1:0] = 0;

	always @(posedge clk) begin
		if(select & out_low) begin
			if(~bus_d[7])
				flag <= 0;
			int_enb <= bus_d[6];
		end
		if(line_clk)
			flag <= 1;
		if(bus_init) begin
			flag <= 1;
			int_enb <= 0;
		end
	end

	wire line_clk;
`ifdef SIMULATION
	clkdiv #(50000000,6000) clkdiv(clk, line_clk);
`else
	clkdiv #(50000000,FREQ) clkdiv(clk, line_clk);
`endif
endmodule
