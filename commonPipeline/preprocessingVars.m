classdef preprocessingVars
    %PREPROCESSINGVARS This class contains the default preprocessing variables

    properties

        spmPath % SPM patch
        dsRoot % data source root directory
        srcDir % source directory
        tgtDir % data target directory
        BIDSlabel % BIDS labels
        stepSegmentationT1 % segmentation/Normalization of T1 images
        stepRealignment % realignement
        stepSlicetiming % slicetiming correction
        stepCoregistration % coregistration of mean EPI to T1
        stepNormalization % application of normalization parameters to EPI data
        stepSmoothing % smoothing
        runSel % fMRI run numbers
        nSlices % number of slices for each volume
        TR % TR of the sequence
        sliceTiming % timing of acquisition of each slice relative to beginning of each volume (in s)

    end

    methods

        function preprocessingVars = preprocessingVars
            % PREPROCESSINGVARS Initializes the object instance
            
            % Get the parent directory of the current directory
            parentDir = fileparts(pwd);

            % SPM12
            preprocessingvars.spmPath = fullfile(parentDir,'spm12/');
            preprocessingvars.dsRoot = fullfile(parentDir,'exampleData/');
            preprocessingvars.srcDir = 'func';
            preprocessingvars.tgt_dir = fullfile(cd,'derived');
            preprocessingvars.BIDSlabel{1} = {'_task-localizer';'_task-main'}; % BIDS file name task label
            preprocessingvars.BIDSlabel{2} = ''; % BIDS file name acquisition label
            preprocessingvars.BIDSlabel{3} = '_run-00'; % BIDS file name run index
            preprocessingvars.BIDSlabel{4} = '_bold'; % BIDS file name modality suffix
           
            % Choose preprocessing steps
            preprocessingvars.stepSegmentationT1 = false;
            preprocessingvars.stepRealignment = true;
            preprocessingvars.stepSlicetiming = false;
            preprocessingvars.stepCoregistration = false;
            preprocessingvars.stepNormalization = true;
            preprocessingvars.stepSmoothing = false;
            
            % fMRI parameters
            preprocessingvars.runSel = {1,1:12};  % should match example data
            preprocessingvars.nSlices = 57; % should match example data
            preprocessingvars.TR = 1.5; % should match example data
            preprocessingvars.sliceTiming = nan; % should match example data
        end
    end
end