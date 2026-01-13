classdef preprocessingVars
    %PREPROCESSINGVARS  This class contains the default preprocessing variables

    properties
        
        % paths and directories
        spmPath % SPM path
        dsRoot % data source root directory (BIDS folder)
        preRoot % data target root directory
        srcDir % session-specific source directory
        tgtDir % session-specific data target directory
        funcLab % label for functional data sub directory
        anatLab % label for anatomical data sub directory
        fmapLab % label for field-map data sub directory
        BIDSlabel % BIDS labels
        overwriteFiles % overwrite existing preproc files (true/false)
        deleteFiles    % delete intermediate preproc files (true/false)

        % preprocessing steps
        steps   % list of preprocessing steps
        stepSlicetiming % slicetiming correction
        stepUnwarping % unwarping (fmap correction)
        stepRealignment % realignment
        stepCoregistration % coregistration of mean EPI to T1
        stepSegmentation % segmentation of T1 image
        stepNormalization % application of normalization parameters to EPI data
        stepSmoothing % smoothing
        preprocessingComponents % list of preprocessing steps to perform
        prefix
        currPrefix

        % fMRI parameters
        subjects % subject IDs
        runSel % fMRI run numbers
        nSlices % number of slices for each volume
        TR % TR of the sequence
        refSlice % reference slice (for slice-timing correction)
        sliceTiming % timing of acquisition of each slice relative to beginning of each volume (in s)
        epiReadoutTime % total epi readout time (for unwarping)
        echoTime1 % fieldmap short echo time
        echoTime2 % fieldmap long echo time
        voxelSize % EPI voxel size (used for normalization)

    end

    methods

        function obj = preprocessingVars()
            % PREPROCESSINGVARS Function that initializes the object
            %   instance with default parameters (adjust to fit your setup)
            
            % Get the parent directory of the current directory
            parentDir = fileparts(pwd);

            % SPM12
            obj.spmPath = fullfile(parentDir,'spm12/');
            obj.dsRoot = fullfile(parentDir,'exampleData/');
            obj.preRoot = fullfile(obj.dsRoot,'derivatives');
            obj.srcDir = {''};
            obj.tgtDir = {''};
            obj.funcLab = 'func';
            obj.anatLab = 'anat';
            obj.fmapLab = 'fmap';
            obj.BIDSlabel{1} = {'task-localizer';'_task-main'}; % BIDS file name task label
            obj.BIDSlabel{2} = ''; % BIDS file name acquisition label
            obj.BIDSlabel{3} = 'run-0'; % BIDS file name run index
            obj.BIDSlabel{4} = 'bold'; % BIDS file name modality suffix
            obj.overwriteFiles = true; % overwrite existing preproc files?
            obj.deleteFiles = false;    % delete intermediate preproc files?

            % Choose preprocessing steps
            obj.steps = {'slicetiming',...    
                        'unwarping',...
                        'realignment',...
                        'coregistration',...
                        'segmentation',...
                        'normalization',...
                        'smoothing'};

            obj.stepSlicetiming = true;
            obj.stepUnwarping = false;
            obj.stepRealignment = true;
            obj.stepCoregistration = true;
            obj.stepSegmentation = true;
            obj.stepNormalization = true;
            obj.stepSmoothing = false;
            obj.preprocessingComponents = [obj.stepSlicetiming,...
                                            obj.stepUnwarping,...
                                            obj.stepRealignment,...
                                            obj.stepCoregistration,...
                                            obj.stepSegmentation,...
                                            obj.stepNormalization,...
                                            obj.stepSmoothing];

            % prefixes
            obj.prefix.slicetiming = 'a';
            obj.prefix.unwarping = 'u';
            obj.prefix.realignment = 'r';
            obj.prefix.coregistration = 'c';
            obj.prefix.normalization = 'w';
            obj.prefix.smoothing = 's';
            obj.currPrefix = ''; % default prefix before first preproc step
            
            % fMRI parameters - remove defaults for specific settings (and give warning for some?)
            obj.subjects = {'all'};
            obj.runSel{1} = {1:4};  % number of functional runs per sub
            obj.nSlices = nan;      % total number of EPI slices
            obj.TR = nan;           % repetition time in seconds (!)
            obj.refSlice = (obj.TR/2)*1000; % reference slice in ms (!); default = 0.5 * TR
            obj.sliceTiming = nan;      % slice timings in ms (!)
            obj.epiReadoutTime = nan;   % total epi readout time in ms (!)
            obj.echoTime1 = nan;        % fieldmap short echo time in ms (!)
            obj.echoTime2 = nan;        % fieldmap long echo time in ms (!)
            obj.voxelSize = nan;        % [x,y,z] EPI voxel size in mm (for normalization)
        end
    end
end