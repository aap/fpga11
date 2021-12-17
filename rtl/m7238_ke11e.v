module m7238_ke11e(
	input wire clk,
	input wire reset,

	// input from DATA
	input wire d15,
	input wire d15_00_eq_0,
	input wire b15,
	input wire [15:0] dmux,
	input wire alu00,
	input wire cout15,
	input wire [8:0] eupp,

	// inputs from IR
	input wire [15:0] ir,
	input wire ir14_12_eq_0,
	input wire ir14_12_eq_7,
	input wire rsvd_instr,
	input wire dad_3_2,

	// inputs from TIME
	input wire p1,
	input wire p2,
	input wire p3,
	input wire p_end,
	input wire part_p_end,
	input wire eclk_u,

	// inputs from STATUS
	input wire but37,

	output wire [15:0] bus_rd,
	output wire ext_p_clr_trap,
	output wire [3:0] esalu,
	output wire ecin00,
	output wire inh_ps_clk1,
	output wire [1:0] ecomuxs,
	output wire enprclk,

	output wire [8:0] eubc,
	output wire [56:0] bus_u,
	output wire p_clk_upp8
);

wire fis_instr = 0;
wire eubf4 = 0;
wire fubc1 = 0;
wire faux_alu = 0;
wire msr00 = 0;
wire msr15 = 0;
wire xxx = 0;	// cannot read this
wire fdiv = 0;
wire unfl = 0;
wire ovfl = 0;

	// BR and DR
	wire dr_0_in = ~ashc & ~(~msr15 & xxx) & ~(fdiv & ~xxx | div & ~cout15);
	wire dr_15_in = mul&alu00 | ~mul&br[0];
	reg [15:0] br;
	reg [15:0] dr;

	always @(posedge clk) begin
		if(clk_br)
			br <= dmux;
		if(e_p1_p2) case(sdr)
		2'b00: dr <= dr;
		2'b01: dr <= { dr_15_in, dr[15:1] };
		2'b10: dr <= { dr[14:0], dr_0_in };
		2'b11: dr <= br;
		endcase
	end


	// RD MUX
	reg [15:0] rd_mux;
	assign bus_rd = eupp[8] & strdm ? rd_mux : 0;
	always @(*) begin
		case(srdm)
		2'b00: rd_mux <= { eps_n, eps_z, eps_v, eps_c };
		2'b01: rd_mux <= dr;
		2'b10: rd_mux <= { br[14:0], dr[15] };
		2'b11: rd_mux <= br;
		endcase
	end


	// EUBC
	wire eis = ~ir[15] & ir14_12_eq_7;
	wire mul = eis & (ir[11:9] == 0);
	wire div = eis & (ir[11:9] == 1);
	wire ash = eis & (ir[11:9] == 2);
	wire ashc = eis & (ir[11:9] == 3);
	wire ir_075xxx = eis & (ir[11:9] == 5);
	wire eis_instr = mul | div | ash | ashc;

	// EUBC decode
	reg [4:1] eubc_;
	wire div_quit = ~d15_00_eq_0 & dr[0] |
		~b15 & ~eps_n & dr[0] |
		b15 & eps_n & dr[0];
	always @(*) begin
		eubc_ <= 0;
		if(eupp[8]) case(eubf)
		// TODO; these can be disabled by KE11-F
		4'o00: eubc_ <= 0;
		4'o01: eubc_ <= d15;
		4'o02: eubc_ <= eps_n;
		4'o03: eubc_ <= br[15];
		4'o04: eubc_ <= d15_00_eq_0;
		4'o05: eubc_ <= dr[15];
		4'o06: eubc_ <= 0;
		4'o07: eubc_ <= div_quit;

		4'o10: eubc_ <= { count_0, 1'b0 };
		4'o11: eubc_ <= { ovfl, unfl };
		4'o12: eubc_ <= { ~dr[0], b15 };
		4'o13: eubc_ <= { |br[5:0], br[5] };
		4'o14: eubc_ <= 0;	// TODO: can't read. ZB + EPS(Z) ??
		4'o15: eubc_ <= { ir[4], ir[3] };
		4'o16: eubc_ <= ir[11:9];
		4'o17: eubc_ <= { eis_instr, eis_instr&ir[5],
			eis_instr&ir[4], fis_instr | eis_instr&ir[3] };
		endcase
	end
	assign eubc[8] = rsvd_instr & ~eupp[8];		// enter EIS mode
	assign eubc[7:5] = 0;
	assign eubc[4:1] = eubc_ | fubc1;
	assign eubc[0] = 0;



	// Timing and ALU
	wire e_p1_p2 = p1 | p2;
	wire clk_eps_nz = e_p1_p2 & clknz;
	wire clk_eps_v = e_p1_p2 & clkv;
	wire clk_br = p1&clkbr | p3&clkbr;
	// eclk_u should be negated here but that doesn't work very well....
	assign p_clk_upp8 = part_p_end & but37 | clk_upp8 & eclk_u;
	wire ld_count = p1&lcnt | p2&lcnt;
	wire clk_eps_c = p1&clkc | p2&clkc;
	wire clk_count = p_end & ecnt & ~count_0;

	wire gpc1 = eupp[8] & (gpc == 1);
	wire gpc2 = eupp[8] & (gpc == 2);
	wire gpc3 = eupp[8] & (gpc == 3);
	wire gpc4 = eupp[8] & (gpc == 4);
	wire gpc5 = eupp[8] & (gpc == 5);
	wire gpc6 = eupp[8] & (gpc == 6);
	wire gpc7 = eupp[8] & (gpc == 7);
	assign ext_p_clr_trap = (fis_instr | eis_instr) & (&eubf)&eupp[8] & e_p1_p2;
	wire mul_addsub = mul & dad_3_2 & eupp[8] & gpc2;
	wire div_addsub = div & dad_3_2 & eupp[8] & gpc2;
	wire div_sub = b15 & ~dr[0] | ~b15 & dr[0];
	// if set, A + B
	assign esalu[0] = mul_addsub & eps_c & ~dr[0] |
		faux_alu & ~msr00 |
		div_addsub & ~div_sub |
		~gpc2 & dad_3_2 & eupp[8] & b15;
	assign esalu[3] = esalu[0];
	// if set, A - B - 1
	assign esalu[1] = mul_addsub & ~eps_c & dr[0] |
		faux_alu & ~msr00 |
		div_addsub & div_sub |
		~gpc2 & dad_3_2 & eupp[8] & ~b15;
	assign esalu[2] = esalu[1];
	assign ecin00 = esalu[1] | dr[15]&gpc3 | eps_c&gpc4;
	assign inh_ps_clk1 = eupp[8];
	assign ecomuxs = {2{eupp[8]}};
	assign enprclk = (eubf == 'o10) & eupp[8] & ~count_0;


	// COUNT and flags
	reg [7:0] count;
	wire count_dn = ~count[5];
	wire count_0 = count[5:0] == 0;
	reg cmux;
	reg cvmux_c;
	reg cvmux_v;
	reg nzmux_z;
	reg nzmux_n;
	reg eps_n;
	reg eps_z;
	reg eps_v;
	reg eps_c;

	always @(*) begin
		cmux <= 0;
		cvmux_c <= 0;
		cvmux_v <= 0;
		nzmux_z <= 0;
		nzmux_n <= 0;

		case(scvm)
		3'b000: cvmux_c <= br[0];
		3'b001: cvmux_c <= ~scvm[2];
		3'b010: cvmux_c <= dr[0];
		3'b011: cvmux_c <= br[15];	// can't read this
		3'b100: cmux <= cout15;
		3'b101: cmux <= 0;
		3'b110: cmux <= 0;
		3'b111: cmux <= alu00;
		endcase

		case(scvm[1:0])
		2'b00: cvmux_v <= br[1];
		2'b01: cvmux_v <= ~scvm[2];
		2'b10: cvmux_v <= 0;
		2'b11: cvmux_v <= eps_v | (br[14]|br[15])&(~br[14]|~br[15]);
		endcase

		case(snzm)
		2'b00: nzmux_z <= br[2];
		2'b01: nzmux_z <= 1;
		2'b10: nzmux_z <= d15_00_eq_0;
		2'b11: nzmux_z <= 0;
		endcase

		case(snzm)
		2'b00: nzmux_n <= br[3];
		2'b01: nzmux_n <= eps_n;
		2'b10: nzmux_n <= br[15];
		2'b11: nzmux_n <= br[15];
		endcase
	end

	always @(posedge clk) begin
		if(ld_count)
			count <= br[7:0];
		if(clk_count & ~count_0) begin
			if(count_dn)
				count <= count - 1;
			else
				count <= count + 1;
		end

		if(clk_eps_nz) eps_n <= nzmux_n;
		if(clk_eps_nz) eps_z <= nzmux_z;
		if(clk_eps_v) eps_v <= cvmux_v;
		if(clk_eps_c) eps_c <= cvmux_c | cmux;
	end


	// ROM
	reg [56:0] rom1[0:255];
	reg [80:57] rom2[0:255];
	initial $readmemh("ucode_40_ke.rom", rom1);
	initial $readmemh("ucode_40_eis.rom", rom2);
	// this is a bit simplified but it works fine
	assign bus_u = eupp[8] ? rom1[eupp[7:0]] : 0;
	wire [80:57] erom = eupp[8] ? rom2[eupp[7:0]] : 0;

	reg strdm;
	reg [1:0] srdm;
	reg [1:0] sdr;
	reg [2:0] scvm;
	reg [1:0] snzm;
	reg clknz;
	reg clkv;
	reg clkc;
	reg [2:0] gpc;
	reg clk_upp8;
	reg lcnt;
	reg ecnt;
	reg [3:0] eubf;
	reg clkbr;

	wire clk_eu_80_57 = ~(~eclk_u & eupp[8]);	// TODO: edge
	always @(posedge clk) begin
		if(clk_eu_80_57) begin
			strdm <= erom[80];
			srdm <= erom[79:78];
			sdr <= erom[77:76];
			scvm <= erom[75:73];
			snzm <= erom[72:71];
			clknz <= erom[70];
			clkv <= erom[69];
			clkc <= erom[68];
			gpc <= erom[67:65];
			clk_upp8 <= erom[64];
			lcnt <= erom[63];
			ecnt <= erom[62];
			eubf <= erom[61:58];
			clkbr <= erom[57];
		end
		if(~eupp[8])
			clk_upp8 <= 0;
	end

endmodule
