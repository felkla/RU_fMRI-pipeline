% List of open inputs
nrun = X; % enter the number of runs here
jobfile = {'/project/3023009.03/scripts/fMRI/2_preproc/rm_vols_new_job.m'};
jobs = repmat(jobfile, 1, nrun);
inputs = cell(0, nrun);
for crun = 1:nrun
end
spm('defaults', 'FMRI');
spm_jobman('run', jobs, inputs{:});
