
doMean = 0;
IMDIR = '~/Desktop/sequence_001/raw';
WRITEDIR = '~/Desktop/sequence_001/zeromeansub';


IMBASE = 'mng-1-072-B_sequence-001_';

EXT = '.tif';

NDIGITS = 6;
START = 1;
STOP = 1000;

numberFormat = ['%0' num2str(NDIGITS) '.0f'];

nImages = STOP - START + 1;

firstImagePath = fullfile(IMDIR, [IMBASE num2str(START, numberFormat) EXT]);

firstImage = imread(firstImagePath);

[height width] = size(firstImage);

meanImage = zeros(height, width);


%     
%     for k = 1: nImages
%         fprintf(1, ['Image ' num2str(START + k - 1) '\n']);
%         imagePath = fullfile(IMDIR, [IMBASE num2str(START + k - 1, numberFormat) EXT]);
%         img = double(imread(imagePath));
%         meanImage = meanImage + img;
%     end
% 
% MEANIMAGE = meanImage / nImages;
% imwrite(uint8(MEANIMAGE), fullfile(WRITEDIR, 'meanImage.tif'));
% 

% Now subtract the mean image from each image
for k = 1:nImages
     fprintf(1, ['Image ' num2str(START + k - 1) '\n']);
      imagePath = fullfile(IMDIR, [IMBASE num2str(START + k - 1, numberFormat) EXT]);
      img = double(imread(imagePath));
      zeroMeanSubImage = img - MEANIMAGE;
      imwrite(uint8(zeroMeanSubImage), fullfile(WRITEDIR, [IMBASE 'zms_' num2str(START + k - 1, numberFormat) EXT]));
    
    
end


















