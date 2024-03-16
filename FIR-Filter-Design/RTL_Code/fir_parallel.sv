// Rojan Karn - FIR Parallel

module fir_parallel (input clk,
	input logic signed[15:0] inp[1:0],
	output logic signed[39:0] outp[1:0]
);
`include "fir_params.sv"
`include "fir_filter.sv" // pipelined filter
	
	// internal logic
	logic signed[39:0] out_H0;
	logic signed[39:0] out_H1, out_H1_delayed;
	logic signed[39:0] out_H0H1;
	logic signed[15:0] accum_inp;
	
	generate
	
		// assign the delayed output according to clock
		always @(posedge clk) begin
			out_H1_delayed <= out_H1;
		end
		
		// output assignment
		assign outp[0] = out_H1_delayed + out_H0;
		assign outp[1] = out_H0H1 - out_H0 - out_H1;
		
		assign accum_inp = {inp[0][15], inp[0]} + {inp[1][15], inp[1]}; // H0 + H1
		
		// can't make function returning unpacked array, must make typedef
		typedef logic signed[15:0] subfs[0:(NUM_TAPS/2)-1];
		
		function subfs generate_sub(int offs1);
			for (int i = 0; i < 85; i++) begin
			  generate_sub[i] = fir_coefs[offs1 + 2*i];
			end
		endfunction
		
		// generate coefficients
		
		// fill in H0 coefficients
		localparam logic signed[15:0] H0_cefs[84:0] = generate_sub(0);

		
		// fill in H1 coefficients
		localparam logic signed[15:0] H1_cefs[84:0] = generate_sub(1);
		
		// H0H1 coefficients
		// need function to add the coefficients
		function subfs merge(logic signed[15:0] sub1[84:0], logic signed[15:0] sub2[84:0]);
			for (int i = 0; i < 85; i++) begin
			  merge[i] = sub1[i] + sub2[i];
			end
		endfunction
		
		// add H0 and H1 coefficients together
		localparam logic signed[15:0] H0H1_cefs[84:0] = merge(H0_cefs, H1_cefs);

		
		// instantiate 3 FIR filter blocks for H0, H1, and H0+H1
		// pipelined filters
		fir_filter #(.sub_coefs(H0_cefs), .sub_taps(85)) H0 (.clk(clk), .inp(inp[0]), .outp(out_H0));
		
		fir_filter #(.sub_coefs(H1_cefs), .sub_taps(85)) H1 (.clk(clk), .inp(inp[1]), .outp(out_H1));
		
		fir_filter #(.sub_coefs(H0H1_cefs), .sub_taps(85)) H0H1 (.clk(clk), .inp(accum_inp), .outp(out_H0H1));



	endgenerate
endmodule

// non-pipelined 2-parallel filter
module parallel_2_filter_no_pipeline (input clk,
	input logic signed[15:0] inp[1:0],
	output logic signed[39:0] outp[1:0]
);
`include "fir_params.sv"
`include "fir_filter.sv" // using non-pipelined filter
	
	// internal logic
	logic signed[39:0] out_H0;
	logic signed[39:0] out_H1, out_H1_delayed;
	logic signed[39:0] out_H0H1;
	logic signed[15:0] accum_inp;
	
	generate
	
		// assign the delayed output according to clock
		always @(posedge clk) begin
			out_H1_delayed <= out_H1;
		end
		
		// output assignment
		assign outp[0] = out_H1_delayed + out_H0;
		assign outp[1] = out_H0H1 - out_H0 - out_H1;
		
		assign accum_inp = {inp[0][15], inp[0]} + {inp[1][15], inp[1]}; // sign extend
		
		// can't make function returning unpacked array, must make typedef
		typedef logic signed[15:0] subfs[0:(NUM_TAPS/2)-1];
		
		function subfs generate_sub(int offs1);
			for (int i = 0; i < 85; i++) begin
			  generate_sub[i] = fir_coefs[offs1 + 2*i];
			end
		endfunction
		
		// generate coefficients
		
		// fill in H0 coefficients
		localparam logic signed[15:0] H0_cefs[84:0] = generate_sub(0);

		
		// fill in H1 coefficients
		localparam logic signed[15:0] H1_cefs[84:0] = generate_sub(1);
		
		// H0H1 coefficients
		// need function to add the coefficients
		function subfs merge(logic signed[15:0] sub1[84:0], logic signed[15:0] sub2[84:0]);
			for (int i = 0; i < 85; i++) begin
			  merge[i] = sub1[i] + sub2[i];
			end
		endfunction
		
		// add H0 and H1 coefficients
		localparam logic signed[15:0] H0H1_cefs[84:0] = merge(H0_cefs, H1_cefs);

		
		// instantiate 3 FIR filter blocks for H0, H1, and H0+H1
		// non-pipelined filters
		fir_filter_no_pipeline #(.sub_coefs(H0_cefs), .sub_taps(85)) H0 (.clk(clk), .inp(inp[0]), .outp(out_H0));
		
		fir_filter_no_pipeline #(.sub_coefs(H1_cefs), .sub_taps(85)) H1 (.clk(clk), .inp(inp[1]), .outp(out_H1));
		
		fir_filter_no_pipeline #(.sub_coefs(H0H1_cefs), .sub_taps(85)) H0H1 (.clk(clk), .inp(accum_inp), .outp(out_H0H1));



	endgenerate
endmodule



