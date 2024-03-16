// Rojan Karn
// PIPELINED FILTER

// NUM_TAPS = 170
// OUTPUT WIDTH = 16 + 16 + log2(170) ~= 40

// Implements the pipelined FIR filter
// for 2-parallel: sub_coefs[0:84]
// for 3-parallel: sub_coefs[0:55]
module fir_filter #(parameter int sub_taps = 0, parameter logic signed[15:0] sub_coefs[0:55] = '{default: '0})(
    input clk,
    input logic signed[15:0] inp,
    output logic signed[39:0] outp // 16 + 16 + log2(170) = 40 bits wide for output
);
	`include "fir_params.sv"
	
	generate
	
		if (sub_taps == 0) begin // regular use of pipelined filter
		
			logic signed [39:0] tap_res;
			logic signed [39:0] delay_elements[169:0] = '{default:'0}; // fill in zeros
			

			always @(posedge clk) begin
				 for (int i=168; i > 0; i=i-1) begin
					  delay_elements[i] <= delay_elements[i+1] + fir_coefs[i]*inp;
				 end
				 delay_elements[169] <= fir_coefs[169]*inp;
				 outp <= tap_res[39:0];
			end
			
			assign tap_res = delay_elements[1] + fir_coefs[0]*inp;
		
		end else begin // pipelined filter used as a subfilter in parallel implementation
		
			logic signed [39:0] tap_res;
			logic signed [39:0] delay_elements[sub_taps-1:1] = '{default:'0}; // fill in zeros
			
			// use sub_coefs here
			always @(posedge clk) begin
				 for (int i=sub_taps-2; i > 0; i=i-1) begin
					  delay_elements[i] <= delay_elements[i+1] + sub_coefs[i]*inp;
				 end
				 delay_elements[sub_taps-1] <= sub_coefs[sub_taps-1]*inp;
				 outp <= tap_res[39:0];
			end
			
			assign tap_res = delay_elements[1] + sub_coefs[0]*inp;
		
		
		end
	endgenerate
	
endmodule

// for 2-parallel: sub_coefs[0:84]
// for 3-parallel: sub_coefs[0:55]
module fir_filter_no_pipeline #(parameter int sub_taps = 0, parameter logic signed[15:0] sub_coefs[0:55] = '{default: '0})(
    input clk,
    input logic signed[15:0] inp,
    output logic signed[39:0] outp // 16 + 16 + log2(170) = 40 bits wide for output
);
	`include "fir_params.sv"
	
	generate
	
		if (sub_taps == 0) begin // regular use of pipelined filter
		
			logic signed [39:0] tap_res;
			logic signed [39:0] delay_elements[168:0] = '{default:'0};
			

			always @(posedge clk) begin
				 delay_elements[0] <= inp;
				 for (int i=1; i < 169; i=i+1) begin
					  delay_elements[i] <= delay_elements[i-1];
				 end
				 outp <= tap_res;
			end
			
			// change assign of tap_res to be combinational
			always_comb begin
				tap_res = fir_coefs[0] * inp;
				for (int j=1; j < 170; j=j+1) tap_res = (fir_coefs[j] * delay_elements[j-1]) + tap_res;
			end
			
		
		end else begin // non-pipelined filter used as a subfilter in parallel implementation
		
			logic signed [39:0] tap_res;
			logic signed [39:0] delay_elements[sub_taps-2:0] = '{default:'0};

			always @(posedge clk) begin
				 delay_elements[0] <= inp;
				 for (int i=1; i < sub_taps-1; i=i+1) begin
					  delay_elements[i] <= delay_elements[i-1];
				 end
				 outp <= tap_res;
			end
			
			// change assign of tap_res to be combinational
			always_comb begin
				tap_res = sub_coefs[0] * inp;
				for (int j=1; j < sub_taps; j=j+1) tap_res = (sub_coefs[j] * delay_elements[j-1]) + tap_res;
			end
		
		
		end
	endgenerate
	
endmodule


