function a_anger_task3_firstlevel(SUBJNAME)

%--------------------------------------------------------------------------
%
% perform first level model for ANGER
%
%LdV 2016
%--------------------------------------------------------------------------
    
%get subjname
if ~exist('SUBJNAME')
    SUBJNAME=inputdlg('Which subject?');
    SUBJNAME=SUBJNAME{1};
end

%run conditions
%a_anger_task3_makeconfile(SUBJNAME,2);

%run retroicorspm
if any(strcmp(SUBJNAME,{'sub-014','sub-018','sub-023','sub-026','sub-032'}))
    disp('No retroicor for this participant')
    a_anger_RP(SUBJNAME,3)
else
    a_anger_RETROICORplus(SUBJNAME,3);
end    

% PARAMETERS
%--------------------------------------------------------------------------
%stats path name
statsname='fMRI/task_3';

%load paths
padi=i_anger_infofile(SUBJNAME);

%stats output
statspath=fullfile(padi.stats,statsname,char(SUBJNAME));
if exist(statspath) rmdir(statspath,'s'); end %remove when exists
mkdir(statspath);

% RUN FIRST LEVEL
%--------------------------------------------------------------------------
%load spm batch
if any(strcmp(SUBJNAME,{'sub-014','sub-018','sub-023','sub-026','sub-032'}))
    disp('No retroicor for this participant')
    load f_anger_task3_firstlevel_noret
else
    load f_anger_task3_firstlevel
end    

%replace name
matlabbatch = struct_string_replace(matlabbatch,'sub-002',char(SUBJNAME));

%replace scans
direc_func = ['/project/3017061.01/Anger/work_data/',SUBJNAME,'/func/task_3'];
scans = cfg_getfile('FPList',direc_func,'any','^swu');
matlabbatch{1}.spm.stats.fmri_spec.sess.scans = scans(6:end);

%change outputdir
matlabbatch{1}.spm.stats.fmri_spec.dir = {statspath};

%contrats
run(fullfile('/project/3017061.01/Anger/scripts/Linda/3_firstlevel/i_anger_task3_contrasts.m'));
%run job
spm_jobman('run',matlabbatch);







