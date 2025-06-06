function run_RETROICOR(SUBJNR, stage)
%% Description
%   Master script to run RETROICOR. Accepts input arguments SUBJNR (subject
%   nr) and 'stage' (should be ''prep'' (1),''hera'' (2), or ''create'' (3)).

% Felix Klaassen, 2021

%% Preparation
% Get input
if ~exist('SUBJNR','var')
    SUBJNR = input('Please input subject number: ');
end
if ~exist('stage','var')
    stage = input('Please input which processing stage to do (''prep'' (1),''hera'' (2), or ''create''(3)): ');
end

% get subjname
if SUBJNR < 10 || SUBJNR == 'x'
    SUBJNAME = ['sub-00' num2str(SUBJNR)];
elseif SUBJNR < 100
    SUBJNAME = ['sub-0' num2str(SUBJNR)];
else
    SUBJNAME = ['sub-' num2str(SUBJNR)];
end

% Set paths
addpath 1_RETROICOR
padi = i_aafreeze_infofile(SUBJNAME);

%% Run stages
switch stage
    case {'prep', 1}
        % Run preparation of physiological data: convert to HERA and
        % Autonomate-compatible formats
        a_aafreeze_RETROICOR_prep(SUBJNR,padi);
        
    case {'hera', 2}
        % Run HERA to do artifact correction of HR data
        a_aafreeze_RETROICOR_hera(padi);
        
    case {'create', 3}
        % Run RETROICOR algorithm to create R-regressors for 1st lvl fMRI
        check_runs = input('Have you done the artifact correction for ALL 3 runs? (yes=1, no=0): ');
        if check_runs
            a_aafreeze_RETROICOR_create(SUBJNR,padi);
        else
            return
        end
        
    otherwise
        warning('Input not recognized. Aborting function...');
end
        

end

