function batchMaskImages(SEGMENTLIST)
% This function calculates the spatial ensemble correlation of each 
% image in a series of images

% Default to one measly core. 
if nargin < 2
    NPROCESSORS = 1;
end

% Start a matlab pool if it's requested
if NPROCESSORS > 1
    if matlabpool('size') ~= NPROCESSORS
        if matlabpool('size') > 0
            matlabpool close
        end
        matlabpool(NPROCESSORS)
    end
end

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
    rawImageBaseName = SEGMENTLIST(k).Parameters.Images.Raw.BaseName;
    rawInputImageExtension = SEGMENTLIST(k).Parameters.Images.Raw.Extension;
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
        rawImageDir = SEGMENTLIST(k).Parameters.Images.Raw.Dir;
        if maskImages
           maskDir =  SEGMENTLIST(k).Parameters.PIV.Files.Mask.Directory;
        end
    else
        rawImageDir = fullfile(projectRepository, SEGMENTLIST(k).Parameters.Images.Raw.Dir);
        if maskImages
           maskDir =  fullfile(projectRepository, SEGMENTLIST(k).Parameters.PIV.Files.Mask.Directory);
        end
    end
   
    % Inform user of progress
    disp(['Creating mask for segment ' fullfile(specimenName, segmentName) ' (' num2str(k) ' of ' num2str(nSegments) ')...'])
    
    % Specify the numbering format
    numberFormat = ['%0' num2str(nDigits) '.0f'];   

    firstImagePath = fullfile(rawImageDir, [rawImageBaseName num2str(startImage, numberFormat) rawInputImageExtension]);

    % Validate the segment list
    segmentIsValid = exist(firstImagePath, 'file');
    
    % If there are no job problems...
    if segmentIsValid && maskImages
        
        % Create the directory for the PIV output files if it doesn't already exist.
        if ~exist(maskDir, 'dir')
            mkdir(maskDir);
        end
   
        % Specify the mask name, extension, and path
        maskName = SEGMENTLIST(k).Parameters.PIV.Files.Mask.Name;
        maskExtension = SEGMENTLIST(k).Parameters.PIV.Files.Mask.Extension;
        maskPath = fullfile(maskDir, [maskName maskExtension]);

        % Check if mask already exists. If it does, prompt before overwriting.
        if exist(maskPath, 'file')
            OVERWRITE = input('Mask exists. Overwrite? (0 for no, 1 for yes. Default no): ');
            if isempty(OVERWRITE)
                overWriteMask = 0;
            else
                overWriteMask = OVERWRITE;
            end
        else
            overWriteMask = 1;
        end
            
        if overWriteMask
            acceptMask = 0;
            while acceptMask == 0
                rawImage = imread(firstImagePath);
                Mask = createStaticMask(rawImage, maskPath);
                close all;
                GreenMask = cat(3, zeros(size(Mask)), Mask, zeros(size(Mask)));
                imshow(rawImage);
                hold on;
                h = imshow(GreenMask);
                hold off;
                set(h, 'AlphaData', 0.3)
                
                acceptMask = input('Accept mask? (0 for no, 1 for yes. Default yes: ');
                
                if isempty(acceptMask)
                    acceptMask = 1;
                end
                close all;
            end
        end
        
    else
        disp(['Problem with segment ' fullfile(specimenName, segmentName)]);
        disp(''); % How do you do a Carriage return with disp()??
    end
   
    
end


end







