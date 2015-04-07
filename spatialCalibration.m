% function spatialCalibration(IMAGE)

CALIMAGE = double(imread('~/Desktop/calibrationImage000001.tif'));
sensorSize = [1024, 1024];

[rawHeight, rawWidth] = size(CALIMAGE);

calImageCropped = CALIMAGE(rawHeight - sensorSize(1) + 1 : end, rawWidth-sensorSize(2) + 1:end);

[height, width] = size(calImageCropped);

spatialWindowFraction = [ 0.3 0.3 ];

spatialWindow = gaussianWindowFilter(size(calImageCropped), spatialWindowFraction, 'fraction');

calImageWindowed = spatialWindow .* calImageCropped;

calImageZeroMean = calImageWindowed - mean(calImageWindowed(:));

% Compute the Fourier transform of the image
fftImage = fftn(double(calImageZeroMean), [height width]); 

% Shift the zero-frequency of the Fourier transform to the center of the 2-D domain;
% then calculate the spectral magnitude of this shifted Fourier transform of the image
spectralMagnitude = abs(fftshift(fftImage));

[pk, loc] = max(spectralMagnitude(:));

[rMax cMax] = ind2sub([height, width], loc);


% 
% end