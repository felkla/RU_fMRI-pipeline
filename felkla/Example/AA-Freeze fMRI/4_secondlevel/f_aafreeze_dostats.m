function f_aafreeze_dostats(DESIGN, ROUTE)
% f_aafreeze_dostats
% Function to run group-level statistics on contrast images
%
% Felix Klaassen 2022

%% Preparation
%input
if ~exist('DESIGN','var')
    DESIGN = input('Please input the model design (''basic'',''factorial'',''parametric'', ''hybrid'', ''freezing'', or ''FIR''): ');
end
if strcmp(DESIGN, 'freezing') && ~exist('ROUTE','var')
    ROUTE = input('Please indicate which route: 1, 2, or 3: ');
elseif ~exist('ROUTE','var')
    ROUTE = [];
end

%paths
padi = i_aafreeze_paths(DESIGN, ROUTE);

%get dirs
conpaths = dir(fullfile(padi.statspath,'groupstats','T*'));

%% Run analyses
%loop over contrasts for one sample t test
for c_con = 1:numel(conpaths)
        
    %load job
    load f_aafreeze_secondlevel
    
    %remove dir if exist then re-make dir
    outputpath = fullfile(padi.statspath,'groupstats',conpaths(c_con).name,'one_sample_ttest');
    if exist(outputpath,'dir'); rmdir(outputpath,'s'); end %remove when exists
    mkdir(outputpath);
    
    %get confiles
    conpath=fullfile(padi.statspath,'groupstats',conpaths(c_con).name);
    confiles=cellstr(spm_select('List',conpath,['^.*\.nii']));

    %change input
    matlabbatch{1}.spm.stats.factorial_design.dir = cellstr(outputpath);
    matlabbatch{1}.spm.stats.factorial_design.des.t1.scans = ...
        strcat(conpath,filesep,confiles);
    
    %select own spm defaults files [altered threshold]
    %i_spm_defaults
    %> use explicit mask instead!
    
    %run job
    spm_jobman('run',matlabbatch); clear matlabbatch

end