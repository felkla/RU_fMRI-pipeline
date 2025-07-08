function coregistration(struct_dir, run_filt, run_dir, curr_prefix)
%COREGISTRATION This function runs the coregistration preprocessing step
% 
%   Input
%       struct_dir: Structural directory
%       run_filt: Run filenames filter
%       run_dir: Run directory 
%       curr_prefix: Current prefix
%
%   Output
%       None


warning off

% Select relevant references
file = spm_select('List', struct_dir, '^sub.*\.nii$');
ref = cellstr([struct_dir filesep file ',1']);

% Select relevant sources
file = spm_select('List', run_dir, run_filt);
source = cellstr([run_dir filesep file ',1']);

% Select relevant remaining images
other = cellstr(spm_select('ExtFPList', run_dir, ['^' curr_prefix '.*\.nii$'], Inf));

% Perform coregistration (estimate)
matlabbatch = [];
matlabbatch{1}.spm.spatial.coreg.estimate.ref = ref;
matlabbatch{1}.spm.spatial.coreg.estimate.source = source;
matlabbatch{1}.spm.spatial.coreg.estimate.other = other;
matlabbatch{1}.spm.spatial.coreg.estimate.eoptions.cost_fun = 'nmi';
matlabbatch{1}.spm.spatial.coreg.estimate.eoptions.sep = [4 2];
matlabbatch{1}.spm.spatial.coreg.estimate.eoptions.tol = [0.02 0.02 0.02 0.001 0.001 0.001 0.01 0.01 0.01 0.001 0.001 0.001];
matlabbatch{1}.spm.spatial.coreg.estimate.eoptions.fwhm = [7 7];

% Run job
spm('defaults', 'FMRI');
spm_jobman('run', matlabbatch)
clear jobs

end

