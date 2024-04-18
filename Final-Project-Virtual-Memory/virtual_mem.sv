// Rojan Karn
// Advanced VLSI Design - Final Project

`include "defines.sv"

`timescale 1ns/100ps

// top-level module
module virtual_mem (input logic clk, reset,
						input logic instr_valid, instr_write,
						input logic [31:0] instr_address,
						input logic [31:0] instr_wdata_in,
						output logic [31:0] data_out,
						output logic system_ready
);


	// CPU INSTANTIATION
	
	// CPU logic signals
	logic CPU_valid, CPU_write, MMU_CPU_ready;
	logic [31:0] CPU_address, mem_CPU_data, CPU_mem_data;
	
	logic mem_mmu_ready, restart_instr, update_pt;
	
	CPU PROCESSOR (.clk(clk), .reset(reset), .valid_instr(CPU_valid), .CPU_write(CPU_write), .address(CPU_address),
						.MMU_ready(MMU_CPU_ready), .mem_ready(mem_mmu_ready), .mem_return_data(mem_CPU_data), .write_data_out(CPU_mem_data),
						.TOP_instr_valid(instr_valid), .instr_write(instr_write), .instr_address(instr_address),
						.instr_wdata_in(instr_wdata_in), .proc_done(system_ready), .proc_return_data(data_out)
	);
	
	// END CPU INSTANTIATION
	
	// MMU INSTANTIATION
	
	// MMU logic signals
	// from MEM to MMU
	//logic mem_mmu_ready, restart_instr, update_pt;
	logic [`PPN_WIDTH-1:0] valid_PPN, invalid_PPN;
	// from MMU to MEM
	logic mmu_mem_valid, mmu_mem_write, page_fault;
	logic [`PPN_WIDTH-1:0] mmu_mem_ppn;
	logic [`OFFSET_WIDTH-1:0] mmu_mem_offset;
	// from TLB to MMU
	logic tlb_ready, tlb_miss, translation_request, new_entry_request;
	logic [`PPN_WIDTH-1:0] translated_PPN;
	logic [`VPN_WIDTH-1:0] tlb_mmu_VPN;
	logic [`PPN_WIDTH-1:0] mmu_tlb_PPN;
	
	MMU MM_UNIT (.clk(clk), .reset(reset), .valid_instr(CPU_valid), .CPU_write(CPU_write), .address(CPU_address),
					 .MMU_ready(MMU_CPU_ready), .mem_ready(mem_mmu_ready), .restart_instr(restart_instr), .update_page_table(update_pt),
					 .valid_PPN(valid_PPN), .invalid_PPN(invalid_PPN), .MMU_valid(mmu_mem_valid), .MMU_write(mmu_mem_write),
					 .PPN_out(mmu_mem_ppn), .offset_out(mmu_mem_offset), .page_fault(page_fault), .tlb_ready(tlb_ready),
					 .tlb_miss(tlb_miss), .translated_PPN(translated_PPN), .translation_request(translation_request),
					 .VPN_out(tlb_mmu_VPN), .new_entry_request(new_entry_request), .tlb_PPN_out(mmu_tlb_PPN)
	);
	
	// END MMU INSTANTIATION
	
	// TLB INSTANTIATION
	
	// tlb logic signals
	logic invalidate_trigger;
	//logic [`PPN_WIDTH-1:0] invalid_PPN;
	
	tlb TLB (.clk(clk), .reset(reset), .translation_request(translation_request), .VPN_in(tlb_mmu_VPN), .new_entry_request(new_entry_request),
				.PPN_in(mmu_tlb_PPN), .tlb_ready(tlb_ready), .tlb_miss(tlb_miss), .translated_PPN(translated_PPN),
				.invalidate_trigger(invalidate_trigger), .invalid_PPN(invalid_PPN)
	);
	
	// END TLB INSTANTIATION
	
	// MEMORY INSTATIATION
	
	// MEM logic signals
	
	
	main_mem MEMORY (.clk(clk), .reset(reset), .MMU_valid(mmu_mem_valid), .MMU_write(mmu_mem_write), .CPU_wdata_in(CPU_mem_data),
						  .PPN_in(mmu_mem_ppn), .offset_in(mmu_mem_offset), .page_fault(page_fault), .mem_ready(mem_mmu_ready),
						  .restart_instr(restart_instr), .update_page_table(update_pt), .data_out(mem_CPU_data), .valid_PPN(valid_PPN),
						  .invalid_PPN(invalid_PPN), .invalidate_trigger(invalidate_trigger)
	);


endmodule


// processor module for sending instructions
module CPU(
	input logic clk, reset,
	
	// Signals to MMU
	output logic valid_instr, CPU_write,
	output logic [31:0] address,
	//output logic [31:0] write_data_in,
	
	// Signals from MMU
	input logic MMU_ready,
	
	// signal from memory
	input logic mem_ready,
	//input logic [31:0] MMU_return_data,
	
	// data going to and from main mem
	input logic [31:0] mem_return_data,
	output logic [31:0] write_data_out,
	
	// Signals from TOP level
	// breaking down the instruction
	input logic TOP_instr_valid,
	input logic instr_write,
	input logic [31:0] instr_address,
	input logic [31:0] instr_wdata_in,
	
	// Signals to TOP level
	output logic proc_done,
	output logic [31:0] proc_return_data
);

	// internal logic
	logic operation_in_progress; // indicates whether the CPU is waiting for an operation to complete
	
	//assign proc_return_data = mem_return_data;

	// CPU checks if the given instruction matches its processorID
	always @(posedge clk) begin
		if (reset) begin
			// make sure cache and top level are not reading anything from CPU in reset
			valid_instr <= 1'b0;
			proc_done <= 1'b0;
			operation_in_progress <= 1'b0;
		end
		else if (TOP_instr_valid) begin
			// the given instruction is intended for this processor, send the request
			//$display("CPU: Received instruction from TOP");
			if (MMU_ready) begin // only send request when cache is ready
				//$display("CPU: Sent instruction to MMU");
				valid_instr <= 1'b1;
				CPU_write <= instr_write;
				address <= instr_address;
				write_data_out <= instr_wdata_in;
				operation_in_progress <= 1'b1;
				// Request sent
			end
			
		end 
		// if operation in progress and MMU_ready is set, operation is complete
		else if (MMU_ready && operation_in_progress) begin
			//$display("CPU: Waiting for mem_ready");
//			operation_in_progress <= 1'b0;
			// notify TOP level that this processor is done
			if (mem_ready) begin
				//$display("CPU: Instruction complete");
				operation_in_progress <= 1'b0;
				proc_done <= 1'b1;
				proc_return_data <= mem_return_data;
			end
		
		end
		else begin
			// the given instruction is not valid
			valid_instr <= 1'b0;
			proc_done <= 1'b0;
			//operation_in_progress <= 1'b0;
		end
	
	end // end always @ posedge clk

	
	
endmodule

