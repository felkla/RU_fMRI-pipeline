classdef preprocessingObj
    %PREPROCESSINGOBJ This class implements the preprocessing steps of the
    % RU pipeline

    properties
        
        % paths and directories
        spmPath % SPM patch
        dsRoot % data source root directory
        srcDir % source directory
        tgtDir % data target directory
        BIDSlabel % BIDS labels

        % preprocessing steps
        steps % list of preprocessing steps
        stepSegmentation % segmentation/Normalization of T1 images
        stepRealignment % realignement
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

        function obj = preprocessingObj(preprocessingVars)
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
            
            % paths
            obj.spmPath = preprocessingVars.spmPath;
            obj.dsRoot = preprocessingVars.dsRoot;
            obj.srcDir = preprocessingVars.srcDir;
            obj.tgtDir = preprocessingVars.tgtDir;
            obj.BIDSlabel = preprocessingVars.BIDSlabel;
            
            % preprocessing steps
            obj.steps = preprocessingVars.steps;
            obj.stepSegmentation = preprocessingVars.stepSegmentation;
            obj.stepRealignment = preprocessingVars.stepRealignment;
            obj.stepSlicetiming = preprocessingVars.stepSlicetiming;
            obj.stepCoregistration = preprocessingVars.stepCoregistration;
            obj.stepNormalization = preprocessingVars.stepNormalization;
            obj.stepSmoothing = preprocessingVars.stepSmoothing;
            obj.stepDeleteFiles = preprocessingVars.stepDeleteFiles;
            obj.preprocessingComponents = preprocessingVars.preprocessingComponents;

            % fMRI parameters
            obj.runSel = preprocessingVars.runSel;
            obj.nSlices = preprocessingVars.nSlices;
            obj.TR = preprocessingVars.TR;
            obj.sliceTiming = preprocessingVars.sliceTiming;

        end

        % TODO:

        % Preprocessing function that goes through the different steps
        % On the subject level and applied to each run
        %   - select each preprocessing step based on 'stepSegmentation' etc.
        function obj = preprocessSubj(obj, subNr)
            %   Input
            %       subNr: subject ID
            %       steps: preprocessing steps to perform
            %
            %   Output
            %       none

            % select subject data
            fprintf('Preprocessing sub %i\n', subNr)

            % select preprocessing steps
            obj.steps = obj.steps(find(obj.preprocessingComponents == true));
            
            % inform user about steps
            fprintf('Performing steps:\n')
            for i = 1:numel(obj.steps)
                fprintf('%i: %s\n', i, obj.steps{i})
            end

            % loop over preprocessing steps
            for s = 1:numel(obj.steps)
                switch obj.steps{s}
                    case 'segmentation'
                        obj.runSegmentation(subNr);

                    case 'realignment'
                        obj.runRealignment(subNr);

                    case 'slicetiming'
                        obj.runSlicetiming(subNr);

                    case 'coregistration'
                        obj.runCoregistration(subNr);

                    case 'normalization'
                        obj.runNormalization(subNr);

                    case 'smoothing'
                        obj.runSmoothing(subNr);

                end % switch steps

            end % loop steps
            
            % delete intermediate files
            if obj.stepDeleteFiles
                obj.deleteFiles(subNr)
            end
            
            % inform user
            fprintf('sub %i - Done!\n-------------------------------\n', subNr)
        end

        % Separate functions for each step that gets called in subject-level processing function
        % runSegmentation
        function obj = runSegmentation(obj, subNr)
            fprintf('sub %i - running step: Segmentation... ', subNr)
            % do segmentation

            fprintf('Done!\n')
        end

        % runRealignment
        function obj = runRealignment(obj, subNr)
            fprintf('sub %i - running step: Realignment... ', subNr)
            % do realignment

            fprintf('Done!\n')
        end

        % runSlicetiming
        function obj = runSlicetiming(obj, subNr)
            fprintf('sub %i - running step: Slicetiming... ', subNr)
            % do slice time correction

            fprintf('Done!\n')
        end

        % runCoregistration
        function obj = runCoregistration(obj, subNr)
            fprintf('sub %i - running step: Coregistration... ', subNr)
            % do coregistration
            
            fprintf('Done!\n')
        end

        % runNormalization
        function obj = runNormalization(obj, subNr)
            fprintf('sub %i - running step: Normalization... ', subNr)
            % do normalization
            
            fprintf('Done!\n')
        end

        % runSmoothing
        function obj = runSmoothing(obj, subNr)
            fprintf('sub %i - running step: Smoothing... ', subNr)
            % do smoothing

            fprintf('Done!\n')
        end

        % Function that you call in config file that applies preprocessing to each subject
        function preprocessLoop(obj, subs)
            %   Input
            %       subs: vector containing subject IDs (BIDS compatible)
            %
            %   Output
            %       none

            % loop over subjects
            for s = 1:numel(subs)
                obj.preprocessSubj(subs(s));
            end
        end

        % Function for deleting intermediate files
        function deleteFiles(obj, subNr)
            for i = 1:numel(obj.steps)
                fprintf('sub %i - deleting intermediate files for step: %s... ', subNr, obj.steps{i})
                % do deletion

                fprintf('Done!\n')                
            end
        end

    end % methods
end % class