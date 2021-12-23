`default_nettype none

`define KW11

module pdp11_40(
	input wire clk,
	input wire reset,

	input wire power,

	// KY
	input wire ldadrs_sw,
	input wire exam_sw,
	input wire dep_sw,
	input wire cont_sw,
	input wire start_sw,
	input wire begin_sw,
	input wire halt_sw,
	input wire [17:0] sr,
	output wire [17:0] addr_lights,
	output wire [15:0] data_lights,
	output wire [5:0] status_lights,

	// KM
	input wire mclk_enable,
	input wire mclk,
	input wire mstop,
	output wire [8:0] bupp,
	output wire [8:0] pupp,
	output wire [4:0] flags,
	output wire [2:0] status,

	// KL11
	input wire cnsl_RX,
	output wire cnsl_TX,

	// TU58
	input wire tu58_RX,
	output wire tu58_TX,

	input wire enable_M9312
);

	// UNIBUS wiring
	wire bus_pwr_lo = ~power;
	wire bus_init;
	// wire ORed from all masters
	wire [15:0] bus_d = bus_d_cpu | bus_d_mem | bus_d_m9312 | bus_d_kl11 | bus_d_kw11 | bus_d_tu58;
	wire [17:0] bus_addr = bus_addr_cpu | bus_addr_m9312;
	wire bus_c0 = bus_c0_cpu;
	wire bus_c1 = bus_c1_cpu;
	wire bus_bbsy = bus_bbsy_cpu | bus_bbsy_kl11 | bus_bbsy_kw11 | bus_bbsy_tu58;
	wire bus_msyn = bus_msyn_cpu;
	wire bus_intr = bus_intr_kl11 | bus_intr_kw11 | bus_intr_tu58;
	// wire ORed from all slaves
	wire [7:4] bus_br = bus_br_kl11 | bus_br_kw11 | bus_br_tu58;
	wire bus_npr = 0;
	wire bus_ssyn = bus_ssyn_cpu | bus_ssyn_mem | bus_ssyn_m9312 | bus_ssyn_kl11 | bus_ssyn_kw11 | bus_ssyn_tu58;
	wire bus_sack = bus_sack_kl11 | bus_sack_kw11 | bus_sack_tu58;


	wire [15:0] bus_d_mem;
	wire bus_ssyn_mem;
	memory memory(.clk(clk), .reset(reset),
		.bus_init(bus_init),
		.bus_addr(bus_addr),
		.bus_d_in(bus_d),
		.bus_d_out(bus_d_mem),
		.bus_msyn(bus_msyn),
		.bus_ssyn(bus_ssyn_mem),
		.bus_c0(bus_c0),
		.bus_c1(bus_c1)
	);

	wire [15:0] bus_d_m9312;
	wire [17:0] bus_addr_m9312;
	wire bus_ssyn_m9312;
	m9312 #(1, 1,'o20) m9312(.clk(clk), .reset(reset),
		.enable(enable_M9312),
		.bus_pwr_lo(bus_pwr_lo),
		.bus_addr(bus_addr),
		.bus_d_out(bus_d_m9312),
		.bus_addr_out(bus_addr_m9312),
		.bus_msyn(bus_msyn),
		.bus_ssyn(bus_ssyn_m9312)
	);

	wire [15:0] bus_d_kl11;
	wire bus_ssyn_kl11;
	wire bus_sack_kl11;
	wire bus_bbsy_kl11;
	wire bus_intr_kl11;
	wire [7:4] bus_br_kl11;
	wire [7:4] bus_bg_kl11;
	dl11 #('o777560, 'o60, 9600) kl11(
		.clk(clk),
		.reset(reset),
		.bus_init(bus_init),
		.bus_d(bus_d),
		.bus_addr(bus_addr),
		.bus_c0(bus_c0),
		.bus_c1(bus_c1),
		.bus_bbsy(bus_bbsy),
		.bus_msyn(bus_msyn),
		.bus_intr(bus_intr),
		.bus_br(bus_br_kl11),
		.bus_ssyn(bus_ssyn),
		.bus_sack(bus_sack),
		.bus_bg_in(bus_bg_cpu),
		.bus_bg_out(bus_bg_kl11),

		.bus_ssyn_out(bus_ssyn_kl11),
		.bus_sack_out(bus_sack_kl11),
		.bus_bbsy_out(bus_bbsy_kl11),
		.bus_intr_out(bus_intr_kl11),
		.bus_d_out(bus_d_kl11),

		.RX(cnsl_RX),
		.TX(cnsl_TX)
	);

`ifdef KW11
	wire [15:0] bus_d_kw11;
	wire bus_ssyn_kw11;
	wire bus_sack_kw11;
	wire bus_bbsy_kw11;
	wire bus_intr_kw11;
	wire [7:4] bus_br_kw11;
	wire [7:4] bus_bg_kw11;
	kw11 #('o777546, 'o100, 60) kw11(
		.clk(clk),
		.reset(reset),

		.bus_init(bus_init),
		.bus_d(bus_d),
		.bus_addr(bus_addr),
		.bus_c0(bus_c0),
		.bus_c1(bus_c1),
		.bus_bbsy(bus_bbsy),
		.bus_msyn(bus_msyn),
		.bus_intr(bus_intr),
		.bus_br(bus_br_kw11),
		.bus_ssyn(bus_ssyn),
		.bus_sack(bus_sack),
		.bus_bg_in(bus_bg_kl11),
		.bus_bg_out(bus_bg_kw11),

		.bus_ssyn_out(bus_ssyn_kw11),
		.bus_sack_out(bus_sack_kw11),
		.bus_bbsy_out(bus_bbsy_kw11),
		.bus_intr_out(bus_intr_kw11),
		.bus_d_out(bus_d_kw11)
	);
`else
	wire [15:0] bus_d_kw11 = 0;
	wire bus_ssyn_kw11 = 0;
	wire bus_sack_kw11 = 0;
	wire bus_bbsy_kw11 = 0;
	wire bus_intr_kw11 = 0;
	wire [7:4] bus_br_kw11 = 0;
	wire [7:4] bus_bg_kw11 = bus_bg_kl11;
`endif

	wire [15:0] bus_d_tu58;
	wire bus_ssyn_tu58;
	wire bus_sack_tu58;
	wire bus_bbsy_tu58;
	wire bus_intr_tu58;
	wire [7:4] bus_br_tu58;
	wire [7:4] bus_bg_tu58;
//	dl11 #('o776500, 'o300, 9600) dl11_tu58(
	dl11 #('o776500, 'o300, 38400) dl11_tu58(
		.clk(clk),
		.reset(reset),
		.bus_init(bus_init),
		.bus_d(bus_d),
		.bus_addr(bus_addr),
		.bus_c0(bus_c0),
		.bus_c1(bus_c1),
		.bus_bbsy(bus_bbsy),
		.bus_msyn(bus_msyn),
		.bus_intr(bus_intr),
		.bus_br(bus_br_tu58),
		.bus_ssyn(bus_ssyn),
		.bus_sack(bus_sack),
		.bus_bg_in(bus_bg_kw11),
		.bus_bg_out(bus_bg_tu58),

		.bus_ssyn_out(bus_ssyn_tu58),
		.bus_sack_out(bus_sack_tu58),
		.bus_bbsy_out(bus_bbsy_tu58),
		.bus_intr_out(bus_intr_tu58),
		.bus_d_out(bus_d_tu58),

		.RX(tu58_RX),
		.TX(tu58_TX)
	);

	// bus output from cpu
	wire [15:0] bus_d_cpu;
	wire [17:0] bus_addr_cpu;
	wire bus_c0_cpu;
	wire bus_c1_cpu;
	wire bus_bbsy_cpu;
	wire bus_msyn_cpu;
	wire bus_ssyn_cpu;
	wire bus_npg_cpu;
	wire [7:4] bus_bg_cpu;
	kd11a kd11a(
		.clk(clk),
		.reset(reset),

		// KY
		.ldadrs_sw(ldadrs_sw),
		.exam_sw(exam_sw),
		.dep_sw(dep_sw),
		.cont_sw(cont_sw),
		.start_sw(start_sw),
		.begin_sw(begin_sw),
		.halt_sw(halt_sw),
		.sr(sr),
		.data_lights(data_lights),
		.addr_lights(addr_lights),
		.status_lights(status_lights),

		// KM
		.mclk_enable(mclk_enable),
		.mclk(mclk),
		.mstop(mstop),
		.bupp(bupp),
		.pupp(pupp),
		.flags(flags),
		.status(status),

		.bus_pwr_lo(bus_pwr_lo),
		.bus_c0(bus_c0),
		.bus_c1(bus_c1),
		.bus_d(bus_d),
		.bus_bbsy(bus_bbsy),
		.bus_msyn(bus_msyn),
		.bus_ssyn(bus_ssyn),
		.bus_intr(bus_intr),
		.bus_npr(bus_npr),
		.bus_br(bus_br),
		.bus_sack(bus_sack),

		.bus_init(bus_init),
		.bus_npg(bus_npg_cpu),
		.bus_bg(bus_bg_cpu),
		.bus_d_cpu(bus_d_cpu),
		.bus_addr_cpu(bus_addr_cpu),
		.bus_c0_cpu(bus_c0_cpu),
		.bus_c1_cpu(bus_c1_cpu),
		.bus_bbsy_cpu(bus_bbsy_cpu),
		.bus_msyn_cpu(bus_msyn_cpu),
		.bus_ssyn_cpu(bus_ssyn_cpu)
	);
endmodule
