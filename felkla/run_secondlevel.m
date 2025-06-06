function run_secondlevel(DESIGN, ROUTE)
% run_secondlevel
% Wrapper function to run first-level scripts for AA-FREEZE
%
% INPUTS
%   - DESIGN: a string indicating the type of design to do the first level
%   analysis with. Should be either 'basic', 'factorial', 'parametric', or
%   'hybrid'
%
% Felix Klaassen 2022

%% Preparation
%check input
if ~exist('DESIGN','var')
    DESIGN = input('Please input the model design (''basic'',''factorial'',''parametric'',''hybrid'', ''freezing'', or ''FIR''): ');
end
if strcmp(DESIGN, 'freezing') && ~exist('ROUTE','var')
    ROUTE = input('Please indicate which route: 1, 2, or 3: ');
elseif ~exist('ROUTE','var')
    ROUTE = [];
end

%load SPM and its fmri defaults
LoadSPM;

%add firstlevel folder to path
addpath /project/3023009.03/scripts/fMRI/4_secondlevel/

%% Perform group-level analysis
a_aafreeze_secondlevel(DESIGN, ROUTE)

end