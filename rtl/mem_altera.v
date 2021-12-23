module memory(
	input wire clk,
	input wire reset,

	input wire bus_init,
	input wire [17:0] bus_addr,
	input wire [15:0] bus_d_in,
	output wire [15:0] bus_d_out,
	input wire bus_msyn,
	output wire bus_ssyn,
	input wire bus_c0,
	input wire bus_c1
);

	wire [15:0] memcontents;
/*
	unibus_ram32k ram(.address(bus_addr[15:1]),
		.byteena({hibyte, lobyte}),
		.clock(clk),
		.data(bus_d_in[15:0]),
		.wren(bus_msyn & bus_ssyn & bus_c1),
		.q(memcontents)
	);

	wire selected = bus_msyn & (bus_addr[17:1] < 'o100000);
*/
	unibus_ram128k ram(.address(bus_addr[17:1]),
		.byteena({hibyte, lobyte}),
		.clock(clk),
		.data(bus_d_in[15:0]),
		.wren(bus_msyn & bus_ssyn & bus_c1),
		.q(memcontents)
	);

	wire selected = bus_msyn & (bus_addr[17:1] < 'o370000);
	wire lobyte = ~bus_c0 | ~bus_addr[0];
	wire hibyte = ~bus_c0 | bus_addr[0];

	reg [15:0] ssyndly;	// TODO: SENSITIVE to clock
	always @(posedge clk) begin
		ssyndly <= {ssyndly[14:0], selected};
	end
	assign bus_ssyn = ssyndly[15];
	assign bus_d_out = selected&~bus_c1 ? memcontents : 0;

endmodule
