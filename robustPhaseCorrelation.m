function spectralRPC = robustPhaseCorrelation(IMAGE1, IMAGE2, SPECTRALFILTER)
% robustPhaseCorrelation(IMAGE1, IMAGE2, RPCDIAMETER) performs robust phase correlation of two 
% 2-D signals and returns the output in the spectral domain. 
% 
% INPUTS
%   IMAGE1 = First signal to be correlated. This signal remains stationary during the correlaiton. 
%   IMAGE2 = Second signal to be correlated. This signal is shifted during the correlation. 
%   SPECTRALFILTER = Spectal Energy Filter for RPC algorithm (matrix whose
%       dimensions are equivalent to the height and width of the input images)/
% OUTPUTS
%   spectralRPC = Robust phase correlation plane of Image 1 and Image 2 in the spectral domain.
% 
% SEE ALSO
%   crossCorrelation, phaseCorrelation, spectralEnergyFilter, fftshift,

% Phase-only-filtered cross correlation in the spectral domain
spectralPhaseCorr = phaseCorrelation(IMAGE1, IMAGE2);

% Shift quadrants of spectral phase correlation in preparation for convolution
spectralPhaseCorrShift = fftshift(spectralPhaseCorr);

% Convolve spectral energy filter with spectral phase correlation
spectralRPC = spectralPhaseCorrShift .* SPECTRALFILTER;

end
