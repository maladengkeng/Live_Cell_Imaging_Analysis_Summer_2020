function [] = SuperSeggerSegment(configVar) 
%% Settings that can be chosen also in the GUI
    segmentParameters = loadConstants(configVar.ssConst, 0); 
    
    segmentParameters.parallel.PARALLEL_FLAG = false; %true Growthcurve: false
    segmentParameters.parallel.parallel_pool_num = 0; %4 Growthcurve: 0
    segmentParameters.parallel.xy_parallel = 0; %1 Growthcurve: 0
    
    segmentParameters.trackOpti.NEIGHBOR_FLAG = false;
    segmentParameters.trackOpti.REMOVE_STRAY = false;
    segmentParameters.trackOpti.MIN_CELL_AGE = 1;
    
    segmentParameters.trackLoci.fluorFlag = true;

    cleanFlag = 1;
    skipFrame = 100; % Skips 0 frames each time
    frameRate = 1;
 
%% Info options
    segmentParameters.parallel.show_status = true;
    segmentParameters.parallel.verbose = false;
    
%% Defined in config
    segmentParameters.getLocusTracks.TimeStep = frameRate;
    segmentParameters.getLocusTracks.PixelSize = configVar.pixelSize;
    segmentParameters.trackLoci.numSpots = ...
        ones(1,numel(configVar.channels)-1).*configVar.numSpots; 

%% Apply supersegger
    cd(configVar.rootPath)
    figure()
    BatchSuperSeggerOpti(configVar.pathToOutput,skipFrame,...
        cleanFlag,segmentParameters,[2 2],0); 
    close(gcf)
end