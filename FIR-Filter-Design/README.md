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


## Hardware Implementation
### Architecture

### Code Structure

### Results

## Conclusion
