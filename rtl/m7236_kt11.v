module m7236_kt11(
	input wire clk,
	input wire reset,

	// input from DATA
	input wire [15:0] dmux,
	input wire [15:0] ba,
	input wire ba17_16,

	// input from UWORD
	input wire [8:0] bupp,
	input wire clkir,
	input wire clkba,

	// input from IR
	input wire [15:0] ir,
	input wire priv_instr,
	input wire sm0,
	input wire dm0,

	// input from TIME
	input wire init,
	input wire bus_fm_ps,
	input wire bus_fm_ba,
	input wire ps_p1_p3,
	input wire p1_p3,
	input wire p2,
	input wire clk_u56_17,
	input wire clk_ir,
	input wire clk_bus,
	input wire clk_msyn,
	input wire p_clr_msyn,
	input wire msyn,
	input wire ckoda,
	input wire bc0,
	input wire bc1,
	input wire dout_low,
	input wire dout_high,

	// input from STATUS
	input wire busrd_fm_ps,
	input wire sps_2_0_eq_7,
	input wire sbc_10,
	input wire sbc_16,
	input wire but05,
	input wire but26,
	input wire stall,
	input wire consl,

	// input from KY
	input wire [17:16] sr,

	// output
	output wire ps15,
	output reg mode_sel1,
	output wire inh_ps_clk2,
	output reg relocate,
	output wire fault_l,
	output wire fault_h,
	output wire [15:0] bus_rd,
	output [17:0] bus_a,
	output wire ps_adrs,
	output wire slr_adrs,
	output wire reg_adrs,
	output wire sr_adrs,
	output wire no_msyn,
	output reg ssyn,
	output wire [15:0] bus_d_out,
	output wire kt_instr,
	output wire mfp_sm0,
	output reg s_hook,
	output reg d_hook,

	// input from KE
	input wire inh_ps_clk1
);
	assign ps15 = ps[15];
	assign bus_rd = busrd_ps | bus_ir;
	assign bus_d_out = data_mux | bus_ps;

	// PS extension
	reg [15:14] t;
	reg [15:12] ps;
	wire clr_t = p1_p3 & ~rom_a & ~rom_b;
	wire clk_t = p1_p3 & ~rom_a & rom_b & rom_c;	// actually inverted
	wire clk_ps = p_clk_msyn & msyn & ps_adrs & dout_high |
		ps_p1_p3 & sps_2_0_eq_7 & ~inh_ps_clk1 & ~inh_ps_clk2;
	assign inh_ps_clk2 = ~rom_c & ps[15];
	reg [3:0] ktrom[0:255];
	initial $readmemh("ucode_40_kt.rom", ktrom);
	wire [3:0] rom_out = bupp[8] ? 4'o00 : ~ktrom[bupp[7:0]];
	reg rom_a, rom_b, rom_c, rom_d;
	wire [15:0] busrd_ps;
	wire [15:0] bus_ps;
	assign busrd_ps[15:12] = busrd_fm_ps ? ps : 0;
	assign busrd_ps[11:0] = 0;
	assign bus_ps[15:12] = bus_fm_ps ? ps : 0;
	assign bus_ps[11:0] = 0;
	wire [1:0] modemux = { ~rom_a&rom_b | rom_b&mfpi | rom_a&~rom_b&mtpi, rom_a };
	reg mode_sel0;
	always @(*) begin
		case(modemux)
		2'b00: mode_sel0 <= ps[14];
		2'b01: mode_sel0 <= ps[14];
		2'b10: mode_sel0 <= t[14];
		2'b11: mode_sel0 <= ps[12];
		endcase
		case(modemux)
		2'b00: mode_sel1 <= ps[15];
		2'b01: mode_sel1 <= ps[15];
		2'b10: mode_sel1 <= t[15];
		2'b11: mode_sel1 <= ps[13];
		endcase
	end

	always @(posedge clk) begin
		if(clk_u56_17) begin
			rom_a <= rom_out[3];
			rom_b <= rom_out[2];
			rom_c <= rom_out[1];
			rom_d <= rom_out[0];
		end
		if(clk_ps) begin
			ps[15:14] <= dmux[15:14];
//			ps[13] <= ~(~dmux[13]&~rom_c | ~ps[15]&rom_c);
//			ps[12] <= ~(~dmux[12]&~rom_c | ~ps[14]&rom_c);
			ps[13] <= (dmux[13]|rom_c) & (ps[15]|~rom_c);
			ps[12] <= (dmux[12]|rom_c) & (ps[14]|~rom_c);
		end
		if(clk_t)
			t[15:14] <= dmux[15:14];
		if(clr_t)
			t <= 0;
		if(init)
			ps <= 0;
	end


	// STATUS, SR0
	reg mode1;
	reg mode0;
	reg nr;
	reg pl;
	reg ro;
	reg relocate_enb;
	reg maint;
	reg [3:1] sr0_page;
	reg [6:5] sr0_mode;
	wire nr_cond = mode1&~mode0 | ~mode1&mode0 | ~acf1;
	wire pl_cond = vba_gt_plf & ~ed | vba_lt_plf & ed;
	wire ro_cond = ~acf2 & acf1 & ~(~bc1 & ~bc0);	// bc0 unreadable but very likely
	wire check_paging = p_clk_msyn & relocate & ~abort;
	wire abort = nr | pl | ro;
	wire oda_err = vba[0] & ckoda & ~consl;
	// weird that they're not the same...
	assign fault_h = relocate_enb & (nr_cond | pl_cond | ro_cond) & relocate & ~stall & ~oda_err;
	assign fault_l = fault_h & abort;
	wire [15:0] sr0_data = { nr, pl, ro, 4'b0, maint, 1'b0, sr0_mode, 1'b0, sr0_page, relocate_enb };

	always @(posedge clk) begin
		// this should be edges but we don't have to care
		if(write_sr0_low)
			relocate_enb <= dmux[0];
		if(write_sr0_high) begin
			maint <= dmux[8];
			nr <= dmux[15];
			pl <= dmux[14];
			ro <= dmux[13];
		end
		if(check_paging & nr_cond) nr <= 1;
		if(check_paging & pl_cond) pl <= 1;
		if(check_paging & ro_cond) ro <= 1;

		if(clk_bus) begin
			relocate <= relocate_enb | maint&rom_d;
			mode1 <= mode_sel1;
			mode0 <= mode_sel0;
		end
		if(check_paging) begin
			sr0_page <= vba[15:13];
			sr0_mode <= {mode1, mode0};
		end
		if(stall) begin
			relocate <= 0;
			mode1 <= 0;
			mode0 <= 0;
		end

		if(init) begin
			nr <= 0;
			pl <= 0;
			ro <= 0;
			relocate_enb <= 0;
			maint <= 0;
			sr0_page <= 0;
			sr0_mode <= 0;
		end
	end


	// PAR, PBA
	reg [11:0] pars[15:0];
`ifdef SIMULATION
	// ALU seems to get confused with uninitialized data
// TODO: is that still the case?
	initial begin : initpars
		integer i;
		for(i = 0; i < 16; i = i+1) begin
			pars[i] <= 0;
			// maybe better clear those as well
			pdrs[i] <= 0;
		end
	end
`endif
	wire [11:0] par = pars[s];
	wire [15:0] vba = ba;
	wire [17:6] pba;
	wire cout03, cout07;
	wire [3:0] alus_lo = relocate ? 4'b1001 : 4'b1010;
	wire [3:0] alus_hi = relocate ? 4'b0000 : 4'b1010;
	alu74181 alu0(
		.a(par[3:0]), .b(vba[9:6]), .cin(1'b0),
		.s(alus_lo), .m(~relocate),
		.f(pba[9:6]), .cout(cout03)
	);
	alu74181 alu1(
		.a(par[7:4]), .b({vba[13]&~relocate, vba[12:10]}), .cin(cout03),
		.s(alus_lo), .m(~relocate),
		.f(pba[13:10]), .cout(cout07)
	);
	alu74181 alu2(
		.a(par[11:8]), .b({a17, a16, vba[15:14]}), .cin(cout07),
		.s(alus_hi), .m(~relocate),
		.f(pba[17:14])
	);
	assign bus_a[17:6] = bus_fm_ba ? pba[17:6] : 0;
	assign bus_a[5:0] = 0;
	always @(posedge clk) begin
		if(write_par_low) pars[s][7:0] <= dmux[7:0];
		if(write_par_high) pars[s][11:8] <= dmux[11:8];
	end


	// PDR
	wire [3:0] s = par_pdr_sel ? { buf_vba06, vba[3:1] } : { ~mode1, ba[15:13] };
	reg [14:0] pdrs[15:0];	// not all bits used
	wire [14:0] pdr = pdrs[s];
	wire [14:8] plf = pdr[14:8];
	wire vba_gt_plf = vba[12:6] > plf[14:8];
	wire vba_lt_plf = vba[12:6] < plf[14:8];
	wire w = pdr[6];
	reg prev_w;
	wire w_enb = ~sr0_select;
	wire w_data = ~par_pdr & (prev_w | relocate);
	wire ed = pdr[3];
	wire acf2 = pdr[2];
	wire acf1 = pdr[1];
	wire [15:0] pdr_data = {1'b0, plf, 1'b0, w, 2'b0, ed, acf2, acf1, 1'b0 };
	always @(posedge clk) begin
		if(clk_msyn & w_enb)
			prev_w <= w;
		if(write_pdr_low)
			pdrs[s][3:1] <= dmux[3:1];
		if(msyn & ~in & w_enb)
			pdrs[s][6] <= w_data;
		if(write_pdr_high)
			pdrs[s][14:8] <= dmux[14:8];
	end


	// internal address decode
	wire high_addr = (pba[17:12] == 'o77) & pba[10];
	wire pba_11_9_8 = pba[11] & pba[9] & pba[8];
	wire ba_6543 = pba[6] & vba[5] & vba[4] & vba[3];
	// 772300-17 and 722340-57
	wire upxr_select = pba_11_9_8 & pba[7] & ~pba[6] & ~vba[4];
	// 777600-17 and 727640-57
	wire kpxr_select = ~pba[11] & ~pba[9] & ~pba[8] & pba[7] & pba[6] & ~vba[4];
	wire sr0_select = pba_11_9_8 & ~pba[7] & ba_6543 & (vba[2] | vba[1]);
	wire kt_adrs = high_addr & (upxr_select | kpxr_select | sr0_select);
	wire par_pdr = upxr_select | kpxr_select;

	assign sr_adrs = high_addr & pba_11_9_8 & ~pba[7] & ba_6543 & ~vba[2] & ~vba[1];
	assign ps_adrs = high_addr & pba_11_9_8 & pba[7] & ba_6543 & vba[2] & vba[1];
	assign slr_adrs = high_addr & pba_11_9_8 & pba[7] & ba_6543 & vba[2] & ~vba[1];
	assign reg_adrs = high_addr & pba_11_9_8 & pba[7] & pba[6] & ~vba[5] & ~vba[4];

	reg adrs;
	reg int_adrs;
	reg wrt_sr0;
	reg par_pdr_sel;
	reg wrt_par;
	reg buf_vba06;
	wire clr_adrs = init | ~msyn;
	wire clk_adrs;
	wire p_clk_msyn;
	wire int_adrs_edge;
	wire clr_int_adrs;
	wire clr_int_adrs_done;
	wire write;
	wire clk_ssyn;
	edgedet2 msynedge(clk, reset, msyn, clk_adrs);
	edgedet2 intadrsedge(clk, reset, int_adrs, int_adrs_edge);
	dly200ns dly1(.clk(clk), .reset(reset), .in(clk_msyn), .out(p_clk_msyn));
	dly200ns dly2(.clk(clk), .reset(reset), .in(int_adrs_edge),
		.active(clr_int_adrs), .out(clr_int_adrs_done));
	dly200ns dly3(.clk(clk), .reset(reset), .in(clr_int_adrs_done),
		.active(write), .out(clk_ssyn));
	assign no_msyn = adrs | int_adrs;
	wire write_high = dout_high & write;
	wire write_low = dout_low & write;
	wire write_sr0_low = write_low & wrt_sr0;
	wire write_sr0_high = write_high & wrt_sr0;
	wire write_par_low = write_low & par_pdr_sel & wrt_par;
	wire write_par_high = write_high & par_pdr_sel & wrt_par;
	wire write_pdr_low = write_low & par_pdr_sel & ~wrt_par;
	wire write_pdr_high = write_high & par_pdr_sel & ~wrt_par;
	wire in = ~bc1;
	wire dmux_enable = int_adrs & in & (par_pdr_sel | vba[1]);
	always @(posedge clk) begin
		if(clk_adrs)
			adrs <= kt_adrs;
		if(p_clk_msyn)
			int_adrs <= adrs;
		if(clk_ssyn)
			ssyn <= 1;
		if(int_adrs_edge) begin
			wrt_sr0 <= sr0_select & ~vba[2];
			par_pdr_sel <= par_pdr;
			wrt_par <= vba[5];
// seems this was fixed in ECO M-7236-00005 (TEST61 of BKTAD)
//			buf_vba06 <= vba[6];	// this selects kernel
			buf_vba06 <= pba[6];	// this selects kernel
		end
		if(init | clr_int_adrs)
			adrs <= 0;
		if(clr_adrs) begin
			int_adrs <= 0;
			ssyn <= 0;
			wrt_sr0 <= 0;
			par_pdr_sel <= 0;
			wrt_par <= 0;
			buf_vba06 <= 0;
		end
	end


	// instruction decode
	reg mfpi;
	reg mtpi;
	wire mfpi_inst = ~(|ir[14:12]) & (&ir[11:10]) & ~ir[9] & ir[8] & ~ir[7] & ir[6];
	wire mtpi_inst = ~(|ir[14:12]) & (&ir[11:10]) & ~ir[9] & ir[8] & ir[7] & ~ir[6];
	wire reset_inst = priv_instr & ps15 & ir[0];
	assign kt_instr = mfpi_inst | mtpi_inst | reset_inst;
	wire [12:0] mfpi_newir = { 1'b1, ir[5:0], 6'o46 };
	wire [12:0] mtpi_newir = { 1'b1, 6'o26, ir[5:0] };
	wire [12:0] reset_newir = 'o240;
	wire [12:0] bus_ir = {13{clkir&mfpi_inst}}&mfpi_newir |
		{13{clkir&mtpi_inst}}&mtpi_newir |
		{13{clkir&reset_inst}}&reset_newir;

	always @(posedge clk) begin
		if(clk_ir) begin
			mfpi <= mfpi_inst;
			mtpi <= mtpi_inst;
		end
		if(init) begin
			mfpi <= 0;
			mtpi <= 0;
		end
	end


	// SR2, bus data mux
	reg [15:0] data_mux;
	reg [15:0] sr2;
	wire muxsel0 = ~(par_pdr_sel & vba[5] | ~par_pdr_sel & vba[2]);
	wire muxsel1 = par_pdr_sel;

	// PDR, PAR, SR0, SR2
	always @(*) begin
		data_mux <= 0;
		if(dmux_enable) case({muxsel1, muxsel0})
		2'b00: data_mux <= sr2;
		2'b01: data_mux <= sr0_data;
		2'b10: data_mux <= par;
		2'b11: data_mux <= pdr_data;
		endcase
	end

	always @(posedge clk) begin
		if(clk_ir & ~abort)
			sr2 <= vba;
		if(init)
			sr2 <= 0;
	end


	// bus data mux, sp select, console cntl
	wire dr6 = ir[2:0] == 6;	// actually from IR
	wire sr6 = ir[8:6] == 6;
	wire hookmuxs1 = sm0 & mfpi;
	wire hookmuxs0 = dm0 & mtpi;
	always @(*) begin
		s_hook <= 0;
		d_hook <= 0;
		if(sr6) case({hookmuxs1, hookmuxs0})
		2'b00: s_hook <= ps[15];	// normal
		2'b01: s_hook <= ps[15];	// from current
		2'b10: s_hook <= ps[13];	// from previous
		endcase
		if(dr6) case({hookmuxs1, hookmuxs0})
		2'b00: d_hook <= ps[15];	// normal
		2'b01: d_hook <= ps[13];	// to previous
		2'b10: d_hook <= ps[15];	// to current
		endcase
	end
	wire mfp = sbc_16 & sr6 & hookmuxs1;
	assign mfp_sm0 = ps[15] & ps[13] & mfp |
		~ps[15] & ~ps[13] & mfp;

	// the upper bits of the loaded switches
	reg [17:16] srreg;
	always @(posedge clk) begin
		if(ps_p1_p3 & but05)
			srreg <= sr[17:16];
		if(init | ps_p1_p3 & but26)
			srreg <= 0;
	end

	// extend address when loading SR over the bus
	// otherwise take upper bits from SR in console operation
	reg sbc_10_reg;
	always @(posedge clk) begin
		if(p2 & clkba & ~sbc_10_reg)
			sbc_10_reg <= sbc_10;
		if(p_clr_msyn)
			sbc_10_reg <= 0;
	end
	wire bamuxs = sbc_10_reg | ~consl;

	wire a17 = ~relocate & (bamuxs ? ba17_16 : srreg[17]);
	wire a16 = ~relocate & (bamuxs ? ba17_16 : srreg[16]);


endmodule

