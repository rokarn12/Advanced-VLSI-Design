// Rojan Karn
// 3-Parallel FIR Filter

module fir_3_parallel (input clk,
	input logic signed[15:0] inp[2:0],
	output logic signed[39:0] outp[2:0]
);
`include "fir_params.sv"
`include "fir_filter.sv" // pipelined filter
	
	// internal logic
	// filter outputs
	logic signed[39:0] out_H0;
	logic signed[39:0] out_H1;
	logic signed[39:0] out_H2, out_H2_delayed;
	logic signed[39:0] out_H0H1, out_H1H2, out_H0H1H2;
	
	// inputs
	logic signed[15:0] in_H0H1, in_H1H2, in_H0H1H2;
	
	// additions and subtraction intermediate signals
	logic signed[39:0] pre_delay_val, delayed_valH1H2;
	logic signed[39:0] A, B, C;
	

	generate
	
		// assign the delayed output according to clock
		always @(posedge clk) begin
			out_H2_delayed <= out_H2;
			delayed_valH1H2 <= pre_delay_val;
		end
		
		// input assignment
		assign in_H0H1 = {inp[0][15], inp[0]} + {inp[1][15], inp[1]};
		assign in_H1H2 = {inp[1][15], inp[1]} + {inp[2][15], inp[2]};
		assign in_H0H1H2 = in_H0H1 + {inp[2][15], inp[2]};
		
		// intermediate assigns
		assign pre_delay_val = out_H1H2 - out_H1;
		assign A = out_H0 - out_H2_delayed;
		assign B = out_H0H1 - out_H1;
		assign C = out_H0H1H2 - B;
		
		// output assignment
		assign outp[0] = A + delayed_valH1H2;
		assign outp[1] = B - A;
		assign outp[2] = C - pre_delay_val;
		
		// can't make function returning unpacked array, must make typedef
		typedef logic signed[15:0] subfs[0:55];
		
		function subfs generate_sub(int offs1);
			for (int i = 0; i < 56; i++) begin
			  generate_sub[i] = fir_coefs[offs1 + 3*i];
			end
		endfunction
		
		// generate coefficients
		// 170/3 = 56.7 ... generate list of 56 coefficients for each filter
		
		// fill in H0 coefficients
		localparam logic signed[15:0] H0_cefs[55:0] = generate_sub(0);

		// fill in H1 coefficients
		localparam logic signed[15:0] H1_cefs[55:0] = generate_sub(1);
		
		// fill in H1 coefficients
		localparam logic signed[15:0] H2_cefs[55:0] = generate_sub(2);
		
		// H0H1 coefficients
		// need function to add the coefficients
		function subfs merge(logic signed[15:0] sub1[55:0], logic signed[15:0] sub2[55:0]);
			for (int i = 0; i < 56; i++) begin
			  merge[i] = sub1[i] + sub2[i];
			end
		endfunction
		
		// add H0 and H1 coefficients together
		localparam logic signed[15:0] H0H1_cefs[55:0] = merge(H0_cefs, H1_cefs);
		
		// add H1 and H2 coefficients together
		localparam logic signed[15:0] H1H2_cefs[55:0] = merge(H1_cefs, H2_cefs);
		
		// add H0 and H1 and H2 coefficients together
		localparam logic signed[15:0] H0H1H2_cefs[55:0] = merge(H0H1_cefs, H2_cefs);

		
		// instantiate 6 FIR filter blocks for H0, H1, H2, H0+H1, H1+H2, and H0+H1+H2
		// pipelined filters
		fir_filter #(.sub_coefs(H0_cefs), .sub_taps(56)) H0 (.clk(clk), .inp(inp[0]), .outp(out_H0)); // H0
		
		fir_filter #(.sub_coefs(H1_cefs), .sub_taps(56)) H1 (.clk(clk), .inp(inp[1]), .outp(out_H1)); // H1
		
		fir_filter #(.sub_coefs(H2_cefs), .sub_taps(56)) H2 (.clk(clk), .inp(inp[2]), .outp(out_H2)); // H2
		
		fir_filter #(.sub_coefs(H0H1_cefs), .sub_taps(56)) H0H1 (.clk(clk), .inp(in_H0H1), .outp(out_H0H1)); // H0+H1
		
		fir_filter #(.sub_coefs(H1H2_cefs), .sub_taps(56)) H1H2 (.clk(clk), .inp(in_H1H2), .outp(out_H1H2)); // H1+H2
		
		fir_filter #(.sub_coefs(H0H1H2_cefs), .sub_taps(56)) H0H1H2 (.clk(clk), .inp(in_H0H1H2), .outp(out_H0H1H2)); // H0+H1+H2

	endgenerate
endmodule


module fir_3_parallel_no_pipeline (input clk,
	input logic signed[15:0] inp[2:0],
	output logic signed[39:0] outp[2:0]
);
`include "fir_params.sv"
`include "fir_filter.sv" // pipelined filter
	
	// internal logic
	// filter outputs
	logic signed[39:0] out_H0;
	logic signed[39:0] out_H1;
	logic signed[39:0] out_H2, out_H2_delayed;
	logic signed[39:0] out_H0H1, out_H1H2, out_H0H1H2;
	
	// inputs
	logic signed[15:0] in_H0H1, in_H1H2, in_H0H1H2;
	
	// additions and subtraction intermediate signals
	logic signed[39:0] pre_delay_val, delayed_valH1H2;
	logic signed[39:0] A, B, C;
	

	generate
	
		// assign the delayed output according to clock
		always @(posedge clk) begin
			out_H2_delayed <= out_H2;
			delayed_valH1H2 <= pre_delay_val;
		end
		
		// input assignment
		assign in_H0H1 = {inp[0][15], inp[0]} + {inp[1][15], inp[1]};
		assign in_H1H2 = {inp[1][15], inp[1]} + {inp[2][15], inp[2]};
		assign in_H0H1H2 = in_H0H1 + {inp[2][15], inp[2]};
		
		// intermediate assigns
		assign pre_delay_val = out_H1H2 - out_H1;
		assign A = out_H0 - out_H2_delayed;
		assign B = out_H0H1 - out_H1;
		assign C = out_H0H1H2 - B;
		
		// output assignment
		assign outp[0] = A + delayed_valH1H2;
		assign outp[1] = B - A;
		assign outp[2] = C - pre_delay_val;
		
		// can't make function returning unpacked array, must make typedef
		typedef logic signed[15:0] subfs[0:55];
		
		function subfs generate_sub(int offs1);
			for (int i = 0; i < 56; i++) begin
			  generate_sub[i] = fir_coefs[offs1 + 2*i];
			end
		endfunction
		
		// generate coefficients
		// 170/3 = 56.7 ... generate list of 56 coefficients for each filter
		
		// fill in H0 coefficients
		localparam logic signed[15:0] H0_cefs[55:0] = generate_sub(0);

		// fill in H1 coefficients
		localparam logic signed[15:0] H1_cefs[55:0] = generate_sub(1);
		
		// fill in H1 coefficients
		localparam logic signed[15:0] H2_cefs[55:0] = generate_sub(2);
		
		// H0H1 coefficients
		// need function to add the coefficients
		function subfs merge(logic signed[15:0] sub1[55:0], logic signed[15:0] sub2[55:0]);
			for (int i = 0; i < 56; i++) begin
			  merge[i] = sub1[i] + sub2[i];
			end
		endfunction
		
		// add H0 and H1 coefficients together
		localparam logic signed[15:0] H0H1_cefs[55:0] = merge(H0_cefs, H1_cefs);
		
		// add H1 and H2 coefficients together
		localparam logic signed[15:0] H1H2_cefs[55:0] = merge(H1_cefs, H2_cefs);
		
		// add H0 and H1 and H2 coefficients together
		localparam logic signed[15:0] H0H1H2_cefs[55:0] = merge(H0H1_cefs, H2_cefs);

		
		// instantiate 6 FIR filter blocks for H0, H1, H2, H0+H1, H1+H2, and H0+H1+H2
		// pipelined filters
		fir_filter_no_pipeline #(.sub_coefs(H0_cefs), .sub_taps(56)) H0 (.clk(clk), .inp(inp[0]), .outp(out_H0)); // H0
		
		fir_filter_no_pipeline #(.sub_coefs(H1_cefs), .sub_taps(56)) H1 (.clk(clk), .inp(inp[1]), .outp(out_H1)); // H1
		
		fir_filter_no_pipeline #(.sub_coefs(H2_cefs), .sub_taps(56)) H2 (.clk(clk), .inp(inp[2]), .outp(out_H2)); // H2
		
		fir_filter_no_pipeline #(.sub_coefs(H0H1_cefs), .sub_taps(56)) H0H1 (.clk(clk), .inp(in_H0H1), .outp(out_H0H1)); // H0+H1
		
		fir_filter_no_pipeline #(.sub_coefs(H1H2_cefs), .sub_taps(56)) H1H2 (.clk(clk), .inp(in_H1H2), .outp(out_H1H2)); // H1+H2
		
		fir_filter_no_pipeline #(.sub_coefs(H0H1H2_cefs), .sub_taps(56)) H0H1H2 (.clk(clk), .inp(in_H0H1H2), .outp(out_H0H1H2)); // H0+H1+H2

	endgenerate
endmodule
