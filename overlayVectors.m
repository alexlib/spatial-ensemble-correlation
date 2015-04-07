% overlayVectors
close all
vectorDir = '/Users/matthewgiarra/Desktop/piv/pass_02';
imDir = '/Users/matthewgiarra/Documents/School/VT/Research/EFRI/Data/Argonne_2012-04-03/grasshopper_xray/mng-1-072-B/raw/sequence-001';

vectorBase = 'mng_1_072_B_motion_pass2_';
imBase = 'mng-1-072-B_sequence-001_';

figureDir = '~/Desktop/figs';
figureBase = 'mng_1_072_B_motion_';
figureExt = '.png';

vectorExt = '.mat';
imExt = '.tif';

nDigits = 6;
numberFormat = ['%0' num2str(nDigits) '.0f'];

startFrame = 1;
frameStep = 1;
endFrame = 100;

frameNums = startFrame : frameStep : endFrame;

nFrames = length(frameNums);

Skip = 20;
Thresh = 0.01;

videoDir = '~/Desktop';
videoName = [imBase '_motionTracking.mp4'];
videoPath = fullfile(videoDir, videoName);    

% Make video writer object
writerObj = VideoWriter(videoPath, 'MPEG-4');

% Open video object for writing
open(writerObj);


for k = 1 : nFrames
    ImagePath = fullfile(imDir, [imBase num2str(frameNums(k), numberFormat) imExt]);
    vectorPath = fullfile(vectorDir, [vectorBase num2str(frameNums(k), numberFormat) vectorExt]);
    
    img = imread(ImagePath);
    vect = load(vectorPath);
    
    X = vect.X;
    Y = flipud(vect.Y);
    U = vect.U;
    V = -1 * vect.V;
    
    
    uVal = U(abs(U) > Thresh);
    vVal = V(abs(U) > Thresh);
    xVal = X(abs(U) > Thresh);
    yVal = Y(abs(U) > Thresh);
    
    
    
    imagesc(img); axis image; colormap gray;
    hold on
%     
    quiver(xVal(1:Skip:end), yVal(1:Skip:end), uVal(1:Skip:end), vVal(1:Skip:end), 'green');
    
    hold off;
    
    figurePath = fullfile(figureDir, [figureBase num2str(frameNums(k), numberFormat) figureExt]);
    print(1, '-dpng', '-r300', figurePath);

    
    
    
    
    
end


movie(currFrame, 1);


