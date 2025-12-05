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

        % preprocessing steps
        steps   % list of preprocessing steps
        stepSegmentation % segmentation/Normalization of T1 images
        stepSlicetiming % slicetiming correction
        stepUnwarping % unwarping (fmap correction)
        stepRealignment % realignment
        stepCoregistration % coregistration of mean EPI to T1
        stepNormalization % application of normalization parameters to EPI data
        stepSmoothing % smoothing
        stepDeleteFiles % delete intermediate files
        preprocessingComponents % list of preprocessing steps to perform
        prefix

        % fMRI parameters
        subjects % subject IDs
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
            obj.preRoot = fullfile(obj.dsRoot,'derived');
            obj.srcDir = {''};
            obj.tgtDir = {''};
            obj.funcLab = 'func';
            obj.anatLab = 'anat';
            obj.fmapLab = 'fmap';
            obj.BIDSlabel{1} = {'task-localizer';'_task-main'}; % BIDS file name task label
            obj.BIDSlabel{2} = ''; % BIDS file name acquisition label
            obj.BIDSlabel{3} = 'run-0'; % BIDS file name run index
            obj.BIDSlabel{4} = 'bold'; % BIDS file name modality suffix

            % Choose preprocessing steps
            obj.steps = {'segmentation',...
                        'slicetiming',...    
                        'realignment',...
                        'unwarping',...
                        'coregistration',...
                        'normalization',...
                        'smoothing'};

            obj.stepSegmentation = false;
            obj.stepSlicetiming = false;
            obj.stepUnwarping = false;
            obj.stepRealignment = true;
            obj.stepCoregistration = true;
            obj.stepNormalization = true;
            obj.stepSmoothing = false;
            obj.stepDeleteFiles = false;
            obj.preprocessingComponents = [obj.stepSegmentation,...
                                            obj.stepSlicetiming,...
                                            obj.stepUnwarping,...
                                            obj.stepRealignment,...
                                            obj.stepCoregistration,...
                                            obj.stepNormalization,...
                                            obj.stepSmoothing];

            % prefixes
            obj.prefix.segmentation = '';
            obj.prefix.slicetiming = 'a';
            obj.prefix.unwarping = 'u';
            obj.prefix.realignment = 'r';
            obj.prefix.coregistration = '';
            obj.prefix.normalization = 'w';
            obj.prefix.smoothing = 's';
            
            % fMRI parameters - remove defaults for specific settings (and give warning for some?)
            obj.subjects = {'all'};
            obj.runSel{1} = {1:4};  % should match example data
            obj.nSlices = nan;      % should match example data
            obj.TR = nan;           % should match example data
            obj.sliceTiming = nan;  % should match example data
        end
    end
end