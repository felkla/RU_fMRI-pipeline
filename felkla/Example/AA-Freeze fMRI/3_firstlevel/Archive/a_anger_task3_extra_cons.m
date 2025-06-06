function a_anger_task3_extra_cons(SUBJNAME)

% PARAMETERS
%--------------------------------------------------------------------------
%stats path name
statsname='fMRI/task_3';

%load paths
padi=i_anger_infofile(SUBJNAME);

%stats output
statspath=fullfile(padi.stats,statsname,char(SUBJNAME));

%load spm batch
load f_anger_task3_extra_cons

matlabbatch{1}.spm.stats.con.spmmat = {fullfile(statspath,'SPM.mat')};

%contrasts
run(fullfile('/project/3017061.01/Anger/scripts/Linda/3_firstlevel/i_anger_task3_extra_cons.m'));

%run job
spm_jobman('run',matlabbatch);