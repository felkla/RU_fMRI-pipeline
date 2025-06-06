function a_anger_task1_firstlevel(SUBJNAME,takeHR)

%--------------------------------------------------------------------------
%
% perform first level model for ANGER
%
%LdV 2016
%--------------------------------------------------------------------------
    
%get subjname
if ~exist(SUBJNAME,'var')
    subjnr = input('Please input subject number: ');
    if subjnr < 10
        SUBJNAME = ['sub-00' num2str(subjnr)];
    elseif subjnr < 100
        SUBJNAME = ['sub-0' num2str(subjnr)];
    else
        SUBJNAME = ['sub-' num2str(subjnr)];
    end
end

%run conditions
a_anger_task1_makeconfile(SUBJNAME);

%run retroicorspm
if takeHR
    a_anger_RETROICORplus(SUBJNAME,1);
elseif ~takeHR
    a_anger_RP(SUBJNAME,1)
end

% PARAMETERS
%--------------------------------------------------------------------------
%stats path name
statsname='fMRI/task_1';

%load paths
padi=i_aafreeze_infofile(SUBJNAME);

%stats output
statspath=fullfile(padi.stats,statsname,char(SUBJNAME));
if exist(statspath) rmdir(statspath,'s'); end %remove when exists
mkdir(statspath);

% RUN FIRST LEVEL
%--------------------------------------------------------------------------
%load spm batch
load f_anger_task1_firstlevel

%some pp do not have HR
if takeHR==0
    matlabbatch{1}.spm.stats.fmri_spec.sess.multi_reg = {fullfile(padi.func,padi.tasks(2),'log','rp_only.mat')};
end

%replace name
matlabbatch = struct_string_replace(matlabbatch,'sub-001',char(SUBJNAME));

%change outputdir
matlabbatch{1}.spm.stats.fmri_spec.dir = {statspath};

%run job
spm_jobman('run',matlabbatch);
