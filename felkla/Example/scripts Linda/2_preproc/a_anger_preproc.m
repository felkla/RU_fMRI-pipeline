function a_anger_preproc(subjname)

%--------------------------------------------------------------------------
%
% perform preproc steps for ANGER
%
%LdV 2016
%--------------------------------------------------------------------------

%get subjname
if ~exist('subjname')
    subjname=inputdlg('Which subject?');
end

% PARAMETERS
%--------------------------------------------------------------------------
%load paths
padi=i_anger_infofile(subjname);


% GET FILES
%--------------------------------------------------------------------------

%get func files [task_3 differs across runs]
for c_tsk=1:numel(padi.tasks)
    funcfiles{c_tsk}=dir(fullfile(padi.func,padi.tasks{c_tsk},'sub*.nii'));
end

%task 1 and 2 are fixed, check this
if numel(funcfiles{1})~=658; error('task 1 does not have 658 nii files'); end;
if numel(funcfiles{2})~=809; error('task 2 does not have 809 nii files'); end;


% LOAD BATCH - NATIVE SPACE
%--------------------------------------------------------------------------
load f_anger_preproc

%change subject code
matlabbatch = struct_string_replace(matlabbatch,'sub-004',char(subjname));

%change func files
for c_tsk=1:numel(padi.tasks)
    matlabbatch{2}.spm.spatial.realignunwarp.data(c_tsk).scans = ...
        cellstr(strcat(fullfile(padi.func,padi.tasks{c_tsk}),...
        '/',char(funcfiles{c_tsk}.name)));
end

%run batch
spm_jobman('run',matlabbatch);

% REORGANIZE AND CLEAN UP
%--------------------------------------------------------------------------

%tsnr image
a_anger_cnr_tsnr(subjname)

%move mean image
mkdir(fullfile(padi.struc,'meanEPI'));
movefile(...
    fullfile(padi.func,padi.tasks{1},['meanu',char(subjname),'_0001.nii']),...
    fullfile(padi.struc,'meanEPI',['meanu',char(subjname),'.nii']));
movefile(...
    fullfile(padi.func,padi.tasks{1},['wmeanu',char(subjname),'_0001.nii']),...
    fullfile(padi.struc,'meanEPI',['wmeanu',char(subjname),'.nii']));
movefile(...
    fullfile(padi.func,padi.tasks{1},['swmeanu',char(subjname),'_0001.nii']),...
    fullfile(padi.struc,'meanEPI',['swmeanu',char(subjname),'.nii']));

%move R
for c_tsk=1:numel(padi.tasks)
    mkdir(fullfile(padi.func,padi.tasks{c_tsk},'log'));
    movefile(...
        fullfile(padi.func,padi.tasks{c_tsk},['rp_',char(subjname),'_0001.txt']),...
        fullfile(padi.func,padi.tasks{c_tsk},'log',['rp_',char(subjname),'_0001.txt']));
end

%remove orig nii + 'u' + 'wu' files [to save space and we do not need these]
rmstr={'sub*.nii','usub*.nii','wusub*.nii'};

%loop over files to be deleted
for c_str=1:numel(rmstr);
    
    %loop over tasks
    for c_tsk=1:numel(padi.tasks)
        
        %get files
        funcfiles{c_tsk}=dir(fullfile(padi.func,padi.tasks{c_tsk},rmstr{c_str}));
        
        funcfiles{c_tsk}=cellstr(strcat(fullfile(padi.func,padi.tasks{c_tsk}),...
        '/',char(funcfiles{c_tsk}.name)));
        
        %loop over files to delete them
        for c_files=1:numel(funcfiles{c_tsk});
            delete(char(funcfiles{c_tsk}(c_files)));
        end
    end
end