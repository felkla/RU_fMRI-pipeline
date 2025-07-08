function realignment(run_filt, run_dir, realignment_prefix)
%REALIGNMENT This function runs the realignment preprocessing step
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

% Perform realignment
matlabbatch = [];
matlabbatch{1}.spatial{1}.realign{1}.estwrite.data = {fileset'};
matlabbatch{1}.spatial{1}.realign{1}.estwrite.eoptions.quality = 0.9;
matlabbatch{1}.spatial{1}.realign{1}.estwrite.eoptions.sep = 4;
matlabbatch{1}.spatial{1}.realign{1}.estwrite.eoptions.fwhm = 5;
matlabbatch{1}.spatial{1}.realign{1}.estwrite.eoptions.rtm = 1;
matlabbatch{1}.spatial{1}.realign{1}.estwrite.eoptions.interp = 2;
matlabbatch{1}.spatial{1}.realign{1}.estwrite.eoptions.wrap = [0 0 0];
matlabbatch{1}.spatial{1}.realign{1}.estwrite.eoptions.weight = {''};
matlabbatch{1}.spatial{1}.realign{1}.estwrite.roptions.which = [2 1];
matlabbatch{1}.spatial{1}.realign{1}.estwrite.roptions.interp = 4;
matlabbatch{1}.spatial{1}.realign{1}.estwrite.roptions.wrap = [0 0 0];
matlabbatch{1}.spatial{1}.realign{1}.estwrite.roptions.mask = 1;
matlabbatch{1}.spatial{1}.realign{1}.estwrite.roptions.prefix = realignment_prefix;

% Run job
spm('defaults', 'FMRI');
inputs = cell(0, 1);
spm_jobman('serial', matlabbatch, '', inputs{:});
clear jobs

end

