// Rojan Karn
// PIPELINED FILTER
// Include filter coefficients
//`include "my_filter_parameters.sv"

// NUM_TAPS = 170
// OUTPUT WIDTH = 16 + 16 + log2(170) ~= 40

// Implements the pipelined FIR filter
module fir_filter #(parameter int sub_taps = 1, parameter logic[15:0] sub_coefs[0:84] = '{default: '0})(
    input clk,
    input logic signed[15:0] inp,
    output logic signed[39:0] outp // 16 + 16 + log2(170) = 40 bits wide for output
);
	`include "my_filter_parameters.sv"
	logic signed [39:0] tap_res;
	logic signed [39:0] delay_elements[169:1] = '{default:'0}; // try to change this default thing

	always @(posedge clk) begin
		 delay_elements[169] <= filter_coeffs[169]*inp;
		 for (int i=168; i > 0; i=i-1) begin
			  delay_elements[i] <= delay_elements[i+1] + filter_coeffs[i]*inp;
		 end
		 outp <= tap_res[39:0];
	end
	
	assign tap_res = delay_elements[1] + filter_coeffs[0]*inp;
	
endmodule
