// Rojan Karn - PARALLEL FIR Testbench

`timescale 1ns / 1ps

module parallel_testbench();
	`include "fir_params.sv"
	
	// NUM_SAMPLES = 27
	
	// tb signals
	logic clk;
	logic signed[15:0] inp[1:0];
	logic signed[39:0] outp[1:0];
	logic signed[39:0] outp_max;
	real magnitude, radians, s;
	
	// Instantiate DUT
	parallel_2_filter_no_pipeline dut(.clk(clk), .inp(inp), .outp(outp));
	
	// clock frequency
	always #500 clk = ~clk;
	
	// run
	initial begin
		clk = 1'b0;
		inp[0] = 16'b0;
		inp[1] = 16'b0;
		radians = 0;
		
		for (int i = 1; i < 27; i++) begin
			#1000;
			
			radians = real'((real'(i) * real'(2*3.141592654)) / real'(27));
			s = $sin(radians);
			inp[0] = 16'($rtoi(s * real'(2**16)));
			inp[1] = 16'($rtoi(s * real'(2**16)));
			
			repeat (340) @(posedge clk);
			
			outp_max = (outp[0] > outp[1]) ? outp[0] : outp[1];
			for (int j = 0; j < 2000; j++) begin
				 @(posedge clk);
				 if (outp[1] > outp_max) outp_max = outp[1];
				 if (outp[0] > outp_max) outp_max = outp[0];
			end
			magnitude = $log10($itor(outp_max) * (1/real'(2**14))) *  real'(20);
			
			// display the output in ModelSim
			$display("Section: %f --> Max Magnitude Out: %f", real'(real'(i)/ real'(27)), magnitude);
			
		end
		$stop; // end simulation after 27 tests
		
	end


endmodule

module three_parallel_testbench(); // for the 3-parallel modules
	`include "fir_params.sv"
	
	// NUM_SAMPLES = 27
	
	// tb signals
	logic clk;
	logic signed[15:0] inp[2:0];
	logic signed[39:0] outp[2:0];
	logic signed[39:0] outp_max;
	
	real magnitude, radians, s;
	
	// Instantiate DUT
	fir_filter dut(.clk(clk), .inp(inp), .outp(outp));
	
	// clock frequency
	always #500 clk = ~clk;
	
	// run
	initial begin
		clk = 1'b0;
		inp[0] = 16'b0;
		inp[1] = 16'b0;
		inp[2] = 16'b0;
		radians = 0;
		
		for (int i = 1; i < 27; i++) begin
			#1000;
			
			radians = real'((real'(i) * real'(2*3.141592654)) / real'(27));
			s = $sin(radians);
			inp[0] = 16'($rtoi(s * real'(2**16)));
			inp[1] = 16'($rtoi(s * real'(2**16)));
			inp[2] = 16'($rtoi(s * real'(2**16)));
			
			repeat (340) @(posedge clk);
			
			outp_max = (outp[0] > outp[1]) ? outp[0] : outp[1];
			outp_max = (outp[2] > outp_max) ? outp[2] : outp_max;
			for (int j = 0; j < 2000; j++) begin
				 @(posedge clk);
				 if (outp[1] > outp_max) outp_max = outp[1];
				 if (outp[0] > outp_max) outp_max = outp[0];
				 outp_max = (outp[2] > outp_max) ? outp[2] : outp_max;
			end
			magnitude = $log10($itor(outp_max) * (1/real'(2**14))) *  real'(20);
			
			// display output in ModelSim
			$display("Section: %f --> Max Magnitude Out: %f", real'(real'(i)/ real'(27)), magnitude);
			
		end
		$stop;
		
	end


endmodule
