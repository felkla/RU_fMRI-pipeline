function a_aafreeze_preproc(subjname)

%--------------------------------------------------------------------------
%
% perform preproc steps for AA-FREEZE
%
%LdV 2016, adapted by FelKla 2020
%--------------------------------------------------------------------------

%get subjname
if nargin == 0
    subjnr = input('Please input subject number: ');
    if subjnr < 10 || subjnr == 'x'
        subjname = ['sub-00' num2str(subjnr)];
    elseif subjnr < 100
        subjname = ['sub-0' num2str(subjnr)];
    else
        subjname = ['sub-' num2str(subjnr)];
    end
end

if ~exist('subjnr','var')
    subjnr = str2double(subjname(end-2:end));
end

% PARAMETERS
%--------------------------------------------------------------------------
% Set whether to back-up 'sub' files for debugging
backup = false;

% nr. of warm-up volumes
nrWarmup = 5;

%load paths and settings
padi = i_aafreeze_infofile(subjname);

if subjnr == padi.incompl_subs(1)
    padi.tasks = padi.tasks(1:2);
end


% GET FILES
%--------------------------------------------------------------------------

%get func files
for c_tsk=1:numel(padi.tasks)
    funcfiles{c_tsk}=dir(fullfile(padi.func,['sub*',padi.tasks{c_tsk},'*bold.nii']));
end

% nr. of volumes per run is fixed, check the numbers!
for r = 1:numel(padi.tasks)
    ims_temp = spm_select('expand', fullfile(funcfiles{r}.folder,funcfiles{r}.name));
    if size(ims_temp,1) ~= 724 && ~ismember(subjnr, padi.incompl_subs(2))
        warning(['run ', num2str(r),' does not have 724 nii files'])
        cont_check = input('Continue with run or cancel? (1 = continue, 0 = cancel):');
        if cont_check == 1
            continue
        else
            return
        end
    end
end

nr_ims = size(ims_temp,1); clear ims_temp

% REMOVE WARM-UP SCANS
%--------------------------------------------------------------------------
run('rm_vols_new_batch.m')

nr_ims_c = numel(matlabbatch{1}.spm.util.cat.vols);

if ~ismember(subjnr, padi.incompl_subs)
    if nr_ims_c ~= (nr_ims - nrWarmup)
        error(['The number of scans removed from the full run (',...
            num2str(nr_ims),' - ',num2str(nr_ims_c),' = ',...
            num2str(nr_ims-nr_ims_c),...
            ') does not match the indicated number of warm-up volumes (',num2str(nrWarmup),').',...
            ' Consider changing the number of warm-up volumes indicated in the preprocessing script,'...
            ' or update the ''rm_vols_job'' script.']);
    end
end

if backup % only for debugging
    warning('Please note that ''backup'' was set to ''true'', which may slow down the pre-processing...');
    %create a temporary back-up of the original files (for debugging purposes)
    if ~exist(fullfile(padi.func, 'temp'),'dir')
        mkdir(fullfile(padi.func, 'temp'));
    end
    for crun = 1:numel(padi.tasks)
        copyfile(fullfile(funcfiles{crun}.folder,funcfiles{crun}.name), fullfile(padi.func, 'temp'));
    end
end

%change subject code
matlabbatch = struct_string_replace(matlabbatch,'sub-001',char(subjname));

%loop over runs
nrun = numel(padi.tasks);
for crun = 1:nrun
    %change run number per job
    matlabbatch_job = struct_string_replace(matlabbatch,'run-1',padi.tasks{crun});
    
    %run batch
    spm_jobman('run', matlabbatch_job);
end

% clear batch file before continuing
clearvars matlabbatch matlabbatch_job

% RUN PRE-PROCESSING
%--------------------------------------------------------------------------
if numel(padi.tasks) == 2 % this participant only has 2 runs
    load('f_aafreeze_preproc_2ses')
else
    load('f_aafreeze_preproc') % load standard batch
end

%change subject code
matlabbatch = struct_string_replace(matlabbatch,'sub-001',char(subjname));

% change smoothing kernel?
matlabbatch{5}.spm.spatial.smooth.fwhm = [5 5 5]; % default 5

%run batch
spm_jobman('run',matlabbatch);

% REORGANIZE AND CLEAN UP
%--------------------------------------------------------------------------

%tSNR image
a_aafreeze_cnr_tsnr(subjname) % note that std calculation seems off. See 'a_telos_cnr_tsnr.m' for correction

%move mean image
mkdir(fullfile(padi.anat,'meanEPI'));
movefile(...
    fullfile(padi.func,['meanuc',char(subjname),'_task-PAT_run-1_bold.nii']),...
    fullfile(padi.anat,'meanEPI',['meanuc',char(subjname),'.nii']));
movefile(...
    fullfile(padi.func,['wmeanuc',char(subjname),'_task-PAT_run-1_bold.nii']),...
    fullfile(padi.anat,'meanEPI',['wmeanuc',char(subjname),'.nii']));
movefile(...
    fullfile(padi.func,['swmeanuc',char(subjname),'_task-PAT_run-1_bold.nii']),...
    fullfile(padi.anat,'meanEPI',['swmeanuc',char(subjname),'.nii']));

%move R
mkdir(fullfile(padi.func,'log'));
for c_tsk=1:numel(padi.tasks)
    movefile(...
        fullfile(padi.func,['rp_c',char(subjname),'_task-PAT_run-',num2str(c_tsk),'_bold.txt']),...
        fullfile(padi.func,'log',['rp_',char(subjname),'_task-PAT_run-',num2str(c_tsk),'_bold.txt']));
end

%remove orig nii + 'c' + 'uc' + 'wuc' files [to save space and we do not need these]
rmstr={'csub*.nii','ucsub*.nii','wucsub*.nii','csub*.mat','ucsub*.mat','wucsub*.mat'};

%loop over files to be deleted
for c_str=1:numel(rmstr)
    
    %loop over tasks
    for c_tsk=1:numel(padi.tasks)
        
        %get files
        funcfiles{c_tsk}=dir(fullfile(padi.func,rmstr{c_str}));
        
        funcfiles{c_tsk}=cellstr(strcat(padi.func,...
        '/',char(funcfiles{c_tsk}.name)));
        
        %loop over files to delete them
        for c_files=1:numel(funcfiles{c_tsk})
            delete(char(funcfiles{c_tsk}(c_files)));
        end
    end
end

%finally, remove back-up niftii's if present
if exist(fullfile(padi.func,'temp'),'dir')
    rmdir(fullfile(padi.func, 'temp'),'s');
end