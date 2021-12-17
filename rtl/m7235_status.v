module m7235_status(
	input wire clk,
	input wire reset,

	// inputs from DATA
	input wire [15:0] dmux,
	input wire [15:0] bmux,
	input wire [15:0] rd,
	input wire [15:0] d,
	input wire d15_00_eq_0,
	input wire d07_04_eq_0,
	input wire d03_00_eq_0,
	input wire ps_adrs,
	input wire bovfl,
	input wire eovfl,	// KJ11

	// inputs from UWORD
	input wire c1bus,
	input wire c0bus,
	input wire bgbus,
	input wire [3:0] dad,
	input wire [2:0] sps,
	input wire [3:0] sbc,
	input wire [4:0] ubf,

	// input from IR
	input wire [15:0] ir,
	input wire ir14_12_eq_0,
	input wire sm0,
	input wire sm1,
	input wire sm2,
	input wire sm3,
	input wire ovlap_instr,
	input wire but3x,
	input wire trace,
	input wire cc_instr,
	input wire wait_,
	input wire iot,
	input wire trap,
	input wire emt,
	input wire rsvd_instr,
	input wire bpt,
	input wire ill_instr,
	input wire traps_data,
	input wire v_data,
	input wire c_data,
	input wire byte_codes,

	// input from TIME
	input wire set_clk,
	input wire part_p_end,
	input wire ps_p1_p3,
	input wire p1_p3,
	input wire p1,
	input wire p2,
	input wire p3,
	input wire clk_d,
	input wire oda_err,
	input wire ovflw_err,
	input wire clk_bovflw,
	input wire b_intr,
	input wire jamupp,
	input wire brptr,
	input wire bus_fm_ps,
	input wire ps_p_fm_bus,
	input wire nodat,

	// outputs
	output wire [15:0] bus_d_out,
	output wire [15:0] bus_rd_out,
	output reg [7:5] ps_pl,
	output reg ps_c,
	output reg ps_n,
	output reg ps_z,
	output reg ps_v,
	output reg ps_t,
	output wire load_ps,
	output wire busrd_fm_ps,
	output reg pasta,
	output wire pastb,
	output reg pastc,
	output wire n_data,

	output wire br_instr,
	output wire true_br,
	output wire false_br,
	output wire but05,
	output wire but26,
	output wire but37,

	output reg berr,
	output reg trap_ff,
	output reg intr,
	output reg awby,
	output reg brsv,
	output reg bovflw,
	output reg pwrdn,
	output reg stall,
	output reg wait_ff,
	output reg ovlap,
	output wire duberr,

	output reg [15:0] bc,
	output wire bcon_12,

	output reg start,
	output reg begin_,
	output reg swtch,
	output reg consl,
	output reg exam,
	output reg dep,
	output wire [2:0] bubc_but30,

	output wire init,
	output wire bus_init,
	output wire pwrup_init,
	output wire pwr_restart,
	output wire p_endreset,

	// inputs from KY
	input wire ldadrs_sw,
	input wire exam_sw,
	input wire dep_sw,
	input wire cont_sw,
	input wire start_sw,
	input wire begin_sw,
	input wire halt_sw,

	// inputs from BUS
	input wire bus_pwr_lo,

	// inputs from KM
	input wire mclk_enable,

	// inputs from KE
	input wire inh_ps_clk1,
	input wire ext_p_clr_trap,

	// inputs from KT
	input wire inh_ps_clk2,
	input wire mfp_sm0
);

	// ps flags
	wire [7:0] ps_reg = {ps_pl[7:5], ps_t, ps_n, ps_z, ps_v, ps_c};
	assign bus_d_out = {16{bus_fm_ps}} & ps_reg;
	assign bus_rd_out = {16{busrd_fm_ps}} & ps_reg;
	wire sps7 = sps==7;
	wire ps_sps0 = ps_adrs & sps==0;
	wire clk_ps07_05 = ~inh_ps_clk1 & ~inh_ps_clk2 & ps_p1_p3 & sps7 |
		~inh_ps_clk1 & ps_p_fm_bus & ps_sps0;
	wire clk_ps_t = ~inh_ps_clk1 & sps7 & ps_p1_p3;
	assign load_ps = sps7 | cc_instr | ps_sps0;
	wire clk_ps_nzv = ps_p1_p3 & sps[1] |
		ps_p_fm_bus & ps_sps0;
	wire clk_ps_c = ps_p1_p3 & sps[0] |
		ps_p_fm_bus & ps_sps0;
	assign busrd_fm_ps = cc_instr & ~sps[2] & sps[1] & sps[0] |
		sps[2] & sps[1] & ~sps[0];
	assign pastb = byte_codes ? bmux[7] : bmux[15];
	wire dsign = byte_codes ? d[7] : d[15];
	assign n_data = load_ps & dmux[3] | ~load_ps & dsign;
	wire z_data = load_ps & dmux[2] | ~load_ps & d15_00_eq_0 |
		~load_ps & byte_codes & d07_04_eq_0 & d03_00_eq_0;
	always @(posedge clk) begin
		if(clk_ps07_05)
			ps_pl[7:5] <= dmux[7:5];
		if(clk_ps_t)
			ps_t <= dmux[4];
		if(clk_ps_nzv) begin
			ps_n <= n_data;
			ps_z <= z_data;
			ps_v <= v_data;
		end
		if(clk_ps_c) begin
			ps_c <= c_data;
			pastc <= ps_c;
		end
		if(clk_d)
			pasta <= byte_codes ? rd[7] : rd[15];
		if(init) begin
			ps_pl <= 0;
			ps_t <= 0;
			ps_n <= 0;
			ps_z <= 0;
			ps_v <= 0;
			ps_c <= 0;
			pasta <= 0;
		end
		if(p_but37)
			pastc <= 0;
	end

	// branch and BUT
	wire lessthan = ps_n&~ps_v | ~ps_n&ps_v;
	wire br_cond =
		sm0 & (~ir[15]&ir[8] | ir[15]&ps_n) |
		sm1 & (~ir[15]&ps_z | ir[15]&(ps_z|ps_c)) |
		sm2 & (~ir[15]&lessthan | ir[15]&ps_v) |
		sm3 & (~ir[15]&(lessthan|ps_z) | ir[15]&ps_c);
	wire branch = sm0&(ir[15] | ~ir[15]&ir[8]) | sm1 | sm2 | sm3;
	assign br_instr = branch & ir14_12_eq_0;
	assign false_br = branch & ir14_12_eq_0 & ~ir[8] & ~br_cond;
	assign true_br = ir14_12_eq_0 & ir[8] & br_cond;
	wire but01 = ubf == 5'o01;
	wire but02 = ubf == 5'o02;
	wire but03 = ubf == 5'o03;
	wire but04 = ubf == 5'o04;
	assign but05 = ubf == 5'o05;
	wire but06 = ubf == 5'o06;
	wire but07 = ubf == 5'o07;
	wire but10 = ubf == 5'o10;
	wire but24 = ubf == 5'o24;
	wire but25 = ubf == 5'o25;
	assign but26 = ubf == 5'o26;
	assign but37 = ubf == 5'o37;



	// flags
	wire clk_berr;
	wire berr_data = nodat | oda_err;
	assign duberr = berr & berr_data;
	edgedet2 berr_clk(clk, reset, ~((nodat | oda_err) & jamupp), clk_berr);
	wire clk_intr;
	edgedet2 intr_clk(clk, reset, ~(b_intr & ~intr & (set_clk|p3)), clk_intr);
	wire flag_trap_clr = pwrdn & stack04 & p3;
	wire flag_clr = init | flag_trap_clr;
	wire trap_clr1 = init | ext_p_clr_trap | flag_trap_clr | p1 & but03;
	wire trap_clr = jamupp | trap_clr1;
	wire sv_clr = p3 & but07 | trap_clr1;
	wire no_trap = ~(berr | trap_ff | intr | trace);
	wire clr_ovflw = p1_p3 & but01 & no_trap | flag_clr;
	wire p_but04 = p1 & but04;
	wire clr_pwrdn = init | p_but04 & no_trap & bovflw;
	wire awby_data = ~bgbus & ~c1bus & c0bus;
`ifdef KJ11
	wire ovflw_data = ovflw_err | eovfl;
`else
	wire ovflw_data = ovflw_err | bovfl;
`endif
	wire clk_pwrdn = 0;	// TODO
	wire clk_stall;
	wire stall_data = pwrdn | stall | ovflw_err | duberr;
	wire clr_stall = init | p_but04;
	edgedet2 stall_clk(clk, reset, ~jamupp, clk_stall);
	always @(posedge clk) begin
		if(clk_berr) berr <= berr_data;
		if(clk_intr) intr <= b_intr;
		if(clk_bovflw) bovflw <= ovflw_data;
		if(clk_pwrdn) pwrdn <= 1;
		if(clk_stall) stall <= stall_data;

		if(consl | trap_clr1) berr <= 0;
		if(trap_clr) begin
			trap_ff <= 0;
			intr <= 0;
		end
		if(p_but37) begin
			trap_ff <= traps_data;
			ovlap <= ovlap_instr;
			wait_ff <= wait_;
		end
		if(p1_p3 & awby_data)
			awby <= 1;
		if(p2 & but25 & brptr)
			brsv <= 1;
		if(flag_clr | p1_p3 & ~awby_data)
			awby <= 0;
		if(clr_ovflw) bovflw <= 0;
		if(clr_pwrdn) pwrdn <= 0;
		if(clr_stall) stall <= 0;
		if(sv_clr) begin
			brsv <= 0;
			wait_ff <= 0;
		end
		if(flag_clr) ovlap <= 0;
	end



	// B constants
	wire [4:2] stpm;
	wire notrap_trace = ~trap_ff & trace;
	wire notrap = ~trap_ff & ~trace;
	assign stpm[4] = ~trap4 & (notrap&pwrdn | trap_ff&(iot|trap|emt));
	assign stpm[3] = ~trap4 & (trap_ff&(trap|emt|rsvd_instr|bpt) | notrap_trace);
	assign stpm[2] = trap4 | trap_ff&(trap|bpt|ill_instr) | notrap&pwrdn | notrap_trace;
	wire trap4 = notrap&bovflw | stall | berr;

	assign bcon_12 = sbc == 3;
	wire stack04 = sbc == 'o17;
	always @(*) begin
		bc <= 0;
		case(sbc)
		4'o00: bc <= {stpm, 2'b00};
		4'o01: bc <= 1;
		4'o02: bc <= 2;
		4'o03: bc <= 1;
		4'o07: bc <= consl_inc;
		4'o10: bc <= 'o177570;
		4'o11: bc <= 'o24;	// jumpers
		4'o12: bc <= 'o17;
		4'o13: bc <= 'o77;
`ifdef SIMULATION
		4'o14: bc <= 0;
`else
		4'o14: bc <= {~mclk_enable, 4'b0};
`endif
		4'o15: bc <= 'o250;
		4'o16: bc <= {mfp_sm0, 1'b0};
		4'o17: bc <= 'o4;
		endcase
	end


	// console
	wire p_but37 = part_p_end&but37;
	wire clr_start = init | p_but37 | part_p_end&but10;
	wire clr_swtch = init | p_but37 | part_p_end&but3x;
	wire clk_begin, clk_start, clk_swtch;
	edgedet2 beginedge(clk, reset, ~begin_sw, clk_begin);
	edgedet2 startedge(clk, reset, ~start_sw, clk_start);
	edgedet2 swtchedge(clk, reset, ldadrs_sw|exam_sw|cont_sw|dep_sw|begin_|start, clk_swtch);
	wire clk_consl = part_p_end & (but06 | but24 | but26 | but04&begin_ | but10);
	wire clk_exam = part_p_end & (but04&dad[0] | but24 | but26 | but03 | but05);
	wire clk_dep = part_p_end & (but03&dad[0] | but24 | but26 | but05 | but04);
	wire consl_inc = exam | dep;

	assign bubc_but30[2] = begin_ | ldadrs_sw | exam_sw | cont_sw | dep_sw;
	assign bubc_but30[1] = begin_ | ldadrs_sw | cont_sw | start;
	assign bubc_but30[0] = begin_ | ldadrs_sw | exam_sw;

	always @(posedge clk) begin
		if(clk_begin) begin_ <= 1;
		if(clk_start) start <= 1;
		if(clr_start) begin
			begin_ <= 0;
			start <= 0;
		end
		if(clk_swtch) swtch <= 1;
		if(clr_swtch) swtch <= 0;
		if(clk_consl)
			consl <= but06 | but24;
		if(clk_exam)
			exam <= but04&dad[0];
		if(clk_dep)
			dep <= but03&dad[0];
		if(init) begin
			consl <= 0;
			exam <= 0;
			dep <= 0;
		end
	end


	// no idea how powerup works, but this seems workable
	wire pwr_edge;
	wire pwrup_init_done;
	edgedet2 edge0(clk, reset, ~bus_pwr_lo, pwr_edge);
	testdly1 dly0(.clk(clk), .reset(reset),
		.in(pwr_edge), .active(pwrup_init), .out(pwrup_init_done));
	wire pwr_restart_done;
	testdly2 dly1(.clk(clk), .reset(reset),
		.in(pwrup_init_done), .active(pwr_restart), .out(pwr_restart_done));

// TODO
wire start_init = start_sw;
wire begin_init = 0;
	wire start_reset = p3 & but02;
	wire reset_signal, reset_restart;
	dly20ms resetdly1(.clk(clk), .reset(reset), .in(start_reset), .active(reset_signal));
	dly70ms resetdly2(.clk(clk), .reset(reset), .in(start_reset), .active(reset_restart), .out(p_endreset));

	assign init = pwrup_init | start_init | begin_init;
	assign bus_init = init | reset_signal;
endmodule

module dly20ms(
	input wire clk,
	input wire reset,
	input wire in,
	output wire active,
	output wire out
);
	// 50mhz clock -> 20ns -> 1000000/o3641100 ticks
	reg [23:0] cnt;
	always @(posedge clk) begin
		if(reset | out)
			cnt <= 0;
		else if(in)
			cnt <= 1;
		else if(cnt)
			cnt <= cnt + 1;
	end
`ifdef SIMULATION
	assign out = cnt == 'o2000;	// testing
`else
	assign out = cnt == 'o3641100;
`endif
	assign active = |cnt & ~out;
endmodule

module dly70ms(
	input wire clk,
	input wire reset,
	input wire in,
	output wire active,
	output wire out
);
	// 50mhz clock -> 20ns -> 3500000/o15263740 ticks
	reg [23:0] cnt;
	always @(posedge clk) begin
		if(reset | out)
			cnt <= 0;
		else if(in)
			cnt <= 1;
		else if(cnt)
			cnt <= cnt + 1;
	end
`ifdef SIMULATION
	assign out = cnt == 'o4000;	// testing
`else
	assign out = cnt == 'o15263740;
`endif
	assign active = |cnt & ~out;
endmodule

