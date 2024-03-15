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
The RTL code for the hardware implementation of the designed FIR filter is written in SystemVerilog. Currently, this repository contains code for two configurations of the FIR filter:

1. Pipelined FIR Filter
2. 2-Parallel FIR Filter with Pipelining

After the MATLAB script is run, a new SystemVerilog file (fir_params.sv) is generated that contains the number of taps (NUM_TAPS) necessary for the desired functionality of the FIR filter and a list of 16-bit wide filter coefficients (fir_coefs). The number of taps needed for this filter is 170.

### Architecture
The first configuration of the FIR filter that was implemented was the pipelined filter with no parallelization. The architecture is drawn out as shown for "N" taps. In this actual implementation, N = 170 which is a 170-tap filter.

<img width="1020" alt="image" src="https://github.com/rokarn12/Advanced-VLSI-Design/assets/66972178/e18f0b73-8aa4-4684-ba07-73f6c3c57875">

**Figure 3: N-Tap Pipelined FIR Filter Architecture**

Between each delay element (pipeline register), there is one multiplication and one addition that occurs, so the critical path of this design is the time of one multiplication plus the time of one addition. This allows for the design to be able to operate at high clock frequencies since the critical path is small. Since N = 170, after 170 clock cycles from the initial input, the correct output will be available.

The next configuration of the filter that was implemented was the 2-parallel filter that uses the pipelined filter architecture described above. The architecture of the 2-parallel design is shown here:

<img width="504" alt="image" src="https://github.com/rokarn12/Advanced-VLSI-Design/assets/66972178/ff39b6f3-facc-425c-8d8a-df7a864da0ad">

**Figure 4: Reduced Complexity 2-Parallel FIR (from Part 4 Lecture Slides, Slide 8)**

The H0, H1, and H0+H1 blocks in Figure 4 are implemented as the N-tap pipelined filter from Figure 3. Since this is a 2-parallel architecture, H0, H1, and H0+H1 are instantiated as (NUM_TAPS/2)-tap filters: 170/2 = 85 so these subfilters are 85-tap. The parallel architecture improves throughput for the FIR filter, and the pipelined nature of the subfilters serve the same purpose as well.


### Code Structure

### Results

## Conclusion
