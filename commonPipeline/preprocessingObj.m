classdef preprocessingObj
    %PREPROCESSINGOBJ   This class implements the preprocessing steps of
    % the RU pipeline

    properties

        % paths and directories
        spmPath % SPM path
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
        runParallel    % perform preprocessing in parallel?
        maxCores       % max number of ocres to use for parallel processing

        % preprocessing steps
        steps % list of preprocessing steps
        stepSlicetiming % slicetiming correction
        stepUnwarping % unwarping (fmap correction)
        stepRealignment % realignment
        stepCoregistration % coregistration of mean EPI to T1
        stepSegmentation % segmentation of T1 images
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
        echoTime1 % fieldmap short echo time in ms (for unwarping)
        echoTime2 % fieldmap long echo time in ms (for unwarping)
        voxelSize % [x,y,z] EPI voxel size in mm (for normalization)
        smoothingKernel % [x,y,z] FWHM smoothing kernel in mm

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
            obj.runParallel = preprocessingVars.runParallel;
            obj.maxCores = preprocessingVars.maxCores;

            % preprocessing steps
            obj.steps = preprocessingVars.steps;
            obj.stepSlicetiming = preprocessingVars.stepSlicetiming;
            obj.stepUnwarping = preprocessingVars.stepUnwarping;
            obj.stepRealignment = preprocessingVars.stepRealignment;
            obj.stepCoregistration = preprocessingVars.stepCoregistration;
            obj.stepSegmentation = preprocessingVars.stepSegmentation;
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
            obj.echoTime1 = preprocessingVars.echoTime1;
            obj.echoTime2 = preprocessingVars.echoTime2;
            obj.voxelSize = preprocessingVars.voxelSize;
            obj.smoothingKernel = preprocessingVars.smoothingKernel;

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
            % [dataset_description.json & participants.tsv & task.json]
            copyfile(fullfile(obj.dsRoot, 'dataset_description.json'), fullfile(obj.preRoot, 'dataset_description.json'))
            copyfile(fullfile(obj.dsRoot, 'participants.tsv'), fullfile(obj.preRoot, 'participants.tsv'))
            copyfile(fullfile(obj.dsRoot, [obj.BIDSlabel{1}{1} '_' obj.BIDSlabel{4} '.json']), ...
                fullfile(obj.preRoot, [obj.BIDSlabel{1}{1} '_' obj.BIDSlabel{4} '.json']))
            
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

                        case 'slicetiming'
                            obj.runSlicetiming(subID, sesDir{ses});
                            obj.currPrefix = obj.prefix.slicetiming;

                        case 'unwarping'
                            obj.runUnwarping(subID, sesDir{ses});
                            obj.currPrefix = obj.prefix.unwarping;

                        case 'realignment'
                            obj.runRealignment(subID, sesDir{ses});
                            obj.currPrefix = obj.prefix.realignment;

                        case 'coregistration'
                            obj.runCoregistration(subID, sesDir{ses});
                            % no prefix; todo - unless also reslicing.

                        case 'segmentation'
                            obj.runSegmentation(subID);
                            % no prefix necessary

                        case 'normalization'
                            obj.runNormalization(subID, sesDir{ses});
                            obj.currPrefix = obj.prefix.normalization;

                        case 'smoothing'
                            obj.runSmoothing(subID, sesDir{ses});
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
            %   reflect the time-corrected TRs!
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
            allNiftis = cell(nRuns,1); % we add separate runs as Sessions in the same module
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
                    runNiftis = spm_select('ExtFPlist', spm_file(epi,'path'), spm_file(spm_file(epi,'filename'),'prefix',['^' obj.currPrefix]),Inf);
                else
                    runNiftis = spm_select('ExtFPlist', spm_file(epi,'path'), spm_file(spm_file(epi,'filename'),'prefix',['^' obj.currPrefix '.*']),Inf);
                end
                allNiftis{r,1}  =  cellstr(runNiftis);

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

        % runUnwarping
        function obj = runUnwarping(obj, subID, sesDir)
            % RUNUNWARPING Function to compute voxel displacement maps (VDM)
            %   and unwarp + realign the EPIs (field-map correction)
            %
            %   Input
            %       subID: BIDS-compliant subject ID (e.g., 'sub-001')
            %       sesDir: directory containing anat/fmap/func data of
            %               current session
            %   Output
            %       none

            % input checks
            assert(obj.stepRealignment == false, 'stepUnwarping: stepRealignment must be set to false!');

            % select data for all runs
            subIdx = contains(obj.subjects,subID); % index to select the correct number of runs for the subject
            subRuns = obj.runSel{subIdx}{1};       % the second index reflects the task number - currently only works for 1 task
            nRuns = numel(subRuns); 
            
            % get BIDS structure of data set
            BIDS = spm_BIDS(obj.preRoot);

            % Step 1: calculate voxel displacement maps (VDMs)
            % -----------------------------------------------
            % This step uses functionalities from the FieldMap toolbox to
            % compute voxel displacement maps (VDMs) for each run
            % ('session'). To do this, we need the phasediff and magnitude
            % images produced from the acquired field map.

            % check for FieldMap toolbox and get T1 image
            TBs = spm('TBs');
            TBnames = cellstr(char(TBs.name));
            if any(contains(TBnames,'FieldMap'))
                FMdir = TBs(contains(TBnames,'FieldMap')).dir;
                FMtempl = fullfile(FMdir,'T1.nii');
            else
                error('FieldMap toolbox missing. Please install the toolbox')
            end

            % get phasediff image
            pd = spm_BIDS(BIDS,'data','sub',subID,'ses',sesDir,'type','phasediff');
            pdIma = pd(1); % in case there are multiple pd images, take the first one.

            % get magnitude image
            magnIma = strrep(pdIma,'phasediff','magnitude1'); % hack because spm_BIDS can't find the magnitude images

            % get short and long echo times
            if isnan(obj.echoTime1) || isnan(obj.echoTime2)
                % get short and long TE from the phasediff json files
                meta_pd = spm_BIDS(BIDS,'metadata',...
                    'sub',subID,'ses',sesDir,'type','phasediff');

                if numel(meta_pd) > 1 % if there are multiple field maps, take the metadata of the first one (for now)
                    meta_pd = meta_pd{1};
                end

                obj.echoTime1 = round(meta_pd.EchoTime1*1000, 2); % convert to ms
                obj.echoTime2 = round(meta_pd.EchoTime2*1000, 2); % convert to ms
            end

            assert(obj.echoTime2 > obj.echoTime1, 'stepUnwarping: longTE (echoTime2) should be larger than shortTE (echoTime1)!')

            % get total EPI readout time
            if isnan(obj.epiReadoutTime)
                % get total EPI readout time from the dataset json file
                meta_bold = spm_BIDS(BIDS,'metadata','sub',subID,'ses',sesDir,'run','run-01','type','bold'); % assume constant across runs
                obj.epiReadoutTime = round(meta_bold.TotalReadoutTime.*1000, 2); % convert to ms
            end

            % perform unit checks
            assert(obj.echoTime1 > 1 & obj.echoTime1 < 100, 'stepUnwarping: shortTE (echoTime1) should be defined in seconds!')
            assert(obj.echoTime2 > 1 & obj.echoTime2 < 100, 'stepUnwarping: longTE (echoTime2) should be defined in seconds!')
            assert(obj.epiReadoutTime > 1 & obj.epiReadoutTime < 1000, 'stepUnwarping: Total EPI read-out time should be defined in seconds!')

            % get first EPI per run (VDMs will be coregistered to these)
            allNiftis = cell(nRuns,1); % we add separate runs as Sessions in the same module
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
                    runNiftis = spm_select('ExtFPlist', spm_file(epi,'path'), spm_file(spm_file(epi,'filename'),'prefix',['^' obj.currPrefix]),1); % index the 1st EPI
                else
                    runNiftis = spm_select('ExtFPlist', spm_file(epi,'path'), spm_file(spm_file(epi,'filename'),'prefix',['^' obj.currPrefix '.*']),1); % index the 1st EPI
                end
                allNiftis{r,1} = cellstr(runNiftis);
            end

            % prepare SPM batch
            matlabbatch = [];
            matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.data.presubphasemag.phase = pdIma;
            matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.data.presubphasemag.magnitude = magnIma;
            matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.defaults.defaultsval.et = [obj.echoTime1 obj.echoTime2];
            matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.defaults.defaultsval.maskbrain = 1;
            matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.defaults.defaultsval.blipdir = -1;
            matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.defaults.defaultsval.tert = obj.epiReadoutTime;
            matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.defaults.defaultsval.epifm = 0;
            matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.defaults.defaultsval.ajm = 0;
            matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.defaults.defaultsval.uflags.method = 'Mark3D';
            matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.defaults.defaultsval.uflags.fwhm = 10;
            matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.defaults.defaultsval.uflags.pad = 0;
            matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.defaults.defaultsval.uflags.ws = 1;
            matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.defaults.defaultsval.mflags.template = {FMtempl};
            matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.defaults.defaultsval.mflags.fwhm = 5;
            matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.defaults.defaultsval.mflags.nerode = 2;
            matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.defaults.defaultsval.mflags.ndilate = 4;
            matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.defaults.defaultsval.mflags.thresh = 0.5;
            matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.defaults.defaultsval.mflags.reg = 0.02;
            for r = 1:nRuns
                matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.session(r).epi = allNiftis{r}; % first EPI of each run
            end
            matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.matchvdm = 1; % VDMs will be coregistered to the first EPI of each run
            matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.sessname = 'run';
            matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.writeunwarped = 0;
            matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.anat = {''};
            matlabbatch{1}.spm.tools.fieldmap.calculatevdm.subj.matchanat = 0;

            % run job
            spm('defaults','FMRI');
            spm_jobman('initcfg');
            spm_jobman('run', matlabbatch);
            
            % Step 2: move and rename VDM files
            % ---------------------------------
            % This step moves the VDM files from the fmap to the func
            % folder and renames them to clean up a bit.
            % We have vdm5_scsub-001_ses-01_run-01_phasediff_run1.nii, ..run2.nii, etc in fmap
            % and want: vdm5_asub-001_task-<task>_ses-01_run-01_bold.nii in func
            %           vdm5_asub-001_task-<task>_ses-01_run-02_bold.nii in func

            % get source and target location for VDM files
            VDMdir = spm_file(pdIma,'path');
            EPIdir = spm_file(allNiftis{1},'path');

            % prepare SPM batch
            matlabbatch = cell(1,nRuns);
            for r = 1:nRuns
                matlabbatch{r}.cfg_basicio.file_dir.file_ops.file_move.files = fullfile(VDMdir,sprintf('vdm5_sc%s_%s_run-01_phasediff_run%d.nii',subID,sesDir,r)); % move and rename vdms
                matlabbatch{r}.cfg_basicio.file_dir.file_ops.file_move.action.moveren.moveto = EPIdir;
                matlabbatch{r}.cfg_basicio.file_dir.file_ops.file_move.action.moveren.patrep(1).pattern = 'vdm5_sc';
                matlabbatch{r}.cfg_basicio.file_dir.file_ops.file_move.action.moveren.patrep(1).repl = 'vdm5_a';
                matlabbatch{r}.cfg_basicio.file_dir.file_ops.file_move.action.moveren.patrep(2).pattern = sprintf('_run-01_phasediff_run%d',r);
                matlabbatch{r}.cfg_basicio.file_dir.file_ops.file_move.action.moveren.patrep(2).repl = sprintf('_%s_%s%i_%s',obj.BIDSlabel{1}{1},obj.BIDSlabel{3},r, obj.BIDSlabel{4});
                matlabbatch{r}.cfg_basicio.file_dir.file_ops.file_move.action.moveren.unique = false;
            end

            % run job
            spm('defaults','FMRI');
            spm_jobman('initcfg');
            spm_jobman('run', matlabbatch);

            % Step 3: perform realignment and unwarping
            % -----------------------------------------
            % This step performs realignment of the EPIs, unwarps
            % them using the VDMs, and creates a mean image of the 
            % realigned and unwarped EPIs (which is used for 
            % coregistration).

            % get EPIs and VDMs
            allNiftis = cell(nRuns,1); % we add separate runs as Sessions in the same module
            allVDMs = cell(nRuns,1);
            for r = 1:nRuns
                % select the right session/run
                if ~isempty(sesDir)
                    epi = spm_BIDS(BIDS,'data', ... %todo: add task label to query?
                        'sub',subID,'ses',sesDir,'run',[obj.BIDSlabel{3} num2str(r)],'type',obj.BIDSlabel{4});
                else
                    epi = spm_BIDS(BIDS,'data', ...
                        'sub',subID,'run',[obj.BIDSlabel{3} num2str(r)],'type',obj.BIDSlabel{4});
                end
                
                % get the EPIs
                if isempty(obj.currPrefix)
                    runNiftis = spm_select('ExtFPlist', spm_file(epi,'path'), spm_file(spm_file(epi,'filename'),'prefix',['^' obj.currPrefix]),Inf);
                else
                    runNiftis = spm_select('ExtFPlist', spm_file(epi,'path'), spm_file(spm_file(epi,'filename'),'prefix',['^' obj.currPrefix '.*']),Inf);
                end
                allNiftis{r,1}  =  cellstr(runNiftis);

                % get the VDMs
                allVDMs{r,1} = cellstr(spm_file(epi,'prefix','vdm5_a'));

            end
            
            % prepare SPM batch
            matlabbatch = [];
            for r = 1:nRuns
                matlabbatch{1}.spm.spatial.realignunwarp.data(r).scans = allNiftis{r}; % all EPIs per run
                matlabbatch{1}.spm.spatial.realignunwarp.data(r).pmscan = allVDMs{r}; % VDMs per run
            end

            matlabbatch{1}.spm.spatial.realignunwarp.eoptions.quality = 0.9;
            matlabbatch{1}.spm.spatial.realignunwarp.eoptions.sep = 4;
            matlabbatch{1}.spm.spatial.realignunwarp.eoptions.fwhm = 5;
            matlabbatch{1}.spm.spatial.realignunwarp.eoptions.rtm = 1; % register to the mean image for better performance. Set to 0 to save time
            matlabbatch{1}.spm.spatial.realignunwarp.eoptions.einterp = 2;
            matlabbatch{1}.spm.spatial.realignunwarp.eoptions.ewrap = [0 0 0];
            matlabbatch{1}.spm.spatial.realignunwarp.eoptions.weight = '';
            matlabbatch{1}.spm.spatial.realignunwarp.uweoptions.basfcn = [12 12];
            matlabbatch{1}.spm.spatial.realignunwarp.uweoptions.regorder = 1;
            matlabbatch{1}.spm.spatial.realignunwarp.uweoptions.lambda = 100000;
            matlabbatch{1}.spm.spatial.realignunwarp.uweoptions.jm = 0;
            matlabbatch{1}.spm.spatial.realignunwarp.uweoptions.fot = [4 5];
            matlabbatch{1}.spm.spatial.realignunwarp.uweoptions.sot = [];
            matlabbatch{1}.spm.spatial.realignunwarp.uweoptions.uwfwhm = 4;
            matlabbatch{1}.spm.spatial.realignunwarp.uweoptions.rem = 1;
            matlabbatch{1}.spm.spatial.realignunwarp.uweoptions.noi = 5;
            matlabbatch{1}.spm.spatial.realignunwarp.uweoptions.expround = 'Average';
            matlabbatch{1}.spm.spatial.realignunwarp.uwroptions.uwwhich = [2 1];
            matlabbatch{1}.spm.spatial.realignunwarp.uwroptions.rinterp = 7; % higher than default (= 4) to increase performance. Set to 4 to save time
            matlabbatch{1}.spm.spatial.realignunwarp.uwroptions.wrap = [0 0 0];
            matlabbatch{1}.spm.spatial.realignunwarp.uwroptions.mask = 1;
            matlabbatch{1}.spm.spatial.realignunwarp.uwroptions.prefix = 'u';

            % run job
            spm('defaults','FMRI');
            spm_jobman('initcfg');
            spm_jobman('run', matlabbatch);

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

            % select data for all runs
            subIdx = contains(obj.subjects,subID); % index to select the correct number of runs for the subject
            subRuns = obj.runSel{subIdx}{1};       % the second index reflects the task number - currently only works for 1 task
            nRuns = numel(subRuns); 
            
            % get BIDS structure of data set
            BIDS = spm_BIDS(obj.preRoot);

            % get EPIs
            allNiftis = cell(nRuns,1); % we add separate runs as Sessions in the same module
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
                    runNiftis = spm_select('ExtFPlist', spm_file(epi,'path'), spm_file(spm_file(epi,'filename'),'prefix',['^' obj.currPrefix]),Inf);
                else
                    runNiftis = spm_select('ExtFPlist', spm_file(epi,'path'), spm_file(spm_file(epi,'filename'),'prefix',['^' obj.currPrefix '.*']),Inf);
                end
                allNiftis{r,1}  =  cellstr(runNiftis);
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
            %   images.
            %   Some people in the Büchel lab perform non-linear coreg 
            %   instead of field-map correction.

            % get BIDS structure of data set
            BIDS = spm_BIDS(obj.preRoot);

            % get reference image - anatomical T1
            anat = spm_BIDS(BIDS,'data',...
                'sub',subID,'type','T1w');
            refIma = anat(1); %in case there are more sessions with T1w

            % get source image - mean image of slice-time corrected and realigned (& unwarped) EPIs
            epi = spm_BIDS(BIDS,'data',...  
                'sub',subID,'type',obj.BIDSlabel{4});
            meanIma = cellstr(spm_select('ExtFPlist', spm_file(epi,'path'), spm_file(spm_file(epi,'filename'),'prefix','^mean.*')));
            sourceIma = meanIma(1); % in case of multiple runs
            assert(~isempty(sourceIma{1}), 'stepCoregistration: Could not find mean realigned (and unwarped) image. Please run realignment first.')
            sourceDir = spm_file(sourceIma,'path');

            % get other images (i.e., all EPIs across runs)
            subIdx = contains(obj.subjects,subID); % index to select the correct number of runs for the subject
            subRuns = obj.runSel{subIdx}{1};       % the second index reflects the task number - currently only works for 1 task
            nRuns = numel(subRuns);

            allNiftis = [];
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
                    runNiftis = spm_select('ExtFPlist', spm_file(epi,'path'), spm_file(spm_file(epi,'filename'),'prefix',['^' obj.currPrefix]),Inf);
                else
                    runNiftis = spm_select('ExtFPlist', spm_file(epi,'path'), spm_file(spm_file(epi,'filename'),'prefix',['^' obj.currPrefix '.*']),Inf);
                end
                allNiftis = char(allNiftis, runNiftis);

            end
            
            allNiftis = cellstr(allNiftis(2:end,:));

            % prepare spm batch - coregistration
            matlabbatch{1}.spm.spatial.coreg.estimate.ref = refIma;
            matlabbatch{1}.spm.spatial.coreg.estimate.source = sourceIma;
            matlabbatch{1}.spm.spatial.coreg.estimate.other = allNiftis;
            matlabbatch{1}.spm.spatial.coreg.estimate.eoptions.cost_fun = 'nmi';
            matlabbatch{1}.spm.spatial.coreg.estimate.eoptions.sep = [4 2];
            matlabbatch{1}.spm.spatial.coreg.estimate.eoptions.tol = [0.02 0.02 0.02 0.001 0.001 0.001 0.01 0.01 0.01 0.001 0.001 0.001];
            matlabbatch{1}.spm.spatial.coreg.estimate.eoptions.fwhm = [7 7];

            % prepare spm batch - new co-registered mean image
            matlabbatch{2}.cfg_basicio.file_dir.file_ops.file_move.files = sourceIma; % rename mean(ua) file to cmean(ua) now that it is coregistered
            matlabbatch{2}.cfg_basicio.file_dir.file_ops.file_move.action.moveren.moveto = sourceDir; % same dir
            matlabbatch{2}.cfg_basicio.file_dir.file_ops.file_move.action.moveren.patrep(1).pattern = 'mean';
            matlabbatch{2}.cfg_basicio.file_dir.file_ops.file_move.action.moveren.patrep(1).repl = [obj.prefix.coregistration, 'mean'];
            matlabbatch{2}.cfg_basicio.file_dir.file_ops.file_move.action.moveren.unique = false;

            % run job
            spm('defaults','FMRI');
            spm_jobman('initcfg');
            spm_jobman('run', matlabbatch);

        end
        
        % runSegmentation (optional)
        function obj = runSegmentation(obj, subID)
            % RUNSEGMENTATION Function to perform segmentation of 
            %   the anatomical image
            %
            %   Input
            %       subNr: subject ID
            %   Output
            %       none

            % get BIDS structure of data set
            BIDS = spm_BIDS(obj.preRoot);

            % get anatomical image (T1)
            anat = spm_BIDS(BIDS,'data',...
                'sub',subID,'type','T1w');
            anatIma = anat(1); %in case there are more sessions with T1w

            % prepare spm batch
            matlabbatch{1}.spm.spatial.preproc.channel.vols = anatIma;
            matlabbatch{1}.spm.spatial.preproc.channel.biasreg = 0.001;
            matlabbatch{1}.spm.spatial.preproc.channel.biasfwhm = 60;
            matlabbatch{1}.spm.spatial.preproc.channel.write = [0 1];
            matlabbatch{1}.spm.spatial.preproc.tissue(1).tpm = {fullfile(obj.spmPath, 'tpm', 'TPM.nii,1')};
            matlabbatch{1}.spm.spatial.preproc.tissue(1).ngaus = 1;
            matlabbatch{1}.spm.spatial.preproc.tissue(1).native = [1 0];
            matlabbatch{1}.spm.spatial.preproc.tissue(1).warped = [0 0];
            matlabbatch{1}.spm.spatial.preproc.tissue(2).tpm = {fullfile(obj.spmPath, 'tpm', 'TPM.nii,2')};
            matlabbatch{1}.spm.spatial.preproc.tissue(2).ngaus = 1;
            matlabbatch{1}.spm.spatial.preproc.tissue(2).native = [1 0];
            matlabbatch{1}.spm.spatial.preproc.tissue(2).warped = [0 0];
            matlabbatch{1}.spm.spatial.preproc.tissue(3).tpm = {fullfile(obj.spmPath, 'tpm', 'TPM.nii,3')};
            matlabbatch{1}.spm.spatial.preproc.tissue(3).ngaus = 2;
            matlabbatch{1}.spm.spatial.preproc.tissue(3).native = [1 0];
            matlabbatch{1}.spm.spatial.preproc.tissue(3).warped = [0 0];
            matlabbatch{1}.spm.spatial.preproc.tissue(4).tpm = {fullfile(obj.spmPath, 'tpm', 'TPM.nii,4')};
            matlabbatch{1}.spm.spatial.preproc.tissue(4).ngaus = 3;
            matlabbatch{1}.spm.spatial.preproc.tissue(4).native = [1 0];
            matlabbatch{1}.spm.spatial.preproc.tissue(4).warped = [0 0];
            matlabbatch{1}.spm.spatial.preproc.tissue(5).tpm = {fullfile(obj.spmPath, 'tpm', 'TPM.nii,5')};
            matlabbatch{1}.spm.spatial.preproc.tissue(5).ngaus = 4;
            matlabbatch{1}.spm.spatial.preproc.tissue(5).native = [1 0];
            matlabbatch{1}.spm.spatial.preproc.tissue(5).warped = [0 0];
            matlabbatch{1}.spm.spatial.preproc.tissue(6).tpm = {fullfile(obj.spmPath, 'tpm', 'TPM.nii,6')};
            matlabbatch{1}.spm.spatial.preproc.tissue(6).ngaus = 2;
            matlabbatch{1}.spm.spatial.preproc.tissue(6).native = [0 0];
            matlabbatch{1}.spm.spatial.preproc.tissue(6).warped = [0 0];
            matlabbatch{1}.spm.spatial.preproc.warp.mrf = 1;
            matlabbatch{1}.spm.spatial.preproc.warp.cleanup = 1;
            matlabbatch{1}.spm.spatial.preproc.warp.reg = [0 0.001 0.5 0.05 0.2];
            matlabbatch{1}.spm.spatial.preproc.warp.affreg = 'mni';
            matlabbatch{1}.spm.spatial.preproc.warp.fwhm = 0;
            matlabbatch{1}.spm.spatial.preproc.warp.samp = 3;
            matlabbatch{1}.spm.spatial.preproc.warp.write = [0 1];
            matlabbatch{1}.spm.spatial.preproc.warp.vox = NaN;
            matlabbatch{1}.spm.spatial.preproc.warp.bb = [NaN NaN NaN
                NaN NaN NaN];

            % run job
            spm('defaults','FMRI');
            spm_jobman('initcfg');
            spm_jobman('run', matlabbatch);

        end

        % runNormalization (optional?)
        function obj = runNormalization(obj, subID, sesDir)
            % RUNNORMALIZATION Function to perform spatial normalization of
            %   functional images
            %
            %   Input
            %       subNr: subject ID
            %       sesDir: directory containing anat/func data of current
            %               session
            %   Output
            %       none
            
            % input checks
            assert(all(~isnan(obj.voxelSize)), 'stepNormalization: EPI voxel size is missing!')
            
            % get BIDS structure of data set
            BIDS = spm_BIDS(obj.preRoot);
            
            % get deformation field for normalization parameters
            anat = spm_BIDS(BIDS,'data',...
                'sub',subID,'type','T1w');
            defIma = spm_file(anat,'prefix','y_'); % we need the deformation field
            assert(exist(defIma{1}, 'file'), 'stepNormalization: Could not find deformation field image. Please run segmentation first.')

            % get EPI images across runs to normalize
            subIdx = contains(obj.subjects,subID); % index to select the correct number of runs for the subject
            subRuns = obj.runSel{subIdx}{1};       % the second index reflects the task number - currently only works for 1 task
            nRuns = numel(subRuns);

            allNiftis = [];
            for r = 1:nRuns
                if ~isempty(sesDir)
                    epi = spm_BIDS(BIDS,'data', ... %todo: add task label to query?
                        'sub',subID,'ses',sesDir,'run',[obj.BIDSlabel{3} num2str(r)],'type',obj.BIDSlabel{4});
                else
                    epi = spm_BIDS(BIDS,'data', ...
                        'sub',subID,'run',[obj.BIDSlabel{3} num2str(r)],'type',obj.BIDSlabel{4});
                end

                % these need to be the *coregistered* realigned/unwarped EPIs
                runNiftis = spm_select('ExtFPlist', spm_file(epi,'path'), ...
                    spm_file(spm_file(epi,'filename'),'prefix',['^(?:' obj.prefix.realignment '|' obj.prefix.unwarping ').*']),Inf);
                allNiftis = char(allNiftis, runNiftis);

            end
            
            allNiftis = cellstr(allNiftis(2:end,:));

            % check if coregistration has been done by testing if the
            % coregistered mean image exists
            epi = spm_BIDS(BIDS,'data',...
                'sub',subID,'type',obj.BIDSlabel{4});
            meanIma = cellstr(spm_select('ExtFPlist', spm_file(epi,'path'), spm_file(spm_file(epi,'filename'),'prefix',['^' obj.prefix.coregistration 'mean.*'])));
            meanIma = meanIma(1); % in case of multiple runs
            assert(~isempty(meanIma{1}), 'stepNormalization: Images have not coregistered. Please run coregistration first.')
            
            % prepare spm batch
            matlabbatch = [];
            matlabbatch{1}.spm.spatial.normalise.write.subj.def = defIma;
            matlabbatch{1}.spm.spatial.normalise.write.subj.resample = allNiftis;
            matlabbatch{1}.spm.spatial.normalise.write.woptions.bb = [-78 -112 -70;78 76 85];
            matlabbatch{1}.spm.spatial.normalise.write.woptions.vox = obj.voxelSize;
            matlabbatch{1}.spm.spatial.normalise.write.woptions.interp = 4;
            matlabbatch{1}.spm.spatial.normalise.write.woptions.prefix = obj.prefix.normalization;

            %todo: add normalization of c1 - c5 segments?

            % run job
            spm('defaults','FMRI');
            spm_jobman('initcfg');
            spm_jobman('run', matlabbatch);

        end

        % runSmoothing (optional)
        function obj = runSmoothing(obj, subID, sesDir)
            % RUNSMOOTHING Function to perform spatial smoothing of
            %   functional images
            %
            %   Input
            %       subNr: subject ID
            %       sesDir: directory containing func data of current
            %               session
            %   Output
            %       none
            
            % input checks
            assert(all(~isnan(obj.smoothingKernel)), 'stepSmoothing: Size of the smoothing kernel is missing!')
            assert(all(size(obj.smoothingKernel) == [1,3]), 'stepSmoothing: Size of the smoothing kernel should be defined as a triplet: [x, y, z]!')
            
            % select data for all runs
            subIdx = contains(obj.subjects,subID); % index to select the correct number of runs for the subject
            subRuns = obj.runSel{subIdx}{1};       % the second index reflects the task number - currently only works for 1 task
            nRuns = numel(subRuns); 
            
            % get BIDS structure of data set
            BIDS = spm_BIDS(obj.preRoot);

            % get EPIs
            allNiftis = [];
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
                    runNiftis = spm_select('ExtFPlist', spm_file(epi,'path'), spm_file(spm_file(epi,'filename'),'prefix',['^' obj.currPrefix]),Inf);
                else
                    runNiftis = spm_select('ExtFPlist', spm_file(epi,'path'), spm_file(spm_file(epi,'filename'),'prefix',['^' obj.currPrefix '.*']),Inf);
                end
                allNiftis = char(allNiftis, runNiftis);

            end

            allNiftis = cellstr(allNiftis(2:end,:));

            % prepare spm batch
            matlabbatch{1}.spm.spatial.smooth.data = allNiftis;
            matlabbatch{1}.spm.spatial.smooth.fwhm = obj.smoothingKernel;
            matlabbatch{1}.spm.spatial.smooth.dtype = 0;
            matlabbatch{1}.spm.spatial.smooth.im = 0;
            matlabbatch{1}.spm.spatial.smooth.prefix = obj.prefix.smoothing;

            % run job
            spm('defaults','FMRI');
            spm_jobman('initcfg');
            spm_jobman('run', matlabbatch);

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

            if obj.runParallel
                % parallel preprocessing of subjects
                % determine number of processes
                if numel(obj.subjects) > obj.maxCores
                    nCores = obj.maxCores;
                else
                    nCores = numel(obj.subjects);
                end

                % distribute subjects across processes
                nSubs = numel(obj.subjects);
                subsPerProc  = (1/nCores)*nSubs;
                parProcs = cell(nCores,1);
                for i = 1:nCores
                    idxs = (floor(round((i-1)*subsPerProc)):floor(round((i) * subsPerProc))-1) + 1;
                    parProcs{i} = obj.subjects(idxs,:);
                end
                
                % start pool of parallel processes
                pool = gcp('nocreate');
                if isempty(pool)
                    pool = parpool(nCores);
                elseif pool.NumWorkers ~= nCores
                    fprintf('Wrong number of workers. Starting again.\n');
                    delete(pool);
                    pool = parpool(nCores);
                else
                    fprintf('Pool with %d workers already running.\n', nCores);
                end

                % start preprocessing jobs for each process
                parfor worker = 1:nCores
                    % get subjects for this process
                    procSubs = parProcs{worker}

                    % loop over process-specific subjects
                    for s = 1:numel(procSubs)
                        obj.preprocessSubj(procSubs{s});
                    end
                end

                % close pool
                delete(pool)

            else
                % sequential preprocessing of subjects
                for s = 1:numel(obj.subjects)
                    obj.preprocessSubj(obj.subjects{s});
                end
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