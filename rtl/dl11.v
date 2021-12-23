/*
 * DL11-W. passes ZDLDI0 but NO line clock included! attach separate KW11-L
 */
module dl11
#(parameter ADDR='o777560, VEC='o60, BAUD=9600)
(
	input wire clk,
	input wire reset,

	input wire bus_init,
	input wire [15:0] bus_d,
	input wire [17:0] bus_addr,
	input wire bus_c0,
	input wire bus_c1,
	input wire bus_bbsy,
	input wire bus_msyn,
	input wire bus_intr,
	output wire [7:4] bus_br,
	input wire bus_ssyn,
	input wire bus_sack,
	input wire [7:4] bus_bg_in,

	output wire bus_ssyn_out,
	output wire bus_sack_out,
	output wire bus_bbsy_out,
	output wire bus_intr_out,
	output wire [15:0] bus_d_out,
	output wire [7:4] bus_bg_out,

	input wire RX,
	output wire TX
);
	wire rx;
	syncsignal rxsyn(clk, RX, rx);

	wire select0, select2, select4, select6;
	wire out_high, out_low, in;
	m105_addrsel #(ADDR) addrsel(
		.clk(clk),
		.reset(reset),
		.addr(bus_addr),
		.c0(bus_c0),
		.c1(bus_c1),
		.msyn(bus_msyn),
		.ssyn(bus_ssyn_out),
		.select0(select0),
		.select2(select2),
		.select4(select4),
		.select6(select6),
		.out_high(out_high),
		.out_low(out_low),
		.in(in)
	);


	wire bg_in = bus_bg_in[4];
	wire bg_tmp;
	wire bg_out;
	wire br_a, br_b;
	wire bus_int_out;
	wire master_a, master_b;
	wire intr_done_a, intr_done_b;
	wire [7:2] bus_d_vec;
	assign bus_bg_out[7:5] = bus_bg_in[7:5];
	assign bus_bg_out[4] = bg_out;
	m782_intctl #(VEC) intctl(
		.clk(clk),
		.reset(reset),

		.vector_bit2(~master_a),

		.int_a(rcvr_done),
		.int_enb_a(rcvr_intr_enb),
		.bg_in_a(bg_in),
		.bg_out_a(bg_tmp),
		.master_clear_a(intr_done_a),
		.br_a(br_a),
		.master_a(master_a),
		.start_intr_a(master_a),
		.intr_done_a(intr_done_a),

		.int_b(xmit_rdy),
		.int_enb_b(xmit_intr_enb),
		.bg_in_b(bg_tmp),
		.bg_out_b(bg_out),
		.master_clear_b(intr_done_b),
		.br_b(br_b),
		.master_b(master_b),
		.start_intr_b(master_b),
		.intr_done_b(intr_done_b),

		.bus_bbsy(bus_bbsy),
		.bus_ssyn(bus_ssyn),
		.bus_sack_out(bus_sack_out),
		.bus_bbsy_out(bus_bbsy_out),
		.bus_intr_out(bus_intr_out),
		.bus_d_out(bus_d_vec)
	);
	assign bus_br[7:5] = 0;
	assign bus_br[4] = br_a | br_b;

	reg break;
	reg rcvr_busy;
	reg rcvr_intr_enb;
	reg xmit_intr_enb;
	reg maint;
	reg rdr_enable;	// fake. only needed for ASR33 i think

	wire rcsr_to_bus = select0 & in;
	wire rbuf_to_bus = select2 & in;
	wire xcsr_to_bus = select4 & in;
	wire bus_to_rcsr = select0 & out_low;
	wire bus_to_xcsr = select4 & out_low;
	wire bus_to_xbuf = select6 & out_low;

	wire clk_rcsr, clk_xcsr, clk_xbuf;
	edgedet2 rcsr_edge(clk, reset, bus_to_rcsr, clk_rcsr);
	edgedet2 xcsr_edge(clk, reset, bus_to_xcsr, clk_xcsr);
	edgedet2 xbuf_edge(clk, reset, bus_to_xbuf, clk_xbuf);

	wire enb_error = 1;

	assign bus_d_out[15] = rbuf_to_bus&enb_error&error;
	assign bus_d_out[14] = rbuf_to_bus&enb_error&or_err;
	assign bus_d_out[13] = rbuf_to_bus&enb_error&fr_err;
	assign bus_d_out[12] = rbuf_to_bus&enb_error&p_err;
	assign bus_d_out[11] = rcsr_to_bus&rcvr_busy;
	assign bus_d_out[10:8] = 0;
	assign bus_d_out[7] = rbuf_to_bus&rd[7] | rcsr_to_bus&rcvr_done | xcsr_to_bus&xmit_rdy | bus_d_vec[7];
	assign bus_d_out[6] = rbuf_to_bus&rd[6] | rcsr_to_bus&rcvr_intr_enb | xcsr_to_bus&xmit_intr_enb | bus_d_vec[6];
	assign bus_d_out[5:3] = {3{rbuf_to_bus}}&rd[5:3] | bus_d_vec[5:3];
	assign bus_d_out[2] = rbuf_to_bus&rd[2] | xcsr_to_bus&maint | bus_d_vec[2];
	assign bus_d_out[1] = rbuf_to_bus&rd[1];
	assign bus_d_out[0] = rbuf_to_bus&rd[0] | xcsr_to_bus&break;

	wire serial_out_raw;
	wire serial_out = serial_out_raw & ~break;
	assign TX = serial_out;
	wire serial_in = maint ? serial_out : rx;
	wire [7:0] rd;

	wire init = bus_init | reset;
	always @(posedge clk) begin
		if(clk_rcsr) begin
			rdr_enable <= bus_d[0];
			rcvr_intr_enb <= bus_d[6];
		end
		if(clk_xcsr) begin
			break <= bus_d[0];
			maint <= bus_d[2];
			xmit_intr_enb <= bus_d[6];
		end
		// not quite sure about this, but seems reasonable
		if(uart_clk & ~serial_in)
			rcvr_busy <= 1;
		if(init | rcvr_busy)
			rdr_enable <= 0;
		if(init | rcvr_done)
			rcvr_busy <= 0;
		if(init) begin
			break <= 0;
			rcvr_intr_enb <= 0;
			maint <= 0;
			xmit_intr_enb <= 0;
		end
	end

	wire uart_clk;
	clkdiv #(50000000,BAUD*16) clkdivtest(clk, uart_clk);
	wire or_err, fr_err, p_err;
	wire error = or_err | fr_err | p_err;
	wire rcvr_done, xmit_rdy;
	uart1402 uart1402(.clk(clk), .reset(init),
		.tr(bus_d[7:0]),
		.thrl(clk_xbuf),
		.tro(serial_out_raw),
		.trc(uart_clk),
		.thre(xmit_rdy),

		.rr(rd),
		.rrd(1'b0),
		.ri(serial_in),
		.rrc(uart_clk),
		.dr(rcvr_done),
		.drr(rbuf_to_bus | rdr_enable),
		.oe(or_err),
		.fe(fr_err),
		.pe(p_err),
		.sfd(1'b0),

		.crl(1'b1),
		// jumpers
		.pi(1'b1),	// no parity
		.epe(1'b1),	// even parity
		.sbs(1'b0),	// one stop bit
		.wls1(1'b1),	// 8 data bits
		.wls2(1'b1)
	);

endmodule
