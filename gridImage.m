function [ X, Y ] = gridImage(IMAGESIZE, GRIDSPACING, GRIDBUFFERY, GRIDBUFFERX)
%Generates a grid of points 
% INPUTS
%   IMAGESIZE = 2 x 1 vector of integers specifying image size in pixels (L = [height, width]);
%
%   GRIDSPACING = 2 x 1 vector of integers specifying the vertical and horizontal
%   grid spacing in pixels.
%
%   GRIDBUFFERY = 2 x 1 vector of integers specifying the grid buffer in pixels on
%   the top and bottom edges of the image, respectively.
%
%   GRIDBUFFERX = 2 x 1 vector of integers specifying the grid buffer in pixels on
%   the left and right edges of the image, respectively.

% Set the default vertical grid buffers to zero (i.e. no buffer on either the top or bottom edge)
if nargin < 3
    GRIDBUFFERY = [ 0 0 ];
end

% Set the default horizontal grid buffers to zero (i.e. no buffer on either the left or right edge)
if nargin < 4
    GRIDBUFFERX = [ 0 0 ];
end

% Parse the image size
imageHeight = IMAGESIZE(1);
imageWidth = IMAGESIZE(2);

% Determine the vertical and horizontal grid spacing  in pixels.
gridSpacingY = GRIDSPACING(1);
gridSpacingX = GRIDSPACING(2);

% Determine the left and right-side grid buffers in pixels.
gridBufferXLeft = GRIDBUFFERX(1);
gridBufferXRight = GRIDBUFFERX(2);

% Determine the top and bottom edge grid buffers in pixels.
gridBufferYTop = GRIDBUFFERY(1);
gridBufferYBottom = GRIDBUFFERY(2);

% GRIDSPACING=[gridSpacingY gridSpacingX];
% GRIDBUFFER=[GRIDBUFFER(1) GRIDBUFFER(2) imageHeight-GRIDBUFFER(1)+1 imageWidth-GRIDBUFFER(2)+1];
GRIDBUFFER=[gridBufferYTop gridBufferXLeft imageHeight-gridBufferYBottom+1 imageWidth-gridBufferXRight+1];

% Populate the grid.
if max(GRIDSPACING)==0
    %pixel grid
    y = (1 : imageHeight)';
    x = 1 : imageWidth;
else
    if GRIDBUFFER(1)==0
        %buffers 1/2 grid spacing
        y = (ceil((imageHeight-(floor(imageHeight/gridSpacingY)-2)*gridSpacingY)/2):gridSpacingY:(imageHeight-gridSpacingY))';
    else
        %predefined grid buffer
        y = (GRIDBUFFER(1):gridSpacingY:GRIDBUFFER(3))';
    end
    if GRIDBUFFER(2)==0
        %buffers 1/2 grid spacing
        x = ceil((imageWidth-(floor(imageWidth/gridSpacingX)-2)*gridSpacingX)/2):gridSpacingX:(imageWidth-gridSpacingX);
    else
        %predefined grid buffer
        x = (GRIDBUFFER(2) : gridSpacingX : GRIDBUFFER(4));
    end
end

%vector2matrix conversion
X = x( ones( length(y) ,1 ), : );
Y = y( : , ones(1 , length(x) ) );

% plot(X, Y, 'ok')
% xlim([1 imageWidth])
% ylim([1 imageHeight])
% set(gca, 'YDir', 'reverse')


end







