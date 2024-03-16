// Rojan Karn - Pipelined FIR Testbench

`timescale 1ns / 1ps

module pipelined_testbench();
	`include "fir_params.sv"
	
	// NUM_SAMPLES = 27
	
	// tb signals
	logic clk;
	logic signed[15:0] inp;
	logic signed[39:0] outp;
	logic signed[39:0] outp_max;
	real magnitude, radians, s;
	
	// Instantiate DUT
	fir_filter dut(.clk(clk), .inp(inp), .outp(outp));
	
	// clock frequency
	always #500 clk = ~clk;
	
	// run
	initial begin
		clk = 1'b0;
		inp = 16'b0;
		radians = 0;
		
		for (int i = 1; i < 27; i++) begin
			#1000;
			radians = real'((real'(i) * real'(2*3.141592654)) / real'(27));
			s = $sin(radians);
			inp = 16'($rtoi(s * real'(2**16)));

			repeat (170) @(posedge clk); // wait 170 clock cycles before reading output
			
			outp_max = outp;
			for (int j = 0; j < 2000; j++) begin
				 @(posedge clk);
				 if (outp > outp_max) outp_max = outp;
			end
			magnitude = $log10($itor(outp_max) * (1/real'(2**16))) *  real'(20);
			
			// display output in ModelSim
			$display("Section: %f --> Max Magnitude Out: %f", real'(real'(i)/ real'(27)), magnitude);
			
		end
		$stop;
		
	end

endmodule
