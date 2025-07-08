% fMRI GLM
%
% This script runs the GLM for the preprocessed fMRI data obtained by
% running runPreprocessing.m

% Initialization
% --------------

clc
remAppledouble
close all
clear all
dbstop if error

% Directories
% -----------

% SPM12
spm_path = fullfile(userpath, 'spm12');
addpath(spm_path)
spm('defaults','fmri')
spm_jobman('initcfg')

% Data source root directory
% E.g., ds_root = '~/Documents/gb_fmri_data/BIDS/ds_xxx';
if ispc
    ds_root = 'G:\Pilot_P8_MRT\BIDS';
elseif ismac
    ds_root = '/Volumes/WORK/Pilot_P8_MRT/BIDS';
else
    error('Unsupported operating system');
end
src_dir = 'func';

% Subject directories
% E.g., sub_dir = {'sub-01', 'sub-02', 'sub-03'};
sub_dir_struct = dir(fullfile(ds_root, 'sub*'));  % Get directory listing
sub_dir = {sub_dir_struct.name};  % Convert to a cell array
sub_dir = sub_dir(:);  % Ensure it is a column vector

% Data target directory
if ispc
    tgt_dir = 'G:\Pilot_P8_MRT\derived';  % For Windows
elseif ismac
    tgt_dir = '/Volumes/WORK/Pilot_P8_MRT/derived';  % For macOS
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
%%% split between {[T1/localizer],[task]}
for i = 1:length(sub_dir)
    run_sel{i} = {[19],[10 12 14 16]};
end

% Preprocessing variables
prep_vars = struct();
prep_vars.spm_path = spm_path;
prep_vars.ds_root = ds_root;
prep_vars.src_dir = src_dir;
prep_vars.tgt_dir = tgt_dir;
prep_vars.BIDS_fn_label = BIDS_fn_label;
prep_vars.prep_steps = [];
prep_vars.nslices = 72;
prep_vars.TR = 1;
prep_vars.slicetiming = [0, 0.41, 0.82, 0.25, 0.65, 0.08, 0.49, 0.9, 0.33, 0.74, 0.16, 0.57, ...
    0, 0.41, 0.82, 0.25, 0.65, 0.08, 0.49, 0.9, 0.33, 0.74, 0.16, 0.57, ...
    0, 0.41, 0.82, 0.25, 0.65, 0.08, 0.49, 0.9, 0.33, 0.74, 0.16, 0.57, ...
    0, 0.41, 0.82, 0.25, 0.65, 0.08, 0.49, 0.9, 0.33, 0.74, 0.16, 0.57, ...
    0, 0.41, 0.82, 0.25, 0.65, 0.08, 0.49, 0.9, 0.33, 0.74, 0.16, 0.57, ...
    0, 0.41, 0.82, 0.25, 0.65, 0.08, 0.49, 0.9, 0.33, 0.74, 0.16, 0.57];

% Cycle over participants
% -----------------------

for i = 1:numel(sub_dir)

    prep_vars.run_sel = run_sel{i};

    % Preprocessing object instance
    prep = prepobj(prep_vars);

    % generate onsets files from '*_events' files in the 'func' directory
    create_onset_files(prep,sub_dir{i});

    %%% what if I don't have s5nar because I did not do smoothing?
    % set parameters for GLM
    prefix = 's5nar';
    fir = 0; % no finite impulse response model
    is_loc = 0; % if GLM for localizer should be computed or not
    mparams = 1 ; % do / do not include movement parameters
    tapas_denoise = 0; % do/ do not include tapas noise regressors
    physio = 0 ; % do / do not include physiological variables
    glmdenoise =  0; % do / do not include GLM denoise regressors
    results_dir = fullfile(tgt_dir,sub_dir{i}, 'GLM');
    if ~isdir(results_dir), mkdir(results_dir); end

    % Run GLM for current subject
    matlabbatch = firstlevel(prep,prefix,results_dir,sub_dir{i},mparams,physio,tapas_denoise,glmdenoise,is_loc);
    spm_jobman('run',matlabbatch)

    % run contrasts
    if is_loc
        % Set contrasts for localizer
        clear matlabbatch
        matlabbatch{1}.spm.stats.con.spmmat = {fullfile(results_dir, 'SPM.mat')};
        matlabbatch{1}.spm.stats.con.consess{1}.tcon.name = 'objects > scrambled';
        matlabbatch{1}.spm.stats.con.consess{1}.tcon.weights = [0 1 -1];
        matlabbatch{1}.spm.stats.con.consess{2}.tcon.name = 'scrambled > objects';
        matlabbatch{1}.spm.stats.con.consess{2}.tcon.weights = [0 -1 1];
        matlabbatch{1}.spm.stats.con.consess{3}.tcon.name = 'all > baseline';
        matlabbatch{1}.spm.stats.con.consess{3}.tcon.weights = [0 1 1];
        matlabbatch{1}.spm.stats.con.delete = 1;
        spm_jobman('run', matlabbatch);
    else
        % Set contrasts for task GLM
        clear matlabbatch
        contrast_names = {'WaitScene vs Outcome'};

        for con = 1:length(contrast_names)
            % First get condition order
            cond_order = get_cond_order(prep, sub_dir{i});
            weights = [];

            % Determine the number of volumes dynamically
            n_volumes_per_run = zeros(1, length(run_sel{i}{2}));

            for r = 1:length(run_sel{i}{2})
                run_number = run_sel{i}{2}(r);
                nii_file = fullfile(ds_root, sub_dir{i}, src_dir, ...
                    sprintf('sub-%s%s%s%d%s.nii', sub_dir{i}(5:end), BIDS_fn_label{1}, BIDS_fn_label{3}, run_number, BIDS_fn_label{4}));

                nii_gz_file = [nii_file, '.gz'];

                if exist(nii_file, 'file')
                    V = spm_vol(nii_file);
                    n_volumes_per_run(r) = numel(V);
                elseif exist(nii_gz_file, 'file')
                    gunzip(nii_gz_file);
                    V = spm_vol(nii_file);
                    n_volumes_per_run(r) = numel(V);
                    delete(nii_file);
                else
                   error('File not found: %s or %s', nii_file, nii_gz_file);
                end
            end

            for run = 1:length(cond_order)
                % Create a weight vector with zeroes for the current run
                current_weights = zeros(1, n_volumes_per_run(run));

                % Assign 1 to all WaitScene, -1 to all Outcome trials
                weights(cond_order == 2) = 1;
                weights(cond_order == 3) = -1;

                % Append to overall weights
                weights = [weights, current_weights];
            end  % End of loop over runs

            % Create contrast batch
            matlabbatch{1}.spm.stats.con.spmmat = {fullfile(results_dir, 'SPM.mat')};
            matlabbatch{1}.spm.stats.con.consess{con}.tcon.name = contrast_names{con};
            matlabbatch{1}.spm.stats.con.consess{con}.tcon.weights = weights;
        end  % End of contrast_names loop

        matlabbatch{1}.spm.stats.con.delete = 1;
        spm_jobman('run', matlabbatch);
    end

end