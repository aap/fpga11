module m7231_data(
	input wire clk,
	input wire reset,

	// outputs
	output wire [15:0] bus_d_out,
	output wire [17:0] bus_addr,
	output wire alu00,
	output wire cout15,
	output reg [15:0] dmux,
	output wire [15:0] d,
	output reg d_c,
	output wire d15_00_eq_0,
	output wire d07_04_eq_0,
	output wire d03_00_eq_0,
	output wire ba07_05_1,
	output wire b15,
	output reg [15:0] bmux,
	output wire [15:0] bus_rd,
	output reg [15:0] ba,
	output wire ba17_16,
	output wire ps_adrs,
	output wire slr_adrs,
	output wire reg_adrs,
	output wire sr_adrs,
	output wire casi_adrs,
	output wire bovfl_stop,
	output wire bovfl,
	output wire [3:0] radrs,
	output wire rx6_x7,
	output wire upp_match,
	output wire p_match,

	// inputs from UWORD
	input wire [8:0] bupp,
	input wire [1:0] sbmh,
	input wire [1:0] sbml,
	input wire [1:0] sdm,
	input wire sbam,
	input wire srs,
	input wire srd,
	input wire srba,
	input wire sri,
	input wire [3:0] rif,

	// inputs from IR
	input wire [15:0] ir,
	input wire [3:0] alus,
	input wire alum,
	input wire cin,
	input wire [1:0] comuxs,

	// inputs from TIME
	input wire p_end,
	input wire clk_b,
	input wire clk_d,
	input wire clk_ba,
	input wire wr_r15_08,
	input wire wr_r07_00,
	input wire ckovf,
	input wire bus_fm_sr,
	input wire bus_fm_d,
	input wire bus_fm_ba,

	// inputs from STATUS
	input wire [15:0] bus_rd_in,
	input wire init,
	input wire ps_c,
	input wire [15:0] bc,

	// inputs from bus
	input wire [15:0] bus_d,

	// inputs from KY
	input wire [15:0] sr,

	// from KT
	input wire mode_sel1,
	input wire s_hook,
	input wire d_hook
);
	reg [15:0] breg;
	wire [15:0] alu;
	reg [15:0] dreg;
	reg [15:0] bamux;
	reg coutmux;
	reg [15:0] r[15:0];

	// unused
	wire clr_b = 0;
	wire clr_d = 0;

	wire [3:0] p;
	wire [3:0] g;
	wire cout03, cout07, cout11;
	alu74181 alu0(
		.a(bus_rd[3:0]), .b(bmux[3:0]), .cin(cin),
		.s(alus), .m(alum),
		.f(alu[3:0]), .gout(g[0]), .pout(p[0])
	);
	alu74181 alu1(
		.a(bus_rd[7:4]), .b(bmux[7:4]), .cin(cout03),
		.s(alus), .m(alum),
		.f(alu[7:4]), .gout(g[1]), .pout(p[1])
	);
	alu74181 alu2(
		.a(bus_rd[11:8]), .b(bmux[11:8]), .cin(cout07),
		.s(alus), .m(alum),
		.f(alu[11:8]), .gout(g[2]), .pout(p[2])
	);
	alu74181 alu3(
		.a(bus_rd[15:12]), .b(bmux[15:12]), .cin(cout11),
		.s(alus), .m(alum),
		.f(alu[15:12]), .cout(cout15)
	);
	cla74182 cla74182(.g(g), .p(p), .cin(cin),
		.coutx(cout03), .couty(cout07), .coutz(cout11)
	);
	assign alu00 = alu[0];

	assign radrs[2:0] =
		{3{srs}} & ir[8:6] |
		{3{srd}} & ir[2:0] |
		{3{srba}} & ba[2:0] |
		{3{sri}} & rif[2:0];
	assign radrs[3] =
		mode_sel1 & (rif[2:0]==6) |
		srs & s_hook |
		srd & d_hook |
		srba & ba[3] |
		sri & rif[3];
	assign rx6_x7 = radrs[2] & radrs[1];
	wire reg_cs = srs | srd | srba | sri;
	assign bus_rd = {16{reg_cs}} & r[radrs] | bus_rd_in;

	assign bus_d_out = {16{bus_fm_sr}} & sr |
		{16{bus_fm_d}} & dreg;
	assign ba17_16 = &ba[15:13];
`ifndef KT11
	assign bus_addr[17:6] = {12{bus_fm_ba}} & {ba17_16, ba17_16, ba[15:6]};
`else
	assign bus_addr[17:6] = 0;
`endif
	assign bus_addr[5:0] = {6{bus_fm_ba}} & ba[5:0];

	assign d = dreg;
	assign b15 = breg[15];

	always @(*) begin
		dmux <= 0;
		bmux <= 0;
		bamux <= 0;
		coutmux <= 0;

		case(sbmh)
		2'b00: bmux[15:8] <= breg[15:8];
		2'b01: bmux[15:8] <= {8{breg[7]}};
		2'b10: bmux[15:8] <= breg[7:0];
		2'b11: bmux[15:8] <= bc[15:8];
		endcase
		case(sbml)
		2'b00: bmux[7:0] <= breg[7:0];
		2'b01: bmux[7:0] <= breg[7:0];
		2'b10: bmux[7:0] <= breg[15:8];
		2'b11: bmux[7:0] <= bc[7:0];
		endcase

		case(sdm)
		2'b00: dmux <= bus_rd;
		2'b01: dmux <= bus_d;
		2'b10: dmux <= dreg;
		2'b11: dmux <= { d_c, dreg[15:1] };
		endcase

		case(sbam)
		1'b0: bamux <= alu;
		1'b1: bamux <= bus_rd;
		endcase

		case(comuxs)
		2'b00: coutmux <= cout15;
		2'b01: coutmux <= cout07;
		2'b10: coutmux <= ps_c;
		2'b11: coutmux <= alu[15];
		endcase
	end

`ifdef SIMULATION
	reg [15:0] lastreg;
	reg [3:0] lastadr_hi;
	reg [3:0] lastadr_lo;
`endif
	always @(posedge clk) begin
		if(clk_b)
			breg <= dmux;
		if(clr_b)
			breg <= 0;
		if(clk_d) begin
			dreg <= alu;
			d_c <= coutmux;
		end
		if(clr_d) begin
			dreg <= 0;
			d_c <= 0;
		end
		if(clk_ba)
			ba <= bamux;
		if(init)
			ba <= 0;
		if(wr_r15_08 & reg_cs)
			r[radrs][15:8] <= dmux[15:8];
		if(wr_r07_00 & reg_cs)
			r[radrs][7:0] <= dmux[7:0];

`ifdef SIMULATION
		if(wr_r15_08 & reg_cs) begin
			lastadr_hi <= radrs;
			lastreg[15:8] <= dmux[15:8];
		end
		if(wr_r07_00 & reg_cs) begin
			lastadr_lo <= radrs;
			lastreg[7:0] <= dmux[7:0];
		end
`endif
	end
	assign d15_00_eq_0 = dreg == 0;
	assign d07_04_eq_0 = dreg[7:4] == 0;
	assign d03_00_eq_0 = dreg[3:0] == 0;

	// address decode
	wire ba15_08_1 = &ba[15:8];
	assign ba07_05_1 = &ba[7:5];
	wire ba06_03_1 = &ba[6:3];
`ifndef KT11
	assign ps_adrs = ba15_08_1 & ba[7] & ba06_03_1 & ba[2] & ba[1];
`ifdef KJ11
	assign slr_adrs = ba15_08_1 & ba[7] & ba06_03_1 & ba[2];
`else
	assign slr_adrs = 0;
`endif
	assign reg_adrs = ba15_08_1 & ba[7] & ba[6] & ~ba[5] & ~ba[4];
	assign sr_adrs = ba15_08_1 & ~ba[7] & ba[6] & ba[5] & ba[4] & ba[3] & ~ba[2] & ~ba[1];
`endif

	// why is 177560 in here? that's serial console
	assign casi_adrs = ba15_08_1 & ~ba[7] & ba[6] & ba[5] & ba[4] & ~ba[3];

	assign bovfl_stop = ~(|ba[15:8]) & ~ba07_05_1;
	assign bovfl = ckovf & ~(|ba[15:8]);


	assign upp_match = bupp == sr[8:0];
	assign p_match = upp_match & p_end;
endmodule

