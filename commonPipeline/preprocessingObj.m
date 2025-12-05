classdef preprocessingObj
    %PREPROCESSINGOBJ   This class implements the preprocessing steps of
    % the RU pipeline

    properties

        % paths and directories
        spmPath % SPM patch
        dsRoot % data source root directory
        preRoot % data target root directory
        srcDir % session-specific source directory
        tgtDir % session-specific data target directory
        funcLab % label for functional data sub directory
        anatLab % label for anatomical data sub directory
        fmapLab % label for field-map data sub directory
        BIDSlabel % BIDS labels

        % preprocessing steps
        steps % list of preprocessing steps
        stepSegmentation % segmentation/Normalization of T1 images
        stepSlicetiming % slicetiming correction
        stepUnwarping % unwarping (fmap correction)
        stepRealignment % realignment
        stepCoregistration % coregistration of mean EPI to T1
        stepNormalization % application of normalization parameters to EPI data
        stepSmoothing % smoothing
        stepDeleteFiles % delete intermediate files
        preprocessingComponents % list of preprocessing steps to perform
        prefix % prefix for each preprocessing step
        currPrefix % variable to dynamically update prefix

        % fMRI parameters
        subjects % selected subjects (IDs)
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
            obj.preRoot = preprocessingVars.preRoot;
            obj.srcDir = preprocessingVars.srcDir;
            obj.tgtDir = preprocessingVars.tgtDir;
            obj.funcLab = preprocessingVars.funcLab;
            obj.anatLab = preprocessingVars.anatLab;
            obj.fmapLab = preprocessingVars.fmapLab;
            obj.BIDSlabel = preprocessingVars.BIDSlabel;

            % preprocessing steps
            obj.steps = preprocessingVars.steps;
            obj.stepSegmentation = preprocessingVars.stepSegmentation;
            obj.stepSlicetiming = preprocessingVars.stepSlicetiming;
            obj.stepUnwarping = preprocessingVars.stepUnwarping;
            obj.stepRealignment = preprocessingVars.stepRealignment;
            obj.stepCoregistration = preprocessingVars.stepCoregistration;
            obj.stepNormalization = preprocessingVars.stepNormalization;
            obj.stepSmoothing = preprocessingVars.stepSmoothing;
            obj.stepDeleteFiles = preprocessingVars.stepDeleteFiles;
            obj.preprocessingComponents = preprocessingVars.preprocessingComponents;
            obj.prefix = preprocessingVars.prefix;

            % fMRI parameters
            obj.subjects = preprocessingVars.subjects;
            obj.runSel = preprocessingVars.runSel;
            obj.nSlices = preprocessingVars.nSlices;
            obj.TR = preprocessingVars.TR;
            obj.sliceTiming = preprocessingVars.sliceTiming;

        end

        % preprocessing function
        % ----------------------
        function obj = preprocessSubj(obj, subID)
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

            % check if minimally-required preprocessing parameters are defined
            assert(~isnan(obj.nSlices) | ~isnan(obj.TR), 'Not all required preprocessing parameters are defined!');
            
            % select subject data
            subDir = fullfile(obj.dsRoot, subID);
            sesDir = dir(fullfile(subDir, 'ses*'));
            if ~isempty(sesDir)
                sesDir = {sesDir.name}';
            else
                sesDir = {''};
            end

            % check if preprocessing directory exists 
            % TODO: add option to re-create preprocessing directory from scratch
            if ~exist(fullfile(obj.preRoot,subID), 'dir')
                if isempty(sesDir{1})
                    % if no session indicator
                    mkdir(fullfile(obj.preRoot,subID,obj.anatLab)) % anat
                    mkdir(fullfile(obj.preRoot,subID,obj.funcLab)) % func
                    if ~isempty(obj.fmapLab)
                        mkdir(fullfile(obj.preRoot,subID,obj.fmapLab)) % fmap
                    end
                else
                    % if (multiple) session indicators
                    for ses = 1:numel(sesDir)
                        mkdir(fullfile(obj.preRoot,subID,sprintf('ses-%02d',ses),obj.anatLab)) % anat
                        mkdir(fullfile(obj.preRoot,subID,sprintf('ses-%02d',ses),obj.funcLab)) % func
                        if ~isempty(obj.fmapLab)
                            mkdir(fullfile(obj.preRoot,subID,sprintf('ses-%02d',ses),obj.fmapLab)) % fmap
                        end
                    end
                end
            end

            % loop over sessions (ses-01, ses-02, etc.)
            for ses = 1:numel(sesDir)

                %inform user
                fprintf('%s ses-%2.2d\n', subID, ses)
                
                % update source- and target directory for session-specific data
                obj.srcDir = fullfile(obj.dsRoot, subID, sesDir{ses});
                obj.tgtDir = fullfile(obj.preRoot, subID, sesDir{ses});

                % TODO: copy a working-version of BIDS data to preproc
                % folder and use this for the preproc steps 
                % (currently preprocessing is done inside the BIDS folder 
                % which is not ideal since e.g. realignment adjusts the 
                % header of the input niftis)

                % select preprocessing steps
                obj.steps = obj.steps(find(obj.preprocessingComponents == true));

                % inform user about steps
                fprintf('Performing the following steps:\n')
                for i = 1:numel(obj.steps)
                    fprintf('%i: %s\n', i, obj.steps{i})
                end

                % loop over preprocessing steps
                for st = 1:numel(obj.steps)

                    % inform user
                    fprintf('running step %i: %s\n', st, obj.steps{st})

                    switch obj.steps{st}

                        case 'segmentation'
                            obj.runSegmentation(subID);

                        case 'slicetiming'
                            obj.runSlicetiming(subID);
                            obj.currPrefix = obj.prefix.slicetiming;

                        case 'unwarping'
                            obj.runUnwarping(subID);
                            obj.currPrefix = obj.prefix.unwarping;

                        case 'realignment'
                            obj.runRealignment(subID, sesDir{ses});
                            obj.currPrefix = obj.prefix.realignment;

                        case 'coregistration'
                            obj.runCoregistration(subID);
                            obj.currPrefix = obj.prefix.coregistration;

                        case 'normalization'
                            obj.runNormalization(subID);
                            obj.currPrefix = obj.prefix.normalization;

                        case 'smoothing'
                            obj.runSmoothing(subID);
                            obj.currPrefix = obj.prefix.smoothing;

                    end %switch steps

                    % inform user
                    fprintf('completed step %i: %s\n', st, obj.steps{st})

                end %loop steps

                % delete intermediate files
                if obj.stepDeleteFiles
                    fprintf('deleting intermediate files...\n')
                    obj.deleteFiles(subID)
                end

                % inform user
                fprintf('completed preprocessing %s ses-%2.2d\n----------------------------------\n', subID, ses)

            end %loop session

        end

        % Preprocessing steps
        % -------------------
        % Separate functions for each step that gets called in
        % subject-level processing function:

        % runSegmentation (optional)
        function obj = runSegmentation(obj, subID)
            % RUNSEGMENTATION Function to perform segmentation and
            %   normalization of the anatomical image
            %
            %   Input
            %       subNr: subject ID
            %   Output
            %       none

            % do segmentation
            fprintf('<segmenting %s...>\n', subID) % placeholder code

        end

        % runSlicetiming (optional)
        function obj = runSlicetiming(obj, subID)
            % RUNSLICETIMING Function to perform slice-timing correction
            %   of the functional images
            %
            %   Input
            %       subNr: subject ID
            %   Output
            %       none

            %notes:
            % - STC for TR ~ 2 s is the sweet spot and recommended. 
            %   For TRs below 1 s, STC has not a big effect, 
            %   and for TRs above ~3 s STC is not great (requires a lot of interpolation). 
            % - STC for interleaved acquisition order is tricky because you have to do STC before realignment. 
            %   STC for sequential (e.g. descending) acquisition order can be
            %   done after realignment, unless you expect lots of motion
            % - Note that the onsets in 1st-level GLM should be adapted to
            %   reflect the new time-corrected TRs!
            %   See also the SPM website: https://www.fil.ion.ucl.ac.uk/spm/docs/tutorials/fmri/preprocessing/slice_timing/

            % do slice time correction
            fprintf('<slice-time correcting %s...>\n', subID) % placeholder code
            
            % some input checks
            assert(any(~isnan(prepVars.sliceTiming)),'stepSlicetiming: Slice timings are missing!');
            assert(prepVars.nSlices == numel(prepVars.sliceTiming), 'stepSlicetiming: Number of slices does not match number of slice timings!')

        end
        
        % runUnwarping (if no realignment)
        function obj = runUnwarping(obj, subID)
            % RUNUNWARPING Function to compute voxel-displacement map (VDM) 
            %   and unwarp + realign the EPIs (field-map correction)
            %
            %   Input
            %       subNr: subject ID
            %   Output
            %       none

            % do unwarping
            fprintf('<unwarping %s...>\n', subID) % placeholder code

        end
        
        
        % runRealignment (if no unwarping)
        function obj = runRealignment(obj, subID, sesDir)
            % RUNREALIGNMENT Function to perform realignment of the
            %   functional images
            %
            %   Input
            %       subID: BIDS-compliant subject ID (e.g., 'sub-001')
            %       sesDir: directory containing anat/func data of current
            %               session
            %   Output
            %       none

            % select data for all runs. Better to add separate runs as Sessions in the same module
            subIdx = contains(obj.subjects,subID); % index to select the correct number of runs for the subject
            subRuns = obj.runSel{subIdx}{1};       % the second index reflects the task number - currently only works for 1 task
            nRuns = numel(subRuns); 
            
            % get BIDS structure of data set
            BIDS = spm_BIDS(obj.dsRoot);

            % get EPIs
            allNiftis = cell(nRuns,1);
            for r = 1:nRuns
                if ~isempty(sesDir)
                    epi = spm_BIDS(BIDS,'data', ... %todo: add task label to query?
                        'sub',subID,'ses',sesDir,'run',[obj.BIDSlabel{3} num2str(r)],'type',obj.BIDSlabel{4});
                else
                    epi = spm_BIDS(BIDS,'data', ...
                        'sub',subID,'run',[obj.BIDSlabel{3} num2str(r)],'type',obj.BIDSlabel{4});
                end
                
                % (dynamically) change pre-fix in case another step was done first (e.g., to '^a' for STC)
                run_niftis = spm_select('ExtFPlist', spm_file(epi,'path'), spm_file(spm_file(epi,'filename'),'prefix',['^' obj.currPrefix]),Inf); 
                allNiftis{r,1}  =  cellstr(run_niftis);
            end

            % prepare spm batch
            matlabbatch = [];
            matlabbatch{1}.spm.spatial.realign.estwrite.data = allNiftis;
            matlabbatch{1}.spm.spatial.realign.estwrite.eoptions.quality = 0.9;
            matlabbatch{1}.spm.spatial.realign.estwrite.eoptions.sep = 4;
            matlabbatch{1}.spm.spatial.realign.estwrite.eoptions.fwhm = 5;
            matlabbatch{1}.spm.spatial.realign.estwrite.eoptions.rtm = 1;   % register to the mean realigned image
            matlabbatch{1}.spm.spatial.realign.estwrite.eoptions.interp = 2;
            matlabbatch{1}.spm.spatial.realign.estwrite.eoptions.wrap = [0 0 0];
            matlabbatch{1}.spm.spatial.realign.estwrite.eoptions.weight = '';
            matlabbatch{1}.spm.spatial.realign.estwrite.roptions.which = [2 1];
            matlabbatch{1}.spm.spatial.realign.estwrite.roptions.interp = 4;
            matlabbatch{1}.spm.spatial.realign.estwrite.roptions.wrap = [0 0 0];
            matlabbatch{1}.spm.spatial.realign.estwrite.roptions.mask = 1;
            matlabbatch{1}.spm.spatial.realign.estwrite.roptions.prefix = obj.prefix.realignment;

            % run job
            spm('defaults','FMRI');
            spm_jobman('initcfg');
            spm_jobman('run', matlabbatch);

        end

        % runCoregistration
        function obj = runCoregistration(obj, subID)
            % RUNCOREGISTRATION Function to perform coregistration of
            %   functional images to the anatomical image
            %
            %   Input
            %       subNr: subject ID
            %   Output
            %       none

            %note:
            % The Büchel lab performs non-linear coreg using Dartel 
            % instead of field maps. In that case, you need to perform
            % segmentation of the anatomical image (runSegmentation).

            % do coregistration
            fprintf('<coregistering %s...>\n', subID) % placeholder code

        end

        % runNormalization (optional?)
        function obj = runNormalization(obj, subID)
            % RUNNORMALIZATION Function to perform spatial normalization of
            %   functional images (optional; use normalization parameters
            %   obtained from the segmentation step)
            %
            %   Input
            %       subNr: subject ID
            %   Output
            %       none

            % do normalization
            fprintf('<normalizing %s...>\n', subID) % placeholder code

        end

        % runSmoothing (optional)
        function obj = runSmoothing(obj, subID)
            % RUNSMOOTHING Function to perform spatial smoothing of
            %   functional images
            %
            %   Input
            %       subNr: subject ID
            %   Output
            %       none

            % do smoothing
            fprintf('<smoothing %s...>\n', subID) % placeholder code

        end

        % Other functions
        % ---------------

        % preprocessLoop
        function preprocessLoop(obj)
            % PREPROCESSLOOP Function that you call in config file that applies
            %   the preprocessing pipeline to each subject
            %
            %   Input
            %       subs: vector containing subject IDs
            %
            %   Output
            %       none

            % inform user
            fprintf('Preprocessing subjects:')
            for s = 1:numel(obj.subjects)
                if s < numel(obj.subjects)
                    fprintf(' %s,', obj.subjects{s})
                else
                    fprintf(' %s\n----------------------------------------\n', obj.subjects{s})
                end
            end

            % loop over subjects
            for s = 1:numel(obj.subjects)
                obj.preprocessSubj(obj.subjects{s});
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