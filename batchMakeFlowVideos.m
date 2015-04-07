function batchMakeFlowVideos(SEGMENTLIST, PLOTTYPE)

if nargin < 2
    PLOTTYPE = 'nomarker';
end

% Determine the local-path to the project repository
projectRepository = determineLocalRepositoryPath;
addpath(fullfile(projectRepository, 'analysis', 'src', 'segmentLists', 'trunk'));

% Deterime the number of segments in the segment list
nSegments = length(SEGMENTLIST);

% Set the plot directory
figureDir = fullfile(projectRepository, 'results', 'plots', 'spatialensemble');

parfor k = 1 : nSegments
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
    
    % Raw image base name and extension
    rawImageBaseName = SEGMENTLIST(k).Parameters.Images.Raw.BaseName;
    rawImageExtension = SEGMENTLIST(k).Parameters.Images.Raw.Extension;
    
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
    pivImageType = SEGMENTLIST(k).Parameters.PIV.Files.Inputs.ImageType;
    
    numberFormat = ['%0' num2str(nDigits) '.0f'];

    % Raw image directory
    if dataRepositoryPathIsAbsolute
        rawImageDir = SEGMENTLIST(k).Parameters.Images.Raw.Dir;
        pivInputImageDir = SEGMENTLIST(k).Parameters.PIV.Files.Inputs.Dir;
        pivOutputDir = SEGMENTLIST(k).Parameters.PIV.Files.Outputs.Dir;

    else
        rawImageDir = fullfile(projectRepository, SEGMENTLIST(k).Parameters.Images.Raw.Dir);
        pivInputImageDir = fullfile(projectRepository, SEGMENTLIST(k).Parameters.PIV.Files.Inputs.Dir);
        pivOutputDir = fullfile(projectRepository, SEGMENTLIST(k).Parameters.PIV.Files.Outputs.Dir);
    end
    
    % Specify the flow data output directory. Create it if needed.
    flowDataDir = fullfile(pivOutputDir, '..', '..', 'flow', segmentName);

    videoImageDir = fullfile(flowDataDir, 'videoimages', pivImageType, PLOTTYPE);
    videoDir = fullfile(flowDataDir, 'videos', pivImageType);
    if ~exist(videoDir, 'dir')
        mkdir(videoDir);
    end
   
    % Inform user of progress
    disp(['Calculating flow statistics for ' fullfile(specimenName, segmentName) ' (' num2str(k) ' of ' num2str(nSegments) ')...'])

    pivFilePath = fullfile(pivOutputDir, [pivOutputBaseName num2str(startImage, numberFormat)...
     '-' num2str(endImage, numberFormat) pivOutputExtension]);
    
 
     % Make sure the piv file exists.
    segmentIsValid = exist(pivFilePath, 'file');
    
    
    % If there are no job problems...
    if segmentIsValid
        
        % Load the PIV file
        pivData = load(pivFilePath);

        % Image numbers of the first and second images
        firstImageNumbers = pivData.firstImageNumbers;
        
        % Number of image pairs
        numberOfPairs = length(firstImageNumbers);
        
        videoName = [specimenName '_' segmentName '_' pivImageType '_flow_' PLOTTYPE '.avi'];
        videoPath = fullfile(videoDir, videoName);    
        
        % Make video writer object
        writerObj = VideoWriter('~/Desktop/testVid.avi');
%         writerObj = VideoWriter(videoPath);   
        
        % Open video object for writing
        open(writerObj);
        
        for n = 1 : numberOfPairs
            % Make a new figure and make it invisible.

            
            disp(['Adding image to video ' fullfile(specimenName, segmentName) ' image ' num2str(n) ' of ' num2str(numberOfPairs)]);
            
            videoImageName = [specimenName '_' segmentName '_' pivImageType '_flow_' PLOTTYPE '_' num2str(n, numberFormat) '.png' ];
            
            videoImagePath = fullfile(videoImageDir, videoImageName);
            
            videoImage = imread(videoImagePath);
            
            writeVideo(writerObj, videoImage)
            
   
        end
        
        close(writerObj);
        

         
%          % Save the output data to disk
%          save(fullfile(pivOutputDir, [pivOutputBaseName num2str(startImage, numberFormat)...
%              '-' num2str(endImage, numberFormat) pivOutputExtension]),...
%              'U', 'V', 'firstImageNumbers', 'secondImageNumbers',...
%              'firstImagePaths', 'secondImagePaths', 'timePerImagePair', 'segmentData');         
    else
        disp(['Problem with segment ' fullfile(specimenName, segmentName)]);
        disp(''); % How do you do a Carriage return with disp()??
    end
   
end


















% writerObj = VideoWriter('~/Desktop/testVideo_eps.mp4', 'MPEG-4');
% 
% imDir = '/Users/matthewgiarra/Documents/School/VT/Research/EFRI/Data/Argonne_2012-04-03/grasshopper_xray/mng-1-074-A/flow/sequence-002/videoimages/meansubtracted';
% 
% imBase = 'mng-1-074-A_sequence-002_meansubtracted_flow_';
% 
% imExt = '.png';
% nDigits = 6;
% numberFormat = ['%0' num2str(nDigits) '.0f'];
% 
% startImage = 1;
% endImage = 90;
% 
% imageNums = startImage : endImage;
% 
% nImages = length(imageNums);
% 
% open(writerObj)
% for k = 1 : nImages
%    disp(['Writing frame ' num2str(k) ' of ' num2str(nImages)]);
%    imageName = [imBase num2str(imageNums(k), numberFormat) imExt];
%    imagePath = fullfile(imDir, imageName);
%    img = imread(imagePath);
%    writeVideo(writerObj, img)
% end
% 
% close(writerObj);



 
% end