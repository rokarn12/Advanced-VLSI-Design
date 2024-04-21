# Final Project: Virtual Memory
### Rojan Karn

### Virtual Memory Overview
Ideally, memory would have infinite capacity so that programmers would not need to worry about constraining their programs to a system's memory limits. However, real physical memory has limited size. Main memory in systems are much smaller than what the programmer assumes, but the concept of virtual memory makes this not an issue for programmers.

One of the main purposes of virtual memory is to make sure that the programmer does not need to manage the data movement between primary memory (DRAM) and secondary memory (disk). Because the programmer assumes a much larger memory address space than what is actually available, the virtual memory system handles moving data between main and disk memory, if necessary.

Essentially, virtual memory addresses the challenge of limited physical memory by providing a larger (virtual) address space than what is physically available. For example, an ISA with 32-bit addresses should mean that there are 2^32 bytes (4GB) available in RAM. But in reality, the primary memory may only have 1GB available, with the rest of the data stored in a much larger and slower secondary memory.

Paging is an important concept in virtual memory and is essentially a method of grouping blocks of the address spaces into "pages", and virtual page numbers are mapped to physical page numbers. Virtual page numbers can be mapped to either a physical page, if that page is present in physical memory, or a disk storage location if that page is not present in physical memory.

The page table sits in between virtual memory and physical memory, and it is where the virtual to physical page number translations are stored. The translation lookaside buffer (or TLB) is essentially a “cache” for VPN-PPN translations, which allows for much faster address translations on frequently used addresses. A page fault is what happens when a requested physical page is not currently present in main memory, so an access to secondary memory (which is the disk storage) is necessary.

![image](https://github.com/rokarn12/Advanced-VLSI-Design/assets/66972178/fbf08547-0abc-4b6f-9886-20a8bdab68ed)

This diagram should give a good understanding on what the flow of address translation is in a virtual memory system:
    - The programmer requests an address in the virtual memory space
    - The page table is checked for the physical translation of that address
    - If the translation is valid, access the physical memory
    - If the translation is invalid, there is a page fault, and the requested physical page is brought into main memory from the disk storage

### Design Specification
![image](https://github.com/rokarn12/Advanced-VLSI-Design/assets/66972178/cbc3193d-cb6b-430e-b449-577d03633358)

This diagram shows my implementation of the virtual memory system on a block-level. The CPU sends addresses (in the virtual space) to the memory management unit (or MMU) but sends data directly to and from DRAM. The memory management unit holds the page table within it, and communicates with the translation lookaside buffer which, again, is essentially a cache to the page table. One thing to note is that even though I have designed the system so that the page table is in the MMU, getting translations from the TLB is faster than accessing the page table for those translations.

Once the physical page number is retrieved, the physical address is sent to the memory module, which encapsulates both the primary memory (DRAM) and the secondary memory (disk). The disk is a substantially larger memory component than the DRAM, but accesses to the disk are also substantially slower than accesses to DRAM. For this reason, the disk is only accessed in the event of a page fault, where the requested page from the disk replaces the Least Recently Used page in DRAM. Data is only sent once the requested address is in DRAM, so data is never sent to the CPU directly from the disk.

### Implementation Details
All of the code for this project was written in SystemVerilog.
#### Addressing
![image](https://github.com/rokarn12/Advanced-VLSI-Design/assets/66972178/b25a2c86-ff2e-49b8-bfac-86829f37a703)

This diagram shows how addressing in my scaled-down implementation of the virtual memory system works. The page table has a total of 64 entries which represents all of the potential addresses the programmer can access as there are a total of 64 words of data in the secondary memory. So, the virtual memory address space is accessed using 6 bits.

However, the DRAM only contains 32 addresses, meaning that the physical main memory only needs 5 bits to access it. This level of abstraction gives the programmer the illusion that it has 64 addresses available to it, when in reality, there are only 32 addresses present in the main memory.

#### Memory Management Unit (MMU) FSM Diagram
![image](https://github.com/rokarn12/Advanced-VLSI-Design/assets/66972178/4fe5fb18-f673-4874-99b6-1d395e0b7b87)

#### Page Fault Handling
When a VPN-PPN translation in the Page Table is not valid, this means that the requested physical page is not in main memory, indicating a page fault. On a page fault, the modules do:

**MMU**: Send “page_fault” signal and requested PPN to memory module

**Memory Module**:
- Find least recently used (LRU) page in DRAM
- If page is dirty (modified), do writeback to DISK
- Requested physical page from DISK replaces LRU page in DRAM
- Send update signals to PT and TLB to reflect new state of DRAM
- Tell MMU to restart the instruction

**PAGE TABLE**: Set “valid” bit on new page in DRAM, invalidate replaced page

**TLB**: Invalidates all translations pointing to replaced page

### Testing
The following image shows the 4 main test cases that display the working functionality of this virtual memory system.
![image](https://github.com/rokarn12/Advanced-VLSI-Design/assets/66972178/8c525c5d-7bef-4ace-904d-67db64b6da14)

Test 0 is a simple read to a valid VPN while the VPN-PPN translation is not in the TLB. The VPN is valid, so the data is present in main memory and the system returns the correct value.

Test 1 is a simple write to a valid VPN (again, with no TLB access). Successful writes are encoded as a 32 bit word including the PPN, Offset, and Data Written so that the testbench can self-check whether the write was successful or not.

Test 2 is a read to an invalid VPN. Because the VPN is invalid, this means the requested page is not present in physical memory, so it causes a page fault. We can see that the access to the disk causes a substantial delay of 500 units. Also, we see that the requested page (Page 9) replaces the least recently used page (Page 7) in main memory. Once the page is replaced, then the instruction is restarted and completed successfully. But the time taken for this operation is much higher than the other tests.

Test 3 is a read to a valid VPN whose translation is present in the TLB. We see that the TLB hit allows us to bypass the delay that is caused by accessing the page table in the other tests. Because of the TLB hit, this access is the fastest operation of all of the tests.

On those same 4 tests, this image shows the waveforms of the I/O ports in the Memory Management Unit.
![image](https://github.com/rokarn12/Advanced-VLSI-Design/assets/66972178/936305bf-ef55-491d-8e5e-0dc0bd8e5f7f)

We see the signals that go to memory, signals for page faults, and signals to the TLB.

When sending a physical address to memory, we need to include both the PPN and the offset. If MMU_valid is high and page_fault is low, the memory module knows to send the requested data straight to the CPU. However, when MMU_valid is high and page_fault is high, the memory module performs the page fault handling. Of course, this only happens on test 2 where the page fault occurs. Once the page fault is handled, the memory module tells the MMU to update the page table and restart the instruction.

For the TLB, we see that the MMU sends a translation request to the TLB in every test. The TLB returns 2 signals: tlb_ready and tlb_miss. When both are high, the translation was not present in TLB so the MMU then checks the page table. In test 3, we got a TLB hit, which returns the requested physical page we are looking for is Page 9. In every test that we get a TLB miss, the translation is added as a new entry in the TLB.

### Final Remarks
This project was just a fundamental implementation of the virtual memory system - and there is a lot more to this concept that can be added as future work. Some examples include:

  - Handling multiple processes
  - Handling multiple users using private address spaces and protection checks
  - And “virtually addressed cache” which is a method that helps to minimize accesses to the page table

Virtual memory is a fundamental aspect of modern computing systems today, and are mostly managed by the operating system. This project was a hardware implementation of the virtual memory system, and doing this project taught me a lot about this important design concept that I was unfamiliar with before.

*Virtual memory is treating secondary memory as if it were main memory.*
