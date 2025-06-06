function a_anger_task2_firstlevel(SUBJNAME,takeHR)

%--------------------------------------------------------------------------
%
% perform first level model for ANGER
%
%LdV 2016
%--------------------------------------------------------------------------
    
%get subjname
if ~exist('SUBJNAME')
    SUBJNAME=inputdlg('Which subject?');
end

%run conditions
a_anger_task2_makeconfile(SUBJNAME,2);

%run retroicorspm
if takeHR
    a_anger_RETROICORplus(SUBJNAME,2);
elseif ~takeHR
    a_anger_RP(SUBJNAME,2)
end

% PARAMETERS
%--------------------------------------------------------------------------
%stats path name
statsname='fMRI/task_2';

%load paths
padi=i_anger_infofile(SUBJNAME);

%stats output
statspath=fullfile(padi.stats,statsname,char(SUBJNAME));
if exist(statspath) rmdir(statspath,'s'); end;%remove when exists
mkdir(statspath);

% RUN FIRST LEVEL
%--------------------------------------------------------------------------
%load spm batch
load f_anger_task2_firstlevel

%some pp do not have HR
if ~takeHR;
    matlabbatch{1}.spm.stats.fmri_spec.sess.multi_reg = {fullfile(padi.func,padi.tasks{2},'log','rp_only.mat')};
end

%replace name
matlabbatch = struct_string_replace(matlabbatch,'sub-002',char(SUBJNAME));

%change outputdir
matlabbatch{1}.spm.stats.fmri_spec.dir = {statspath};

%contrats
run(fullfile('/project/3017061.01/Anger/scripts/Linda/3_firstlevel/i_anger_task2_contrasts.m'));

%run job
spm_jobman('run',matlabbatch);
