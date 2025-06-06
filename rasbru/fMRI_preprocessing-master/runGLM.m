% fMRI GLM
%
% This script runs the GLM for the preprocessed fMRI data obtained by
% running runPreprocessing.m

% Initialization
% --------------

clc
close all

% Directories
% -----------

% SPM12
spm_path = '/Users/johannessinger/Documents/cloud_Berlin/Projekte/dfg/WP1/analysis_tools/spm/spm12/';
addpath(spm_path)
spm('defaults','fmri')
spm_jobman('initcfg')

% Data source root directory
% E.g., ds_root = '~/Documents/gb_fmri_data/BIDS/ds_xxx';
ds_root = '/Users/johannessinger/Documents/cloud_Berlin/Projekte/fmri_pipeline/data/ds004331-download';
src_dir = 'func';  % functional data sub-directory

% Subject directories
% E.g., sub_dir = {'sub-01', 'sub-02', 'sub-03'};
sub_dir = dir(fullfile(ds_root,'sub*'));
sub_dir = {sub_dir.name}';

% Data target directory
tgt_dir = '/Users/johannessinger/Documents/cloud_Berlin/Projekte/fmri_pipeline/derived';

% BIDS format file name part labels
BIDS_fn_label{1} = {'_task-localizer';'_task-main'}; % BIDS file name task label
BIDS_fn_label{2} = ''; % BIDS file name acquisition label
BIDS_fn_label{3} = '_run-00'; % BIDS file name run index
BIDS_fn_label{4} = '_bold'; % BIDS file name modality suffix

% Preprocessing object
% --------------------

% Select run numbers
% E.g., run_sel = {[1 2 3 4 5 6], [1 2 3 4 5 6]};
% first vector in the first cell is for subject 1 and for the first task, second vector is for the second task
for i = 1:length(sub_dir)
    run_sel{i} = {[1],[1:12]};
end

% Preprocessing variables
prep_vars = struct();
prep_vars.spm_path = spm_path;
prep_vars.ds_root = ds_root;
prep_vars.src_dir = src_dir;
prep_vars.tgt_dir = tgt_dir;
prep_vars.BIDS_fn_label = BIDS_fn_label;
prep_vars.prep_steps = [];
prep_vars.nslices = 57;
prep_vars.TR = 1.5;
prep_vars.slicetiming = [0, 0.78, 0.0775, 0.8575, 0.1575, 0.935, 0.235, 1.0125,...
    0.3125, 1.09, 0.39, 1.17, 0.4675, 1.2475, 0.545, 1.325,...
    0.625, 1.4025, 0.7025, 0, 0.78, 0.0775, 0.8575, 0.1575,...
    0.935, 0.235, 1.0125, 0.3125, 1.09, 0.39, 1.17, 0.4675,...
    1.2475, 0.545, 1.325, 0.625, 1.4025, 0.7025, 0, 0.78,...
    0.0775, 0.8575, 0.1575, 0.935, 0.235, 1.0125, 0.3125,...
    1.09, 0.39, 1.17, 0.4675, 1.2475, 0.545, 1.325, 0.625, 1.4025, 0.7025];

% Cycle over participants
% -----------------------
for i = 23:numel(sub_dir)
    
    prep_vars.run_sel = run_sel{i};
    
    % Preprocessing object instance
    prep = prepobj(prep_vars);
    
    % generate onsets files from '*_events' files in the 'func' directory
    create_onset_files(prep,sub_dir{i});
    
    % set parameters for GLM
    prefix = 's5nar';
    fir = 0; % no finite impulse response model
    is_loc = 1; % if GLM for localizer should be computed or not
    mparams = 1 ; % do / do not include movement parameters
    tapas_denoise = 0; % do/ do not include tapas noise regressors
    physio = 0 ; % do / do not include physiological variables
    glmdenoise =  0; % do / do not include GLM denoise regressors
    results_dir = fullfile(tgt_dir,sub_dir{i},'results','GLM','localizer');
    if ~isdir(results_dir), mkdir(results_dir); end
    
    % Run GLM for current subject
    matlabbatch = firstlevel(prep,prefix,results_dir,sub_dir{i},mparams,physio,tapas_denoise,glmdenoise,is_loc);
    spm_jobman('run',matlabbatch)
    
    % run contrasts
    if is_loc
        
        % Set contrasts
        clear matlabbatch
        matlabbatch{1}.spm.stats.con.spmmat = {fullfile(results_dir,'SPM.mat')};
        matlabbatch{1}.spm.stats.con.consess{1}.tcon.name = 'objects > scrambled';
        matlabbatch{1}.spm.stats.con.consess{1}.tcon.weights = [0 1 -1];
        matlabbatch{1}.spm.stats.con.consess{2}.tcon.name = 'scrambled > objects';
        matlabbatch{1}.spm.stats.con.consess{2}.tcon.weights = [0 -1 1];
        matlabbatch{1}.spm.stats.con.consess{3}.tcon.name = 'all > baseline';
        matlabbatch{1}.spm.stats.con.consess{3}.tcon.weights = [0 1 1];
        matlabbatch{1}.spm.stats.con.delete = 1 ;
        spm_jobman('run',matlabbatch)
    else
        % Set contrasts
        clear matlabbatch
        contrast_names = {'Photo';'Drawing';'Sketch'};%
        for con = 1:length(contrast_names)
            % first get condition order
            cond_order = get_cond_order(prep,sub_dir{i});
            cond_order(cond_order ~=con) =0;
            cond_order(cond_order==con)=1;
            
            weights = [];
            
            for run = 1:length(cond_order)
                weights = [weights,[ones(1,48),zeros(1,36)]*cond_order(run)];
            end
            matlabbatch{1}.spm.stats.con.spmmat = {fullfile(results_dir,'SPM.mat')};
            matlabbatch{1}.spm.stats.con.consess{con}.tcon.name = contrast_names{con};
            matlabbatch{1}.spm.stats.con.consess{con}.tcon.weights = weights;
        end
        matlabbatch{1}.spm.stats.con.delete = 1 ;
        spm_jobman('run',matlabbatch)
    end
end 
    fprintf('GLM finished\n');