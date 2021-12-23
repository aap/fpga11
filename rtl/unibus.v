module m105_addrsel
#(parameter ADDR='o760000)
(
	input wire clk,
	input wire reset,

	input wire [17:0] addr,
	input wire c0,
	input wire c1,
	input wire msyn,
	output wire ssyn,
	output wire select0,
	output wire select2,
	output wire select4,
	output wire select6,
	output wire out_high,
	output wire out_low,
	output wire in
);
	wire select = msyn & (&addr[17:13]) & (addr[12:3] == ADDR[12:3]);
	reg [15:0] ssyndly;	// TODO: SENSITIVE to clock
	always @(posedge clk) ssyndly <= {ssyndly[14:0], select};
	assign ssyn = ssyndly[14];
	assign in = ~c1;
	assign out_low = ~in & (~c0 | ~addr[0]);
	assign out_high = ~in & (~c0 | addr[0]);
	assign select0 = select & ~addr[2] & ~addr[1];
	assign select2 = select & ~addr[2] & addr[1];
	assign select4 = select & addr[2] & ~addr[1];
	assign select6 = select & addr[2] & addr[1];
endmodule

module m782_intctl
#(parameter VEC='o60)
(
	input wire clk,
	input wire reset,

	input wire vector_bit2,

	input wire int_a,
	input wire int_enb_a,
	input wire bg_in_a,
	output wire bg_out_a,
	input wire master_clear_a,
	output wire br_a,
	output wire master_a,
	input wire start_intr_a,
	output wire intr_done_a,

	input wire int_b,
	input wire int_enb_b,
	input wire bg_in_b,
	output wire bg_out_b,
	input wire master_clear_b,
	output wire br_b,
	output wire master_b,
	input wire start_intr_b,
	output wire intr_done_b,

	input bus_bbsy,
	input bus_ssyn,
	output bus_sack_out,
	output bus_bbsy_out,
	output wire bus_intr_out,
	output wire [7:2] bus_d_out
);

	// this is strange. causes extra clocks
	wire bus_idle = 1;
//	wire bus_idle = ~bus_bbsy & ~bus_ssyn;

	wire start_intr = start_intr_a | start_intr_b;
	assign bus_intr_out = start_intr;

	assign bus_sack_out = grant_taken_a & ~bus_taken_a | grant_taken_b & ~bus_taken_b;
	assign bus_bbsy_out = grant_taken_a & bus_taken_a | grant_taken_b & bus_taken_b;
	assign bus_d_out[7:3] = {5{start_intr}} & VEC[7:3];
	assign bus_d_out[2] = start_intr & vector_bit2;

	// NB: bus_taken is not cleared at the end
	// which will cause no further interrupts to happen
	// until the cause has gone away


	reg grant_taken_a;
	reg bus_taken_a;
	wire req_a = int_a & int_enb_a;
	assign br_a = req_a & ~grant_taken_a & ~bus_taken_a;
	wire clk_grant_a, clk_bus_a;
	edgedet2 bg_a_edge(clk, reset, bg_in_a, clk_grant_a);
	edgedet2 bus_a_edge(clk, reset, ~bg_dly_a[1]&~bus_taken_a & bus_idle, clk_bus_a);
	assign master_a = grant_taken_a & bus_taken_a;
	assign intr_done_a = start_intr_a & bus_ssyn;
	reg [1:0] bg_dly_a;
	always @(posedge clk) begin
		bg_dly_a <= {bg_dly_a[0], bg_in_a};
		if(clk_grant_a)
			grant_taken_a <= grant_taken_a | ~bus_taken_a;
		if(clk_bus_a)
			bus_taken_a <= grant_taken_a;
		if(master_clear_a | ~req_a)
			grant_taken_a <= 0;
		if(~req_a)
			bus_taken_a <= 0;
	end
	assign bg_out_a = bg_dly_a[1] & ~(grant_taken_a&~bus_taken_a);


	reg grant_taken_b;
	reg bus_taken_b;
	wire req_b = int_b & int_enb_b;
	assign br_b = req_b & ~grant_taken_b & ~bus_taken_b;
	wire clk_grant_b, clk_bus_b;
	edgedet2 bg_b_edge(clk, reset, bg_in_b, clk_grant_b);
	edgedet2 bus_b_edge(clk, reset, ~bg_dly_b[1]&~bus_taken_b & bus_idle, clk_bus_b);
	assign master_b = grant_taken_b & bus_taken_b;
	assign intr_done_b = start_intr_b & bus_ssyn;
	reg [1:0] bg_dly_b;
	always @(posedge clk) begin
		bg_dly_b <= {bg_dly_b[0], bg_in_b};
		if(clk_grant_b)
			grant_taken_b <= grant_taken_b | ~bus_taken_b;
		if(clk_bus_b)
			bus_taken_b <= grant_taken_b;
		if(master_clear_b | ~req_b)
			grant_taken_b <= 0;
		if(~req_b)
			bus_taken_b <= 0;
	end
	assign bg_out_b = bg_dly_b[1] & ~(grant_taken_b&~bus_taken_b);
endmodule
