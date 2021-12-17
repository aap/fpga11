module m7232_uword(
	input wire clk,
	input wire reset,

	// outputs
	output wire [8:0] bupp,
	output reg [8:0] pupp,
	output reg [1:0] clkl,
	output reg clkoff,
	output reg clkir,
	output reg wrh,
	output reg wrl,
	output reg clkb,
	output reg clkd,
	output reg clkba,
	output reg c1bus,
	output reg c0bus,
	output reg bgbus,
	output reg [3:0] dad,
	output reg [2:0] sps,
	output reg salum,
	output reg [3:0] salu,
	output reg [3:0] sbc,
	output reg [1:0] sbmh,
	output reg [1:0] sbml,
	output reg [1:0] sdm,
	output reg sbam,
	output reg [4:0] ubf,
	output reg srs,
	output reg srd,
	output reg srba,
	output reg sri,
	output reg [3:0] rif,

	// inputs from IR
	input wire [5:0] bubc,

	// inputs from TIME
	input wire clk_u56_17,
	input wire clk_u16_09,
	input wire clk_upp_pupp,
	input wire jamupp,
	input wire clr_upp0,
	input wire set_upp0,
	input wire clr_upp1,
	input wire set_upp1,
	input wire clr_upp762,
	input wire set_upp762,
	input wire clr_upp43,
	input wire set_upp43,
	input wire clr_upp5,
	input wire set_upp5,

	// inputs from KE
	input wire p_clk_upp8,
	input wire [56:0] bus_u_in,
	input wire [8:0] eubc,
	// outputs to KE
	output wire [8:0] eupp
);

	reg [56:0] rom[0:255];
	initial $readmemh("ucode_40_base.rom", rom);
	reg [8:0] upp;
	wire [56:0] romdata = upp[8] ? 0 : rom[upp[7:0]];
	wire [56:0] bus_u = romdata | bus_u_in;
	assign bupp = upp;
	assign eupp = upp;
	// unused
	wire clr_u16_09 = 0;
	wire clr_pupp = 0;

	always @(posedge clk) begin
		if(clk_upp_pupp) begin
			upp[7:0] <= bus_u[7:0] | eubc | bubc;
			pupp <= upp;
		end
		if(p_clk_upp8)
			upp[8] = bus_u[8] | eubc[8];
		if(clk_u56_17) begin
			clkl <= bus_u[56:55];
			clkoff <= bus_u[54];
			clkir <= bus_u[53];
			wrh <= bus_u[52];
			wrl <= bus_u[51];
			clkb <= bus_u[50];
			clkd <= bus_u[49];
			clkba <= bus_u[48];
			c1bus <= bus_u[47];
			c0bus <= bus_u[46];
			bgbus <= bus_u[45];
			dad <= bus_u[44:41];
			sps <= bus_u[40:38];
			salum <= bus_u[37];
			salu <= bus_u[36:33];
			sbc <= bus_u[32:29];
			sbmh <= bus_u[28:27];
			sbml <= bus_u[26:25];
			sdm <= bus_u[24:23];
			sbam <= bus_u[22];
			ubf <= bus_u[21:17];
		end
		if(clk_u16_09) begin
			srs <= bus_u[16];
			srd <= bus_u[15];
			srba <= bus_u[14];
			sri <= bus_u[13];
			rif <= bus_u[12:09];
		end

		if(jamupp) upp[8] <= 0;
		if(set_upp0) upp[0] <= 1;
		if(clr_upp0) upp[0] <= 0;
		if(set_upp1) upp[1] <= 1;
		if(clr_upp1) upp[1] <= 0;
		if(set_upp5) upp[5] <= 1;
		if(clr_upp5) upp[5] <= 0;
		if(set_upp762) begin
			upp[7] <= 1;
			upp[6] <= 1;
			upp[2] <= 1;
		end
		if(clr_upp762) begin
			upp[7] <= 0;
			upp[6] <= 0;
			upp[2] <= 0;
		end
		if(set_upp43) begin
			upp[4] <= 1;
			upp[3] <= 1;
		end
		if(clr_upp43) begin
			upp[4] <= 0;
			upp[3] <= 0;
		end
		if(clr_pupp)
			pupp <= 0;

		if(jamupp) begin
			clkl <= 0;
			clkoff <= 0;
			clkir <= 0;
			wrh <= 0;
			wrl <= 0;
			clkb <= 0;
			clkd <= 0;
			clkba <= 0;
			c1bus <= 0;
			c0bus <= 0;
			bgbus <= 0;
			dad <= 0;
			sps <= 0;
			salum <= 0;
			salu <= 0;
			sbc <= 0;
			sbmh <= 0;
			sbml <= 0;
			sdm <= 0;
			sbam <= 0;
			ubf <= 0;
		end
		if(clr_u16_09) begin
			srs <= 0;
			srd <= 0;
			srba <= 0;
			sri <= 0;
			rif <= 0;
		end
	end
endmodule

