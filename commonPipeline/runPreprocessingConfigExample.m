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
spmVersion = 12; %or 25
if spmVersion == 25
    spmPath = fullfile('C:\Users','klaassen','Documents','MATLAB','spm25');
else
    spmPath = fullfile('C:\Users','klaassen','Documents','MATLAB','spm12');
end

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
BIDSlabel{1} = {'_task-PT'}; % BIDS file name task label: BIDSlabel{1} = {'task1';'task2')
BIDSlabel{2} = ''; % BIDS file name acquisition label
BIDSlabel{3} = '_run-0'; % BIDS file name run index
BIDSlabel{4} = '_bold'; % BIDS file name modality suffix

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
stepSegmentation = false;
stepRealignment = true;
stepSlicetiming = false; % -> consider doing this *before* realignment (see büchel pipeline)
stepCoregistration = false; % -> add option to do non-linear coregistration (e.g., instead of fmap correction; see büchel pipeline)
stepNormalization = false;
stepSmoothing = false;
stepDeleteFiles = false;

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

%update steps
prepVars.stepSegmentation = stepSegmentation;
prepVars.stepRealignment = stepRealignment;
prepVars.stepSlicetiming = stepSlicetiming;
prepVars.stepCoregistration = stepCoregistration; % -> add option to do coregistration between two functional runs (if ppt left scanner)
prepVars.stepNormalization = stepNormalization;
prepVars.stepSmoothing = stepSmoothing;
prepVars.stepDeleteFiles = stepDeleteFiles;

prepVars.preprocessingComponents = [stepSegmentation,...
                                    stepRealignment,...
                                    stepSlicetiming,...
                                    stepCoregistration,...
                                    stepNormalization,...
                                    stepSmoothing];

% Select subjects to preprocess
subs2incl = {'203'}; % should be cell array with your BIDS-compliant numbers: subs2incl = {'001','002','051'}, or 'all' to preprocess all subjects in dsRoot
if any(contains(subs2incl,'all'))
    sub_idx = 1:numel(allSubjects);
else
    sub_idx = find(contains(allSubjects,subs2incl));
end
prepVars.subjects = allSubjects(sub_idx); % selected subjects
prepVars.runSel = runSel(sub_idx); % update nr of functional runs for selected subjects

% Update fMRI parameters
prepVars.nSlices = 66;
prepVars.TR = 1.975;
prepVars.sliceTiming = [];

% check if minimally-required preprocessing parameters are defined. 
% TODO: or should we move these checks to the prepObj-class methods that implement these steps?
assert(~isnan(prepVars.nSlices) | ~isnan(prepVars.TR), 'Not all required preprocessing parameters are defined!');
if stepSlicetiming == true
    assert(any(~isnan(prepVars.sliceTiming)),'stepSlicetiming: Not all required preprocessing parameters are defined!');
    assert(prepVars.nSlices == numel(prepVars.sliceTiming), 'stepSlicetiming: Number of slices does not match number of slice timings!')
end

%% Run preprocessing 
% Initialize preprocessing object
prepObj = preprocessingObj(prepVars);

% Call the function that implements preprocessing across subjects
prepObj.preprocessLoop();
