function normalization(struct_dir, run_filt, run_dir, norm_prefix)
%NORMALIZATION This function runs the normalization preprocessing step
% 
%   Input
%       struct_dir: Structural directory
%       run_filt: Run filenames filter
%       run_dir: Run directory 
%       norm_prefix: Normalization prefix
%
%   Output
%       None


warning off

% Get parameter file
struct_files = spm_select('List', struct_dir, '^y.*\.nii$');
def = cellstr([struct_dir filesep struct_files ]);

% File selection
run_files = spm_select('List', run_dir, run_filt);

% Create SPM style file list for model specification
fileset = getImagingFileset(run_dir, run_files);

% Voxel size in mm
vox_size = [3 3 3]; 

% Perform normalization
matlabbatch = [];
matlabbatch{1}.spm.spatial.normalise.write.subj.def = def;
matlabbatch{1}.spm.spatial.normalise.write.subj.resample = fileset';
matlabbatch{1}.spm.spatial.normalise.write.woptions.bb = [-78 -112 -70;78 76 85];
matlabbatch{1}.spm.spatial.normalise.write.woptions.vox = vox_size;
matlabbatch{1}.spm.spatial.normalise.write.woptions.interp = 4;
matlabbatch{1}.spm.spatial.normalise.write.woptions.prefix = norm_prefix;

% Run job
spm('defaults','fmri');
spm_jobman('initcfg');
spm_jobman('run', matlabbatch)
clear jobs

end
