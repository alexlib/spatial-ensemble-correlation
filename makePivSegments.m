function PIVSEGMENTLIST = makePivSegments(SEGMENTLIST, INPUTIMAGETYPE)

% Copy the input segment list to the output list.
PIVSEGMENTLIST = SEGMENTLIST;

% Determine the number of segments
nSegments = length(PIVSEGMENTLIST);

% Remove dashes and underscores from the input
inputImageType = strrep(INPUTIMAGETYPE, '-', '');
inputImageType = strrep(inputImageType, '_', '');

% Populate the PIV file name fields.
for k = 1 : nSegments
    regionSize = PIVSEGMENTLIST(k).Parameters.PIV.Processing.RegionSize;
    gridSpacing = PIVSEGMENTLIST(k).Parameters.PIV.Processing.GridSpacing;
    useMask = PIVSEGMENTLIST(k).Parameters.PIV.Processing.MaskImages;
    maskMethod = PIVSEGMENTLIST(k).Parameters.PIV.Processing.MaskMethod;
    
    % Set a descriptive name for the outputs.
    if regexpi(inputImageType, 'meansub')
        PIVSEGMENTLIST(k).Parameters.PIV.Files.Inputs = PIVSEGMENTLIST(k).Parameters.Images.MeanSubtracted;
        PIVSEGMENTLIST(k).Parameters.PIV.Files.Inputs.ImageType = 'meansubtracted';
        pivOutputBaseName = PIVSEGMENTLIST(k).Parameters.Images.MeanSubtracted.BaseName;

    elseif regexpi(INPUTIMAGETYPE, 'raw')
        PIVSEGMENTLIST(k).Parameters.PIV.Files.Inputs = PIVSEGMENTLIST(k).Parameters.Images.Raw;
        PIVSEGMENTLIST(k).Parameters.PIV.Files.Inputs.ImageType = 'raw';
        pivOutputBaseName = [PIVSEGMENTLIST(k).Parameters.Images.Raw.BaseName 'raw_'];
        
    end
    
    PIVSEGMENTLIST(k).Parameters.PIV.Files.Outputs.BaseName =...
    [pivOutputBaseName 'region_' num2str(regionSize(1)) '_' num2str(regionSize(2)) ...
    '_grid_' num2str(gridSpacing(1)) '_' num2str(gridSpacing(2)) ...
    '_mask_' num2str(useMask), '_' maskMethod '_'];
    
    % PIV Start and end images. Default to the same image numbers for which
    % we have raw images.
    PIVSEGMENTLIST(k).Parameters.PIV.Files.Inputs.StartImage = PIVSEGMENTLIST(k).Parameters.Images.Raw.Start;
    PIVSEGMENTLIST(k).Parameters.PIV.Files.Inputs.EndImage = PIVSEGMENTLIST(k).Parameters.Images.Raw.End;
   
end

end