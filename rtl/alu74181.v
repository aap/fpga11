module alu74181(
	input wire [3:0] a,
	input wire [3:0] b,
	input wire cin,
	input wire [3:0] s,
	input wire m,

	output wire [3:0] f,
	output wire cout,
	output wire pout,
	output wire gout
);
	wire [3:0] p;
	wire [3:0] g;
	wire [3:0] h;
	wire [3:0] c;

	/* propagate */
	assign p[0] = b[0]&s[0] | ~b[0]&s[1] | a[0];
	assign p[1] = b[1]&s[0] | ~b[1]&s[1] | a[1];
	assign p[2] = b[2]&s[0] | ~b[2]&s[1] | a[2];
	assign p[3] = b[3]&s[0] | ~b[3]&s[1] | a[3];

	/* generate */
	assign g[0] = (b[0]&s[3] | ~b[0]&s[2]) & a[0];
	assign g[1] = (b[1]&s[3] | ~b[1]&s[2]) & a[1];
	assign g[2] = (b[2]&s[3] | ~b[2]&s[2]) & a[2];
	assign g[3] = (b[3]&s[3] | ~b[3]&s[2]) & a[3];

	/* half sum */
	assign h[0] = p[0] ^ g[0];
	assign h[1] = p[1] ^ g[1];
	assign h[2] = p[2] ^ g[2];
	assign h[3] = p[3] ^ g[3];

	/* carry */
	assign c[0] = p[0] &
		(cin | g[0]);
	assign c[1] = p[1] &
		(p[0] | g[1]) &
		(cin | g[0] | g[1]);
	assign c[2] = p[2] &
		(p[1] | g[2]) &
		(p[0] | g[1] | g[2]) &
		(cin | g[0] | g[1] | g[2]);

	assign gout = g[0] | g[1] | g[2] | g[3];
	assign pout = p[3] &
		(p[2] | g[3]) &
		(p[1] | g[2] | g[3]) &
		(p[0] | g[1] | g[2] | g[3]);
	assign c[3] = pout &
		(cin | gout);
	assign cout = c[3];

	/* full sum */
	assign f[0] = h[0] ^ (cin | m);
	assign f[1] = h[1] ^ (c[0] | m);
	assign f[2] = h[2] ^ (c[1] | m);
	assign f[3] = h[3] ^ (c[2] | m);

endmodule

module cla74182(
	input wire [3:0] g,
	input wire [3:0] p,
	input wire cin,

	output wire pout,
	output wire gout,
	output wire coutx,
	output wire couty,
	output wire coutz
);
	assign coutx = p[0] &
		(cin | g[0]);
	assign couty = p[1] &
		(p[0] | g[1]) &
		(cin | g[0] | g[1]);
	assign coutz = p[2] &
		(p[1] | g[2]) &
		(p[0] | g[1] | g[2]) &
		(cin | g[0] | g[1] | g[2]);

	assign gout = g[0] | g[1] | g[2] | g[3];
	assign pout = p[3] &
		(p[2] | g[3]) &
		(p[1] | g[2] | g[3]) &
		(p[0] | g[1] | g[2] | g[3]);
endmodule

