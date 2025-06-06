function a_aafreeze_secondlevel(DESIGN, ROUTE)
% a_aafreeze_secondlevel
% Wrapper function to run the 2nd (group) level statistical analysis
%
% Felix Klaassen 2022

%% Inputs
if ~exist('DESIGN','var')
    DESIGN = input('Please input the model design (''basic'',''factorial'',''parametric'',''hybrid'', ''freezing'', ''FIR''): ');
end
if strcmp(DESIGN, 'freezing') && ~exist('ROUTE','var')
    ROUTE = input('Please indicate which route: 1, 2, or 3: ');
elseif ~exist('ROUTE','var')
    ROUTE = [];
end

%% Copy over subject-level contrasts to a new folder
disp('Copying first-level contrast maps...')
f_aafreeze_movecontrasts(DESIGN, ROUTE);
disp('Done!')

%% Do group-level statistics on the contrast images
disp('Doing second-level statistics...')
f_aafreeze_dostats(DESIGN, ROUTE);

% Done!
disp('Second-level analysis done!')