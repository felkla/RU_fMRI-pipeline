function a_aafreeze_RETROICOR_create(SUBJNR,padi)
%% Description
% Runs RETROICOR scripts to create RETROICOR regressors for fMRI analysis.
% NOTE: Since this script loops over all runs, make sure to have performed
% all previous steps (i.e. prep and hera) for *all runs* before proceeding.
%
% CREDIT:
% Wrapper function by Felix Klaassen, 2021
% BAC & HERA scripts by Erno Hermans & Linda de Voogd
% See Glover, Li, & Ress (2000) for the original paper on RETROICOR

%% Input
if ~exist('SUBJNR','var')
    SUBJNR = input('Please input subject number: ');
end
if SUBJNR < 10
    SUBJNAME = ['sub-00' num2str(SUBJNR)];
elseif SUBJNR < 100
    SUBJNAME = ['sub-0' num2str(SUBJNR)];
else
    SUBJNAME = ['sub-' num2str(SUBJNR)];
end

%% Settings
warmupscans = 5; % hard coded because it's the same for every subject

%% Run RETROICOR for each run
for r = 1:numel(padi.tasks)
    % create output folder
    if ~exist([padi.hera,filesep,'RETROICOR'],'dir')
        mkdir([padi.hera,filesep,'RETROICOR']);
    end
    
    % Get file
    subfiles = dir([padi.hera,filesep,'*run_',num2str(r),'*_hera.mat']);
    subfile = [subfiles.folder,filesep,subfiles.name];
    
    % Run RETROICOR
    addpath(['1_RETROICOR' filesep 'Tools']);
    R = RETROICORplus(subfile,warmupscans,0);
    
    % check nr of volumes for run (except for a few exceptions)
    if ~ismember(SUBJNR, padi.incompl_subs)
    assert(size(R,1) == 719, ... % hard coded because it's the same for every subject
        'Number of volumes does not equal 719. Check nr. of warm-up scans and nr. of volumes in the raw data.');
    end
    
    % save file
    save([padi.hera,filesep,'RETROICOR',filesep,['R_run-',num2str(r),'.mat']],'R');
end
end