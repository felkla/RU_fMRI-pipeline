function run_preproc(subjname)
%--------------------------------------------------------------------------
%
% wrapper function to run preproc scripts for AA-FREEZE
%
% FelKla 2021
%--------------------------------------------------------------------------

%get subjname
if nargin == 0
    subjnr = input('Please input subject number: ');
    if subjnr < 10
        subjname = ['sub-00' num2str(subjnr)];
    elseif subjnr < 100
        subjname = ['sub-0' num2str(subjnr)];
    else
        subjname = ['sub-' num2str(subjnr)];
    end
end

% PREPARATION
%--------------------------------------------------------------------------
%load SPM
run LoadSPM

%add preproc folder to path
addpath /project/3023009.03/scripts/fMRI/2_preproc

% PERFORM PREPROCESSING
%--------------------------------------------------------------------------
a_aafreeze_preproc(subjname)


end