classdef preprocessingObj
    %PREPROCESSINGOBJ This class implements the preprocessing steps of the
    % RU pipeline

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

        function preprocesingObj = preprocessingObj(preprocessing_vars)
            % PREPROCESSINGOBJ Research unit pipeline preprocessing object
            %
            %   This function creates a task object of class PreprocessingObj based
            %   on the preprocessing_vars initialization input
            %
            %   Input
            %       preprocessing_vars: Preprocessing-variables-object instance
            %
            %   Output
            %       none

            spmPath = preprocessing_vars.spmPath;
            dsRoot = preprocessing_vars.dsRoot;
            srcDir = preprocessing_vars.srcDir;
            tgtDir = preprocessing_vars.tgtDir;
            BIDSlabel = preprocessing_vars.BIDSlabel;
            stepSegmentationT1 = preprocessing_vars.stepSegmentationT1;
            stepRealignment = preprocessing_vars.stepRealignment;
            stepSlicetiming = preprocessing_vars.stepSlicetiming;
            stepCoregistration = preprocessing_vars.stepCoregistration;
            stepNormalization = preprocessing_vars.stepNormalization;
            stepSmoothing = preprocessing_vars.stepSmoothing;
            runSel = preprocessing_vars.runSel;
            nSlices = preprocessing_vars.nSlices;
            TR = preprocessing_vars.TR;
            sliceTiming = preprocessing_vars.sliceTiming;

        end
        
        % TODO: 

        % Preprocessing function that goes through the different steps
        % On the subject level and applied to each run
        %   - select each preprocessing step based on stepSegmentationT1
        %   etc. 
        
        % Separate functions for each step that gets called in subject-level
        % processing function
        %   - runSegmentationT1
        %   - runRrealignment
        %   - runSlicetiming
        %   - runCoregistration
        %   - runNormalization
        %   - runSmoothings

        % Function that you call in config file that applies preprocessing
        % to each subject

        % Function for deleting unnecessary files

    end
end