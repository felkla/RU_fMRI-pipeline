function slicetiming_correction(run_filt, run_dir, slicetiming_prefix,prepobj)
%SLICETIMING_CORRECTION This function runs the slicetiming correction preprocessing step
% 
%   Input
%       run_filt: Run filenames filter
%       run_dir: Run directory 
%       realignment_prefix: Prefix indicating realignment
%
%   Output
%       None

warning off

% File selection
run_files = spm_select('List', run_dir, run_filt); 

% Create SPM style file list for model specification
fileset = getImagingFileset(run_dir, run_files);

clear matlabbatch

matlabbatch{1}.spm.temporal.st.scans{1,1} = fileset';
matlabbatch{1}.spm.temporal.st.nslices = prepobj.nslices;
matlabbatch{1}.spm.temporal.st.tr = prepobj.TR;
slicetiming = prepobj.slicetiming*1000; % we need to multiply the slicetiming here by 1000 because SPM expects the slice timings to be specified in ms and not in s
reference_slice = median(slicetiming); % this variable should be the timing of the reference slice -> here middle slice
matlabbatch{1}.spm.temporal.st.ta = 0; % since we are working with ms inputs and not slice order, this value will not be used and can be set to 0

matlabbatch{1}.spm.temporal.st.so = slicetiming; % specify in ms instead of s 
matlabbatch{1}.spm.temporal.st.refslice = reference_slice;
matlabbatch{1}.spm.temporal.st.prefix = slicetiming_prefix;

% Run job
spm('defaults', 'FMRI');
inputs = cell(0, 1);
spm_jobman('serial', matlabbatch, '', inputs{:});
clear jobs

end
