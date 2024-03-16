# Project 1: FIR Filter Design and Implementation
Rojan Karn

## FIR Filter Design in MATLAB
The given specifications for this FIR filter was to design it as a 100-tap (at least) low-pass filter with a transition region of 0.2&pi; - 0.23&pi; rad/sample and stopband attenuation of at least 80 dB.

MATLAB was used to generate the proper coefficients that the FIR filter would be configured with in order to function according to the specifications above. The "Filter Designer" tool in MATLAB made the generation of the necessary parameters to the filter relatively simple. In the tool, I simply entered the given specifications in the appropriate fields in the GUI, and the tool designed a Stable Direct-Form FIR with Order = 169.

Then, MATLAB code for a Filter Design Function was generated, which resulted in these parameters:

    Fpass = 0.2;             % Passband Frequency
    Fstop = 0.23;            % Stopband Frequency
    Dpass = 0.057501127785;  % Passband Ripple
    Dstop = 0.0001;          % Stopband Attenuation
    dens = 20;               % Density Factor

Using these parameters, the order and coefficients of the FIR filter were generated using the "firpmord" and "firpm" functions. All of this was done in the "design_my_filter" function in the .m file in this repository.

The main function of the MATLAB code simply calls the "design_my_filter" function to retrieve the list of filter coefficients. Then, quantization is done with the following parameters to MATLAB's "quantizenumeric" function:

    s = 1; <- data is signed
    w = 16; <- word length of quantized value
    f = 15; <- fraction length of quantized value
    r = 'nearest'; <- round towards nearest with ties rounding towards positive infinity

Finally, the of the list quantized coefficients is exported as a SystemVerilog file for use in the hardware implementation of the filter, discussed in a later section.

## Filter Frequency Response
Figure 1 below shows the filter frequency response of the original (un-quantized) filter:

<img width="734" alt="image" src="https://github.com/rokarn12/Advanced-VLSI-Design/assets/66972178/e1e8e243-6305-46de-b5d5-40acc5b7ae2b">

**Figure 1: Filter Frequency Response of Un-Quantized Filter**

This filter shows an ideal representation of the specified FIR filter, which as shown, has a transition region of 0.2&pi; - 0.23&pi; rad/sample and stopband attenuation of 80 dB. However, this response is a fully ideal response and may not be realizable through actual hardware implementation as it would consume inefficiently large amounts of area and power. Therefore, quantization is necessary to establish a balance between performance and resource utilization.

The following figure shows the filter frequency response of the quantized filter:

<img width="723" alt="image" src="https://github.com/rokarn12/Advanced-VLSI-Design/assets/66972178/c171c965-5710-4d15-beab-fa39af5e0ab3">

**Figure 2: Filter Frequency Response of Quantized Filter**

This quantized filter still follows the specifications of transition region of 0.2&pi; - 0.23&pi; rad/sample and stopband attenuation of 80 dB, but now there is some performance dropoff in the larger frequency ranges. This is an acceptable tradeoff for the implementation of this FIR filter.


## Hardware Implementation
The RTL code for the hardware implementation of the designed FIR filter is written in SystemVerilog. Currently, this repository contains code for the following configurations of the FIR filter:

1. Pipelined FIR Filter
2. 2-Parallel FIR Filter (No Pipelining)
3. 2-Parallel FIR Filter with Pipelining
4. 3-Parallel FIR Filter (No Pipelining)
5. 3-Parallel FIR Filter with Pipelining
* All parallel implementations are "reduced complexity" implementations

After the MATLAB script is run, a new SystemVerilog file (fir_params.sv) is generated that contains the number of taps (NUM_TAPS) necessary for the desired functionality of the FIR filter and a list of 16-bit wide filter coefficients (fir_coefs). The number of taps needed for this filter is 170.

### Overflow
In this implementation, the inputs were chosen to be 16-bits wide, the coefficients were quantized to be 16-bits wide, and the output width was calculated to be 40 bits wide according to the following calculation to avoid overflow:

Input Width + Coefficient Width + log2(NUM_TAPS) = 16 + 16 + log2(170) ~= 40

This helps to ensure that the output width can accomodate for (properly represent) the potentially large values that the FIR filter may output.

### Architecture
The first configuration of the FIR filter that was implemented was the pipelined filter with no parallelization. The architecture is drawn out as shown for "N" taps. In this actual implementation, N = 170 which is a 170-tap filter.

<img width="1020" alt="image" src="https://github.com/rokarn12/Advanced-VLSI-Design/assets/66972178/e18f0b73-8aa4-4684-ba07-73f6c3c57875">

**Figure 3: N-Tap Pipelined FIR Filter Architecture**

Between each delay element (pipeline register), there is one multiplication and one addition that occurs, so the critical path of this design is the time of one multiplication plus the time of one addition. This allows for the design to be able to operate at high clock frequencies since the critical path is small. Since N = 170, after 170 clock cycles from the initial input, the correct output will be available.

The next configuration of the filter that was implemented was the 2-parallel filter that uses the pipelined filter architecture described above. The architecture of the 2-parallel design is shown here:

<img width="504" alt="image" src="https://github.com/rokarn12/Advanced-VLSI-Design/assets/66972178/ff39b6f3-facc-425c-8d8a-df7a864da0ad">

**Figure 4: Reduced Complexity 2-Parallel FIR (from Part 4 Lecture Slides, Slide 8)**

The H0, H1, and H0+H1 blocks in Figure 4 are implemented as the N-tap pipelined filter from Figure 3. Since this is a 2-parallel architecture, H0, H1, and H0+H1 are instantiated as (NUM_TAPS/2)-tap filters: 170/2 = 85 so these subfilters are 85-tap. The parallel architecture improves throughput for the FIR filter, and the pipelined nature of the subfilters serve the same purpose as well.

Finally, the architecture for the 3-parallel FIR filter is shown below.

<img width="587" alt="image" src="https://github.com/rokarn12/Advanced-VLSI-Design/assets/66972178/f527f91d-4077-4529-8dc0-ba1b3429a8f1">

**Figure 5: Reduced Complexity 3-Parallel FIR (from Part 4 Lecture Slides, Slide 9)**

This architecture utilizes 6 subfilters in the form of H0, H1, H2, H0+H1, H1+H2, and H0+H1+H2. Since this is a 3-parallel architecture, the subfilters are instantiated as (NUM_TAPS/3)-tap filters: 170/3 = 56.7 so these subfilters are 56-tap.
The outputs of the 6 filters are then put through some intermediate logic (additions and subtractions) as well as some delay elements before being fed to the output port.

### Code Structure - Pipelined Filter
The SystemVerilog code for the pipelined FIR filter is found in the file "fir_filter.sv". Since the fir_filter module is used as both the standalone pipelined filter AND as subfilters in the parallel architecture, it must be implemented using a configurable number of taps and different coefficient lists. The parameter "sub_taps" is defaulted to 0 and stays at 0 when the module is being used as the standalone pipelined filter. If sub_taps is greater than 0, that indicates that the module is being used as a subfilter. Before any implementation, the code checks the value of sub_taps and implements the filter accordingly.

The code initializes an array of delay elements which are used as the pipeline registers for all 170 stages. These delay elements store the product of the previous input sample and the corresponding filter coefficient. Then, in a loop, each previous delay element's output is multiplied by its corresponding coefficient and added to the current delay element's output. Finally, after processing all delay elements, the tap result is calculated by adding the output of the first delay element (delay_elements[1]) to the product of the input signal and the first coefficient (fir_coefs[0]*inp).

### Code Structure - 2-Parallel Filter with Pipelining
The SystemVerilog code for the 2-parallel filter is found in the file "fir_parallel.sv". The parallel architecture instantiates 3 of the pipelined filter modules, and specifies the "sub_taps" parameter to be (NUM_TAPS/2) = 85. A function is created to generate the subfilter coefficients for H0 and H1, which is simply alternating coefficients from the original list. This function properly splits the original coefficient list into 2, which are fed into H0 and H1. For the H0+H1 filter, a small function that adds the H0 coefficients and H1 coefficients together is made and this list of sums is fed into the H0+H1 filter.

The output is assigned according to the architecture shown in Figure 4:

    y(2k) = y(0) = out_H1_delayed + out_H0;
    y(2k+1) = y(1) = out_H0H1 - out_H0 - out_H1;

### Code Structure - 2-Parallel Filter (No Pipelining)
The code for this module is also found in the "fir_parallel.sv" file, under the module named "fir_filter_no_pipeline". This module is essentially the same as the 2-parallel filter with pipelining, the only difference being that the modules used for the H0, H1, and H0+H1 blocks are non-pipelined FIR filters. Everything else is the same for this implementation.

### Code Structure - 3-Parallel Filter (both Pipelining and No Pipelining)
The code for both versions of the 3-parallel filter can be found in the "fir_3_parallel.sv" file. Because of the many internal logic operations (addition and subtraction) in the 3-parallel architecture, there are many internal logic signals that are declared to represent the many wires in Figure 5. These wires are then properly assigned.

The 3-parallel code essentially uses the same structure as the 2-parallel code and also uses the same functions "generate_sub" and "merge". The list of coefficients are split up into three groups of equal size (using generate_sub) to be fed into H0, H1, and H2. Then, these groups are added together accordingly to H0+H1, H1+H2, and H0+H1+H2 using the merge function.

Six subfilters are instantiated with the proper parameters and input/output ports. For the 3-parallel filter with pipelining, the pipelined versions of the FIR filter are instantiated. For the 3-parallel filter with NO pipelining, the non-pipelined versions of the FIR filter are instantiated.

### Code Structure - Testbench
The testbench for the pipelined and parallel implementation are essentially the same, the only difference being that for the parallel implementation, two outputs must be checked instead of one.

The testbench simulates 27 different input stimuli to the FIR filter in the form of sine wave samples that are calculated to be different values in every iteration.

The code continuously checks for new maximum output values and updates the maximum accordingly. In each of the 27 iterations, the magnitude (in decibels, dB) is calculated and displayed.

### Results
Simulation results are shown in the "Simulation_Outputs" folder.

Hardware Implementation Results related to area, clock frequency, and power estimation are listed in this section.

Pipelined FIR Filter:

    Worst-case setup slack: -1.011
    Worst-case hold slack: 0.148
    Worst-case minimum pulse width slack: -0.089
    Logic utilization: 6% (Cyclone V Device)
    Power estimation: 355.38 mW

2-Parallel FIR Filter (No Pipeline):

    Worst-case setup slack: 11.814
    Worst-case hold slack: 0.035
    Worst-case minimum pulse width slack: -2.225
    Logic utilization: 11% (Cyclone V Device)
    Power estimation: 356.92 mW

2-Parallel FIR Filter (With Pipeline):

    Worst-case setup slack: -1.824
    Worst-case hold slack: 0.148
    Worst-case minimum pulse width slack: -1.702
    Logic utilization: 9% (Cyclone V Device)
    Power estimation: 356.82 mW

3-Parallel FIR Filter (No Pipeline):

    Worst-case setup slack: -8.823
    Worst-case hold slack: 0.065
    Worst-case minimum pulse width slack: -2.225
    Logic utilization: 19% (Cyclone V Device)
    Power estimation: 358.28 mW
    
3-Parallel FIR Filter (With Pipeline):

    Worst-case setup slack: -1.624
    Worst-case hold slack: 0.132
    Worst-case minimum pulse width slack: -1.702
    Logic utilization: 12% (Cyclone V Device)
    Power estimation: 358.23 mW
    
## Analysis & Conclusion
Clearly, there is a tradeoff between logic utilization and timing performance that is shown in the "Results" section above. Pipelined architectures enable fast execution times by processing data in stages, which at the same time causes a lot of resource usage due to the allocation of pipeline registers needed. On the other hand, non-pipelined architectures don't utilize as much logic resources, but they may fail to meet timing requirements.

This tradeoff relationship is evident when comparing the pipelined vs. non-pipelined versions of the 2- and 3-parallel FIR filter implementations. The pipelined versions were faster at the cost of consuming more logic resources.

One notable metric is the power estimation for all of these configurations, as they seemed to remain relatively constant between the different designs. What this means for the designer is that power is not much of a concern when deciding on an architecture for the design.

The optimal FIR filter design choice depends on the application that it is needed for. If logic utilization is the main concern, then it seems that the non-pipelined architecture is the better fit. However, if timing performance is the main concern, the designer should choose the pipelined architecture to maximize clock frequency.

