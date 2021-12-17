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

	reg [15:0] mem[0:'o20000-1];
	wire selected = bus_msyn & (bus_addr[17:1] < 'o20000);

	wire lobyte = ~bus_c0 | ~bus_addr[0];
	wire hibyte = ~bus_c0 | bus_addr[0];

	reg [15:0] ssyndly;	// TODO: SENSITIVE to clock
	always @(posedge clk) begin
		ssyndly <= {ssyndly[14:0], selected};

		if(bus_msyn & bus_ssyn & bus_c1) begin
			if(lobyte)
				mem[bus_addr[17:1]][7:0] <= bus_d_in[7:0];
			if(hibyte)
				mem[bus_addr[17:1]][15:8] <= bus_d_in[15:8];
		end
	end
	assign bus_ssyn = ssyndly[15];
	assign bus_d_out = selected&~bus_c1 ? mem[bus_addr[17:1]] : 0;

	wire [15:0] memcontents = mem[bus_addr[17:1]];

endmodule
