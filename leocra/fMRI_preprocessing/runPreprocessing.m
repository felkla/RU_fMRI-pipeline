% fMRI Preprocessing pipeline
%
% This script preprocesses the BIDS formatted fMRI data
%
%   Preprocessing steps include
%       0. Create folder and import func and anat files --> if this is
%       selected the current folder is deleted and recreated 
%       1. Segmentation
%       2. Normalization of T1 images
%       3. Realignement
%       4. Slice-timing correction
%       5. Coregistration of mean EPI to T1       
%       6. Application of normalization parameters to EPI data
%       7. Estimation of noise regressors using the aCompCor method
%       Behzadi,2018) 
%       8. Smoothing (optional) 

% Initialization
% --------------

clc
remAppledouble
close all
clear all

% Directories 
% -----------

% SPM12
spm_path = fullfile(userpath, 'spm12');
addpath(spm_path)
spm('defaults','fmri')
spm_jobman('initcfg')

% TAPAS toolbox 
tapas_path = fullfile(userpath, 'tapas');
addpath(tapas_path)

% Data source root directory
% E.g., ds_root = '~/Documents/gb_fmri_data/BIDS/ds_xxx';
if ispc
    ds_root = 'G:\1_RU5389\2_BIDS';
elseif ismac
    ds_root = '/Volumes/WORK/1_RU5389/2_BIDS';
else
    error('Unsupported operating system');
end
src_dir = 'func';

% Subject directories
% E.g., sub_dir = {'sub-01', 'sub-02', 'sub-03'};
sub_dir = dir(fullfile(ds_root,'sub*'));
sub_dir = {sub_dir.name}';

% Data target directory 
if ispc
    tgt_dir = 'G:\1_RU5389\3_DERIVED';
elseif ismac
    tgt_dir = '/Volumes/WORK/1_RU5389/3_DERIVED';
else
    error('Unsupported operating system');
end

% BIDS format file name part labels
BIDS_fn_label{1} = '_Predator'; % BIDS file name task label
BIDS_fn_label{2} = ''; % BIDS file name acquisition label
BIDS_fn_label{3} = '_run-0'; % BIDS file name run index
BIDS_fn_label{4} = '_bold'; % BIDS file name modality suffix

% Preprocessing object
% --------------------

% Select run numbers 
% E.g., run_sel = {[1 2 3 4 5 6], [1 2 3 4 5 6]};
% first vector in the first cell is for subject 1 and for the first task, second vector is for the second task
for i = 1:length(sub_dir)
    run_sel{i} = {[14 17 20 23]};
end 

% Select preprocessing steps 
%       0. Create folder and import func and anat files --> if this is
%       selected the current folder is deleted and recreated 
%       1. Segmentation of T1 images
%       2. Normalization of T1 images
%       3. Realignement
%       4. Slice-timing correction
%       5. Coregistration of mean EPI to T1       
%       6. Application of normalization parameters to EPI data
%       7. Estimation of noise regressors using the aCompCor method
%       (Behzadi,2018) 
%       8. Smoothing (optional)
prep_steps = [8];

% Preprocessing variables
prep_vars = struct();
prep_vars.spm_path = spm_path;
prep_vars.ds_root = ds_root;
prep_vars.src_dir = src_dir;
prep_vars.tgt_dir = tgt_dir;
prep_vars.BIDS_fn_label = BIDS_fn_label;
prep_vars.prep_steps = prep_steps;
prep_vars.nslices = 72;
prep_vars.TR = 1;
prep_vars.slicetiming = [
    0,    0.41, 0.817, 0.245, 0.655, 0.082, 0.49, 0.9,   0.327, 0.735, 0.165, 0.572, ...
    0,    0.41, 0.817, 0.245, 0.655, 0.082, 0.49, 0.9,   0.327, 0.735, 0.165, 0.572, ...
    0,    0.41, 0.817, 0.245, 0.655, 0.082, 0.49, 0.9,   0.327, 0.735, 0.165, 0.572, ...
    0,    0.41, 0.817, 0.245, 0.655, 0.082, 0.49, 0.9,   0.327, 0.735, 0.165, 0.572, ...
    0,    0.41, 0.817, 0.245, 0.655, 0.082, 0.49, 0.9,   0.327, 0.735, 0.165, 0.572, ...
    0,    0.41, 0.817, 0.245, 0.655, 0.082, 0.49, 0.9,   0.327, 0.735, 0.165, 0.572
];

% Cycle over participants
% -----------------------
for i = 1:numel(sub_dir)
    
    prep_vars.run_sel = run_sel{i};

    % Preprocessing object instance
    prep = prepobj(prep_vars);
    
    % Run preprocessing for current subject
    prep.spm_fmri_preprocess(sub_dir{i});
    
    % Delete intermediate files created by SPM12 during fMRI data preprocessing
    prep.spm_delete_preprocess_files(sub_dir{i});
    
end

fprintf('Preprocessing finished\n');