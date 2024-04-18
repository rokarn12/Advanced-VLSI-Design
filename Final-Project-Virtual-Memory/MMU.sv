// Memory Management Unit (MMU)

`include "defines.sv"

`timescale 1ns/100ps

module MMU (
			input logic clk, reset,
			
			// instructions from CPU
			input logic valid_instr,
			input logic CPU_write,
			input logic [31:0] address,
			//input logic [31:0] write_data_in,		// dont need to deal with data
			
			// output to CPU
			output logic MMU_ready,
			//output logic [31:0] data_out,				// dont need to deal with data
			
			// inputs from MEM
			input logic mem_ready,
			input logic restart_instr,
			input logic update_page_table,
			//input logic [31:0] mem_data_in,
			input logic [`PPN_WIDTH-1:0] valid_PPN,
			input logic [`PPN_WIDTH-1:0] invalid_PPN,
			
			// outputs to MEM
			output logic MMU_valid,
			output logic MMU_write,
			//output logic [31:0] MMU_wdata_out,		// dont need to deal with data
			output logic [`PPN_WIDTH-1:0] PPN_out,
			output logic [`OFFSET_WIDTH-1:0] offset_out,
			output logic page_fault,
			
			// inputs from TLB
			input logic tlb_ready,
			input logic tlb_miss,
			input logic [`PPN_WIDTH-1:0] translated_PPN,
			
			// outputs to TLB
			output logic translation_request,
			output logic [`VPN_WIDTH-1:0] VPN_out,
			output logic new_entry_request,
			output logic [`PPN_WIDTH-1:0] tlb_PPN_out
);

	// struct for values of Page Table (PT) map
	typedef struct {
	
		logic valid;			// indicates whether the page is present
		logic [`PPN_WIDTH-1:0] PPN;		// physical page number
	
	} PT_map_line;
	
	// does not need to be associative array, regular array is fine
	PT_map_line page_table[64];
	
	initial begin
		// initialize PT map
		
		// every 8 addresses maps to one page
		logic [`PPN_WIDTH-1:0] phys_page_num = 0;
		
		for (int i = 0; i < 64; i++) begin
			if (i % 8 == 0 && i > 0) phys_page_num = phys_page_num+1;
			
			page_table[i].valid = (i % 2 == 0) ? 1 : 0;
			page_table[i].PPN = (i % 2 == 0) ? phys_page_num : phys_page_num + 8;
		
		end
		// PT map should be initialized now
	
	end // end initial block
	
	// do instruction extraction
	
	// hold instruction on page fault
	
	// ACCESS TO TLB SHOULD BE FASTER THAN ACCESS TO PAGE TABLE
	
	// FSM Design
	
	typedef enum logic [2:0] {IDLE, TLB_ACC, PT_ACC, PAGE_FLT, SEND} state_t;
	state_t curr_state, next_state;
	
	// handle state transitions on clock edge
	always @(posedge clk) begin
		if (reset) curr_state <= IDLE;
		else curr_state <= next_state;
	end
	
	// hold the current instruction in case of page fault
	logic [`VPN_WIDTH-1:0] curr_VPN;
	logic [`OFFSET_WIDTH-1:0] curr_offset;
	logic [31:0] curr_instr;
	logic [`PPN_WIDTH-1:0] curr_PPN;
	logic curr_write;
	logic [31:0] curr_wdata;
	
	
	// handle state functionality
	always @(posedge clk) begin
		if (reset) begin
			//MMU_ready <= 1'b1;
			MMU_valid <= 1'b0;
		end
		next_state <= curr_state;
		MMU_valid <= 1'b0;
	
		// case statement
		case (curr_state)
			
			// waiting for instruction
			IDLE: begin
				if (valid_instr) begin
					//$display("MMU: Received instruction from CPU");
					// instruction came in, mark MMU busy
					MMU_ready <= 1'b0;
					
					MMU_valid <= 1'b0;
					curr_instr <= address;
					curr_write <= CPU_write;
					curr_VPN <= address[7:2];
					curr_offset <= address[1:0];
					//curr_wdata <= write_data_in;		// dont need to deal with data
					// go to EXTRACT state
					next_state <= TLB_ACC;
				end else begin
					//$display("MMU: Waiting for instruction from CPU");
					// waiting for valid instruction, mark MMU ready
					MMU_ready <= 1'b1;
					MMU_valid <= 1'b0;
					curr_instr <= 32'b0;
					curr_write <= 0;
					curr_wdata <= 0;
					
					page_fault <= 1'b0;
					MMU_write <= 0;
					//MMU_wdata_out <= 0;
					PPN_out <= 0;
					offset_out <= 0;
					
					// stay in this state
					next_state <= IDLE;
				end
			
			end // end idle
			
			
			// check the TLB for the requested translation
			TLB_ACC: begin
				//$display("MMU: In TLB_ACC state");
				// get instruction details
				curr_VPN <= curr_instr[7:2];
				curr_offset <= curr_instr[1:0];
				
				// send outputs to TLB and wait for response
				// this is a translation request
				translation_request <= 1'b1;
				new_entry_request <= 1'b0;
				VPN_out <= curr_instr[7:2];
				
				if (tlb_ready) begin
					// toggle off request signal
					translation_request <= 1'b0;
					new_entry_request <= 1'b0;
					// got a response from TLB
					if (tlb_miss) begin
						// miss in TLB, must check page table
						//$display("MMU: Could not find VPN %d in TLB", curr_VPN);
						curr_PPN <= 0;
						next_state <= PT_ACC;
					end else begin
						// hit in TLB
						curr_PPN <= translated_PPN;
						// got the PPN, go to SEND state
						next_state <= SEND;
					end // end if tlb miss
				end else begin
					// no response yet, stay in this state
					next_state <= TLB_ACC;
				end // end if tlb ready
			
			end // end TLB access
			
			// get translation from page table
			PT_ACC: begin
				//$display("MMU: In PT_ACC state");
				
				// first check for validity
				if (page_table[curr_VPN].valid) begin
					// this is valid, add this entry to TLB, and go to SEND step
					
					// this is a new entry request
					new_entry_request <= 1'b1;
					translation_request <= 1'b0;
					VPN_out <= curr_VPN;
					tlb_PPN_out <= page_table[curr_VPN].PPN;
					
					// not a page fault
					page_fault <= 1'b0;
					
					// access to page table, set delay
					$display("MMU: Accessing page table, delay 25 units");
					#25;
					
					// set the current PPN and go to next state
					curr_PPN <= page_table[curr_VPN].PPN;
					next_state <= SEND;
					
				end else begin
					// invalid, trigger PAGE FAULT
					$display("Tried to access VPN %d but not valid -> page fault", curr_VPN);
					// this is NOT a new entry request
					new_entry_request <= 1'b0;
					VPN_out <= 0;
					tlb_PPN_out <= 0;
					
					// begin page fault stuff
					curr_PPN <= page_table[curr_VPN].PPN;
					// GO TO PAGE FAULT STATE
					next_state <= PAGE_FLT;
				
					
				end
			
			end // end page table access
			
			// handle page fault
			PAGE_FLT: begin
				//$display("MMU: In PAGE_FLT state");
				// send a page fault request to main mem
				MMU_valid <= 1'b1;
				page_fault <= 1'b1;
				PPN_out <= curr_PPN;	// if doesn't work, try curr_PPN instead for RHS
				
				//$display("MMU: Sent PPN %d to mem for page fault request", PPN_out);
				
				if (mem_ready) begin
					// toggle off MMU request
					MMU_valid <= 1'b0;
					page_fault <= 1'b0;
					
					// received a response from memory, check restart and update signals
					if (update_page_table && restart_instr) begin
						//$display("MMU: valid_PPN: %d	invalid_PPN: %d", valid_PPN, invalid_PPN);
						// validate the new page in DRAM
						//page_table[valid_PPN].valid <= 1'b1; // cant do it like this, need to access by VPN instead
						// invalidate the replaced page
						//page_table[invalid_PPN].valid <= 1'b0;
						
						// update page table by VPN
						for (int i = 0; i < 64; i++) begin
							if (page_table[i].PPN == valid_PPN) begin
								page_table[i].valid <= 1'b1;
							end
							else if (page_table[i].PPN == invalid_PPN) begin
								page_table[i].valid <= 1'b0;
							end
							
						end
						
						// restart the instruction by going back to PT access state
						next_state <= PT_ACC;
					end

				
				end else begin
					// mem not ready yet, stay in this state
					next_state <= PAGE_FLT;
				end
			
			end // end page fault
			
			// send PPN to mem
			SEND: begin
				//$display("MMU: In SEND state");
				// going to try to send data directly between CPU and main mem
				
				// send a non-page fault request to main mem
				MMU_valid <= 1'b1;
				page_fault <= 1'b0;
				MMU_write <= curr_write;
				//MMU_wdata_out <= curr_wdata;			// dont need to deal with data
				PPN_out <= curr_PPN;
				offset_out <= curr_offset;
				
				
				// sent request to memory, let memory do the rest
				if (mem_ready) begin
					//$display("MMU: Memory data sent to CPU, instruction complete");
					MMU_ready <= 1'b1;
					
					// turn off mem signals
					MMU_valid <= 1'b0;
					// return to IDLE state
					next_state <= IDLE;
				end else begin
					//MMU_valid <= 1'b0;
					
					MMU_ready <= 1'b0;
					next_state <= SEND;
				end
			
			end // end send to memory
		
		endcase
	
	
	
	end
	


endmodule

