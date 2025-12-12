% Example config file for the research unit (RU) preprocessing pipeline
% ---------------------------------------------------------------------

%% Preparation
% Initialization
% --------------

clc
close all
clearvars

% Directories
% -----------
% Get the parent directory of the current directory 
% (assumed to contain the BIDS directory)
parentDir = fullfile('C:\Users','klaassen','Documents','Research Unit 5389','General','fMRI pipeline');
% parentDir = fileparts(pwd);

% SPM12/SPM25 directory
% spmPath = fullfile(parentDir,'spm12/');
spmVersion = 12; %12 or 25
assert(any([12, 25] == spmVersion), 'Unknown SPM version')
spmPath = fullfile('C:\Users','klaassen','Documents','MATLAB',['spm' num2str(spmVersion)]);
addpath(spmPath)
% spm('defaults','fmri') % currently also called in the preprocessing steps
% spm_jobman('initcfg') % currently also called in the preprocessing steps

% Data source- and target root directory
dsRoot = fullfile(parentDir,'data'); %your BIDS folder
preRoot = fullfile(dsRoot,'derived'); %where the preprocessed data will be placed
funcLab = 'func'; % label for functional data sub directory
anatLab = 'anat'; % label for anatomical data sub directory
fmapLab = 'fmap'; % label for field-map data sub directory

%optional, add:
% behavLab = 'behav'; % behavioral data sub-directory
% physLab = 'phys'; % physiological data sub-directory

% Subject directories
% E.g., subDir = {'sub-001', 'sub-002', 'sub-003'};
%todo if necessary: add option to switch between two-digit and three-digit subject numbers?
subDir = dir(fullfile(dsRoot,'sub*'));
allSubjects = {subDir.name}';

% define all run numbers per subject
%e.g., run_sel{1} = {[1], [1:6]}; % sub-001 has 1 run for task 1, and 6 runs for task 2
runSel = cell(1,numel(subDir));
for i = 1:length(allSubjects)
    runSel{i} = {1:4};
end
assert(numel(allSubjects) == numel(runSel), 'Length of subject- and run lists should match!')

% BIDS format file name part labels - do we need the underscores?
BIDSlabel{1} = {'task-PT'}; % BIDS file name task label: BIDSlabel{1} = {'task1';'task2')
BIDSlabel{2} = ''; % BIDS file name acquisition label
BIDSlabel{3} = 'run-0'; % BIDS file name run index
BIDSlabel{4} = 'bold'; % BIDS file name modality suffix

%% Select preprocessing steps
%       0. Create folder and import func and anat files --> if this is
%       selected, the current folder is deleted and recreated
%       1. Segmentation/Normalization of T1 images
%       2. Realignment
%       3. Slice-timing correction
%       4. Coregistration of mean EPI to T1
%       5. Application of normalization parameters to EPI data
%       6. Smoothing

% Default settings for RU pipeline
stepSegmentation    = false;
stepSlicetiming     = true; % -> consider doing this *before* realignment (see büchel pipeline)
stepUnwarping       = false;
stepRealignment     = true;
stepCoregistration  = false; % -> add option to do non-linear coregistration (e.g., instead of fmap correction; see büchel pipeline)
stepNormalization   = false; % do this after first-level model?
stepSmoothing       = false; % do this after first-level model?

overwriteFiles = false; % overwrite existing preproc files?
deleteFiles = false;    % delete intermediate preproc files?

%prefix
prefix.slicetiming      = 'a';
prefix.unwarping        = 'u';
prefix.realignment      = 'r';
prefix.normalization    = 'w';
prefix.smoothing        = 's';

% Initialize preprocessing variables object
prepVars = preprocessingVars();

%update paths and labels
prepVars.spmPath = spmPath;
prepVars.dsRoot = dsRoot;
prepVars.funcLab = funcLab;
prepVars.anatLab = anatLab;
prepVars.fmapLab = fmapLab;
prepVars.preRoot = preRoot;
prepVars.BIDSlabel = BIDSlabel;
prepVars.overwriteFiles = overwriteFiles;
prepVars.deleteFiles = deleteFiles;

%update steps
prepVars.stepSegmentation = stepSegmentation;
prepVars.stepSlicetiming = stepSlicetiming;
prepVars.stepUnwarping = stepUnwarping;
prepVars.stepRealignment = stepRealignment;
prepVars.stepCoregistration = stepCoregistration; % -> add option to do coregistration between two functional runs (if ppt left scanner)
prepVars.stepNormalization = stepNormalization;
prepVars.stepSmoothing = stepSmoothing;

prepVars.preprocessingComponents = [stepSegmentation,...
                                    stepSlicetiming,...
                                    stepUnwarping,...
                                    stepRealignment,...
                                    stepCoregistration,...
                                    stepNormalization,...
                                    stepSmoothing];

%update prefixes
prepVars.prefix.slicetiming = prefix.slicetiming;
prepVars.prefix.unwarping = prefix.unwarping;
prepVars.prefix.realignment = prefix.realignment;
prepVars.prefix.normalization = prefix.normalization;
prepVars.prefix.smoothing = prefix.smoothing;

% Select subjects to preprocess
subs2incl = {'203'}; % should be cell array with your BIDS-compliant numbers: subs2incl = {'001','002','051'}, or 'all' to preprocess all subjects in dsRoot
if any(contains(subs2incl,'all'))
    sub_idx = 1:numel(allSubjects);
else
    sub_idx = find(contains(allSubjects,subs2incl));
end
prepVars.subjects = allSubjects(sub_idx); % selected subjects
prepVars.runSel = runSel(sub_idx); % update nr of functional runs for selected subjects

% Update fMRI parameters (params currently match example dataset)
prepVars.nSlices = 66;
prepVars.TR = 1.975;
prepVars.refSlice = (prepVars.TR/2)*1000;
sliceTimings = [1.91499999998,1.85499999998,1.79499999998,1.73499999999,1.67499999999,1.61499999999,1.55499999999,1.495,1.435,1.375,1.315,...
                1.25749999998,1.19749999998,1.13749999998,1.07749999998,1.01749999999,0.95749999999,0.89749999999,0.83749999999,0.7775,0.7175,0.6575,...
                0.5975,0.53749999998,0.47749999998,0.41749999998,0.35999999999,0.29999999999,0.23999999999,0.17999999999,0.12,0.06, 0,...
                1.91499999998,1.85499999998,1.79499999998,1.73499999999,1.67499999999,1.61499999999,1.55499999999,1.495,1.435,1.375,1.315,...
                1.25749999998,1.19749999998,1.13749999998,1.07749999998,1.01749999999,0.95749999999,0.89749999999,0.83749999999,0.7775,0.7175,0.6575,...
                0.5975,0.53749999998,0.47749999998,0.41749999998,0.35999999999,0.29999999999,0.23999999999,0.17999999999,0.12,0.06,0];
epiReadoutTime = 0.03359989248034406;

prepVars.sliceTiming = round(sliceTimings*1000); % convert to ms
prepVars.epiReadoutTime = round(epiReadoutTime*1000); % convert to ms

%% Run preprocessing 
% Initialize preprocessing object
prepObj = preprocessingObj(prepVars);

% Call the function that implements preprocessing across subjects
prepObj.preprocessLoop();
