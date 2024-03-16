% Main Function
function FIR()
    % Generate filter coefficients
    filter_coeffs = design_my_filter;

    % Un-quantized filter
    freqz(filter_coeffs, 1);
    
    % Quantize the coefficients
    quantized_coeffs = quantizenumeric(filter_coeffs, 1, 16, 15, 'nearest');
    
    % Display the frequency response of the quantized filter
    fig = figure;
    figure(fig);
    freqz(quantized_coeffs, 1);
    
    % Save coefficients as a SystemVerilog array
    export_coefficients("fir_params.sv", quantized_coeffs, 16, 15);
end

% Design a custom discrete-time filter object
function filter_coeffs = design_my_filter
    % Parameters
    Fpass = 0.2;             % Passband Frequency
    Fstop = 0.23;            % Stopband Frequency
    Dpass = 0.057501127785;  % Passband Ripple
    Dstop = 0.0001;          % Stopband Attenuation
    dens = 20;               % Density Factor

    % Calculate the order and coefficients using MATLAB's filter design
    [N, Fo, Ao, W] = firpmord([Fpass, Fstop], [1, 0], [Dpass, Dstop]);
    filter_coeffs = firpm(N, Fo, Ao, W, {dens});
end

% Export coefficients as SystemVerilog parameters
function export_coefficients(filename, quantized_coeffs, w, f)
    q = fi(quantized_coeffs, 1, w, f);
    % Start parameter declarations
    [abs_path, fname, ext] = fileparts(mfilename("fullpath"));
    fileID = fopen(fullfile(abs_path, filename), 'w');
    fprintf(fileID, "parameter int NUM_TAPS = %d;\n", length(quantized_coeffs));
    fprintf(fileID, "parameter logic signed [15:0] fir_coefs[0:NUM_TAPS-1] = '{\n");
    
    % Loop through coefficients and add to file
    for c = 1:length(q)-1
        tmp = q(c);
        fprintf(fileID, "    16'b%s,\n", tmp.bin);
    end

    % Print the last coefficient and close out the file
    tmp = q(length(q));
    fprintf(fileID, "    16'b%s\n};\n", tmp.bin);
    fclose(fileID);
end
