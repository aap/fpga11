module m7234_time(
	input wire clk,
	input wire reset,

	// inputs from DATA
	input wire [15:0] ba,
	input wire ps_adrs,
	input wire slr_adrs,
	input wire sr_adrs,
	input wire bovfl_stop,
	input wire eovfl_stop,	// KJ11
	input wire [3:0] radrs,
	input wire rx6_x7,
	input wire upp_match,

	// inputs from UWORD
	input wire [1:0] clkl,
	input wire clkoff,
	input wire clkir,
	input wire wrh,
	input wire wrl,
	input wire clkb,
	input wire clkd,
	input wire clkba,
	input wire c1bus,
	input wire c0bus,
	input wire bgbus,
	input wire [3:0] dad,

	// inputs from IR
	input wire ovlap_cycle,
	input wire bit_cmp_tst,
	input wire byte_instr,

	// outputs
	output reg idle,
	output wire set_clk,
	output wire eclk_u,
	output wire clk_u56_17,
	output wire clk_u16_09,
	output wire clk_upp_pupp,
	output wire p_end,
	output wire part_p_end,
	output wire ps_p1_p3,
	output wire p1_p3,
	output wire clk_b,
	output wire wr_r15_08,
	output wire wr_r07_00,
	output wire clk_ir,
	output wire p1,
	output wire clk_bus,
	output wire clk_ba,
	output wire p2,
	output wire clk_d,
	output wire p3,

	output wire jamupp,
	output wire clr_upp0,
	output wire set_upp0,
	output wire clr_upp1,
	output wire set_upp1,
	output wire clr_upp762,
	output wire set_upp762,
	output wire clr_upp43,
	output wire set_upp43,
	output wire clr_upp5,
	output wire set_upp5,

	output reg bc0,
	output reg bc1,
	output reg ckoda,
	output reg msyn,
	output wire clk_msyn,
	output wire p_clr_msyn,
	output wire ckovf,
	output wire oda_err,
	output wire ovflw_err,
	output wire dout_low,
	output wire dout_high,
	output wire clk_bovflw,
	output wire b_intr,
	output wire brq,
	output reg bbsy,
	output reg cbr,
	output reg brptr,
	output wire ps_p_fm_bus,
	output wire bus_fm_ps,
	output wire adrs_777774,
	output wire bus_fm_sr,
	output wire bus_fm_d,
	output wire bus_fm_ba,
	output wire bus_c0_out,
	output wire bus_c1_out,
	output wire bus_bbsy_out,
	output wire bus_msyn_out,
	output wire bus_ssyn_out,
	output reg nodat,

	// inputs from STATUS
	input wire [7:5] ps_pl,
	input wire but26,
	input wire but37,
	input wire intr,
	input wire awby,
	input wire brsv,
	input wire stall,
	input wire duberr,
	input wire ovlap,
	input wire init,
	input wire begin_,
	input wire pwrup_init,
	input wire pwr_restart,
	input wire consl,
	input wire p_endreset,

	// inputs from BUS
	input wire bus_pwr_lo,
	input wire bus_init,
	input wire bus_c0,
	input wire bus_c1,
	input wire bus_bbsy,
	input wire bus_msyn,
	input wire bus_ssyn,
	input wire bus_intr,
	input wire bus_npr,
	input wire [7:4] bus_br,
	input wire bus_sack,
	output wire bus_npg,
	output wire [7:4] bus_bg,

	// inputs from KY
	input wire start_sw,
	input wire halt_sw,

	// inputs from KT
	input wire no_msyn,
	input wire fault_h,
	input wire ps15,

	// inputs from KE
	input wire enprclk,

	// inputs from KM
	input wire mclk_enable,
	input wire mclk,
	input wire mstop
);

	reg clkff;
	reg mclkff;

	wire set_clk1 =
		brsv & perif_release |
		brsv & b_intr |
		p_endreset |
		jamstart & ~pwrup_init |
		bbsy & awby & idle;
	assign set_clk =
		set_clk1 & idle & ~mclk_enable |
		(b_ssyn & msyn & idle & ~mclk_enable);
	wire idle_data = 
		jamupp |
		clkoff & ~allow_clk |
		mstop & upp_match |
		ovlap & ~clkl[1] & ~clkl[0];

	wire reclk = p1_last | p2_last | p3_last;
	wire clkdly1, clkdly2, clkdly3;
	wire p1_last = clkdly1 & ~clkl[1];
	wire p1_cont = clkdly1 & clkl[1];
	dly120ns_edge xxx1(clk, reset, clkff | mclkff, clkdly1);
	dly60ns_edge xxx2(clk, reset, p1_cont, clkdly2);
	wire p2_last = clkdly2 & ~clkl[0];
	wire p2_cont = clkdly2 & clkl[0];
	dly100ns_edge xxx3(clk, reset, p2_cont, clkdly3);
	wire p3_last = clkdly3;
	assign p1 = p1_last;
	assign p2 = p2_last | p2_cont;
	assign p3 = p3_last;

	assign p_end = reclk;
	wire clk_u = p_end | jam_clk;
	assign eclk_u = clk_u;
	assign clk_u56_17 = clk_u;
	assign clk_u16_09 = clk_u;
	assign clk_upp_pupp = clk_u;
	assign part_p_end = p_end & clkl[1];
	assign ps_p1_p3 = p1 | p3;
	assign p1_p3 = p1 | p3;
	assign clk_b = p1_p3 & clkb;
	assign wr_r15_08 = p1_p3 & wrh;
	assign wr_r07_00 = p1_p3 & wrl;
	assign clk_ir = p1_p3 & clkir;
	assign clk_bus = (p1 | p2) & bgbus;
	assign clk_ba = (p1 | p2) & clkba;
	assign clk_d = p2 & clkd;

	wire set_mclk;
	edgedet2 ffmclk0(clk, reset, mclk, set_mclk);
	always @(posedge clk or posedge reset) begin
		if(reset) begin
			clkff <= 0;
			mclkff <= 0;
			idle <= 1;
		end else begin
			if(set_clk)
				clkff <= 1;
			if(reclk) begin
				idle <= idle_data;
				clkff <= ~(idle_data | mclk_enable);
			end
			if(clkff | mclkff) begin
				clkff <= 0;
				mclkff <= 0;
				idle <= 0;
			end
			if(set_mclk)
				mclkff <= 1;
			if(bus_pwr_lo)
				idle <= 1;
		end
	end


	reg jberr;
	reg jpup;
	wire jamstart;

wire perj = 0;
	wire jamupp_cond = pwrup_init | jpup | jberr | perj | nodat;
	wire jamupp_start;
	edgedet2 ffclk0(clk, reset, jamupp_cond, jamupp_start);
	wire jam_clk;
	testdly3 dly0(clk, reset, jamupp_start, jamupp, jam_clk);
	wire jamstart_done;
	testdly4 dly1(clk, reset, jam_clk, jamstart, jamstart_done);

	wire clk_jpup;
	edgedet2 ffclk1(clk, reset,
		~(start_sw&halt_sw | pwr_restart), clk_jpup);
	always @(posedge clk or posedge reset) begin
		if(reset) begin
			jpup <= 0;	// otherwise no jamupp on pwrup_init
			jberr <= 0;
		end else begin
			if(clk_jpup)
				jpup <= ~bus_pwr_lo;
			if(jamstart | init)
				jpup <= 0;
			if(clk_msyn)
				jberr <= bus_stop;
		end
	end

	assign set_upp5 = jamupp & pwrup_init;
	assign clr_upp5 = jamupp & ~set_upp5;
	assign set_upp762 = jamupp & (duberr | ovflw_err | set_upp0);
	assign clr_upp762 = jamupp & ~set_upp762;
	assign set_upp43 = jamupp & (set_upp762 | jpup&halt_sw | nodat&consl);
	assign clr_upp43 = jamupp & ~set_upp43;
	assign set_upp1 = jamupp & (set_upp762 | oda_err | nodat&~consl);
	assign clr_upp1 = jamupp & ~set_upp1;
	assign set_upp0 = jamupp & (pwrup_init | jpup&~halt_sw);
	assign clr_upp0 = jamupp & ~set_upp0;


	// Bus cycle
	reg [14:0] msynclkdly;	// TODO: SENSITIVE to clock
	reg bus;
	reg ckovf_ff;
	reg bwait;
	reg msyna;
	wire allow_clk = bit_cmp_tst & dad[1] & dad[3];
	wire no_bus_cycle = (but37 & ~ovlap_cycle) | allow_clk;
	wire msyn_enb = ~proc_release & ~b_ssyn & bbsy & bus;
	wire clk_msyna;
	assign p_clr_msyn = init | jamupp | clr_bus;
`ifdef KT11
	edgedet2 busclk0(clk, reset, msynclkdly[6], clk_msyna);	// no idea how long this should be
	edgedet2 busclk1(clk, reset, msynclkdly[14], clk_msyn);
`else
	edgedet2 busclk0(clk, reset, msynclkdly[2], clk_msyna);
	edgedet2 busclk1(clk, reset, msynclkdly[6], clk_msyn);
`endif
	wire clr_bus;
	edgedet2 busclr0(clk, reset, ~bwait | nodat, clr_bus);
	assign ckovf = ckovf_ff & not_dati & ~ps15;
`ifdef KJ11
	assign ovflw_err = eovfl_stop & ckovf | proc_adrs & ckovf;
`else
	assign ovflw_err = bovfl_stop & ckovf | proc_adrs & ckovf;
`endif
	assign oda_err = (ckoda & ba[0] | perj | fault_h) & ~consl;
	wire bus_stop = ovflw_err | oda_err;
	wire byte_cycle = byte_instr & dad[0];
	assign bus_c0_out = bbsy & bc0;
	assign bus_c1_out = bbsy & bc1;
	wire b_msyn = bus_msyn;
	assign bus_msyn_out = msyn & ~no_msyn;
	wire not_dati = bc0 | bc1;
	wire datip = bc0 & ~bc1;
	assign dout_low = bc1 & (~bc0 | ~ba[0]);
	assign dout_high = bc1 & (~bc0 | ba[0]);
	assign clk_bovflw = p2 & ckovf & ~bit_cmp_tst;
	assign b_intr = ~bus_c1 & ~bus_c0 & bus_intr;
	always @(posedge clk) begin
		msynclkdly <= {msynclkdly[13:0], msyn_enb};

		if(clk_bus) begin
			bus <= ~no_bus_cycle;
			bc1 <= c1bus;
			// turn DATIP into DATI, or DATO into DATOB
			bc0 <= c0bus & ~bit_cmp_tst | c1bus & byte_instr & dad[0];
		end
		if(clk_msyna) msyna <= ~bus_stop;
		if(clk_msyn) msyn <= ~bus_stop;

		if(clk_ba) begin
			ckovf_ff <= ~dad[3] & dad[2] & dad[1] & rx6_x7 & ~radrs[0] & ~stall;
			ckoda <= ~(byte_instr & dad[0]);
		end
		if(init) begin
			bus <= 0;
			ckovf_ff <= 0;
			ckoda <= 0;
			bc1 <= 0;
			bc0 <= 0;
		end
		if(p1_p3)
			bwait <= 0;
		if(p_clr_msyn) begin
			msyna <= 0;
			msyn <= 0;
			bwait <= 0;
			bus <= 0;
		end
		if(idle)	// set has precedence over reset???
			bwait <= 1;
	end


wire grant = 0;	// ? grant_br?
	// Bus ownership
	reg [4:0] sackdly;
	wire b_sack = sackdly[4];	// TODO: SENSITIVE to clock (actually want 75ns here)
	wire p_but26 = p3 & but26;
// TODO: this is kinda weird, seems to be flip-flopping around
	wire perif_release = ~b_sack & ~grant & ~b_ssyn & ~b_bbsy;
	reg [14:0] perif_release_dly;
	wire d_perif_release = perif_release_dly[14];
	wire proc_release = npr | b_sack;
	wire clk_bbsy;
	wire set_bbsy = d_perif_release;
	wire clr_bbsy = clr_ptr&brsv | enprclk | p_but26;
	edgedet2 bsyedge(clk, reset, bbsy&(~clk_bus|p_clr_msyn), clk_bbsy);
	always @(posedge clk) begin
		sackdly <= {sackdly[3:0], bus_sack};
		perif_release_dly <= {perif_release_dly[13:0], perif_release|init};
		if(clk_bbsy)
			bbsy <= ~proc_release;
		if(set_bbsy)
			bbsy <= 1;
		if(clr_bbsy)
			bbsy <= 0;
	end

	wire clk_ptrd = p_but26 | ~ovlap & (p_msyn | enprclk);
//	wire clk_ptrd = p_but26 | ~ovlap & (clk_msyn | enprclk);
	wire ptrd_en = ~(b_sack | npr | grant_br);	// TODO? delay 75ns
	reg dataip;
	reg npr;
	wire clk_npr = p_bgbus | enprclk | (clk_ir | p_but26 | set_clk&~awby) | p_msyn;
	assign bus_fm_d = bbsy & bc1;
	assign bus_fm_ba = bbsy;
	assign bus_bbsy_out = bbsy;
	wire b_bbsy = bus_bbsy;
	wire clr_ptr = bus_init | p_nosack | b_sack;
	wire p_msyn, p_nosack, p_bgbus;
	dly100ns_edge nosackedge(clk, reset, nosack, p_nosack);
	dly100ns_edge bmsynedge(clk, reset, b_msyn, p_msyn);
	dly100ns_edge bgbusedge(clk, reset, bgbus, p_bgbus);
	reg [4:0] ptrd_dly;
	wire ptrd = ~ptrd_dly[4] & (|ptrd_dly[3:0]);
	wire ptrd_done = ptrd_dly[4];
	wire part_grant_br = bbsy & brsv & ~clr_ptr & brq & brptr;
	wire grant_br = part_grant_br & ~npr;
	always @(posedge clk) begin
		if(clk_ptrd & ptrd_en)
			ptrd_dly <= 1;
		else
			ptrd_dly <= {ptrd_dly[3:0], 1'b0};
		if(consl)
			ptrd_dly <= 0;	// TODO? this should produce a pulse but it doesn't

		if(ptrd_done) begin
			cbr <= halt_sw;
			brptr <= brq;
		end
		if(clk_npr & ~consl & ~ptrd)
			npr <= bus_npr & ~bus_pwr_lo & ~dataip;
		if(clr_ptr) begin
			cbr <= 0;
			brptr <= 0;
			npr <= 0;
		end
		if(clk_msyna)
			dataip = datip;
		if(bus_init)
			dataip <= 0;
	end
	assign bus_npg = npr;



	// Bus response
	wire ptrd_edge;
	edgedet2 ptrdedge(clk, reset, ptrd_dly[0], ptrd_edge);
	reg [7:4] br;
	wire brq4 = ~br[7] & ~br[6] & ~br[5] & br[4] & ~ps_pl[7];
	wire brq5 = ~br[7] & ~br[6] & br[5] & (ps_pl[7]&ps_pl[6] | ps_pl[7]&ps_pl[5]);
	wire brq6 = ~br[7] & br[6] & ~(ps_pl[7] & ps_pl[6]);
	wire brq7 = br[7] & ~(ps_pl[7] & ps_pl[6] & ps_pl[5]);
	assign brq =  brq4 | brq5 | brq6 | brq7;
	always @(posedge clk) begin
		if(ptrd_edge)
			br <= bus_br;
		if(init)
			br <= 0;
	end
	assign bus_bg[7] = brq7&grant_br;
	assign bus_bg[6] = brq6&grant_br;
	assign bus_bg[5] = brq5&grant_br;
	assign bus_bg[4] = brq4&grant_br;

	reg [15:0] ssyndly;	// TODO: SENSITIVE to clock
	reg [15:0] ps_fm_busdly;	// TODO: SENSITIVE to clock
	wire proc_adrs = slr_adrs | ps_adrs | sr_adrs;
	wire proc_respond = proc_adrs & msyn & bwait;
	wire proc_respond_ps = ps_adrs & msyn & bwait & dout_low;
	assign adrs_777774 = slr_adrs & msyn & bwait;
	assign bus_fm_ps = proc_respond & ps_adrs;
	assign bus_fm_sr = proc_respond & sr_adrs & ~begin_;
	wire ssyn = proc_respond | intr & b_intr;
	assign bus_ssyn_out = ssyndly[15];
	wire b_ssyn = bus_ssyn;
	edgedet2 psedge(clk, reset, proc_respond_ps, ps_p_fm_bus);

wire disable_tsack = 0;
	reg tsack;
	reg nosack;
	wire clk_tsack;
	edgedet2 bredge(clk, reset, grant_br | npr, clk_tsack);
	wire start_tsack_dly;
	edgedet2 tsackedge(clk, reset, tsack & ~disable_tsack, start_tsack_dly);
	wire clk_nosack;
	testdly2 tsackdly(.clk(clk), .reset(reset | clr_ptr), .in(start_tsack_dly), .out(clk_nosack));
	always @(posedge clk) begin
		if(clk_tsack)
			tsack <= 1;
		if(clk_nosack)
			nosack <= tsack;
		if(clr_ptr) begin
			tsack <= 0;
			nosack <= 0;
		end
	end

	reg tdata;
	wire clr_nodat = b_ssyn | jamstart | init;
	wire clk_tdata;
	edgedet2 msynedge(clk, reset, msyn, clk_tdata);
	wire start_tdata_dly;
	edgedet2 tdataedge(clk, reset, tdata & ~mclk_enable, start_tdata_dly);
	wire clk_nodat;
	testdly2 tdatadly(.clk(clk), .reset(reset | clr_nodat), .in(start_tdata_dly), .out(clk_nodat));
//	assign ps_p_fm_bus = ps_fm_busdly[4];

	always @(posedge clk) begin
		ssyndly <= {ssyndly[14:0], ssyn};
	//	ps_fm_busdly <= {ps_fm_busdly[14:0], bwait&msyn&ps_adrs&dout_low};

		if(clk_tdata)
			tdata <= 1;
		if(clk_nodat)
			nodat <= tdata;
		if(clr_nodat) begin
			tdata <= 0;
			nodat <= 0;
		end
	end
endmodule

