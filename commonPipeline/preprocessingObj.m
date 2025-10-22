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
            subID = sprintf('sub-%2.3d',subNr); % BIDS-compliant subject IDs (e.g., 'sub-001')
            fprintf('%s - Preprocessing started\n', subID)

            % select preprocessing steps
            obj.steps = obj.steps(find(obj.preprocessingComponents == true));
            
            % inform user about steps
            fprintf('Performing steps:\n')
            for i = 1:numel(obj.steps)
                fprintf('%i: %s\n', i, obj.steps{i})
            end

            % loop over preprocessing steps
            for s = 1:numel(obj.steps)
                
                % inform user
                fprintf('%s - starting step %i: %s\n', subID, s, obj.steps{s})

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
                
                % inform user
                fprintf('%s - completed step %i: %s\n', subID, s, obj.steps{s})

            end % loop steps
            
            % delete intermediate files
            if obj.stepDeleteFiles
                fprintf('%s - deleting intermediate files...\n', subID)
                obj.deleteFiles(subNr)
            end
            
            % inform user
            fprintf('%s - Preprocessing completed\n----------------------------------\n', subID)
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
            
            % do segmentation
            fprintf('<segmenting sub %i...>\n', subNr) % placeholder code

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

            % do realignment
            fprintf('<realigning sub %i...>\n', subNr) % placeholder code

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

            % do slice time correction
            fprintf('<slice-time correcting sub %i...>\n', subNr) % placeholder code

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

            % do coregistration
            fprintf('<coregistering sub %i...>\n', subNr) % placeholder code
            
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

            % do normalization
            fprintf('<normalizing sub %i...>\n', subNr) % placeholder code

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
            
            % do smoothing
            fprintf('<smoothing sub %i...>\n', subNr) % placeholder code

        end

        % Other functions
        % ---------------

        % preprocessLoop
        function preprocessLoop(obj, subs)
            % PREPROCESSLOOP Function that you call in config file that applies 
            %   the preprocessing pipeline to each subject
            %
            %   Input
            %       subs: vector containing subject numbers
            %
            %   Output
            %       none
            
            % inform user
            fprintf('Preprocessing subjects:')
            for s = 1:numel(subs)
                if s < numel(subs)
                    fprintf(' %i,', subs(s))
                else
                    fprintf(' %i\n', subs(s))
                end
            end

            % loop over subjects
            for s = 1:numel(subs)
                obj.preprocessSubj(subs(s));
            end

            fprintf('Preprocessing finished!\n')
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
            
            fprintf('<deleting files of sub %i, steps:', subNr) % placeholder code
            
            for i = 1:numel(obj.steps)
                
                % do deletion
                if i < numel(obj.steps) % placeholder code
                    fprintf(' %s,', obj.steps{i})
                else
                    fprintf(' %s>\n', obj.steps{i})
                end
            end
        end 

    end % methods
end % class