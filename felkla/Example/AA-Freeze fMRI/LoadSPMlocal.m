function LoadSPMlocal()
%LOADSPM Adds local version of SPM12 to path and loads fMRI defaults
% this works both on linux and windows machines at DCCN

if ispc
    % add spm12 to path
    addpath('P:\3023009.03\spm12');
elseif isunix
    addpath('/project/3023009.03/spm12');
else
    error('matlab does not know whether you are using windows or linux')
end

% using this instead of spm_defaults based on help of sp_defaults
spm('Defaults','fmri')

fprintf('SPM12 (local) added to path and fMRI defaults loaded.\n');

end