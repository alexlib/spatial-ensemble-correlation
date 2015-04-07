function batchMakePlotVideoImages(SEGMENTLIST, PLOTTYPE)
% This function calculates the spatial ensemble correlation of each 
% image in a series of images

if nargin < 2
    PLOTTYPE = 'nomarker';
end

fSize = 10;

% Determine the local-path to the project repository
projectRepository = determineLocalRepositoryPath;
addpath(fullfile(projectRepository, 'analysis', 'src', 'segmentLists', 'trunk'));
addpath('export_fig');

% Deterime the number of segments in the segment list
nSegments = length(SEGMENTLIST);

% Set the plot directory
figureDir = fullfile(projectRepository, 'results', 'plots', 'spatialensemble');
if ~exist(figureDir, 'dir')
    mkdir(figureDir);
end  


for k = 1 : nSegments
    % Save the segment to a variable. This is just so that it can be saved to disk later.
    segmentData = SEGMENTLIST(k);
    
    % Path to the mask
%     maskPath = fullfile(projectRepository, segmentData.Parameters.PIV.Files.Mask.Directory, [segmentData.Parameters.PIV.Files.Mask.Name segmentData.Parameters.PIV.Files.Mask.Extension]);
    
    
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
    
    disp(['Absolute repository flag : ' num2str(dataRepositoryPathIsAbsolute)]);
    disp(pivOutputDir);
    
    % Specify the flow data output directory. Create it if needed.
    flowDataDir = fullfile(pivOutputDir, '..', '..', 'flow', segmentName);
    if ~exist(flowDataDir, 'dir')
        mkdir(flowDataDir)
    end
    
    videoImageDir = fullfile(flowDataDir, 'videoimages', pivImageType, PLOTTYPE);
    if ~exist(videoImageDir, 'dir');
        mkdir(videoImageDir);
    end
   
    % Inform user of progress
    disp(['Creating video images for ' fullfile(specimenName, segmentName) ' (' num2str(k) ' of ' num2str(nSegments) ')...'])

    pivFilePath = fullfile(pivOutputDir, [pivOutputBaseName num2str(startImage, numberFormat)...
     '-' num2str(endImage, numberFormat) pivOutputExtension]);
 
     % Make sure the piv file exists.
    segmentIsValid = exist(pivFilePath, 'file');
    disp(['Looking for piv file ' pivFilePath '...']);
    
    % If there are no job problems...
    if segmentIsValid
        
        % Load the PIV file
        pivData = load(pivFilePath);
        

        % Image numbers of the first and second images
        firstImageNumbers = pivData.firstImageNumbers;
        secondImageNumbers = pivData.secondImageNumbers;
        
        % Number of image pairs
        numberOfPairs = length(firstImageNumbers);

        % Determine the paths to all the images to be correlated
        for n = 1 : numberOfPairs
            rawImagePaths(n, :) = fullfile(rawImageDir, [rawImageBaseName num2str(firstImageNumbers(n), numberFormat) rawImageExtension]);
            pivImagePaths(n, :) = fullfile(pivInputImageDir, [pivInputImageBaseName num2str(firstImageNumbers(n), numberFormat) pivInputImageExtension]);
        end
        
        framesPerSecond = SEGMENTLIST(k).Parameters.Images.Raw.FramesPerSecond;
        micronsPerPixel = SEGMENTLIST(k).Parameters.Images.Raw.MicronsPerPixel;
        headDirection = SEGMENTLIST(k).Parameters.Images.Raw.HeadDirection;
        
        % Vertical velocity
        V = pivData.V;
        
        % If the head was to the left in the image, flip the sign of the
        % measured velocity.
        if regexpi(headDirection, 'r')
            U = pivData.U;
            
        else
            U = -1 * pivData.U;   
            
        end
      
            Uaugmented = 50 * pivData.U;
        
        % Number of measurements
        nSamples = length(firstImageNumbers);
        
        % Horizontal velocity in mm/sec
        Umms = U * framesPerSecond * correlationStep * micronsPerPixel * 1e-3;
        
        % Vertical velocity in mm/sec
        Vmms = V * framesPerSecond * correlationStep * micronsPerPixel * 1e-3;
        
        % Elapsed time in seconds
        tSeconds = firstImageNumbers / framesPerSecond;
        
        % Smooth the data
        uSmoothed = smooth(Umms, 50, 'moving');
        vSmoothed = smooth(Vmms, 50, 'moving');
        
        Vaugmented = 1000 * vSmoothed;
        Uaugmented = - 1000 * uSmoothed;
        
        
        % Calculate some statistics:
        % Mean
        meanUsmooth = mean(uSmoothed);
        % Standard deviation
        uStd = std(uSmoothed);
        % 95% confidence interval of the mean value
        u95 = 1.96 * uStd / sqrt(nSamples);
        % Upper and lower bounds of the 95% undertainty interval
        uMeanConfUpper = meanUsmooth + u95;
        uMeanConfLower = meanUsmooth - u95;
        
        
        
        close all;
%         figure('Visible', 'off');

%         videoName = [specimenName '_' segmentName '_' pivImageType '_flow_' PLOTTYPE '.avi'];
%         videoPath = fullfile(videoDir, videoName);
%         videoPath = fullfile('~/Desktop/testVid.avi');
        
        fHandle = figure('visible', 'off');
        
        
%         % Make video writer object
%         writerObj = VideoWriter(videoPath);
%         
%         % Open video object for writing
%         open(writerObj);

        

        for n = 1 : numberOfPairs
%           for n = 1 : 10;
            % Make a new figure and make it invisible.
            
            
            % Inform the user
            disp(['Creating video images for segment ' fullfile(specimenName, segmentName) ' image ' num2str(n) ' of ' num2str(numberOfPairs)]);
            
            % Name of the video image to be created
            videoImageName = [specimenName '_' segmentName '_' pivImageType '_flow_' PLOTTYPE '_' num2str(n, numberFormat) '.png' ];
            
            % Path to the video image to be created
            videoImagePath = fullfile(videoImageDir, videoImageName);
            
            % Load the raw image
            rawImage = double(imread(rawImagePaths(n, :)));
            
            % Determine the image size
            [imHeight, imWidth] = size(rawImage);
            
            % Determine the image center
            xc = round(imWidth / 2 );
            bufferSize = imHeight - imWidth;
            yc = round(imWidth/2) + bufferSize; % This line assumes height = width

            
            % Plot the image overlaid with the flow tracer marker
            subplot(1, 2, 1);
            imagesc(rawImage); axis image; colormap gray; axis off
            title('Raw Image', 'FontSize', fSize);
            hold on;
%             plot([xc - 200, xc+200], [yc yc], '--y', 'LineWidth', 1);
            plot([xc xc], [yc - 200, yc + 200], '--y', 'LineWidth', 1);
            quiver(xc, yc, Uaugmented(n), 0, 'green', 'LineWidth', 3);
%             plot(xc+Uaugmented(n), yc+Vaugmented(n), 'ok', 'MarkerFaceColor', 'green', 'MarkerSize', 10);
            hold off;
            
            % Plot the horizontal component of velocity vs time.
            subplot(1, 2, 2);
            plot(tSeconds, Umms, '-k');
            hold on
            plot(tSeconds, uSmoothed, '-r', 'lineWidth', 2);

            % Plot the statistics, etc.  
            plot([tSeconds(1), tSeconds(end)], [meanUsmooth meanUsmooth], '--r'); % plot mean
            plot([tSeconds(1), tSeconds(end)], [uMeanConfUpper uMeanConfUpper], '--b');
            plot([tSeconds(1), tSeconds(end)], [uMeanConfLower uMeanConfLower], '--b');
            plot([tSeconds(1), tSeconds(end)], [0 0], '-k'); % Plot zero
            plot([tSeconds(n), tSeconds(n)], [-1 1], '--k'); % Plot zero

            % Format the plot
            axis square
            xlabel('Time (seconds)', 'fontSize', fSize);
            ylabel('Horizontal velocity (mm/sec)', 'fontSize', fSize);
            title(['Horizontal velocity, ' fullfile(specimenName, segmentName) ], 'fontSize', fSize);
            set(gca, 'fontSize', fSize);            
            ylim(max(abs(uSmoothed(:))) * [-1.1 1.1]);
            xlim([0 tSeconds(end)]);
            hold off

            % Create a legend
            h = legend('Raw Signal', 'Filtered Signal', ...
                'Mean of Filtered Signal', '95% Confidence Interval', ...
                'Location', 'NorthWest');
            set(h,'FontSize',fSize/1.5);
            
%             frame = getframe(fHandle);
            
%             set(fHandle, 'position', [ 100 100 1500 1000]);
%             writeVideo(writerObj, frame);
           

%             export_fig(fHandle, '-painters','-png','-r200', videoImagePath);
            set(fHandle, 'position', [ 100 100 1125 750], 'color', 'white');
            
            if ~ismac
                export_fig(fHandle, '-painters','-png','-r150', videoImagePath);
            else
                print(fHandle, '-dpng', '-r150', videoImagePath);
            end
            
            % Close the open figure.
%             close(fHandle);

%             pause(0.01);
   
          end
        
          % Close video file
%           close(writerObj);
        

         
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









