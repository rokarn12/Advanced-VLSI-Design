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

## Hardware Implementation
### Architecture

### Code Structure

### Results

## Conclusion
