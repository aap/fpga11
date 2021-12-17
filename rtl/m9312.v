/*
 * Does not implement the full m9312
 * just ROMs and powerup hack
 */

module m9312
#(parameter OVERRIDE_BOOT=1, BOOT_CONS=1, BOOT_OFFSET='o20)
(
	input wire clk,
	input wire reset,

	input wire enable,
	input wire bus_pwr_lo,
	input wire [17:0] bus_addr,
	output wire [17:0] bus_addr_out,
	output wire [15:0] bus_d_out,
	input wire bus_msyn,
	output wire bus_ssyn
);

	reg [15:0] rom1[0:'o400-1];
	reg [15:0] rom2[0:'o400-1];
	wire select_lo = enable & bus_msyn & (bus_addr[17:9] == 9'o765);
	wire select_hi = enable & bus_msyn & (bus_addr[17:9] == 9'o773);
	wire select = select_lo | select_hi;

	initial begin
		$readmemh("m9312.rom", rom1);
		$readmemh("m9312_DK.rom", rom2, 0, 'o77);
		$readmemh("m9312_DD.rom", rom2, 'o100, 'o177);
		$readmemh("m9312_empty.rom", rom2, 'o200, 'o277);
		$readmemh("m9312_empty.rom", rom2, 'o300, 'o377);
	end

	reg [15:0] ssyndly;	// TODO: SENSITIVE to clock
	always @(posedge clk) ssyndly <= {ssyndly[14:0], select};
	assign bus_ssyn = ssyndly[15];
	wire allow_switches = select_hi & (bus_addr[8:1] == 'o024>>1);
	wire [15:0] rom_out = {16{select_lo}}&rom1[bus_addr[8:1]] | {16{select_hi}}&rom2[bus_addr[8:1]];

	assign bus_d_out[15:13] = rom_out[15:13];
	// this flips 173000 at 777024 to 165000 !!
	wire flip_12_10 = allow_switches & BOOT_CONS;
	assign bus_d_out[12:10] = {3{flip_12_10}} ^ rom_out[12:10];
	assign bus_d_out[9] = rom_out[9];
	assign bus_d_out[8:0] = rom_out[8:0] | {9{allow_switches}}&BOOT_OFFSET;

	// powerup hack
	//  first two MSYNs after powerup will be to 24 and 26
	//  override them to 773024/6
	//  word from 773024 is 173000 then, which we'll modify by switches
	wire msyn_done, bootup_done;
	edgedet pwredge(clk, reset, ~bus_msyn, msyn_done);
	edgedet msynedge(clk, reset, ~msyn_ff, bootup_done);
	wire clr_pwrdly = bootup_done;
	wire vector = enable & OVERRIDE_BOOT & (|pwrdly);
	reg [23:0] pwrdly;
	reg msyn_ff;
	assign bus_addr_out = vector ? 'o773000 : 0;
	always @(posedge clk) begin
		if(pwrdly)
			pwrdly <= pwrdly + 1;
		if(clr_pwrdly | pwrdly == 'o10000)	// 300ms ~= 71160700
			pwrdly <= 0;
		if(msyn_done)
			msyn_ff <= ~msyn_ff;
		if(bus_pwr_lo) begin
			msyn_ff <= 0;
			pwrdly <= 1;
		end
	end
endmodule

