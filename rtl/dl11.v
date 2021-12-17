/*
 * This is not a real DL11 (yet?)
 * just something like a KL11 with break bit
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

		.int_a(rdr_done),
		.int_enb_a(rdr_int_enb),
		.bg_in_a(bg_in),
		.bg_out_a(bg_tmp),
		.master_clear_a(intr_done_a),
		.br_a(br_a),
		.master_a(master_a),
		.start_intr_a(master_a),
		.intr_done_a(intr_done_a),

		.int_b(pun_ready),
		.int_enb_b(pun_int_enb),
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
	wire rdr_active;
	wire rdr_done;
	reg rdr_int_enb;
	wire pun_ready;
	reg pun_int_enb;
	reg maint;

	wire rdr_csr_to_bus = select0 & in;
	wire rdr_buf_to_bus = select2 & in;
	wire pun_csr_to_bus = select4 & in;
	wire bus_to_rdr_csr = select0 & out_low;
	wire bus_to_pun_csr = select4 & out_low;
	wire bus_to_pun_buf = select6 & out_low;

	wire clk_rdr_csr, clk_pun_csr, clk_pun_buf;
	edgedet2 rdr_csr_edge(clk, reset, bus_to_rdr_csr, clk_rdr_csr);
	edgedet2 pun_csr_edge(clk, reset, bus_to_pun_csr, clk_pun_csr);
	edgedet2 pun_buf_edge(clk, reset, bus_to_pun_buf, clk_pun_buf);

	assign bus_d_out[15:12] = 0;
	assign bus_d_out[11] = rdr_csr_to_bus&rdr_active;
	assign bus_d_out[10:8] = 0;
	assign bus_d_out[7] = rdr_buf_to_bus&rd[7] | rdr_csr_to_bus&rdr_done | pun_csr_to_bus&pun_ready | bus_d_vec[7];
	assign bus_d_out[6] = rdr_buf_to_bus&rd[6] | rdr_csr_to_bus&rdr_int_enb | pun_csr_to_bus&pun_int_enb | bus_d_vec[6];
	assign bus_d_out[5:3] = (rdr_buf_to_bus ? rd[5:3] : 0) | bus_d_vec[5:3];
	assign bus_d_out[2] = rdr_buf_to_bus&rd[2] | pun_csr_to_bus&maint | bus_d_vec[2];
	assign bus_d_out[1] = rdr_buf_to_bus&rd[1];
	assign bus_d_out[0] = rdr_buf_to_bus&rd[0] | pun_csr_to_bus&break;

	wire serial_out_raw;
	wire serial_out = serial_out_raw & ~break;
	assign TX = serial_out;
	wire serial_in = maint ? serial_out : RX;
	wire [7:0] rd;

	always @(posedge clk) begin
		if(clk_rdr_csr) begin
			rdr_int_enb <= bus_d[6];
		end
		if(clk_pun_csr) begin
			break <= bus_d[0];
			maint <= bus_d[2];
			pun_int_enb <= bus_d[6];
		end
		if(bus_init) begin
			break <= 0;
			rdr_int_enb <= 0;
			maint <= 0;
			pun_int_enb <= 0;
		end
	end

	wire uart_clk;
	clkdiv #(50000000,BAUD*16) clkdivtest(clk, uart_clk);
        uart uart(.clk(clk), .reset(reset | bus_init),
		// config
		.uart_clk(uart_clk),
		.twostop(1'b1),

		// serial
		.tx(serial_out_raw),
		.rx(serial_in),

		.tx_data(bus_d[7:0]),
		.tx_data_clr(clk_pun_buf),
		.tx_data_set(clk_pun_buf),
		.tx_done(pun_ready),

		.rx_data(rd),
		.rx_data_clr(rdr_buf_to_bus),
		.rx_active(rdr_active),
		.rx_done(rdr_done));
endmodule
