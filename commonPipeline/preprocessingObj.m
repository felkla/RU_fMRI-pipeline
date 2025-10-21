classdef preprocessingObj
    %PREPROCESSINGOBJ   This class implements the preprocessing steps of 
    % the RU pipeline

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
            % PREPROCESSINGOBJ  Research unit pipeline preprocessing object
            %
            %   This function creates an object of class preprocessingObj based
            %   on the preprocessingVars initialization input
            %
            %   Input
            %       preprocessingVars: Preprocessing-variables object instance
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

        % preprocessing function
        % ----------------------

        function obj = preprocessSubj(obj, subNr)
            %   PREPROCESSSUBJ  Preprocessing function that goes through 
            %       the different steps on the subject level and applied 
            %       to each run.
            %
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

        % Preprocessing steps
        % -------------------
        % Separate functions for each step that gets called in 
        % subject-level processing function:
        
        % runSegmentation (optional)
        function obj = runSegmentation(obj, subNr)
            % RUNSEGMENTATION Function to perform segmentation and 
            %   normalization of the anatomical image
            % 
            %   Input
            %       subNr: subject ID
            %   Output
            %       none
            fprintf('sub %i - running step: Segmentation... ', subNr)
            % do segmentation

            fprintf('Done!\n')
        end

        % runRealignment
        function obj = runRealignment(obj, subNr)
            % RUNREALIGNMENT Function to perform realignment of the 
            %   functional images
            % 
            %   Input
            %       subNr: subject ID
            %   Output
            %       none
            fprintf('sub %i - running step: Realignment... ', subNr)
            % do realignment

            fprintf('Done!\n')
        end

        % runSlicetiming (optional)
        function obj = runSlicetiming(obj, subNr)
            % RUNSLICETIMING Function to perform slice-timing correction
            %   of the functional images
            % 
            %   Input
            %       subNr: subject ID
            %   Output
            %       none
            fprintf('sub %i - running step: Slicetiming... ', subNr)
            % do slice time correction

            fprintf('Done!\n')
        end

        % runCoregistration
        function obj = runCoregistration(obj, subNr)
            % RUNCOREGISTRATION Function to perform coregistration of 
            %   functional images to the anatomical image
            % 
            %   Input
            %       subNr: subject ID
            %   Output
            %       none

            fprintf('sub %i - running step: Coregistration... ', subNr)
            % do coregistration
            
            fprintf('Done!\n')
        end

        % runNormalization (optional?)
        function obj = runNormalization(obj, subNr)
            % RUNNORMALIZATION Function to perform spatial normalization of
            %   functional images (optional; use normalization parameters 
            %   obtained from the segmentation step)
            % 
            %   Input
            %       subNr: subject ID
            %   Output
            %       none

            fprintf('sub %i - running step: Normalization... ', subNr)
            % do normalization
            
            fprintf('Done!\n')
        end

        % runSmoothing (optional)
        function obj = runSmoothing(obj, subNr)
            % RUNSMOOTHING Function to perform spatial smoothing of
            %   functional images
            % 
            %   Input
            %       subNr: subject ID
            %   Output
            %       none
            
            fprintf('sub %i - running step: Smoothing... ', subNr)
            
            % do smoothing

            fprintf('Done!\n')
        end

        % Other functions
        % ---------------

        % preprocessLoop
        function preprocessLoop(obj, subs)
            % PREPROCESSLOOP Function that you call in config file that applies 
            %   the preprocessing pipeline to each subject
            %
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

        % deleteFiles
        function deleteFiles(obj, subNr)
            % DELETEFILES Function for deleting intermediate files
            %
            %   Input
            %       subNr: subject ID
            %
            %   Output
            %       none

            for i = 1:numel(obj.steps)
                fprintf('sub %i - deleting intermediate files for step: %s... ', subNr, obj.steps{i})
                
                % do deletion

                fprintf('Done!\n')                
            end
        end

    end % methods
end % class