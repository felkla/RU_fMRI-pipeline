function run_firstlevel(SUBJNAME, DESIGN, ROUTE, HR, est_level)
%--------------------------------------------------------------------------
%
% wrapper function to run first-level abalysis for AA-FREEZE project
%
% FelKla 2022
% INPUTS
%   - SUBJNAME: a string containing the name of the subject to be
%   processed. Should be formatted as: 'sub-001', 'sub-010', etc. Can be
%   left empty which enables simply entering the subject NUMBER (1 or 10 in
%   these examples).
%   - DESIGN: a string indicating the type of design to do the first level
%   analysis with. Should be one of 'basic', 'factorial', 'parametric', 'hybrid', or 'freezing'.
%   - HR: a logical or numerical indicating whether to add HR (RETROICOR)
%   as nuissance regressors (yes=1,no=0).
%--------------------------------------------------------------------------

%get subjname
if nargin ~= 5
    subjnr = input('Please input subject number: ');
    if subjnr < 10 || subjnr == 'x'
        SUBJNAME = ['sub-00' num2str(subjnr)];
    elseif subjnr < 100
        SUBJNAME = ['sub-0' num2str(subjnr)];
    else
        SUBJNAME = ['sub-' num2str(subjnr)];
    end
    DESIGN = input('Please input design type (''basic'',''factorial'', ''parametric'', or ''freezing''): ');
    if any(strcmp(DESIGN,{'freezing'}))
        ROUTE = input('Please indicate which route: 1, 2, or 3: ');
        est_level = input('Please input whether model-based estimates are on group-level or subject-level (''group'' or ''sub'') :');
    else
        est_level = '';
        ROUTE = [];
    end
    HR = input('Please indicate if you want to add RETROICOR nuisance regressors (yes=1,no=0): ');
end

% PREPARATION
%--------------------------------------------------------------------------
%load SPM and its fmri defaults
LoadSPM;

%add firstlevel folder to path
addpath /project/3023009.03/scripts/fMRI/3_firstlevel

% PERFORM FIRSTLEVEL ANALYSIS
%--------------------------------------------------------------------------
a_aafreeze_firstlevel(SUBJNAME, DESIGN, ROUTE, HR, est_level)

end