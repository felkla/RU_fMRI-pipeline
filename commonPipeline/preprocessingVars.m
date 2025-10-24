classdef preprocessingVars
    %PREPROCESSINGVARS  This class contains the default preprocessing variables

    properties
        
        % paths and directories
        spmPath % SPM path
        dsRoot % data source root directory
        srcDir % source directory
        tgtDir % data target directory
        BIDSlabel % BIDS labels

        % preprocessing steps
        steps   % list of preprocessing steps
        stepSegmentation % segmentation/Normalization of T1 images
        stepRealignment % realignment
        stepSlicetiming % slicetiming correction
        stepCoregistration % coregistration of mean EPI to T1
        stepNormalization % application of normalization parameters to EPI data
        stepSmoothing % smoothing
        stepDeleteFiles % delete intermediate files
        preprocessingComponents % list of preprocessing steps to perform

        % fMRI parameters
        runSel % fMRI run numbers
        nSlices % number of slices for each volume
        TR % TR of the sequence
        sliceTiming % timing of acquisition of each slice relative to beginning of each volume (in s)

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
            obj.srcDir = 'func';
            obj.tgtDir = fullfile(cd,'derived');
            obj.BIDSlabel{1} = {'_task-localizer';'_task-main'}; % BIDS file name task label
            obj.BIDSlabel{2} = ''; % BIDS file name acquisition label
            obj.BIDSlabel{3} = '_run-00'; % BIDS file name run index
            obj.BIDSlabel{4} = '_bold'; % BIDS file name modality suffix

            % Choose preprocessing steps
            obj.steps = {'segmentation',...
                'realignment',...
                'slicetiming',...
                'coregistration',...
                'normalization',...
                'smoothing'};
            obj.stepSegmentation = false;
            obj.stepRealignment = true;
            obj.stepSlicetiming = false;
            obj.stepCoregistration = true;
            obj.stepNormalization = true;
            obj.stepSmoothing = false;
            obj.stepDeleteFiles = false;
            obj.preprocessingComponents = [obj.stepSegmentation,...
                                            obj.stepRealignment,...
                                            obj.stepSlicetiming,...
                                            obj.stepCoregistration,...
                                            obj.stepNormalization,...
                                            obj.stepSmoothing];

            % fMRI parameters - remove defaults for specific settings (and give warning for some?)
            obj.runSel{1} = {1:4};  % should match example data
            obj.nSlices = 57; % should match example data
            obj.TR = 1.5; % should match example data
            obj.sliceTiming = nan; % should match example data
        end
    end
end