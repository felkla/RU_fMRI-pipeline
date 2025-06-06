clear all;
clc;

%--------------------------------------------------------------------------
%
% Run stats
%
%--------------------------------------------------------------------------

%taskname
taskname='task_2';

%paths
padi=i_anger_paths(taskname);

%get dirs
conpaths=dir(fullfile(padi.statspath,'groupstats','T*'));


% RUN ANALYSES
%--------------------------------------------------------------------------

%loop over contrasts for one sample t test
for c_con=1:numel(conpaths)
        
    %load job
    load f_anger_secondlevel
    
    %remove dir if exist then make dir
    outputpath=fullfile(padi.statspath,'groupstats',conpaths(c_con).name,'one_sample_ttest');
    if exist(outputpath) rmdir(outputpath,'s'); end %remove when exists
    mkdir(outputpath);
    
    %get confiles
    conpath=fullfile(padi.statspath,'groupstats',conpaths(c_con).name);
    confiles=cellstr(spm_select('List',conpath,['^.*\.nii']));

    %change input
    matlabbatch{1}.spm.stats.factorial_design.dir = {outputpath};
    matlabbatch{1}.spm.stats.factorial_design.des.t1.scans = ...
        strcat(conpath,filesep,confiles);
    
    %select own spm defaults files [altered threshold]
    %i_spm_defaults
    %> use explicite mask instead!
    
    %run job
    spm_jobman('run',matlabbatch); clear matlabbatch

end