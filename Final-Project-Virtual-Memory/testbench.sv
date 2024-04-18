// Rojan Karn
// Virtual Memory Testbench

`timescale 1ns/100ps

module testbench();
	
	logic clk, reset, CPU_valid, CPU_write;
	logic[31:0] address, write_data_in, data_out;
	logic CPU_ready, mem_accessed;
	
	// instantiate DUT
	virtual_mem DUT (.clk(clk), .reset(reset), .instr_valid(CPU_valid), .instr_write(CPU_write), .instr_address(address),
						  .instr_wdata_in(write_data_in), .data_out(data_out), .system_ready(CPU_ready));
	
					
	logic[31:0] vectornum, errors;
	logic[97:0] testvectors[100:0];
	
	logic[31:0] expected_data_out;
	
	logic ready_for_next_test;
	
	time t1;
	
	always begin
		clk = 1; #15; clk = 0; #15;
	end

	initial begin
		$readmemb("vmem_tests.tv", testvectors);
		vectornum = 0;
		errors = 0;
		$display("Testvectors loaded");
		$display("Starting reset ...");
		clk = 0;
		reset = 1;
		#40; reset = 0;
		ready_for_next_test = 1;
	end
	
	always @(posedge clk) begin
		if (ready_for_next_test) begin
			$display("NEW INSTRUCTION BEGINNING");
			t1 = $realtime/1ns;
			{CPU_write, CPU_valid, address, write_data_in, expected_data_out} = testvectors[vectornum];
			ready_for_next_test = 0;
		end else begin
			CPU_valid = 0;
		end
	end
	
	always @(posedge clk) begin
		if (CPU_ready) begin			
			if (data_out !== expected_data_out) begin
				$display("Error in test %d: expected: %d, received: %d", vectornum, expected_data_out, data_out);
				errors = errors+1;
			end else begin
				$display("Test %d PASSED in time %d", vectornum, (($realtime/1ns)-t1));
			end
			
			$display("Test number %d: retrieved data: %d", vectornum, data_out);
			
			
			vectornum = vectornum+1;
			if (testvectors[vectornum] === 'bx) begin
				$display("%d tests completed with %d errors", vectornum, errors);
				$stop;
			end
			
			ready_for_next_test = 1;
			CPU_ready = 0;
		end
	end
	
	


endmodule

