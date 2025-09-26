% Example config file for the research unit (RU) preprocessing pipeline
% ---------------------------------------------------------------------

% Initialization
% --------------

clc
close all
clearvars

% Directories 
% -----------
% Get the parent directory of the current directory
parentDir = fileparts(pwd);

% SPM12
spmPath = fullfile(parentDir,'spm12/');
addpath(spmPath)
spm('defaults','fmri')
spm_jobman('initcfg')

% Data source root directory
% E.g., dsRoot = '~/Documents/gb_fmri_data/BIDS/ds_xxx';
dsRoot = fullfile(parentDir,'data/ds004331-download');
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

% Select run numbers 
% E.g., run_sel = {[1], [1:6]};
for i = 1:length(subDir)
    run_sel{i} = {[1],[1:12]};
end 

% Select preprocessing steps 
%       0. Create folder and import func and anat files --> if this is
%       selected, the current folder is deleted and recreated 
%       1. Segmentation/Normalization of T1 images
%       2. Realignement
%       3. Slice-timing correction
%       4. Coregistration of mean EPI to T1       
%       5. Application of normalization parameters to EPI data
%       6. Smoothing

% Default settings for RU pipeline
stepSegmentationT1 = false;
stepRealignment = true;
stepSlicetiming = false;
stepCoregistration = false; 
stepNormalization = true;
stepSmoothing = false;

% Preprocessing variables
prep_vars = preprocessingVars();
prep_vars.spmPath = spmPath;
prep_vars.dsRoot = dsRoot;
prep_vars.srcDir = srcDir;
prep_vars.tgtDir = tgtDir;
prep_vars.BIDSlabel = BIDSlabel;
prep_vars.stepSegmentationT1 = stepSegmentationT1;
prep_vars.stepRealignment = stepRealignment;
prep_vars.stepSlicetiming = stepSlicetiming;
prep_vars.stepCoregistration = stepCoregistration;
prep_vars.stepNormalization = stepNormalization;
prep_vars.stepSmoothing = stepSmoothing;
prep_vars.nSlices = 57;
prep_vars.TR = 1.5;
prep_vars.sliceTiming = [0, 0.78, 0.0775, 0.8575, 0.1575, 0.935, 0.235, 1.0125,...
                        0.3125, 1.09, 0.39, 1.17, 0.4675, 1.2475, 0.545, 1.325,...
                        0.625, 1.4025, 0.7025, 0, 0.78, 0.0775, 0.8575, 0.1575,...
                        0.935, 0.235, 1.0125, 0.3125, 1.09, 0.39, 1.17, 0.4675,...
                        1.2475, 0.545, 1.325, 0.625, 1.4025, 0.7025, 0, 0.78,...
                        0.0775, 0.8575, 0.1575, 0.935, 0.235, 1.0125, 0.3125,...
                        1.09, 0.39, 1.17, 0.4675, 1.2475, 0.545, 1.325, 0.625, 1.4025, 0.7025];

% Initialize preprocessing object
preprocessing_obj = preprocessingObj(prep_vars);

% Call the function (tbc) that implements preprocessing across subjects