function SPATIALRPCPLANE = RPC(IMAGE1, IMAGE2, SPECTRALFILTER)
% [TRANSLATIONY TRANSLATIONX SPATIALRPC] = RPC(IMAGE1, IMAGE2, SPECTRALFILTER) calculates the robust phase correlation between two images
% 
% INPUTS
%   IMAGE1 = First image
%   IMAGE2 = Second image
%   SPECTRALFILTER = RPC Spectral energy filter to apply to the spectral correlation between IMAGE1 and IMAGE2
%
% OUTPUTS
%   TRANSLATIONX = Most probable horizontal translation (in pixels) relating the two images
%   TRANSLATIONY = Most probable vertical translation (in pixels) relating the two images
%   SPATIALRPC = Spatial correlation plane of the RPC between the two images
%
% SEE ALSO
%   spectralEnergyFilter, robustPhaseCorrelation, freq2space, subpixel

% % % % % % % % 
% Begin Function  %
% % % % % % % % 

% % % % If nothing is input for SPECTRALFILTER, default to a spectral energy
% % % % filter diameter of 3.3 pixels
% % % if nargin < 3
% % %     SPECTRALFILTER = 2.8;
% % % end
% % % 
% % % % If the input SPECTRALFILTER is only one element long, assume that it
% % % % represents a desired spectral energy filter diameter (pixels) and create
% % % % the new filter
% % % if numel(SPECTRALFILTER) == 1;
% % %     [height, width] = size(IMAGE1);
% % %     spectralFilter = spectralEnergyFilter(height, width, SPECTRALFILTER);
% % % else
% % %     spectralFilter = SPECTRALFILTER;
% % % end

% % % % % Compute the robust phase correlation(RPC) of the windowed images. Report the result in the spectral domain.
% % % % spectralRPC = robustPhaseCorrelation(IMAGE1, IMAGE2, spectralFilter);
% % % % 

% Calculate size of interrogation regions (homogeneous) (pixels)
[nRows, nColumns] = size(IMAGE1);

% Perform Fourier transforms
FFT1 = fftn(IMAGE1, [nRows nColumns]);
FFT2 = fftn(IMAGE2, [nRows nColumns]);

% Perform cross correlation in spectral domain
spectralCrossCorr = FFT2 .* conj(FFT1);

% % % % % Perform standard cross correlation
% % % % spectralCrossCorr = crossCorrelation(A, B);

% Magnitude of crosscorrelation in frequency domain
correlationMagnitude = sqrt(spectralCrossCorr .* conj(spectralCrossCorr));

% If the value of the cross correlation is zero, set the magnitude to 1.
% This avoids division by zero when calculating the phase correlation
% below (i.e., when dividing the cross correlation by its magnitude). 
correlationMagnitude(spectralCrossCorr == 0 ) = 1;

% Divide cross correlation by its nonzero magnitude to extract the phase information
spectralPhaseCorr = spectralCrossCorr ./ correlationMagnitude;

% % 
% % % Perform phase-only filtering
% % spectralPhaseCorr = phaseOnlyFilter(spectralCrossCorr);


% % % 
% % % % Phase-only-filtered cross correlation in the spectral domain
% % % spectralPhaseCorr = phaseCorrelation(IMAGE1, IMAGE2);

% Shift quadrants of spectral phase correlation in preparation for convolution
spectralPhaseCorrShift = fftshift(spectralPhaseCorr);

% Convolve spectral energy filter with spectral phase correlation
spectralRPC = spectralPhaseCorrShift .* SPECTRALFILTER;

% Convert the RPC of the two input images from the spectral domain to the spatial domain
% % SPATIALRPC = freq2space(spectralRPC);


% % Calculate size of correlation matrix
% [nRows, nColumns] = size(spectralCorrelation);

spatialRPCshifted = abs(real(ifftn(spectralRPC, 'symmetric')));

% Shift zero-frequency component of cross-correlation to center of spectrum
xind = [ceil(nColumns/2)+1:nColumns 1:ceil(nColumns/2)];
yind = [ceil(nRows/2)+1:nRows 1:ceil(nRows/2)];
SPATIALRPCPLANE = spatialRPCshifted(yind, xind);



% Prana subplixel implmentation
% [TRANSLATIONY, TRANSLATIONX] = subpixel(SPATIALRPC, ones(size(SPATIALRPC)), 1, 0); % Subpixel peak location (poorly commented function taken from Prana) 

end


