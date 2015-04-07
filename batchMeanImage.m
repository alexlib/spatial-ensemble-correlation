function batchMeanImage(SEGMENTLIST, VALIDATESEGMENT)

% Default to validating the segment before calculating the mean image.
if nargin < 2
    VALIDATESEGMENT = 1;
end

% Determine the local-path to the project repository
projectRepository = determineLocalRepositoryPath;
addpath(fullfile(projectRepository, 'analysis', 'src', 'segmentLists', 'trunk'));

% Deterime the number of segments in the segment list
nSegments = length(SEGMENTLIST);

for k = 1 : nSegments
    % Extract the relevant parameters from the list of jobs.
    dataRepository = SEGMENTLIST(k).DataRepository;
    dataType = SEGMENTLIST(k).DataType;
    specimenName = SEGMENTLIST(k).SpecimenName;
    segmentName = SEGMENTLIST(k).SegmentName;
    rawBaseName = SEGMENTLIST(k).Parameters.Images.Raw.BaseName; 
    startImage = SEGMENTLIST(k).Parameters.Images.Raw.Start;
    endImage = SEGMENTLIST(k).Parameters.Images.Raw.End;
    nDigits = SEGMENTLIST(k).Parameters.Images.NumberOfDigits;
    imageExtension = SEGMENTLIST(k).Parameters.Images.Raw.Extension;
    dataRepositoryPathIsAbsolute = SEGMENTLIST(k).Options.DataRepositoryPathIsAbsolute;
    meanImageBaseName = SEGMENTLIST(k).Parameters.Images.Mean.BaseName;
    meanImageExtension = SEGMENTLIST(k).Parameters.Images.Mean.Extension;
    
    % Raw image directory
    if dataRepositoryPathIsAbsolute
        rawImageDir = SEGMENTLIST(k).Parameters.Images.Raw.Dir;
        meanImageDir = SEGMENTLIST(k).Parameters.Images.Mean.Dir;
    else
        rawImageDir = fullfile(projectRepository, SEGMENTLIST(k).Parameters.Images.Raw.Dir);
        meanImageDir = fullfile(projectRepository, SEGMENTLIST(k).Parameters.Images.Mean.Dir);        
    end
   
    % Inform user of progress
    disp(['Creating mean image for segment ' fullfile(specimenName, segmentName) ' (' num2str(k) ' of ' num2str(nSegments) ')...'])
    
    % Validate the segment list if validation is requested.
    if VALIDATESEGMENT
        segmentIsValid = sum(validateSegmentList(SEGMENTLIST(k))) < 1;
    else
        % If no validation is requested, then segmentIsValid is forced to 1. 
        segmentIsValid = 1;
    end
    
    % If there are no job problems...
    if segmentIsValid
        % Caclulate the number of raw images
        nImages = endImage - startImage + 1;
        % Specify the numbering format
        numberFormat = ['%0' num2str(nDigits) '.0f'];       
        
        % Determine the paths to each image
         for n = 1 : nImages
             % Determine the name of each image
             imageName = [rawBaseName num2str(startImage + n - 1, numberFormat) imageExtension];
             % Determine the path to each image
             imagePath(n, :) = fullfile(rawImageDir, imageName);
         end
        
         % Read in the first image
         firstImage = imread(imagePath(1, :));
         % Determine the dimensions of the first image. The rest of this function
         % assumes that all of the images in the set have the same
         % dimensions as the first image in the set.
         [height, width, nChannels] = size(firstImage);
         
         % Initialize the sum-image as a double precision array.
         sumImage = zeros(height, width, nChannels, 'double');
         
         % Add each image to each channel of the mean image
         for n = 1 : nImages
            % Inform the user of progress
            if mod(n, 100) == 0
                disp(['Processing image ' fullfile(specimenName, segmentName) ' ' num2str(n) ' of ' num2str(nImages) '...' ]);
            end
            currentImage = double(imread(imagePath(n, :)));
            % Add the current image to the mean image
            sumImage = sumImage + currentImage;
            
         end
         
         % Divide the sum-image by the number of images to get the average
         % image. Convert the data type to the same data type as the first
         % image that was read in.
         meanImage = cast(sumImage / nImages, 'like', firstImage);
        
         % Save the mean image to the same folder where the raw images are
         % located. I don't think a single mean image needs its own
         % directory.
         meanImageSaveName = [meanImageBaseName meanImageExtension];    
         meanImageSavePath = fullfile(meanImageDir, meanImageSaveName);
         if ~exist(meanImageDir, 'dir')
             mkdir(meanImageDir);
         end
         
         imwrite(meanImage, meanImageSavePath, 'Compression', 'none');
         disp(['Saved mean image to ' meanImageSavePath '.']);
         disp(''); % How do you do a Carriage return with disp()??
         
    else
        disp(['Problem with segment ' fullfile(specimenName, segmentName)]);
        disp(''); % How do you do a Carriage return with disp()??
    end
   
    
end


end

















