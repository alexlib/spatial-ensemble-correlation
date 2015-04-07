% runPivProcessing
Repository = determineLocalRepositoryPath;

addpath(fullfile(Repository, 'analysis', 'src', 'segmentLists', 'trunk'));

SegmentList = segment_list_grasshopper_xray_reduced;

pivSegListMeanSub = makePivSegments(SegmentList, 'meansub');
pivSegListRaw = makePivSegments(SegmentList, 'raw');

batchSpatialEnsembleCorrelation(pivSegListMeanSub, 8);
batchSpatialEnsembleCorrelation(pivSegListRaw, 8);

matlabpool close

batchCalculateNetFlow(pivSegListMeanSub);
batchCalculateNetFlow(pivSegListRaw);

batchMakePlotVideoImages(pivSegListMeanSub);
batchMakePlotVideoImages(pivSegListRaw);

batchMakeFlowVideos(pivSegListMeanSub);
batchMakeFlowVideos(pivSegListRaw);
