function smoothing(run_filt, run_dir)
%SMOOTHING This function runs the smoothing preprocessing step
% 
%   Input
%       run_filt: Run filenames filter
%       run_dir: Run directory
%
%   Output
%       None

warning off

% select the files
run_files = spm_select('List', run_dir, run_filt);

% Create SPM style file list for model specification
fileset = getImagingFileset(run_dir, run_files);

% Create prefix
kernel_size=[5 5 5];
aa=num2str(unique(kernel_size));
if length(aa)>1
    aa=num2str(kernel_size);
end
smoothing_prefix = ['s' aa(~isspace(aa))];

% Perform smoothing
matlabbatch = [];
matlabbatch{1}.spm.spatial.smooth.data = fileset';
matlabbatch{1}.spm.spatial.smooth.fwhm = kernel_size;
matlabbatch{1}.spm.spatial.smooth.dtype = 0;
matlabbatch{1}.spm.spatial.smooth.im = 0;
matlabbatch{1}.spm.spatial.smooth.prefix = smoothing_prefix;

% Run job
spm('defaults', 'FMRI');
inputs = cell(0, 1);
spm_jobman('serial', matlabbatch, '', inputs{:});
clear jobs

end