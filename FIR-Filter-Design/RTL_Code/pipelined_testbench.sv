// Rojan Karn - Pipelined FIR Testbench

`timescale 1ns / 1ps

module pipelined_testbench();
	`include "my_filter_parameters.sv"
	
	// NUM_SAMPLES = 27
	
	// tb signals
	logic clk;
	logic signed[15:0] inp;
	logic signed[39:0] outp;
	logic signed[39:0] outp_max;
	
	real num_samples;
	real magnitude, radians, s;
	
	// Instantiate DUT
	fir_filter dut(.clk(clk), .inp(inp), .outp(outp));
	
	// run
	initial begin
		#1;
		clk = 1'b0;
		inp = 16'b0;
		radians = 0;
		
		// start the frequency tests
		for (int i = 1; i < 27; i++) begin
			
			rad = real'((real'(i) * real'(2*3.141592654)) / real'(27));
			s = $sin(rad);
			inp = 16'($rtoi(s * real'(2**16)));
			
			// wait for all taps to finish
			repeat (340) @(posedge clk);
			
			outp_max = outp;
			for (int j = 0; j < 2000; j++) begin
				 @(posedge clk);
				 if (outp > outp_max) outp_max = outp;
			end

			magnitude = real'(20) * $log10($itor(outp_max) * (1/real'(2**14)));
			
			// display maximum output magnitude in dB for each frequency test
			$display("Section: %f | Max Magnitude Out: %f", real'(real'(i)/ real'(27)), magnitude);
			
			#1000;
		end

		#100; 
		$stop;
		
	end
	
	always #500 clk = ~clk;
	
	// always check for a new max
	always @(posedge clk) begin
		for (int i = 0; i < 27; i++) begin
			if (outp > outp_max) begin 
				outp_max = outp; 
			end
		end
	end


endmodule
