function batchCalculateNetFlow(SEGMENTLIST)
% This function calculates the spatial ensemble correlation of each 
% image in a series of images

fSize = 16;

% Determine the local-path to the project repository
projectRepository = determineLocalRepositoryPath;
addpath(fullfile(projectRepository, 'analysis', 'src', 'segmentLists', 'trunk'));

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
    pivImageType = SEGMENTLIST(k).Parameters.PIV.Files.Inputs.ImageType;
    
    numberFormat = ['%0' num2str(nDigits) '.0f'];

    % Raw image directory
    if dataRepositoryPathIsAbsolute
        inputImageDir = SEGMENTLIST(k).Parameters.PIV.Files.Inputs.Dir;
        pivOutputDir = SEGMENTLIST(k).Parameters.PIV.Files.Outputs.Dir;

    else
        inputImageDir = fullfile(projectRepository, SEGMENTLIST(k).Parameters.PIV.Files.Inputs.Dir);
        pivOutputDir = fullfile(projectRepository, SEGMENTLIST(k).Parameters.PIV.Files.Outputs.Dir);
    end
    
    % Specify the flow data output directory. Create it if needed.
    flowDataDir = fullfile(pivOutputDir, '..', '..', 'flow', segmentName);
    if ~exist(flowDataDir, 'dir')
        mkdir(flowDataDir)
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
        

        firstImageNumbers = pivData.firstImageNumbers;
        secondImageNumbers = pivData.secondImageNumbers;
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
        
        % Plot velocity vs time
        figure(1);
        plot(tSeconds, Umms, '-k');
        hold on
        plot(tSeconds, uSmoothed, '-b', 'lineWidth', 3);
        
        % Plot the statistics, etc.  
        plot([tSeconds(1), tSeconds(end)], [meanUsmooth meanUsmooth], '--b', 'lineWidth', 1); % plot mean
        plot([tSeconds(1), tSeconds(end)], [uMeanConfUpper uMeanConfUpper], '--r', 'lineWidth', 1);
        plot([tSeconds(1), tSeconds(end)], [uMeanConfLower uMeanConfLower], '--r', 'lineWidth', 1);
        plot([tSeconds(1), tSeconds(end)], [0 0], '-k'); % Plot zero
        
        % Format the plot
        axis square
        xlabel('Time (seconds)', 'fontSize', fSize);
        ylabel('Horizontal velocity (mm/sec)', 'fontSize', fSize);
        title(['Horizontal velocity, ' fullfile(specimenName, segmentName) ], 'fontSize', fSize);
        set(gca, 'fontSize', fSize);
        set(gcf, 'color', 'white');
%         ylim([-0.5 0.5]);

        hold off
        
        
        % Create a legend
        h = legend('Raw Signal', 'Filtered Signal', ...
            'Mean of Filtered Signal', '95% Confidence Interval', ...
            'Location', 'NorthWest');
        set(h,'FontSize',fSize);
       
        % Determine names and paths of figures 
        figureName = [specimenName '_' segmentName '_uVelocity_' pivImageType ];
        figureEpsPath = fullfile(figureDir, [ figureName '.eps' ]);
        figureFigPath = fullfile(figureDir, [ figureName '.fig' ]);
        
        % Determine names and paths of data to save
        flowFileName = [specimenName '_' segmentName '_' pivImageType '_flow.mat' ];
        flowFilePath = fullfile(flowDataDir, flowFileName);
        save(flowFilePath, 'segmentData', 'pivData', 'firstImageNumbers', 'secondImageNumbers', 'Umms', 'Vmms', 'uSmoothed', 'vSmoothed', 'meanUsmooth', 'uStd', 'u95', 'uMeanConfUpper','uMeanConfLower' )
        
        
        
        % Save the plots and inform the user of progress.
        disp(['Saving figure for set ' fullfile(specimenName, segmentName)]);
        print(1, '-depsc', figureEpsPath);
        saveas(1, figureFigPath, 'fig');
        
         
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









