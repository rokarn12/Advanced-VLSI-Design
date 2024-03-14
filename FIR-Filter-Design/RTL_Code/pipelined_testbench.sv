// Rojan Karn - Pipelined FIR Testbench

`timescale 1ns / 1ps

module pipelined_testbench();
	`include "my_filter_parameters.sv"
		
	// define local parameters
	
	// NUM_SAMPLES = 27
	localparam int INP_WIDTH = 16;
	localparam int OUTP_WIDTH = 16;
	localparam int SIM_TIME = 1000; // Simulation time in ns
	localparam int NUM_FREQ_TESTS = 30;
	localparam int pi = 3.141592654;
	localparam real scale_factor = 1 / real'(2**14);
	localparam int CLK_PERIOD_NS = 100;
	
	// define local signals
	logic clk;
	logic signed[15:0] inp;
	logic signed[39:0] outp;
	logic signed[39:0] outp_max;
	
	real num_samples;
	real frequency, step_size, mag_dB, rad, s;
	
	// Instantiate DUT
	fir_filter dut(.clk(clk), .inp(inp), .outp(outp));
	
	// main test
	initial begin
		#1;
		clk = 1'b0;
		inp = 16'b0;
		rad = 0; s = 0;
		
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

			mag_dB = real'(20) * $log10($itor(outp_max) * (1/real'(2**14)));
			
			// display maximum output magnitude in dB for each frequency test
			$display("Clock fraction: %f | Maximum y (dB): %f", real'(real'(i)/ real'(27)), mag_dB);
			
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
