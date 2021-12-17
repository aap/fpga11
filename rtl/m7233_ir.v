module m7233_ir(
	input wire clk,
	input wire reset,

	// inputs from DATA
	input wire [15:0] ba,
	input wire d_c,
	input wire [15:0] d,
	input wire [15:0] dmux,
	input wire reg_adrs,
	input wire d15_00_eq_0,
	input wire rx6_x7,
	input wire ps_adrs,

	// inputs from UWORD
	input wire [3:0] dad,
	input wire [2:0] sps,
	input wire [3:0] salu,
	input wire salum,
	input wire [4:0] ubf,

	// outputs
	output reg [15:0] ir,
	output wire ir14_12_eq_0,
	output wire ir14_12_eq_7,
	output wire sm0,
	output wire sm1,
	output wire sm2,
	output wire sm3,
	output wire dm0,
	output wire ovlap_instr,
	output wire ovlap_cycle,
	output wire but3x,
	output reg [5:0] bubc,
	output wire dad_3_2,
	output wire [3:0] alus,
	output wire alum,
	output wire cin,
	output wire [1:0] comuxs,
	output wire trace,
	output wire bit_cmp_tst,
	output wire cc_instr,
	output wire byte_instr,
	output wire priv_instr,
	output wire wait_,
	output wire iot,
	output wire trap,
	output wire emt,
	output wire rsvd_instr,
	output wire bpt,
	output wire ill_instr,
	output wire traps_data,
	output wire v_data,
	output wire c_data,
	output wire byte_codes,

	// inputs from TIME
	input wire clk_ir,
	input wire intr,
	input wire berr,
	input wire brq,
	input wire cbr,
	input wire brptr,

	// inputs from STATUS
	input wire init,
	input wire swtch,
	input wire begin_,
	input wire [2:0] bubc_but30,
	input wire bcon_12,
	input wire consl,
	input wire ps_c,
	input wire ps_n,
	input wire ps_t,
	input wire pwrdn,
	input wire br_instr,
	input wire true_br,
	input wire false_br,
	input wire load_ps,
	input wire pasta,
	input wire pastb,
	input wire pastc,
	input wire n_data,
	input wire ovlap,
	input wire bovflw,
	input wire wait_ff,

	// inputs from KY
	input wire halt_sw,

	// inputs from KT and KE
	input wire kt_instr,
	input wire fault_l,
	input wire ps15,
	input wire [1:0] ecomuxs,
	input wire ecin00,
	input wire [3:0] esalu,
	input wire esalum
);

	assign but3x = ubf[4] & ubf[3];
	always @(*) begin
		bubc <= 0;
		case(ubf)
		6'o00: bubc <= 0;
		6'o01: bubc[0] <= ~halt_sw;
		6'o02: bubc[0] <= ~halt_sw;
		6'o03: bubc[0] <= reg_adrs;
		6'o04: bubc[0] <= ~reg_adrs;
		6'o05: bubc[0] <= ~begin_;
		6'o06: bubc[0] <= swtch;
		6'o07: bubc[0] <= intr;
		6'o10: bubc[0] <= halt_sw;
		6'o11: bubc[0] <= ~fault_l;
		6'o12: bubc[0] <= d15_00_eq_0;
		6'o13: bubc[0] <= byte_instr;
		6'o15: bubc[0] <= jsr;
		6'o16: bubc[0] <= service;
		6'o17: bubc[0] <= ir[3];

		6'o20: bubc[1:0] <= bubc_but20;
		6'o21: bubc[1:0] <= bubc_but21;
		6'o22: bubc[1:0] <= {ir[15], sm0};
		6'o24: bubc[1] <= halt_sw;
		6'o25: bubc[1:0] <= bubc_but25;
		6'o26: bubc[1:0] <= bubc_but26;
		6'o27: bubc[1:0] <= {service, bubc0_but27};
		6'o30: bubc[2:0] <= bubc_but30;
		6'o31: bubc[1:0] <= {bit_cmp_tst, bubc0_but31};
		6'o33: bubc[3:0] <= bubc_but33;
		6'o34: bubc[3:0] <= bubc_but34;
		6'o35: bubc[5:0] <= bubc_but35;
		6'o36: bubc[5:0] <= bubc_but36;
		6'o37: bubc[5:0] <= bubc_but37;
		endcase
	end

//	wire clr_ir = 0;	// unused
	wire clr_ir = init;	// better be safe for M(F/T)PI instructions
	always @(posedge clk) begin
		if(clk_ir)
			ir <= dmux;
		if(clr_ir)
			ir <= 0;
	end

	assign ir14_12_eq_7 = ir[14:12] == 7;
	wire add_sub = ir[14:12] == 6;
	wire bis = ir[14:12] == 5;
	wire bic = ir[14:12] == 4;
	wire bit = ir[14:12] == 3;
	wire cmp = ir[14:12] == 2;
	wire mov = ir[14:12] == 1;
	assign ir14_12_eq_0 = ir[14:12] == 0;

	wire sm7 = ir[11:9] == 7;
	wire sm6 = ir[11:9] == 6;
	wire sm5 = ir[11:9] == 5;
	wire sm4 = ir[11:9] == 4;
	assign sm3 = ir[11:9] == 3;
	assign sm2 = ir[11:9] == 2;
	assign sm1 = ir[11:9] == 1;
	assign sm0 = ir[11:9] == 0;

	wire ir08_06_eq_7 = ir[8:6] == 7;
	wire ir08_06_eq_6 = ir[8:6] == 6;
	wire ir08_06_eq_5 = ir[8:6] == 5;
	wire ir08_06_eq_4 = ir[8:6] == 4;
	wire ir08_06_eq_3 = ir[8:6] == 3;
	wire ir08_06_eq_2 = ir[8:6] == 2;
	wire ir08_06_eq_1 = ir[8:6] == 1;
	wire ir08_06_eq_0 = ir[8:6] == 0;

	wire dm7 = ir[5:3] == 7;
	wire dm6 = ir[5:3] == 6;
	wire dm5 = ir[5:3] == 5;
	wire dm4 = ir[5:3] == 4;
	wire dm3 = ir[5:3] == 3;
	wire dm2 = ir[5:3] == 2;
	wire dm1 = ir[5:3] == 1;
	assign dm0 = ir[5:3] == 0;



	wire sop = ~ir[14] & ~ir[13] & ~ir[12] & ir[11] & ~ir[10] & ir[9];
	wire tst = sop & (ir[8:6] == 7);
	wire sbc = sop & (ir[8:6] == 6);
	wire adc = sop & (ir[8:6] == 5);
	wire neg = sop & (ir[8:6] == 4);
	wire dec = sop & (ir[8:6] == 3);
	wire inc = sop & (ir[8:6] == 2);
	wire com = sop & (ir[8:6] == 1);
	wire clr = sop & (ir[8:6] == 0);

	wire ir02_00_eq_7 = ir[2:0] == 7;
	wire ir02_00_eq_6 = ir[2:0] == 6;
	wire ir02_00_eq_5 = ir[2:0] == 5;
	wire ir02_00_eq_4 = ir[2:0] == 4;
	wire ir02_00_eq_3 = ir[2:0] == 3;
	wire ir02_00_eq_2 = ir[2:0] == 2;
	wire ir02_00_eq_1 = ir[2:0] == 1;
	wire ir02_00_eq_0 = ir[2:0] == 0;

	assign ovlap_instr =
		(allsop | xor_ | dop&sm0) &
		~(ir02_00_eq_7 | brq | trace | pwrdn | halt_sw) &
		~(mov & ir[15]) &
		dm0;
	assign ovlap_cycle =
		(dm6 | dm7) & (allsop | xor_ | dop&sm0 | jmp | jsr) |
		(sm6 | sm7) & dop |
		ovlap_instr;

	wire xor_ = ~ir[15] & ir14_12_eq_7 & sm4;
	wire rotshf = ir14_12_eq_0 & sm6 & ~ir[8];
	wire allsop = sop | rotshf | sxt | swab;
	wire sxt = ~ir[15] & ir14_12_eq_0 & sm6 & ir08_06_eq_7;
	wire dop = ~ir14_12_eq_7 & ~ir14_12_eq_0;
	wire ir15_08_eq_0 = ~ir[15] & ir14_12_eq_0 & sm0 & ~ir[8];
	wire swab = ir15_08_eq_0 & ir[7] & ir[6];
	wire jmp = ir15_08_eq_0 & ~ir[7] & ir[6];
	wire jsr = ~ir[15] & ir14_12_eq_0 & sm4;
	wire jmp_jsr = jmp|jsr;

	wire i1k3 = br_instr | mark | wait_ | cc_instr | sob | sxt&dm0 | swab&dm0 | kt_instr;
	wire i1k2 = sopmore&dm0 | rotshf_r_dm0 | wait_ | cc_instr | rts | trap_instr | swab&dm0 | kt_instr;
	wire i1k1 = rotshf_r_dm0 | mark | partdop_reg | cc_instr | halt_reset | sxt&dm0 | trap_instr | kt_instr;
	wire i1k0 = true_br | false_br | rti_rtt | cinstr;
	wire i1k4 = kt_instr | swab&dm0 | sxt&dm0 | sob | trap_instr | rts | halt_reset;

	wire [5:0] bubc_but37;
	wire bubc37_a = ~dm0&(allsop|dop)&~mov&(allsop|sm0);
	assign bubc_but37[5] = xor_&~dm0 | dop&~sm0 | (mov&sm0 | jmp_jsr) | bubc37_a;
	assign bubc_but37[4] = xor_&~dm0 | bubc37_a | i1k4 | mov&sm0;
	assign bubc_but37[3] = (mov&sm0 | jmp_jsr) | i1k3;
	wire ir_src = dop&~sm0;
	assign bubc_but37[2] = ir_src&ir[11] | reset_ | i1k2 | ~ir_src&bubc_but37[5]&ir[5];
	assign bubc_but37[1] = ir_src&ir[10] | i1k1 | ~ir_src&bubc_but37[5]&ir[4];
	assign bubc_but37[0] = ir_src&ir[9] | jmp_jsr&ir[3] | i1k0 | bubc_but37[4]&~i1k4&ir[3]&~dm7;

	wire ir15_03_eq_0 = ir15_08_eq_0 & ~ir[7] & ~ir[6] & dm0;
	wire rts = ir15_08_eq_0 & ir[7] & ~ir[6] & dm0;
	assign cc_instr = ir15_08_eq_0 & ir[7] & ~ir[6] & ir[5];
	wire rotshf_r_dm0 = rotshf & ~ir[6] & dm0;
	wire rotshf_l = rotshf & ir[6];
	assign byte_instr = (rotshf | dop | sop)&~add_sub&ir[15];
	wire cinstr = cc_instr & ir[4] | rotshf_r_dm0&byte_instr | (neg|reset_)&dm0 | sub&sm0&dm0;
	wire sopmore = rotshf_l | sop;
	wire mark = ~ir[15] & ir14_12_eq_0 & sm6 & ir08_06_eq_4;
	wire emt_trap = ir[15] & ir14_12_eq_0 & sm4;
	wire partdop_reg = xor_&dm0 | ~ir14_12_eq_7&~ir14_12_eq_0&~mov&sm0&dm0;
	wire sob = ~ir[15] & ir14_12_eq_7 & sm7;

	wire rti_rtt = ir15_03_eq_0 & ir[1] & ~ir[0];
	wire rtt = rti_rtt & ir[2];
	wire reset_ = ir15_03_eq_0 & ~ps15 & ir[2:0]==5;
	wire halt_reset = ir15_03_eq_0 & ~ps15 & (ir[2:0]==5 | ir[2:0]==0);
	assign priv_instr = ir15_03_eq_0 & (ir[2:0]==5 | ir[2:0]==0);
	assign wait_ = ir15_03_eq_0 & ir[2:0]==1;
	assign iot = ir15_03_eq_0 & ir[2:0]==4;
	assign bpt = ir15_03_eq_0 & ir[2:0]==3;
	assign emt = emt_trap & ~ir[8];
	assign trap = emt_trap & ir[8];
	wire trap_instr = iot | bpt | emt_trap;
	assign rsvd_instr = bubc_but37 == 0;
	assign ill_instr = bubc_but37 == 'o50;
	assign traps_data = rsvd_instr | ill_instr | trap_instr;


	wire rotshf_r = rotshf & ~ir[6];
	wire rot_r = rotshf & ir08_06_eq_0;
	wire shf_r = rotshf & ir08_06_eq_2;
	assign comuxs[1] = ecomuxs[1] | shf_r | rot_r;
	assign comuxs[0] = ecomuxs[0] | shf_r | ~rot_r&byte_instr;
	wire rot_l = rotshf & ir08_06_eq_1;
	wire cmp_inc = cmp | inc;
	assign dad_3_2 = dad[3]&dad[2];
	assign cin = dad[3] & ~(dad[2]|dad[1]) |
		dad_3_2 & cmp_inc |
		dad_3_2 & adc&ps_c |
		dad_3_2 & rot_l&ps_c |
		salu[1] & ~rx6_x7 & byte_instr & bcon_12 |
		~(byte_instr & ~rx6_x7) & salu[0] & bcon_12 |
		ecin00;

	assign bit_cmp_tst = bit|cmp|tst;
	wire alus_ir = dad_3_2 & ~sxt;
	assign alus[3] = alus_ir ? bit | rotshf_l | add_sub | dec_sbc_ps_c | esalu[3] : salu[3];
	assign alus[2] = alus_ir ? rotshf_l | dec_sbc_ps_c | cmp | xor_ | esalu[2] : salu[2];
	assign alus[1] = alus_ir ? xor_ | cmp | bic | (bit|dec_sbc_ps_c|clr) | esalu[1] : salu[1];
	assign alus[0] = alus_ir ? add_sub | dec_sbc_ps_c | bis | (bit|dec_sbc_ps_c|clr) | esalu[0] : salu[0];
	wire bic_bit = bic | bit;
	assign alum = ~dad_3_2 & salum |
		dad_3_2 & (xor_ | clr | com) |
		dad_3_2 & bic_bit |
		dad_3_2 & sxt & ~ps_n |
		esalum;


	assign trace = ps_t & ~rtt;
	wire svc_trap = trace | berr | bovflw | pwrdn;
	wire service = ps_adrs&~dm0 | brptr | cbr | svc_trap;
	wire bubc0_but27 = ovlap & ~service;
	wire [1:0] bubc_but25;
	assign bubc_but25[0] = ~brptr & wait_ff;
	assign bubc_but25[1] = ~brptr & wait_ff | ~brptr & ~wait_ff;
	wire [1:0] bubc_but26;
	assign bubc_but26[0] = ~svc_trap & (~consl&halt_sw | ~brq&~wait_ff);
	assign bubc_but26[1] = ~svc_trap & ~(~consl&halt_sw);
	wire [1:0] bubc_but20;
	assign bubc_but20[0] = byte_instr | bubc0_but27;
	assign bubc_but20[1] = byte_instr | service;
	wire [1:0] bubc_but21;
	assign bubc_but21[0] = ~ir[3] & sm0;
	assign bubc_but21[1] = ~ir[3] & ir[15];
	wire bubc0_but31 = byte_instr & ~bit_cmp_tst;
	assign byte_codes = byte_instr | swab;

	wire odd_byte = byte_instr & ba[0];
	wire [5:0] bubc_but36;
	assign bubc_but36[0] = sub&dm0 | dm6 | ir[3];
	assign bubc_but36[1] = ir[4];
	assign bubc_but36[2] = ir[5];
	assign bubc_but36[3] = mov&~dm0;
	assign bubc_but36[4] = 0;
	assign bubc_but36[5] = mov | ~dm0;
	wire [5:0] bubc_but35;
	assign bubc_but35[3:0] = bubc_but36[3:0] | {4{odd_byte}};
	assign bubc_but35[4] = 0;
	assign bubc_but35[5] = bubc_but36[5] & ~odd_byte;
	wire [3:0] bubc_but33 = bubc_but34 | {4{odd_byte}};
	wire [3:0] bubc_but34;
	assign bubc_but34[0] = byte_instr&rotshf_r | neg | dop&~sm0;
	assign bubc_but34[1] = rotshf_r | swab | sub | sopmore&odd_byte;
	assign bubc_but34[2] = dop&~odd_byte | sxt | swab | xor_;
	assign bubc_but34[3] = swab | sxt | rotshf_r | dop&odd_byte;


	// V and C inputs
	wire sub = add_sub & ir[15];
	wire add = add_sub & ~ir[15];
	wire dec_sbc_ps_c = dec|sbc&ps_c;
	wire v_rotshf = ~load_ps & rotshf & (~ps_c&n_data | ps_c&~n_data);
	wire subop = cmp | (dec|sbc&pastc) | sub | neg;
	wire ovop = adc | cmp_inc | add | subop;
	wire signb = subop & ~(~(dec|sbc&pastc) & pastb) | add&pastb;
	wire signa = ~load_ps & ~neg & pasta;
	wire v_compare1 = ~load_ps & n_data & ovop & ~signb & ~signa;
	wire v_compare2 = ~n_data & ovop & signb & signa;
	assign v_data = load_ps&dmux[1] | v_rotshf | v_compare1 | v_compare2;
	// This disables the c flag at uword 361 it seems. but why?
	wire magic = ~sps[2] & ~dm0 & sps[1] & sps[0] & odd_byte;
	wire csubop = com | subop & ~magic & ~dec;
	wire ckeep = dec | mov | xor_ | sxt | inc | bic_bit | bis | magic;
	assign c_data = d_c & ~(sbc | load_ps | csubop | rotshf_r | ckeep) |
		sbc&ps_c & n_data & ~pasta |
		load_ps & dmux[0] |
		~d_c & ~load_ps & ~sbc & csubop |
		~load_ps & ps_c & ckeep |
		~load_ps & rotshf_r & d[0];
endmodule

