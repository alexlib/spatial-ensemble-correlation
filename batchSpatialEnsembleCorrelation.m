function [V, U] = batchSpatialEnsembleCorrelation(SEGMENTLIST)
% This function calculates the spatial ensemble correlation of each 
% image in a series of images

% Determine the local-path to the project repository
projectRepository = determineLocalRepositoryPath;
addpath(fullfile(projectRepository, 'analysis', 'src', 'segmentLists', 'trunk'));

% Deterime the number of segments in the segment list
nSegments = length(SEGMENTLIST);

for k = 1 : nSegments
    % Save the segment to a variable. This is just so that it can be saved to disk later.
    segmentData = SEGMENTLIST(k);
    
    % Extract the relevant parameters from the list of jobs.
    dataRepositoryPathIsAbsolute = SEGMENTLIST(k).Options.DataRepositoryPathIsAbsolute;
    specimenName = SEGMENTLIST(k).SpecimenName;
    segmentName = SEGMENTLIST(k).SegmentName;
    
    % PIV Input image base name and extension
    pivInputImageBaseName = SEGMENTLIST(k).Parameters.PIV.Files.Inputs.BaseName;
    pivInputImageExtension = SEGMENTLIST(k).Parameters.PIV.Files.Inputs.Extension;
    startImage = SEGMENTLIST(k).Parameters.PIV.Files.Inputs.StartImage;
    endImage = SEGMENTLIST(k).Parameters.PIV.Files.Inputs.EndImage;
    
    % PIV output base name
    pivOutputBaseName =  SEGMENTLIST(k).Parameters.PIV.Files.Outputs.BaseName;
    pivOutputExtension = SEGMENTLIST(k).Parameters.PIV.Files.Outputs.Extension;
    nDigits = SEGMENTLIST(k).Parameters.PIV.Files.Inputs.NumberOfDigits;
    
    % Read the PIV processing parameters
    gridSpacing = SEGMENTLIST(k).Parameters.PIV.Processing.GridSpacing;
    gridBufferY = SEGMENTLIST(k).Parameters.PIV.Processing.GridBufferY;
    gridBufferX = SEGMENTLIST(k).Parameters.PIV.Processing.GridBufferX;
    regionSize = SEGMENTLIST(k).Parameters.PIV.Processing.RegionSize;
    spatialWindowFraction = SEGMENTLIST(k).Parameters.PIV.Processing.SpatialWindowFraction;
    spatialRpcDiameter = SEGMENTLIST(k).Parameters.PIV.Processing.SpatialRpcDiameter;  
    imageStep = SEGMENTLIST(k).Parameters.PIV.Processing.ImageStep;    
    correlationStep = SEGMENTLIST(k).Parameters.PIV.Processing.CorrelationStep;
    
    % Determine whether or not image is masked
    maskImages = SEGMENTLIST(k).Parameters.PIV.Processing.MaskImages;
    
    % Specify directories
    if dataRepositoryPathIsAbsolute
        inputImageDir = SEGMENTLIST(k).Parameters.PIV.Files.Inputs.Dir;
        pivOutputDir = SEGMENTLIST(k).Parameters.PIV.Files.Outputs.Dir;
        if maskImages
           maskDir =  SEGMENTLIST(k).Parameters.PIV.Files.Mask.Directory;
        end
    else
        inputImageDir = fullfile(projectRepository, SEGMENTLIST(k).Parameters.PIV.Files.Inputs.Dir);
        pivOutputDir = fullfile(projectRepository, SEGMENTLIST(k).Parameters.PIV.Files.Outputs.Dir);
        if maskImages
           maskDir =  fullfile(projectRepository, SEGMENTLIST(k).Parameters.PIV.Files.Mask.Directory);
        end
    end
   
    % Inform user of progress
    disp(['Calculating spatial ensemble correlation for ' fullfile(specimenName, segmentName) ' (' num2str(k) ' of ' num2str(nSegments) ')...'])
    
    % Validate the segment list
    segmentIsValid = sum(validatePivSegmentList(SEGMENTLIST(k))) < 1;
    
    % If there are no job problems...
    if segmentIsValid
        
        % Create the directory for the PIV output files if it doesn't already exist.
        if ~exist(pivOutputDir, 'dir')
            mkdir(pivOutputDir);
        end
        
        % Specify the numbering format
        numberFormat = ['%0' num2str(nDigits) '.0f'];   
        
        % Image numbers of the first image in each pair
        firstImageNumbers = (startImage : imageStep : (endImage-correlationStep))';
        % Image numbers of the second image in each pair
        secondImageNumbers = firstImageNumbers + correlationStep;
        
        % Caclulate the number of image pairs to be correlated
        numberOfPairs = length(firstImageNumbers);
        
        % Initialize the vectors to hold the displacements
        U = zeros(numberOfPairs, 1);
        V = zeros(numberOfPairs, 1);
        
        % Determine the paths to all the images to be correlated
        for n = 1 : numberOfPairs
            firstImagePaths(n, :) = fullfile(inputImageDir, [pivInputImageBaseName num2str(firstImageNumbers(n), numberFormat) pivInputImageExtension]);
            secondImagePaths(n, :) = fullfile(inputImageDir, [pivInputImageBaseName num2str(secondImageNumbers(n), numberFormat) pivInputImageExtension]);
        end
        

        
        % Determine the number of images in the set.
        numberOfImages = size(unique(cat(1, firstImagePaths, secondImagePaths), 'rows'), 1);
        
        % Load in the static mask if exists
        if maskImages
            maskName = SEGMENTLIST(k).Parameters.PIV.Files.Mask.Name;
            maskExtension = SEGMENTLIST(k).Parameters.PIV.Files.Mask.Extension;
            maskPath = fullfile(maskDir, [maskName maskExtension]);
            if exist(maskPath, 'file')
                imageMask = imread(maskPath);
            else
        % Load the first image just to check its size.
                firstImage = imread(firstImagePaths(1, :));
                imageMask = ones(size(firstImage));
            end
        else
            firstImage = imread(firstImagePaths(1, :));
            imageMask = ones(size(firstImage));
        end
        
        % Set the masking method to 'keep' if none was specified, i.e.
        % don't zero the masked region of the image.
        if isfield(SEGMENTLIST(k).Parameters.PIV.Processing, 'MaskMethod')
            maskMethod = SEGMENTLIST(k).Parameters.PIV.Processing.MaskMethod;
        else
            maskMethod = 'keep';
        end
        
        % Start a clock
        setTicID = tic;
        % Determine the paths to each image
         parfor n = 1 : numberOfPairs
             
             % Inform the user of progress.

             disp(['Calculating spatial ensemble correlation for file ' fullfile(specimenName, segmentName) ' ' num2str(n) ' of ' num2str(numberOfPairs)]);
             
            % Load the pair of images
             image1 = double(imread(firstImagePaths(n, :)));
             image2 = double(imread(secondImagePaths(n, :)));
            
             % Calculate the average displacement from the spatial ensemble correlation
             [V(n), U(n)] = rpcSpatialEnsemble(image1,  image2, gridSpacing, ...
                 gridBufferY, gridBufferX, regionSize, spatialWindowFraction, spatialRpcDiameter, imageMask, maskMethod);                        
         end
         
         timeElapsed = toc(setTicID);
         timePerImagePair = timeElapsed / numberOfImages; 
         
         disp(['Finished spatial ensemble processing for data set ' fullfile(specimenName, segmentName)]);
         disp(['Average performance: ' num2str(timePerImagePair, '%0.4f') ' seconds per image pair']);
         
         % Save the output data to disk
         save(fullfile(pivOutputDir, [pivOutputBaseName num2str(startImage, numberFormat)...
             '-' num2str(endImage, numberFormat) pivOutputExtension]),...
             'U', 'V', 'firstImageNumbers', 'secondImageNumbers',...
             'firstImagePaths', 'secondImagePaths', 'timePerImagePair', 'segmentData');         
    else
        disp(['Problem with segment ' fullfile(specimenName, segmentName)]);
        disp(''); % How do you do a Carriage return with disp()??
    end
   
    
end


end







