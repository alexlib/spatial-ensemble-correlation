function spatialCorr = freq2space(spectralCorrelation)
% FREQ2SPACE Shifts the zero-frequency component of a correlation in the spectral domain 
% to the center of spectrum, then transforms the correlation into the
% spatial domain.

% Calculate size of correlation matrix
[nRows, nColumns] = size(spectralCorrelation);

spatialCorr = abs(real(ifftn(spectralCorrelation, 'symmetric')));

% Shift zero-frequency component of cross-correlation to center of spectrum
xind = [ceil(nColumns/2)+1:nColumns 1:ceil(nColumns/2)];
yind = [ceil(nRows/2)+1:nRows 1:ceil(nRows/2)];
spatialCorr = spatialCorr(yind, xind);

end