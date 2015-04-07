function [V, U, ENSEMBLE_PLANE] = rpcSpatialEnsemble(IMAGE_01, IMAGE_02, ...
    GRID_SPACING, GRID_BUFFER_Y, GRID_BUFFER_X, REGION_SIZE, ...
    SPATIAL_WINDOW_FRACTION, CORRELATION_TYPE, SPATIAL_RPC_DIAMETER, MASK, MASK_METHOD, ...
    COMPILED)
%
% RPCSPATIALENSEMBLE calculates the spatial-ensemble correlation of a
% pair of images.
%
% SYNTAX
% [Y, X, V, U, ENSEMBLEPLANE] = rpcSpatialEnsemble(IMAGE1, IMAGE2, ...
%   GRIDSPACING, GRIDBUFFERY, GRIDBUFFERX, REGIONSIZE, SPATIALWINDOWFRACTION, ...
%   SPATIALRPCDIAMETER)
% 
% INPUTS
%   IMAGE1 = First image in the pair of images. This variable can either be the actual image data
%           or a string specifying the file-path to the image. 
%
%   IMAGE2 = Second image  of images. This variable can either be the actual image data
%           or a string specifying the file-path to the image. 
%
%   GRIDSPACING = [ 2 x 1] vector of integers specifying the vertical and
%           horizontal grid spacing in pixels. 
% 
%   GRIDBUFFERY = [ 2 x 1] vector of integers specifying the grid buffer in pixels on
%        the top and bottom edges of the image, respectively.
%
%   GRIDBUFFERX = [ 2 x 1] vector of integers specifying the grid buffer in pixels on
%           the left and right edges of the image, respectively.
%
%   REGIONSIZE = [ 2 x 1 ] vector of integers specifying the vertical and
%       horizontal size in pixels of the image interrogation region to be correlated.
%
%   SPATIALWINDOWFRACTION = [ 2 x 1 ] vector specifying the effective resolution of the
%        interrogation window as a fraction of the interrogation region (i.e. between [ 0 0 ] and [ 1 1 ])
%
%   SPATIALRPCDIAMETER = [ 2 x 1 ] vector specifying the vertical and
%        horizontal diameters of the RPC spectral filter in pixels.
%
% OUTPUTS
%
%   V = Vertical component of velocity in pixels per frame.
%
%   U = Horizontal component of velocity in pixels per frame.
%
%   ENSEMBLEPLANE = Spatial ensemble correlation plane. 
% 
% SEE ALSO
%   gridImage, RPC
%

% Default to no mask
if nargin < 11
    mask = ones(size(IMAGE_01));
    maskMethod = '';
else
    mask = MASK;
    maskMethod = MASK_METHOD;
end

% Convert the first image to double
if ischar(IMAGE_01)
    image_01 = double(imread(IMAGE_01));
else
    image_01 = double(IMAGE_01);
end

% Convert the first image to double
if ischar(IMAGE_02)
    image_02 = double(imread(IMAGE_02));
else
    image_02 = double(IMAGE_02);
end

% Load the mask if it's specified as a string
if ischar(MASK)
    mask = double(imread(MASK));
else
    mask = double(MASK);
end

% Set the image pixel value to zero in the masked region
% if the mask-method of "zero" was specified.
if regexpi(maskMethod, 'zero')
    image_01(mask == 0) = 0;
    image_02(mask == 0) = 0;
end

% Determine the dimensions of the raw images (in pixels). This code assumes
% that the two images are 2-D and the same size, i.e., that size(IMAGE1) ==
% size(IMAGE2) == nRows x nColumns x 1
[imageHeight, imageWidth ] = size(image_01);
imageSize = [imageHeight imageWidth];

% Dimensions of the interrogation region (pixels)
regionHeight = REGION_SIZE(1); % Vertical size (pixels)
regionWidth = REGION_SIZE(2); % Horizontal size (pixels)

% Create the gaussian intensity window to be applied to the the raw image interrogation regions
spatialWindow = gaussianWindowFilter( [regionHeight regionWidth], SPATIAL_WINDOW_FRACTION, 'fraction' );

% Create the gaussian spectral energy filter be applied to the raw image correlation
imageSpectralFilter = spectralEnergyFilter(regionHeight, regionWidth, SPATIAL_RPC_DIAMETER); 

% Make sure the grid buffer is at least half the region size so we don't
% end up with funky regions.
gridBufferY = max(GRID_BUFFER_Y, ceil(regionHeight/2));
gridBufferX = max(GRID_BUFFER_X, ceil(regionWidth/2));

% Generate the list of coordinates that specifies the (X, Y) centers of all of the interrogation regions 
[ gridX, gridY ] = gridImage(imageSize, GRID_SPACING, gridBufferY, gridBufferX);

% Reshape the grid point arrays into vectors
gridPointsX = gridX(:);
gridPointsY = gridY(:);

% Create a variable to determine whether 
% or not a grid point should be evaluated based on the mask 
% This step applies the mask to the grid.
EvaluateGridPoint = zeros(size(gridPointsX));
for k = 1:length(gridPointsX)
    if mask(gridPointsY(k), gridPointsX(k)) > 0
        EvaluateGridPoint(k) = 1;
    end
end

% Keep only the grid points at which the mask vale was 1
evaluatedGridPointsX = gridPointsX(EvaluateGridPoint==1);
evaluatedGridPointsY = gridPointsY(EvaluateGridPoint==1);

% Determine the number of interrogation regions to be correlated
nRegions = length(evaluatedGridPointsX);
 
 % Initialize the other variables
 xMin = zeros(nRegions, 1);
 xMax = zeros(nRegions, 1);
 yMin = zeros(nRegions, 1);
 yMax = zeros(nRegions, 1);
 
% Initialize the ensemble correlation plane
ENSEMBLE_PLANE = zeros(regionHeight, regionWidth);

% Calculate the RPC for each region and add them together.
for k = 1 : nRegions
     
% Determine the leftmost column of the interrogation region
     xMin(k) = evaluatedGridPointsX(k) - ceil( regionWidth / 2 ) + 1;
     
% Determine the rightmost column of the interrogation region     
     xMax(k) = evaluatedGridPointsX(k) + floor( regionWidth / 2 );
     
% Determine the top row of the interrogation region
     yMin(k) = evaluatedGridPointsY(k) - ceil( regionHeight / 2 ) + 1;
     
%  Determine the bottom row of the interrogation region    
     yMax(k) = evaluatedGridPointsY(k) + floor ( regionWidth / 2 );
%     
% Extract and window subregions
    subRegion1 = spatialWindow .* double(image_01( max([1 yMin(k)]) : min([imageHeight yMax(k)]) , max([1 xMin(k)]) : min([imageWidth xMax(k)]) ));
    subRegion2 = spatialWindow .* double(image_02( max([1 yMin(k)]) : min([imageHeight yMax(k)]) , max([1 xMin(k)]) : min([imageWidth xMax(k)]) ));

    % Add to the ensemble plane
    ENSEMBLE_PLANE = ENSEMBLE_PLANE + phaseCorrelation(...
                    subRegion1, subRegion2);
          
end

% Apply the FFT shift to the ensemble plane
ENSEMBLE_PLANE = fftshift(ENSEMBLE_PLANE);

switch lower(CORRELATION_TYPE)
    case 'rpc'
         % Multiply the spectral correlation by the RPC filter
         % and apply the inverse FT
         ENSEMBLE_PLANE = freq2space(ENSEMBLE_PLANE .* imageSpectralFilter);

         % Locate the peak of the ensemble correlation plane to subpixel precision.
         % This function was taken from PRANA. 
         [V, U] = subpixel(ENSEMBLE_PLANE, ones(size(ENSEMBLE_PLANE)), 1, 0,...
            COMPILED); 

    case 'spc'
        
        % SPC filter cutoff amplitude
        % spc_cutoff_amplitude = 2 / (pi * SPATIAL_RPC_DIAMETER);
        
        % Truncate the RPC filter
%         imageSpectralFilter(imageSpectralFilter < spc_cutoff_amplitude) = 0;
        
        weighting_matrix = zeros(size(ENSEMBLE_PLANE));
        weighting_matrix(54:74, 54:74) = 1;
        
        % Unwrap and fit the plane
        [V, U] = spc_unwrap_2D(ENSEMBLE_PLANE, weighting_matrix,...
    {'mean'}, {5}, 'goldstein', COMPILED); 

end

end









