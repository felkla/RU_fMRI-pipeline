function LoadSPM()
%LOADSPM Loads SPM12 fMRI defaults

% using this instead of spm_defaults based on help of sp_defaults
spm('Defaults','fmri')

fprintf('SPM12 added to path and fMRI defaults loaded.\n');

end