module edgedet(input wire clk, input wire reset, input wire in, output wire p);
	reg [1:0] x;
	reg [1:0] init = 0;
	always @(posedge clk or posedge reset)
		if(reset)
			init <= 0;
		else begin
			x <= { x[0], in };
			init <= { init[0], 1'b1 };
		end
	assign p = (&init) & x[0] & !x[1];
endmodule

module edgedet2(input wire clk, input wire reset, input wire in, output wire p);
	reg x;
	reg [1:0] init = 0;
	always @(posedge clk or posedge reset)
		if(reset)
			init <= 0;
		else begin
			x <= in;
			init <= { init[0], 1'b1 };
		end
	assign p = (&init) & in & !x;
endmodule

module testdly1(
	input wire clk,
	input wire reset,
	input wire in,
	output wire active,
	output wire out
);
	reg [7:0] cnt;
	always @(posedge clk) begin
		if(reset)
			cnt <= 0;
		else if(in)
			cnt <= 1;
		else if(cnt)
			cnt <= cnt + 1;
	end
	assign out = &cnt;
	assign active = |cnt & ~out;
endmodule

module testdly2(
	input wire clk,
	input wire reset,
	input wire in,
	output wire active,
	output wire out
);
	reg [8:0] cnt;
	always @(posedge clk) begin
		if(reset)
			cnt <= 0;
		else if(in)
			cnt <= 1;
		else if(cnt)
			cnt <= cnt + 1;
	end
	assign out = &cnt;
	assign active = |cnt & ~out;
endmodule

module testdly3(
	input wire clk,
	input wire reset,
	input wire in,
	output wire active,
	output wire out
);
	reg [5:0] cnt;
	always @(posedge clk) begin
		if(reset)
			cnt <= 0;
		else if(in)
			cnt <= 1;
		else if(cnt)
			cnt <= cnt + 1;
	end
	assign out = &cnt;
	assign active = |cnt & ~out;
endmodule

module testdly4(
	input wire clk,
	input wire reset,
	input wire in,
	output wire active,
	output wire out
);
	reg [2:0] cnt;
	always @(posedge clk) begin
		if(reset)
			cnt <= 0;
		else if(in)
			cnt <= 1;
		else if(cnt)
			cnt <= cnt + 1;
	end
	assign out = &cnt;
	assign active = |cnt & ~out;
endmodule

module dly60ns_edge(
	input wire clk,
	input wire reset,
	input wire in,
	output wire out
);
	// 50mhz clock -> 20ns -> 3 ticks
	reg [3:0] cnt;
	wire in_edge;
	edgedet2 inedge(clk, reset, in, in_edge);
	always @(posedge clk) begin
		if(reset | out)
			cnt <= 0;
		else if(in_edge)
			cnt <= 1;
		else if(cnt)
			cnt <= cnt + 1;
	end
	assign out = cnt == 3;
endmodule

module dly100ns(
	input wire clk,
	input wire reset,
	input wire in,
	output wire active,
	output wire out
);
	// 50mhz clock -> 20ns -> 5 ticks
	reg [3:0] cnt;
	always @(posedge clk) begin
		if(reset | out)
			cnt <= 0;
		else if(in)
			cnt <= 1;
		else if(cnt)
			cnt <= cnt + 1;
	end
	assign out = cnt == 5;
	assign active = |cnt & ~out;
endmodule

module dly100ns_edge(
	input wire clk,
	input wire reset,
	input wire in,
//	output wire active,
	output wire out
);
	// 50mhz clock -> 20ns -> 5 ticks
	reg [3:0] cnt;
	wire in_edge;
	edgedet2 inedge(clk, reset, in, in_edge);
	always @(posedge clk) begin
		if(reset | out)
			cnt <= 0;
		else if(in_edge)
			cnt <= 1;
		else if(cnt)
			cnt <= cnt + 1;
	end
	assign out = cnt == 5;
//	assign active = |cnt & ~out;
endmodule

module dly120ns_edge(
	input wire clk,
	input wire reset,
	input wire in,
	output wire out
);
	// 50mhz clock -> 20ns -> 6 ticks
	reg [3:0] cnt;
	wire in_edge;
	edgedet2 inedge(clk, reset, in, in_edge);
	always @(posedge clk) begin
		if(reset | out)
			cnt <= 0;
		else if(in_edge)
			cnt <= 1;
		else if(cnt)
			cnt <= cnt + 1;
	end
	assign out = cnt == 6;
endmodule

module dly200ns(
	input wire clk,
	input wire reset,
	input wire in,
	output wire active,
	output wire out
);
	// 50mhz clock -> 20ns -> 10 ticks
	reg [3:0] cnt;
	always @(posedge clk) begin
		if(reset | out)
			cnt <= 0;
		else if(in)
			cnt <= 1;
		else if(cnt)
			cnt <= cnt + 1;
	end
	assign out = cnt == 10;
	assign active = |cnt & ~out;
endmodule

