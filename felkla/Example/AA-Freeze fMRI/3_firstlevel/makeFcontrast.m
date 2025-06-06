% List of open inputs
% Contrast Manager: Select SPM.mat - cfg_files
nrun = X; % enter the number of runs here
jobfile = {'/project/3023009.03/DataAnalysis/fMRI/3_firstlevel/makeFcontrast_job.m'};
jobs = repmat(jobfile, 1, nrun);
inputs = cell(1, nrun);
for crun = 1:nrun
    inputs{1, crun} = MATLAB_CODE_TO_FILL_INPUT; % Contrast Manager: Select SPM.mat - cfg_files
end
spm('defaults', 'FMRI');
spm_jobman('run', jobs, inputs{:});
