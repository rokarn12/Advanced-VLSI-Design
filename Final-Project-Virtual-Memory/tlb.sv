// Translation Lookaside Buffer (TLB)

`include "defines.sv"

`timescale 1ns/100ps

// cache for recently used translations
module tlb (
		input logic clk, reset,
		
		// inputs from MMU
		// when MMU is requesting a translation
		input logic translation_request,
		input logic [`VPN_WIDTH-1:0] VPN_in, 			// used for new entry requests too
		
		// when MMU is adding a new entry
		input logic new_entry_request,
		input logic [`PPN_WIDTH-1:0] PPN_in,
		
		// outputs to MMU
		output logic tlb_ready,								// tells MMU to read tlb signals
		output logic tlb_miss,								// indicates that the requested VPN was not in TLB
		output logic [`PPN_WIDTH-1:0] translated_PPN,// the translated address on a TLB hit
		
		// inputs from main_mem (for translation invalidation)
		input logic invalidate_trigger,
		input logic [`PPN_WIDTH-1:0] invalid_PPN
);

	typedef struct {
	
		logic valid;							// indicates whether this is a valid translation
		logic [`VPN_WIDTH-1:0] VPN;		// virtual page number
		logic [`PPN_WIDTH-1:0] PPN;		// physical page number
	
	} tlb_line;
	
	// make TLB 16 entries
	tlb_line TLB[16];
	
	initial begin
	
		// initialize the TLB as empty, all lines invalid
		for (int i = 0; i < 16; i++) begin
			TLB[i].valid = 1'b0;
			TLB[i].VPN = 0;
			TLB[i].PPN = 0;
		end
	
		// TLB should be initialized
	end
	
	
	// filling in TLB:
	// on every access to the page table, add the entry to TLB
	// LRU for replacement?
	
	// handling page faults in TLB:
	// main_mem will send the # of the page that got replaced in the DRAM
	// loop through TLB and invalidate entries that have a matching PPN
	
	
	// handle new entries
	always @(posedge clk) begin
		// handle reset
		if (reset) begin
			tlb_ready <= 1'b0;
			tlb_miss <= 1'b0;
			translated_PPN <= `PPN_WIDTH'b0;
		
		end else begin // non-reset
		
			if (translation_request) begin
				// MMU requesting a VPN-PPN translation
				//$display("TLB: received translation request for VPN %b", VPN_in);
				
				// search the TLB for the VPN and make sure it's valid
				for (int i = 0; i < 16; i++) begin
					
					if (TLB[i].valid && TLB[i].VPN == VPN_in) begin
						// TLB HIT
						$display("TLB: HIT, skip page table access, no delay");
						// set outputs, break loop
						tlb_ready <= 1'b1;
						tlb_miss <= 1'b0;
						translated_PPN <= TLB[i].PPN;
						break;
						
					end else if (i == 15) begin	// at the end of TLB, still no match
						// TLB MISS
						//$display("TLB: MISS -> TLB[i].valid = %d, TLB[i].VPN = %d, VPN_in = %d", TLB[i].valid, TLB[i].VPN, VPN_in);
						// set outputs
						tlb_ready <= 1'b1;
						tlb_miss <= 1'b1;						// let MMU know there was a miss
						translated_PPN <= `PPN_WIDTH'b0; // doesn't matter
						break;
						
					end // end if statements
				
				
				end // end for loop
			
			end // end if translation request

			// when MMU sends a new entry to TLB
			else if (new_entry_request) begin

				// find the next available spot in the TLB
				for (int i = 0; i < 16; i++) begin
				
					if (!TLB[i].valid) begin
						// found available spot, fill it in
						TLB[i].valid <= 1;
						TLB[i].VPN <= VPN_in;
						TLB[i].PPN <= PPN_in;
						break;
					end
					// if there are no available spots, just put the translation into the last entry
					else if (i == 15) begin
						// TLB[i] is the last entry here, previous entry overwritten (NO REPLACEMENT POLICY)
						TLB[i].valid <= 1;
						TLB[i].VPN <= VPN_in;
						TLB[i].PPN <= PPN_in;
						break;
					end
				
				end // end for loop
			
				//$display("TLB: adding new entry -> VPN: %d	PPN: %d", VPN_in, PPN_in);
			end // end if new entry request
			
			// when a page fault occurs, check if the replaced page is in TLB
			else if (invalidate_trigger) begin
			
				// loop through TLB
				for (int i = 0; i < 16; i++) begin
				
					// check for matches with the invalid PPN
					if (TLB[i].PPN == invalid_PPN) begin
						// simply invalidate this translation
						TLB[i].valid <= 1'b0;
						
					end
				
				end // end for loop
			
			end // end if invalidate trigger
			
			else begin
				tlb_ready <= 1'b0;
				tlb_miss <= 1'b0;
			end
		end // end if non-reset

	end // end new entries always @
	
//
//	
//	// handle translation requests
//	always @(posedge clk) begin
//		// handle reset
//		if (reset) begin
//			tlb_ready <= 1'b0;
//			tlb_miss <= 1'b0;
//			translated_PPN <= `PPN_WIDTH'b0;
//		
//		end else begin // non-reset
//		
//			if (translation_request) begin
//				// MMU requesting a VPN-PPN translation
//				
//				// search the TLB for the VPN and make sure it's valid
//				for (int i = 0; i < 16; i++) begin
//					
//					if (TLB[i].valid && TLB[i].VPN == VPN_in) begin
//						// TLB HIT
//						// set outputs, break loop
//						tlb_ready <= 1'b1;
//						tlb_miss <= 1'b0;
//						translated_PPN <= TLB[i].PPN;
//						break;
//						
//					end else if (i == 15) begin	// at the end of TLB, still no match
//						// TLB MISS
//						// set outputs
//						tlb_ready <= 1'b1;
//						tlb_miss <= 1'b1;						// let MMU know there was a miss
//						translated_PPN <= `PPN_WIDTH'b0; // doesn't matter
//						break;
//						
//					end // end if statements
//				
//				
//				end // end for loop
//			
//			end // end if translation request
//
//		end
//	
//	end // end translation request always @
//	
//	


endmodule

