/*
 * Attempt at a WD 1402 uart
 * Not exactly identical but hopefully close enough
 */

module uart1402(
	input wire clk,
	input wire reset,

	input wire [7:0] tr,
	input wire thrl,
	output reg tro,
	input wire trc,
	output wire thre,
	output wire tre,

	output wire [7:0] rr,
	input wire rrd,
	input wire ri,
	input wire rrc,
	output wire dr,
	input wire drr,
	output wire oe,
	output wire fe,
	output wire pe,
	input wire sfd,

	input wire crl,
	input wire pi,
	input wire epe,
	input wire sbs,
	input wire wls1,
	input wire wls2
);

	reg [1:0] wlen;
	reg evenpar;
	reg parinh;
	reg twostop;

	always @(posedge clk) begin
		if(reset) begin
			wlen <= 0;
			evenpar <= 0;
			parinh <= 0;
			twostop <= 0;
		end else if(crl) begin
			wlen <= { wls2, wls1 };
			evenpar <= epe;
			parinh <= pi;
			twostop <= sbs;
		end
	end

	reg [7:0] r_reg;
	reg [7:0] rh_reg;
	reg perr;
	reg ferr;
	reg oerr;
	reg rdone;
	reg r_start;

	wire [1:0] firstbit = {~wlen[1], ~wlen[0]};

	assign rr = rrd ? 0 : rh_reg;
	reg r_active;
	reg [3:0] r_cnt16;
	reg [3:0] r_bitcnt;
	reg r_par;
	wire r_strobe = r_cnt16 == 6;
	wire r_end = r_bitcnt[3] & (r_bitcnt[0] ^ parinh);

	assign pe = ~sfd & perr;
	assign fe = ~sfd & ferr;
	assign oe = ~sfd & oerr;
	assign dr = ~sfd & rdone;

	always @(posedge clk) begin
		if(reset) begin
			rh_reg <= 0;
			perr <= 0;
			ferr <= 0;
			oerr <= 0;
			rdone <= 0;
			r_start <= 0;
			r_active <= 0;
			rh_reg <= 0;
		end else begin
			if(rrc) begin
				if(~r_active) begin
					// start receiving
					if(~ri) begin
						r_start <= 1;
						r_active <= 1;
					end
				end else begin
					// not a start bit after all
					if(r_start & ri) begin
						r_start <= 0;
						r_active <= 0;
					end

					r_cnt16 <= r_cnt16 + 1;
					if(r_strobe) begin
						r_bitcnt <= r_bitcnt + 1;
						r_par <= r_par ^ ri;
						if(~r_bitcnt[3])
							r_reg <= {ri, r_reg[7:1]};

						if(r_start) begin
							r_start <= 0;
							r_par <= evenpar;
							r_bitcnt <= firstbit;
						end

						if(r_end) begin
							case(wlen)
							2'b00: rh_reg <= r_reg[7:3];
							2'b01: rh_reg <= r_reg[7:2];
							2'b10: rh_reg <= r_reg[7:1];
							2'b11: rh_reg <= r_reg;
							endcase
							rdone <= 1;
							oerr <= rdone;
							perr <= ~parinh & ~r_par;
							ferr <= ~ri;
							r_active <= 0;
						end
					end
				end
			end

			if(drr)
				rdone <= 0;
			if(~r_active)
				r_cnt16 <= 0;
		end
	end

	reg [7:0] t_reg;
	reg [7:0] th_reg;
	reg trempty;
	reg thrempty;
	reg t_start;
	reg t_active;
	reg [3:0] t_cnt16;
	reg [3:0] t_bitcnt;
	reg t_par;

	assign tre = ~sfd & trempty;
	assign thre = thrempty;
	wire t_parity = (t_bitcnt == 8) & ~parinh;
	wire t_shift = &t_cnt16;
	// ending with bitcnt 9, 10 or 11
	wire t_end = t_bitcnt[3] & (t_bitcnt[0] == (parinh^twostop)) &
		(t_bitcnt[1] == (~parinh|twostop));
	// Need to fill transfer reg with stop bits
	wire [7:0] t_pad;
	assign t_pad[7] = ~(wlen[1] & wlen[0]);	// if len < 8
	assign t_pad[6] = ~wlen[1];	// if len < 7
	assign t_pad[5] = ~(wlen[1] | wlen[0]);	// if len < 6
	assign t_pad[4:0] = 0;

	always @(posedge clk) begin
		if(reset) begin
			tro <= 1;
			trempty <= 1;
			thrempty <= 1;
			t_start <= 0;
			t_active <= 0;
		end else begin
			if(thrl) begin
				th_reg <= tr | t_pad;
				thrempty <= 0;
			end
			if(trempty & ~thrempty & ~thrl) begin
				trempty <= 0;
				thrempty <= 1;
				t_reg <= th_reg;
				t_start <= 1;
				t_cnt16 <= 0;
			end
			if(trc) begin
				if(t_start) begin
					t_start <= 0;
					t_active <= 1;
					tro <= 0;	// send start bit
					t_bitcnt <= firstbit;
					t_par <= ~evenpar;
				end
				if(t_active) begin
					t_cnt16 <= t_cnt16 + 1;
					if(t_shift) begin
						t_bitcnt <= t_bitcnt + 1;
						t_par <= t_par ^ t_reg[0];

						t_reg <= { 1'b1, t_reg[7:1] };
						if(t_parity)
							tro <= t_par;
						else
							tro <= t_reg[0];

						if(t_end) begin
							t_active <= 0;
							trempty <= 1;
						end
					end
				end
			end
		end
	end

endmodule

