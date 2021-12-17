`default_nettype none

`define KT11
`define KJ11
`define KE11E

module kd11a(
	input wire clk,
	input wire reset,

	// KY
	input wire ldadrs_sw,
	input wire exam_sw,
	input wire dep_sw,
	input wire cont_sw,
	input wire start_sw,
	input wire begin_sw,
	input wire halt_sw,
	input wire [17:0] sr,
	output wire [15:0] data_lights,
	output wire [17:0] addr_lights,
	output wire [5:0] status_lights,

	// KM
	input wire mclk_enable,
	input wire mclk,
	input wire mstop,
	output wire [8:0] bupp,
	output wire [8:0] pupp,
	output wire [4:0] flags,
	output wire [2:0] status,

	// BUS input
	input wire bus_pwr_lo,
	input wire bus_c0,
	input wire bus_c1,
	input wire [15:0] bus_d,
	input wire bus_bbsy,
	input wire bus_msyn,
	input wire bus_ssyn,
	input wire bus_intr,
	input wire bus_npr,
	input wire [7:4] bus_br,
	input wire bus_sack,

	// BUS output
	output wire bus_init,
	output wire bus_npg,
	output wire [7:4] bus_bg,
	output wire [15:0] bus_d_cpu,
	output wire [17:0] bus_addr_cpu,
	output wire bus_c0_cpu,
	output wire bus_c1_cpu,
	output wire bus_bbsy_cpu,
	output wire bus_msyn_cpu,
	output wire bus_ssyn_cpu
);
	// KY
	assign data_lights = dmux;
	assign addr_lights = bus_addr_cpu;
	assign status_lights[5] = ~idle;	// run
	assign status_lights[4] = bus_bbsy;	// bus
	assign status_lights[3] = ps15;	// user
	assign status_lights[2] = bbsy;	// proc
	assign status_lights[1] = consl;	// console
	assign status_lights[0] = relocate;	// virtual

	// KM
	assign flags[0] = ps_c;
	assign flags[1] = ps_n;
	assign flags[2] = ps_z;
	assign flags[3] = ps_v;
	assign flags[4] = ps_t;
	assign status[0] = bus_msyn;
	assign status[1] = bus_ssyn;
	assign status[2] = 0;	// traps, but what signal is that? the flip-flop?

	assign bus_d_cpu = bus_d_data | bus_d_status | bus_d_kj11 | bus_d_kt11;

	// DATA outputs
	wire [15:0] bus_d_data;
	wire alu00;
	wire cout15;
	wire [15:0] dmux;
	wire [15:0] d;
	wire d_c;
	wire d15_00_eq_0;
	wire d07_04_eq_0;
	wire d03_00_eq_0;
	wire ba07_05_1;
	wire b15;
	wire [15:0] bmux;
	wire [15:0] rd;
	wire [15:0] ba;
	wire ba17_16;
	wire ps_adrs;
	wire slr_adrs;
	wire reg_adrs;
	wire sr_adrs;
	wire casi_adrs;
	wire bovfl_stop;
	wire bovfl;
	wire [3:0] radrs;
	wire rx6_x7;
	wire upp_match;
	wire p_match;
	wire [17:0] bus_addr_cpu1;
	assign bus_addr_cpu = bus_addr_cpu1 | bus_addr_kt11;
	m7231_data m7231_data(.clk(clk), .reset(reset),
		// outputs
		.bus_d_out(bus_d_data),
		.bus_addr(bus_addr_cpu1),
		.alu00(alu00),
		.cout15(cout15),
		.dmux(dmux),
		.d(d),
		.d_c(d_c),
		.d15_00_eq_0(d15_00_eq_0),
		.d07_04_eq_0(d07_04_eq_0),
		.d03_00_eq_0(d03_00_eq_0),
		.ba07_05_1(ba07_05_1),
		.b15(b15),
		.bmux(bmux),
		.bus_rd(rd),
		.ba(ba),
		.ba17_16(ba17_16),
`ifndef KT11
		// have to make quartus happy even if we're not
		// assigning them inside the module
		.ps_adrs(ps_adrs),
		.slr_adrs(slr_adrs),
		.reg_adrs(reg_adrs),
		.sr_adrs(sr_adrs),
`endif
		.casi_adrs(casi_adrs),
		.bovfl_stop(bovfl_stop),
		.bovfl(bovfl),
		.radrs(radrs),
		.rx6_x7(rx6_x7),
		.upp_match(upp_match),
		.p_match(p_match),

		// inputs from UWORD
		.bupp(bupp),
		.sbmh(sbmh),
		.sbml(sbml),
		.sdm(sdm),
		.sbam(sbam),
		.srs(srs),
		.srd(srd),
		.srba(srba),
		.sri(sri),
		.rif(rif),

		// inputs from IR
		.ir(ir),
		.alus(alus),
		.alum(alum),
		.cin(cin),
		.comuxs(comuxs),

		// inputs from TIME
		.p_end(p_end),
		.clk_b(clk_b),
		.clk_d(clk_d),
		.clk_ba(clk_ba),
		.wr_r15_08(wr_r15_08),
		.wr_r07_00(wr_r07_00),
		.ckovf(ckovf),
		.bus_fm_sr(bus_fm_sr),
		.bus_fm_d(bus_fm_d),
		.bus_fm_ba(bus_fm_ba),

		// inputs from STATUS
		.bus_rd_in(bus_rd_status | bus_rd_ke11 | bus_rd_kt11),
		.init(init),
		.ps_c(ps_c),
		.bc(bc),

		// inputs from bus
		.bus_d(bus_d),

		// inputs from KY
		.sr(sr[15:0]),

		// inputs from KT
		.mode_sel1(mode_sel1),
		.s_hook(s_hook),
		.d_hook(d_hook)
	);

	// UWORD outputs
	wire [1:0] clkl;
	wire clkoff;
	wire clkir;
	wire wrh;
	wire wrl;
	wire clkb;
	wire clkd;
	wire clkba;
	wire c1bus;
	wire c0bus;
	wire bgbus;
	wire [3:0] dad;
	wire [2:0] sps;
	wire salum;
	wire [3:0] salu;
	wire [3:0] sbc;
	wire [1:0] sbmh;
	wire [1:0] sbml;
	wire [1:0] sdm;
	wire sbam;
	wire [4:0] ubf;
	wire srs;
	wire srd;
	wire srba;
	wire sri;
	wire [3:0] rif;
	wire [8:0] eupp;
	m7232_uword m7232_uword(.clk(clk), .reset(reset),
		// outputs
		.bupp(bupp),
		.pupp(pupp),
		.clkl(clkl),
		.clkoff(clkoff),
		.clkir(clkir),
		.wrh(wrh),
		.wrl(wrl),
		.clkb(clkb),
		.clkd(clkd),
		.clkba(clkba),
		.c1bus(c1bus),
		.c0bus(c0bus),
		.bgbus(bgbus),
		.dad(dad),
		.sps(sps),
		.salum(salum),
		.salu(salu),
		.sbc(sbc),
		.sbmh(sbmh),
		.sbml(sbml),
		.sdm(sdm),
		.sbam(sbam),
		.ubf(ubf),
		.srs(srs),
		.srd(srd),
		.srba(srba),
		.sri(sri),
		.rif(rif),

		// inputs from IR
		.bubc(bubc),

		// inputs from TIME
		.clk_u56_17(clk_u56_17),
		.clk_u16_09(clk_u16_09),
		.clk_upp_pupp(clk_upp_pupp),
		.jamupp(jamupp),
		.clr_upp0(clr_upp0),
		.set_upp0(set_upp0),
		.clr_upp1(clr_upp1),
		.set_upp1(set_upp1),
		.clr_upp762(clr_upp762),
		.set_upp762(set_upp762),
		.clr_upp43(clr_upp43),
		.set_upp43(set_upp43),
		.clr_upp5(clr_upp5),
		.set_upp5(set_upp5),

		// inputs from KE
		.p_clk_upp8(p_clk_upp8),
		.bus_u_in(bus_u_ke),
		.eubc(eubc),
		// outputs to KE
		.eupp(eupp)
	);

	// IR outputs
	wire [15:0] ir;
	wire ir14_12_eq_0;
	wire ir14_12_eq_7;
	wire sm0;
	wire sm1;
	wire sm2;
	wire sm3;
	wire dm0;
	wire ovlap_instr;
	wire ovlap_cycle;
	wire but3x;
	wire [5:0] bubc;
	wire dad_3_2;
	wire [3:0] alus;
	wire alum;
	wire cin;
	wire [1:0] comuxs;
	wire trace;
	wire bit_cmp_tst;
	wire cc_instr;
	wire byte_instr;
	wire priv_instr;
	wire wait_;
	wire iot;
	wire trap;
	wire emt;
	wire rsvd_instr;
	wire bpt;
	wire ill_instr;
	wire traps_data;
	wire v_data;
	wire c_data;
	wire byte_codes;
	m7233_ir m7233_ir(.clk(clk), .reset(reset),
		// inputs from DATA
		.ba(ba),
		.d_c(d_c),
		.d(d),
		.dmux(dmux),
		.reg_adrs(reg_adrs),
		.d15_00_eq_0(d15_00_eq_0),
		.rx6_x7(rx6_x7),
		.ps_adrs(ps_adrs),

		// inputs from UWORD
		.dad(dad),
		.sps(sps),
		.salu(salu),
		.salum(salum),
		.ubf(ubf),

		// outputs
		.ir(ir),
		.ir14_12_eq_0(ir14_12_eq_0),
		.ir14_12_eq_7(ir14_12_eq_7),
		.sm0(sm0),
		.sm1(sm1),
		.sm2(sm2),
		.sm3(sm3),
		.dm0(dm0),
		.ovlap_instr(ovlap_instr),
		.ovlap_cycle(ovlap_cycle),
		.but3x(but3x),
		.bubc(bubc),
		.dad_3_2(dad_3_2),
		.alus(alus),
		.alum(alum),
		.cin(cin),
		.comuxs(comuxs),
		.trace(trace),
		.bit_cmp_tst(bit_cmp_tst),
		.cc_instr(cc_instr),
		.byte_instr(byte_instr),
		.priv_instr(priv_instr),
		.wait_(wait_),
		.traps_data(traps_data),
		.v_data(v_data),
		.c_data(c_data),
		.byte_codes(byte_codes),
		.iot(iot),
		.trap(trap),
		.emt(emt),
		.rsvd_instr(rsvd_instr),
		.bpt(bpt),
		.ill_instr(ill_instr),

		// inputs from TIME
		.clk_ir(clk_ir),
		.brq(brq),
		.cbr(cbr),
		.brptr(brptr),

		// inputs from STATUS
		.init(init),
		.swtch(swtch),
		.begin_(begin_),
		.bubc_but30(bubc_but30),
		.bcon_12(bcon_12),
		.consl(consl),
		.ps_c(ps_c),
		.ps_n(ps_n),
		.ps_t(ps_t),
		.pwrdn(pwrdn),
		.br_instr(br_instr),
		.true_br(true_br),
		.false_br(false_br),
		.load_ps(load_ps),
		.pasta(pasta),
		.pastb(pastb),
		.pastc(pastc),
		.n_data(n_data),
		.intr(intr),
		.berr(berr),
		.ovlap(ovlap),
		.bovflw(bovflw),
		.wait_ff(wait_ff),

		// inputs from KY
		.halt_sw(halt_sw),

		// inputs from KT and KE
		.kt_instr(kt_instr),
		.fault_l(fault_l),
		.ps15(ps15),
		.ecomuxs(ecomuxs),
		.ecin00(ecin00),
		.esalu(esalu),
		.esalum(esalum)
	);

	// TIME outputs
	wire idle;
	wire set_clk;
	wire eclk_u;
	wire clk_u56_17;
	wire clk_u16_09;
	wire clk_upp_pupp;
	wire p_end;
	wire part_p_end;
	wire ps_p1_p3;
	wire p1_p3;
	wire clk_b;
	wire wr_r15_08;
	wire wr_r07_00;
	wire clk_ir;
	wire p1;
	wire clk_bus;
	wire clk_ba;
	wire p2;
	wire clk_d;
	wire p3;
	wire jamupp;
	wire clr_upp0;
	wire set_upp0;
	wire clr_upp1;
	wire set_upp1;
	wire clr_upp762;
	wire set_upp762;
	wire clr_upp43;
	wire set_upp43;
	wire clr_upp5;
	wire set_upp5;
	wire bc0;
	wire bc1;
	wire ckoda;
	wire msyn;
	wire clk_msyn;
	wire p_clr_msyn;
	wire ckovf;
	wire oda_err;
	wire ovflw_err;
	wire b_intr;
	wire brq;
	wire bbsy;
	wire cbr;
	wire brptr;
	wire ps_p_fm_bus;
	wire bus_fm_ps;
	wire adrs_777774;
	wire bus_fm_sr;
	wire bus_fm_d;
	wire bus_fm_ba;
	wire nodat;
	wire dout_low;
	wire dout_high;
	wire clk_bovflw;
	wire bus_ssyn_cpu1;
	assign bus_ssyn_cpu = bus_ssyn_cpu1 | bus_ssyn_kt11;
	m7234_time m7234_time(.clk(clk), .reset(reset),
		// inputs from DATA
		.ba(ba),
		.ps_adrs(ps_adrs),
		.slr_adrs(slr_adrs),
		.sr_adrs(sr_adrs),
		.bovfl_stop(bovfl_stop),
		.eovfl_stop(eovfl_stop),	// KJ11
		.radrs(radrs),
		.rx6_x7(rx6_x7),
		.upp_match(upp_match),

		// inputs from UWORD
		.clkl(clkl),
		.clkoff(clkoff),
		.clkir(clkir),
		.wrh(wrh),
		.wrl(wrl),
		.clkb(clkb),
		.clkd(clkd),
		.clkba(clkba),
		.c1bus(c1bus),
		.c0bus(c0bus),
		.bgbus(bgbus),
		.dad(dad),

		// inputs from IR
		.ovlap_cycle(ovlap_cycle),
		.bit_cmp_tst(bit_cmp_tst),
		.byte_instr(byte_instr),

		// outputs
		.idle(idle),
		.set_clk(set_clk),
		.eclk_u(eclk_u),
		.clk_u56_17(clk_u56_17),
		.clk_u16_09(clk_u16_09),
		.clk_upp_pupp(clk_upp_pupp),
		.p_end(p_end),
		.part_p_end(part_p_end),
		.ps_p1_p3(ps_p1_p3),
		.p1_p3(p1_p3),
		.clk_b(clk_b),
		.wr_r15_08(wr_r15_08),
		.wr_r07_00(wr_r07_00),
		.clk_ir(clk_ir),
		.p1(p1),
		.clk_bus(clk_bus),
		.clk_ba(clk_ba),
		.p2(p2),
		.clk_d(clk_d),
		.p3(p3),

		.jamupp(jamupp),
		.clr_upp0(clr_upp0),
		.set_upp0(set_upp0),
		.clr_upp1(clr_upp1),
		.set_upp1(set_upp1),
		.clr_upp762(clr_upp762),
		.set_upp762(set_upp762),
		.clr_upp43(clr_upp43),
		.set_upp43(set_upp43),
		.clr_upp5(clr_upp5),
		.set_upp5(set_upp5),

		.bc0(bc0),
		.bc1(bc1),
		.ckoda(ckoda),
		.msyn(msyn),
		.clk_msyn(clk_msyn),
		.p_clr_msyn(p_clr_msyn),
		.ckovf(ckovf),
		.oda_err(oda_err),
		.ovflw_err(ovflw_err),
		.dout_low(dout_low),
		.dout_high(dout_high),
		.clk_bovflw(clk_bovflw),
		.b_intr(b_intr),
		.brq(brq),
		.bbsy(bbsy),
		.cbr(cbr),
		.brptr(brptr),
		.ps_p_fm_bus(ps_p_fm_bus),
		.bus_fm_ps(bus_fm_ps),
		.adrs_777774(adrs_777774),
		.bus_fm_sr(bus_fm_sr),
		.bus_fm_d(bus_fm_d),
		.bus_fm_ba(bus_fm_ba),
		.nodat(nodat),
		.bus_c0_out(bus_c0_cpu),
		.bus_c1_out(bus_c1_cpu),
		.bus_bbsy_out(bus_bbsy_cpu),
		.bus_msyn_out(bus_msyn_cpu),
		.bus_ssyn_out(bus_ssyn_cpu1),

		// inputs from STATUS
		.ps_pl(ps_pl),
		.but26(but26),
		.but37(but37),
		.intr(intr),
		.awby(awby),
		.brsv(brsv),
		.stall(stall),
		.duberr(duberr),
		.ovlap(ovlap),
		.init(init),
		.begin_(begin_),
		.pwrup_init(pwrup_init),
		.pwr_restart(pwr_restart),
		.consl(consl),
		.p_endreset(p_endreset),

		// inputs from BUS
		.bus_pwr_lo(bus_pwr_lo),
		.bus_init(bus_init),
		.bus_c0(bus_c0),
		.bus_c1(bus_c1),
		.bus_bbsy(bus_bbsy),
		.bus_msyn(bus_msyn),
		.bus_ssyn(bus_ssyn),
		.bus_intr(bus_intr),
		.bus_npr(bus_npr),
		.bus_br(bus_br),
		.bus_npg(bus_npg),
		.bus_bg(bus_bg),
		.bus_sack(bus_sack),

		// inputs from KY
		.start_sw(start_sw),
		.halt_sw(halt_sw),

		// inputs from KT
		.no_msyn(no_msyn),
		.fault_h(fault_h),
		.ps15(ps15),

		// inputs from KE
		.enprclk(enprclk),

		// inputs from KM
		.mclk_enable(mclk_enable),
		.mclk(mclk),
		.mstop(mstop)
	);

	// STATUS outputs
	wire [15:0] bus_d_status;
	wire [15:0] bus_rd_status;
	wire [7:5] ps_pl;
	wire ps_c;
	wire ps_n;
	wire ps_z;
	wire ps_v;
	wire ps_t;
	wire load_ps;
	wire busrd_fm_ps;
	wire pasta;
	wire pastb;
	wire pastc;
	wire n_data;
	wire br_instr;
	wire true_br;
	wire false_br;
	wire but05;
	wire but26;
	wire but37;
	wire [15:0] bc;
	wire bcon_12;
	wire berr;
	wire trap_ff;
	wire intr;
	wire awby;
	wire brsv;
	wire bovflw;
	wire pwrdn;
	wire stall;
	wire wait_ff;
	wire ovlap;
	wire duberr;
	wire start;
	wire begin_;
	wire swtch;
	wire consl;
	wire exam;
	wire dep;
	wire [2:0] bubc_but30;
	wire init;
	wire pwrup_init;
	wire pwr_restart;
	wire p_endreset;
	m7235_status m7235_status(.clk(clk), .reset(reset),
		// inputs from DATA
		.dmux(dmux),
		.bmux(bmux),
		.rd(rd),
		.d(d),
		.d15_00_eq_0(d15_00_eq_0),
		.d07_04_eq_0(d07_04_eq_0),
		.d03_00_eq_0(d03_00_eq_0),
		.ps_adrs(ps_adrs),
		.bovfl(bovfl),
		.eovfl(eovfl),	// KJ11

		// inputs from UWORD
		.c1bus(c1bus),
		.c0bus(c0bus),
		.bgbus(bgbus),
		.dad(dad),
		.sps(sps),
		.sbc(sbc),
		.ubf(ubf),

		// input from IR
		.ir(ir),
		.ir14_12_eq_0(ir14_12_eq_0),
		.sm0(sm0),
		.sm1(sm1),
		.sm2(sm2),
		.sm3(sm3),
		.ovlap_instr(ovlap_instr),
		.but3x(but3x),
		.trace(trace),
		.cc_instr(cc_instr),
		.wait_(wait_),
		.iot(iot),
		.trap(trap),
		.emt(emt),
		.rsvd_instr(rsvd_instr),
		.bpt(bpt),
		.ill_instr(ill_instr),
		.traps_data(traps_data),
		.v_data(v_data),
		.c_data(c_data),
		.byte_codes(byte_codes),

		// input from TIME
		.set_clk(set_clk),
		.part_p_end(part_p_end),
		.ps_p1_p3(ps_p1_p3),
		.p1_p3(p1_p3),
		.p1(p1),
		.p2(p2),
		.p3(p3),
		.clk_d(clk_d),
		.oda_err(oda_err),
		.ovflw_err(ovflw_err),
		.clk_bovflw(clk_bovflw),
		.b_intr(b_intr),
		.jamupp(jamupp),
		.brptr(brptr),
		.ps_p_fm_bus(ps_p_fm_bus),
		.bus_fm_ps(bus_fm_ps),
		.nodat(nodat),

		// outputs
		.bus_d_out(bus_d_status),
		.bus_rd_out(bus_rd_status),
		.ps_pl(ps_pl),
		.ps_c(ps_c),
		.ps_n(ps_n),
		.ps_z(ps_z),
		.ps_v(ps_v),
		.ps_t(ps_t),
		.load_ps(load_ps),
		.busrd_fm_ps(busrd_fm_ps),
		.pasta(pasta),
		.pastb(pastb),
		.pastc(pastc),
		.n_data(n_data),

		.br_instr(br_instr),
		.true_br(true_br),
		.false_br(false_br),
		.but05(but05),
		.but26(but26),
		.but37(but37),

		.berr(berr),
		.trap_ff(trap_ff),
		.intr(intr),
		.awby(awby),
		.brsv(brsv),
		.bovflw(bovflw),
		.pwrdn(pwrdn),
		.stall(stall),
		.wait_ff(wait_ff),
		.ovlap(ovlap),
		.duberr(duberr),

		.bc(bc),
		.bcon_12(bcon_12),

		.start(start),
		.begin_(begin_),
		.swtch(swtch),
		.consl(consl),
		.exam(exam),
		.dep(dep),
		.bubc_but30(bubc_but30),

		.init(init),
		.bus_init(bus_init),
		.pwrup_init(pwrup_init),
		.pwr_restart(pwr_restart),
		.p_endreset(p_endreset),

		// inputs from KY
		.ldadrs_sw(ldadrs_sw),
		.exam_sw(exam_sw),
		.dep_sw(dep_sw),
		.cont_sw(cont_sw),
		.start_sw(start_sw),
		.begin_sw(begin_sw),
		.halt_sw(halt_sw),

		// inputs from bus
		.bus_pwr_lo(bus_pwr_lo),

		// inputs from KM
		.mclk_enable(mclk_enable),

		// inputs from KE
		.inh_ps_clk1(inh_ps_clk1),
		.ext_p_clr_trap(ext_p_clr_trap),

		// inputs from KT
		.inh_ps_clk2(inh_ps_clk2),
		.mfp_sm0(mfp_sm0)
	);

`ifdef KT11
	wire ps15;
	wire mode_sel1;
	wire inh_ps_clk2;
	wire relocate;
	wire [15:0] bus_rd_kt11;
	wire kt_instr;
	wire fault_l;
	wire fault_h;
	wire no_msyn;
	wire bus_ssyn_kt11;
	wire [15:0] bus_d_kt11;
	wire [17:0] bus_addr_kt11;
	wire mfp_sm0;
	wire s_hook;
	wire d_hook;
	m7236_kt11 m7236_kt11(
		.clk(clk),
		.reset(reset),

		// input from DATA
		.dmux(dmux),
		.ba(ba),
		.ba17_16(ba17_16),

		// input from UWORD
		.bupp(bupp),
		.clkir(clkir),
		.clkba(clkba),

		// input from IR
		.ir(ir),
		.priv_instr(priv_instr),
		.sm0(sm0),
		.dm0(dm0),

		// input from TIME
		.init(bus_init),
		.bus_fm_ps(bus_fm_ps),
		.bus_fm_ba(bus_fm_ba),
		.ps_p1_p3(ps_p1_p3),
		.p1_p3(p1_p3),
		.p2(p2),
		.clk_u56_17(clk_u56_17),
		.clk_ir(clk_ir),
		.clk_bus(clk_bus),
		.ckoda(ckoda),
		.msyn(msyn),
		.clk_msyn(clk_msyn),
		.p_clr_msyn(p_clr_msyn),
		.bc0(bc0),
		.bc1(bc1),
		.dout_low(dout_low),
		.dout_high(dout_high),

		// input from STATUS
		.busrd_fm_ps(busrd_fm_ps),
			.sps_2_0_eq_7(sps == 7),
			.sbc_10(sbc == 'o10),
			.sbc_16(sbc == 'o16),
			.but05(but05),
		.but26(but26),
		.stall(stall),
		.consl(consl),

		// input from KY
		.sr(sr[17:16]),

		// outputs
		.ps15(ps15),
		.mode_sel1(mode_sel1),
		.inh_ps_clk2(inh_ps_clk2),
		.relocate(relocate),
		.fault_l(fault_l),
		.fault_h(fault_h),
		.bus_rd(bus_rd_kt11),
		.bus_a(bus_addr_kt11),
		.ps_adrs(ps_adrs),
		.slr_adrs(slr_adrs),
		.reg_adrs(reg_adrs),
		.sr_adrs(sr_adrs),
		.no_msyn(no_msyn),
		.ssyn(bus_ssyn_kt11),
		.bus_d_out(bus_d_kt11),
		.kt_instr(kt_instr),
		.mfp_sm0(mfp_sm0),
		.s_hook(s_hook),
		.d_hook(d_hook),

		// input from KE
		.inh_ps_clk1(inh_ps_clk1)
	);
`else
	wire ps15 = 0;
	wire inh_ps_clk2 = 0;
	wire relocate = 0;
	wire mode_sel1 = 0;
	wire kt_instr = 0;
	wire fault_l = 0;
	wire fault_h = 0;
	wire no_msyn = 0;
	wire bus_ssyn_kt11 = 0;
	wire [15:0] bus_rd_kt11 = 0;
	wire [15:0] bus_d_kt11 = 0;
	wire [17:0] bus_addr_kt11 = 0;
	wire mfp_sm0 = 0;
	wire s_hook = 0;
	wire d_hook = 0;
`endif

`ifdef KJ11
	wire eovfl;
	wire eovfl_stop;

	wire [15:0] bus_d_kj11;
	m7237_kj11 m7237_kj11(
		.clk(clk),
		.reset(reset),

		.init(bus_init),
		.dmux(dmux),
		.ba(ba),
		.bus_d_out(bus_d_kj11),
		.bc1(bc1),
		.dout_high(dout_high),
		.adrs_777774(adrs_777774),
		.ckovf(ckovf),
		.ba07_05_1(ba07_05_1),
		.eovfl(eovfl),
		.eovfl_stop(eovfl_stop)		// to K4-4
	);
`else
	wire eovfl = 0;
	wire eovfl_stop = 0;
	wire [15:0] bus_d_kj11 = 0;
`endif

`ifdef KE11E
	wire [56:0] bus_u_ke;
	wire [8:0] eubc;
	wire p_clk_upp8;
	wire [3:0] esalu;
	wire esalum = 0;			// TODO
	wire ecin00;
	wire [1:0] ecomuxs;
	wire inh_ps_clk1;
	wire enprclk;
	wire ext_p_clr_trap;
	wire [15:0] bus_rd_ke11;
	m7238_ke11e m7238_ke11e(
		.clk(clk),
		.reset(reset),

		// inputs from DATA
		.d15(d[15]),
		.d15_00_eq_0(d15_00_eq_0),
		.b15(b15),
		.dmux(dmux),
		.alu00(alu00),
		.cout15(cout15),
		.eupp(eupp),

		// inputs from IR
		.ir(ir),
		.ir14_12_eq_0(ir14_12_eq_0),
		.ir14_12_eq_7(ir14_12_eq_7),
		.rsvd_instr(rsvd_instr),
		.dad_3_2(dad_3_2),

		// inputs from TIME
		.p1(p1),
		.p2(p2),
		.p3(p3),
		.p_end(p_end),
		.part_p_end(part_p_end),
		.eclk_u(eclk_u),

		// inputs from STATUS
		.but37(but37),

		// outputs
		.bus_rd(bus_rd_ke11),
		.ext_p_clr_trap(ext_p_clr_trap),
		.esalu(esalu),
		.ecin00(ecin00),
		.inh_ps_clk1(inh_ps_clk1),
		.ecomuxs(ecomuxs),
		.enprclk(enprclk),
		.bus_u(bus_u_ke),
		.eubc(eubc),
		.p_clk_upp8(p_clk_upp8)
	);
`else
	wire [56:0] bus_u_ke = 0;
	wire [8:0] eubc = 0;
	wire p_clk_upp8 = 0;
	wire [3:0] esalu = 0;
	wire esalum = 0;
	wire ecin00 = 0;
	wire [1:0] ecomuxs = 0;
	wire inh_ps_clk1 = 0;
	wire enprclk = 0;
	wire ext_p_clr_trap = 0;
	wire [15:0] bus_rd_ke11 = 0;
`endif
endmodule

