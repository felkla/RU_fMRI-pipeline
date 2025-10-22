% Example config file for the research unit (RU) preprocessing pipeline
% ---------------------------------------------------------------------

%% Preparation
% Initialization
% --------------

clc
close all
clearvars

debug = true;

% Directories
% -----------
% Get the parent directory of the current directory
parentDir = fileparts(pwd);

% SPM12
spmPath = fullfile(parentDir,'spm12/');
if ~debug
    addpath(spmPath)
    spm('defaults','fmri')
    spm_jobman('initcfg')
end

% Data source root directory
% E.g., dsRoot = '~/Documents/gb_fmri_data/BIDS/ds_xxx';
dsRoot = fullfile(parentDir,'data/ds004331-download'); %your BIDS folder
srcDir = 'func';  % functional data sub-directory

% Subject directories
% E.g., subDir = {'sub-01', 'sub-02', 'sub-03'};
subDir = dir(fullfile(dsRoot,'sub*'));
subDir = {subDir.name}';

% Data target directory
tgtDir = fullfile(cd,'derived');

% BIDS format file name part labels
BIDSlabel{1} = {'_task-localizer';'_task-main'}; % BIDS file name task label
BIDSlabel{2} = ''; % BIDS file name acquisition label
BIDSlabel{3} = '_run-00'; % BIDS file name run index
BIDSlabel{4} = '_bold'; % BIDS file name modality suffix

% Select run numbers (we might have to revise how we code this /FK)
% One cell per subject, each again containing one cell per task. 
% For each subject cell, the first cell is for the first task, second vector is for the second task
% E.g., run_sel{1} = {[1], [1:6]}; % sub-001 has 1 run for task 1, and 6 runs for task 2
for i = 1%:length(subDir)
    runSel{i} = {[1],[1:12]};
end

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
stepSlicetiming = false;
stepCoregistration = true;
stepNormalization = true;
stepSmoothing = false;
stepDeleteFiles = false;

% Initialize preprocessing variables object
prepVars = preprocessingVars();

%update paths
prepVars.spmPath = spmPath;
prepVars.dsRoot = dsRoot;
prepVars.srcDir = srcDir;
prepVars.tgtDir = tgtDir;
prepVars.BIDSlabel = BIDSlabel;

%update steps
prepVars.stepSegmentation = stepSegmentation;
prepVars.stepRealignment = stepRealignment;
prepVars.stepSlicetiming = stepSlicetiming;
prepVars.stepCoregistration = stepCoregistration;
prepVars.stepNormalization = stepNormalization;
prepVars.stepSmoothing = stepSmoothing;
prepVars.stepDeleteFiles = stepDeleteFiles;

prepVars.preprocessingComponents = [stepSegmentation,...
                                    stepRealignment,...
                                    stepSlicetiming,...
                                    stepCoregistration,...
                                    stepNormalization,...
                                    stepSmoothing];

%update fmri parameters
prepVars.runSel = runSel; % nr of functional runs for each subject
prepVars.nSlices = 57;
prepVars.TR = 1.5;
prepVars.sliceTiming = [0, 0.78, 0.0775, 0.8575, 0.1575, 0.935, 0.235, 1.0125,...
    0.3125, 1.09, 0.39, 1.17, 0.4675, 1.2475, 0.545, 1.325,...
    0.625, 1.4025, 0.7025, 0, 0.78, 0.0775, 0.8575, 0.1575,...
    0.935, 0.235, 1.0125, 0.3125, 1.09, 0.39, 1.17, 0.4675,...
    1.2475, 0.545, 1.325, 0.625, 1.4025, 0.7025, 0, 0.78,...
    0.0775, 0.8575, 0.1575, 0.935, 0.235, 1.0125, 0.3125,...
    1.09, 0.39, 1.17, 0.4675, 1.2475, 0.545, 1.325, 0.625, 1.4025, 0.7025];

%% Run preprocessing 
% Initialize preprocessing object
prepObj = preprocessingObj(prepVars);

% define subjects to preprocess
subjects = [1,3,201]; % subject numbers
% TO DO: how can we link subIDs to runSel specifications? Maybe a single table containing al subData?
%assert(numel(subjects) <= numel(runSel),'Missing run selections for some subjects!') 

% Call the function that implements preprocessing across subjects
prepObj.preprocessLoop(subjects);
