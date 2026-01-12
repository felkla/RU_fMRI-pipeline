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
        overwriteFiles % overwrite existing preprocessed files?
        deleteFiles    % delete intermediate preproc files?

        % preprocessing steps
        steps % list of preprocessing steps
        stepSegmentation % segmentation/Normalization of T1 images
        stepSlicetiming % slicetiming correction
        stepUnwarping % unwarping (fmap correction)
        stepRealignment % realignment
        stepCoregistration % coregistration of mean EPI to T1
        stepNormalization % application of normalization parameters to EPI data
        stepSmoothing % smoothing
        preprocessingComponents % list of preprocessing steps to perform
        prefix % prefix for each preprocessing step
        currPrefix % variable to dynamically update prefix

        % fMRI parameters
        subjects % selected subjects (IDs)
        runSel % fMRI run numbers
        nSlices % number of slices for each volume
        TR % TR of the sequence
        refSlice % reference slice (for slice-timing correction)
        sliceTiming % timing of acquisition of each slice relative to beginning of each volume (in s)
        epiReadoutTime % total EPI readout time (for unwarping)

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
            obj.overwriteFiles = preprocessingVars.overwriteFiles;
            obj.deleteFiles = preprocessingVars.deleteFiles;

            % preprocessing steps
            obj.steps = preprocessingVars.steps;
            obj.stepSegmentation = preprocessingVars.stepSegmentation;
            obj.stepSlicetiming = preprocessingVars.stepSlicetiming;
            obj.stepUnwarping = preprocessingVars.stepUnwarping;
            obj.stepRealignment = preprocessingVars.stepRealignment;
            obj.stepCoregistration = preprocessingVars.stepCoregistration;
            obj.stepNormalization = preprocessingVars.stepNormalization;
            obj.stepSmoothing = preprocessingVars.stepSmoothing;
            obj.preprocessingComponents = preprocessingVars.preprocessingComponents;
            obj.prefix = preprocessingVars.prefix;
            obj.currPrefix = preprocessingVars.currPrefix;

            % fMRI parameters
            obj.subjects = preprocessingVars.subjects;
            obj.runSel = preprocessingVars.runSel;
            obj.nSlices = preprocessingVars.nSlices;
            obj.TR = preprocessingVars.TR;
            obj.refSlice = preprocessingVars.refSlice;
            obj.sliceTiming = preprocessingVars.sliceTiming;
            obj.epiReadoutTime = preprocessingVars.epiReadoutTime;

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
            
            % select subject data
            subDir = fullfile(obj.dsRoot, subID);
            sesDir = dir(fullfile(subDir, 'ses*'));
            if ~isempty(sesDir)
                sesDir = {sesDir.name}';
            else
                sesDir = {''};
            end

            % create preprocessing root directory
            if ~exist(fullfile(obj.preRoot),'dir')
                mkdir(fullfile(obj.preRoot))
            end

            % copy BIDS files to preproc dir 
            % [dataset_description.json & participants.tsv]
            copyfile(fullfile(obj.dsRoot, 'dataset_description.json'), fullfile(obj.preRoot, 'dataset_description.json'))
            copyfile(fullfile(obj.dsRoot, 'participants.tsv'), fullfile(obj.preRoot, 'participants.tsv'))
            
            % create/overwrite subject-specific directory
            if ~exist(fullfile(obj.preRoot,subID), 'dir')
                mkdir(fullfile(obj.preRoot,subID));
            elseif obj.overwriteFiles
                rmdir(fullfile(obj.preRoot,subID), 's');
                mkdir(fullfile(obj.preRoot,subID));
            end

            % loop over sessions (ses-01, ses-02, etc.)
            for ses = 1:numel(sesDir)

                %inform user
                fprintf('%s ses-%2.2d\n', subID, ses)
                
                % update source- and target directory for session-specific data
                obj.srcDir = fullfile(obj.dsRoot, subID, sesDir{ses});
                obj.tgtDir = fullfile(obj.preRoot, subID, sesDir{ses});

                % copy source BIDS data to preproc folder
                if ~exist(fullfile(obj.tgtDir,obj.funcLab),'dir') || (exist(fullfile(obj.tgtDir,obj.funcLab),'dir') && obj.overwriteFiles)
                    copyfile(obj.srcDir, obj.tgtDir);
                end

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
                            obj.runSlicetiming(subID, sesDir{ses});
                            obj.currPrefix = obj.prefix.slicetiming;

                        case 'unwarping'
                            obj.runUnwarping(subID);
                            obj.currPrefix = obj.prefix.unwarping;

                        case 'realignment'
                            obj.runRealignment(subID, sesDir{ses});
                            obj.currPrefix = obj.prefix.realignment;

                        case 'coregistration'
                            obj.runCoregistration(subID, sesDir{ses});

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
                if obj.deleteFiles
                    fprintf('deleting intermediate files...\n')
                    obj.runDeleteFiles(subID)
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
        function obj = runSlicetiming(obj, subID, sesDir)
            % RUNSLICETIMING Function to perform slice-timing correction
            %   of the functional images
            %
            %   Input
            %       subNr: subject ID
            %       sesDir: directory containing anat/func data of current
            %               session
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
            
            % some input checks
            assert(~isnan(obj.TR),'stepSlicetiming: TR is missing!');
            assert(~isnan(obj.nSlices),'stepSlicetiming: Number of slices is missing!');
            assert(any(~isnan(obj.sliceTiming)),'stepSlicetiming: Slice timings are missing!');
            assert(~isnan(obj.refSlice), 'stepSlicetiming: Reference slice is missing!');
            assert(obj.nSlices == numel(obj.sliceTiming), 'stepSlicetiming: Number of slice timings does not match number of slices!')

            % loop over runs
            subIdx = contains(obj.subjects,subID); % index to select the correct number of runs for the subject
            subRuns = obj.runSel{subIdx}{1};       % the second index reflects the task number - currently only works for 1 task
            nRuns = numel(subRuns);

            % get BIDS structure of data set
            BIDS = spm_BIDS(obj.preRoot);
            
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

                % (dynamically) change pre-fix in case another step was done first (e.g., to '^r' for realignment)
                if isempty(obj.currPrefix)
                    run_niftis = spm_select('ExtFPlist', spm_file(epi,'path'), spm_file(spm_file(epi,'filename'),'prefix',['^' obj.currPrefix]),Inf);
                else
                    run_niftis = spm_select('ExtFPlist', spm_file(epi,'path'), spm_file(spm_file(epi,'filename'),'prefix',['^' obj.currPrefix '.*']),Inf);
                end
                allNiftis{r,1}  =  cellstr(run_niftis);

            end

            % prepare spm batch
            matlabbatch = [];
            matlabbatch{1}.spm.temporal.st.scans = allNiftis;
            matlabbatch{1}.spm.temporal.st.nslices = obj.nSlices;
            matlabbatch{1}.spm.temporal.st.tr = obj.TR;
            matlabbatch{1}.spm.temporal.st.ta = 0;
            matlabbatch{1}.spm.temporal.st.so = obj.sliceTiming;
            matlabbatch{1}.spm.temporal.st.refslice = obj.refSlice;
            matlabbatch{1}.spm.temporal.st.prefix = obj.prefix.slicetiming;
            
            % run job
            spm('defaults','FMRI');
            spm_jobman('initcfg');
            spm_jobman('run', matlabbatch);

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

            % input checks
            assert(obj.stepRealignment == false);
            assert(~isnan(obj.epiReadoutTime), 'stepUnwarping: Total EPI read-out time is missing!');

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

            % input checks
            assert(obj.stepUnwarping == false);

            % select data for all runs. Better to add separate runs as Sessions in the same module
            subIdx = contains(obj.subjects,subID); % index to select the correct number of runs for the subject
            subRuns = obj.runSel{subIdx}{1};       % the second index reflects the task number - currently only works for 1 task
            nRuns = numel(subRuns); 
            
            % get BIDS structure of data set
            BIDS = spm_BIDS(obj.preRoot);

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
                if isempty(obj.currPrefix)
                    run_niftis = spm_select('ExtFPlist', spm_file(epi,'path'), spm_file(spm_file(epi,'filename'),'prefix',['^' obj.currPrefix]),Inf);
                else
                    run_niftis = spm_select('ExtFPlist', spm_file(epi,'path'), spm_file(spm_file(epi,'filename'),'prefix',['^' obj.currPrefix '.*']),Inf);
                end
                allNiftis{r,1}  =  cellstr(run_niftis);
            end

            % prepare spm batch - currently SPM12 defaults
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
        function obj = runCoregistration(obj, subID, sesDir)
            % RUNCOREGISTRATION Function to perform coregistration 
            %   (estimate, no reslicing) of functional images to the 
            %   anatomical image.
            %
            %   Input
            %       subNr: subject ID
            %       sesDir: directory containing anat/func data of current
            %               session
            %   Output
            %       none
            %
            % notes:
            %   Currently performs linear coregistration on the realigned
            %   images. todo: make compatible with unwarped (fm-corrected)
            %   images.
            % 
            %   The Büchel lab performs non-linear coreg instead of 
            %   field-map correction. In that case, you need to perform
            %   segmentation of the anatomical image (runSegmentation).

            % loop over runs
            subIdx = contains(obj.subjects,subID); % index to select the correct number of runs for the subject
            subRuns = obj.runSel{subIdx}{1};       % the second index reflects the task number - currently only works for 1 task
            nRuns = numel(subRuns);

            % get BIDS structure of data set
            BIDS = spm_BIDS(obj.preRoot);

            % get reference image (anatomical T1)
            anat_image = spm_BIDS(BIDS,'data',...
                'sub',subID,'type','T1w');
            ref = anat_image(1); %in case there are more sessions with T1w

            % get source image (mean realigned image)
            epi = spm_BIDS(BIDS,'data',...
                'sub',subID,'type',obj.BIDSlabel{4});
            source = spm_file(epi,'prefix','meana'); % we need the slice-time (and field-map?) corrected mean image: (u)meanasub.nii
            source = source(1); % in case of multiple runs
            sourceDir = spm_file(source,'path');
            assert(~isempty(source), 'stepCoregistration: Could not find mean image. Please run realignment/unwarping first.')

            % get other images (EPIs)
            all_niftis = [];
            for r = 1:nRuns
                if ~isempty(sesDir)
                    epi = spm_BIDS(BIDS,'data', ... %todo: add task label to query?
                        'sub',subID,'ses',sesDir,'run',[obj.BIDSlabel{3} num2str(r)],'type',obj.BIDSlabel{4});
                else
                    epi = spm_BIDS(BIDS,'data', ...
                        'sub',subID,'run',[obj.BIDSlabel{3} num2str(r)],'type',obj.BIDSlabel{4});
                end

                % (dynamically) change pre-fix in case another step was done first (e.g., to '^r' for realignment)
                if isempty(obj.currPrefix)
                    run_niftis = spm_select('ExtFPlist', spm_file(epi,'path'), spm_file(spm_file(epi,'filename'),'prefix',['^' obj.currPrefix]),Inf);
                else
                    run_niftis = spm_select('ExtFPlist', spm_file(epi,'path'), spm_file(spm_file(epi,'filename'),'prefix',['^' obj.currPrefix '.*']),Inf);
                end
                all_niftis = char(all_niftis, run_niftis);
                % all_niftis = strvcat(all_niftis, run_niftis);
                other = cellstr(all_niftis(2:end,:));

            end

            % prepare spm batch - coregistration
            matlabbatch{1}.spm.spatial.coreg.estimate.ref = ref;
            matlabbatch{1}.spm.spatial.coreg.estimate.source = source;
            matlabbatch{1}.spm.spatial.coreg.estimate.other = other;
            matlabbatch{1}.spm.spatial.coreg.estimate.eoptions.cost_fun = 'nmi';
            matlabbatch{1}.spm.spatial.coreg.estimate.eoptions.sep = [4 2];
            matlabbatch{1}.spm.spatial.coreg.estimate.eoptions.tol = [0.02 0.02 0.02 0.001 0.001 0.001 0.01 0.01 0.01 0.001 0.001 0.001];
            matlabbatch{1}.spm.spatial.coreg.estimate.eoptions.fwhm = [7 7];

            % prepare spm batch - new co-registered mean image
            matlabbatch{2}.cfg_basicio.file_dir.file_ops.file_move.files = source; % rename (u)meana file to cmeana now that it is coregistered
            matlabbatch{2}.cfg_basicio.file_dir.file_ops.file_move.action.moveren.moveto = sourceDir; % same dir
            matlabbatch{2}.cfg_basicio.file_dir.file_ops.file_move.action.moveren.patrep(1).pattern = 'meana';
            matlabbatch{2}.cfg_basicio.file_dir.file_ops.file_move.action.moveren.patrep(1).repl = 'cmeana';
            matlabbatch{2}.cfg_basicio.file_dir.file_ops.file_move.action.moveren.unique = false;

            % run job
            spm('defaults','FMRI');
            spm_jobman('initcfg');
            spm_jobman('run', matlabbatch);

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
        function runDeleteFiles(obj, subNr)
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