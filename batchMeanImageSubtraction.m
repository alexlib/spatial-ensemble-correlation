function batchMeanImageSubtraction(SEGMENTLIST)
% This function subtracts from each image in a series 
% the mean image of all the images.

% Determine the local-path to the project repository
projectRepository = determineLocalRepositoryPath;
addpath(fullfile(projectRepository, 'analysis', 'src', 'segmentLists', 'trunk'));

% Deterime the number of segments in the segment list
nSegments = length(SEGMENTLIST);

for k = 1 : nSegments
    % Extract the relevant parameters from the list of jobs.
%     dataRepository = SEGMENTLIST(k).DataRepository;
%     dataType = SEGMENTLIST(k).DataType;
    specimenName = SEGMENTLIST(k).SpecimenName;
    segmentName = SEGMENTLIST(k).SegmentName;
    rawBaseName = SEGMENTLIST(k).Parameters.Images.Raw.BaseName; 
    startImage = SEGMENTLIST(k).Parameters.Images.Raw.Start;
    endImage = SEGMENTLIST(k).Parameters.Images.Raw.End;
    nDigits = SEGMENTLIST(k).Parameters.Images.NumberOfDigits;
    rawImageExtension = SEGMENTLIST(k).Parameters.Images.Raw.Extension;
    dataRepositoryPathIsAbsolute = SEGMENTLIST(k).Options.DataRepositoryPathIsAbsolute;
    meanImageBaseName = SEGMENTLIST(k).Parameters.Images.Mean.BaseName;
    meanImageExtension = SEGMENTLIST(k).Parameters.Images.Mean.Extension;
    meanSubImageBaseName = SEGMENTLIST(k).Parameters.Images.MeanSubtracted.BaseName;
    meanSubImageExtension = SEGMENTLIST(k).Parameters.Images.MeanSubtracted.Extension;

    
    % Raw image directory
    if dataRepositoryPathIsAbsolute
        rawImageDir = SEGMENTLIST(k).Parameters.Images.Raw.Dir;
        meanImageDir = SEGMENTLIST(k).Parameters.Images.Mean.Dir;
        meanSubDir = SEGMENTLIST(k).Parameters.Images.MeanSubtracted.Dir;
    else
        rawImageDir = fullfile(projectRepository, SEGMENTLIST(k).Parameters.Images.Raw.Dir);
        meanImageDir = fullfile(projectRepository, SEGMENTLIST(k).Parameters.Images.Mean.Dir);
        meanSubDir = fullfile(projectRepository, SEGMENTLIST(k).Parameters.Images.MeanSubtracted.Dir);
    end
   
    % Inform user of progress
    disp(['Creating mean-subtracted image for segment ' fullfile(specimenName, segmentName) ' (' num2str(k) ' of ' num2str(nSegments) ')...'])
    
    % Validate the segment list
    segmentIsValid = sum(validateSegmentList(SEGMENTLIST(k))) < 1;
    
    % If there are no job problems...
    if segmentIsValid
        % Caclulate the number of raw images
        nImages = endImage - startImage + 1;
        
        % Specify the numbering format
        numberFormat = ['%0' num2str(nDigits) '.0f'];   
        
        % Path to the mean image
        meanImagePath = fullfile(meanImageDir, [meanImageBaseName meanImageExtension]);
        
         % If the mean image doesn't exist, then create it. Specify no
         % validation with the 2nd argument of batchMeanImage because
         % validation was just performed above in this code.
        if ~exist(meanImagePath, 'file')
            batchMeanImage(SEGMENTLIST(k), 0);
        end
        
        % Create the directory for the mean-subtracted images if it doesn't
        % already exist.
        if ~exist(meanSubDir, 'dir')
            mkdir(meanSubDir);
        end
        
        % Load the mean image and convert it to double precision.
        meanImage = double(imread(meanImagePath));
        
        % Determine the paths to each image
         for n = 1 : nImages
             
             % Inform the user of progress.
             if mod(n, 100) == 0
                 disp(['Creating mean subtracted image ' fullfile(specimenName, segmentName) ' ' num2str(n) ' of ' num2str(nImages)]);
             end
             
             % Determine the name of each image
             rawImageName = [rawBaseName num2str(startImage + n - 1, numberFormat) rawImageExtension];
             % Determine the path to each raw image
             rawImagePath = fullfile(rawImageDir, rawImageName);
             
             % Determine the name of the mean-subtracted image to be calculated
             meanSubImageName = [meanSubImageBaseName num2str(startImage + n - 1, numberFormat) meanSubImageExtension];
             
             % Determine the path to the mean sub image to be calculated
             meanSubImagePath = fullfile(meanSubDir, meanSubImageName);
             
             % Load the raw image and convert it to double precision.
             rawImage = imread(rawImagePath);
             rawImageDouble = double(rawImage);
             meanSubImage = rawImageDouble - meanImage;
             
             % Set negative numbers to zero
             meanSubImage(meanSubImage < 0) = 0;
             
             % Convert the mean image to the same class as the orignal image.
             meanSubImage = cast(meanSubImage, 'like', rawImage);
             
             % Save the mean-subtracted image to disk
             imwrite(meanSubImage, meanSubImagePath, 'Compression', 'none');
                                     
         end                        
         
    else
        disp(['Problem with segment ' fullfile(specimenName, segmentName)]);
        disp(''); % How do you do a Carriage return with disp()??
    end
   
    
end




end