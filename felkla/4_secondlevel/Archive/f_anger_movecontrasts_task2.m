clear all;
clc;

%--------------------------------------------------------------------------
%
% Move contrast images
%
%--------------------------------------------------------------------------

%taskname
taskname='task_2';

%paths
padi=i_anger_paths(taskname);

%load first level batch to get the contrast names
run('/project/3017061.01/Anger/scripts/Linda/3_firstlevel/i_anger_task2_contrasts.m')

%make dir
warning off;mkdir(padi.savepath);warning on;


%loop over contrast to extract the name
contrastnames=[];
for c_con=1:numel(matlabbatch{3}.spm.stats.con.consess)
    
    if isfield(matlabbatch{3}.spm.stats.con.consess{c_con},'tcon')
        conname=matlabbatch{3}.spm.stats.con.consess{c_con}.tcon.name;
        contrastnames{c_con}=['T_',conname];
    elseif isfield(matlabbatch{3}.spm.stats.con.consess{c_con},'fcon')
        conname=matlabbatch{3}.spm.stats.con.consess{c_con}.fcon.name;
        contrastnames{c_con}=['F_',conname];
    end
    
end

%get files
subjdirs=dir(fullfile(padi.statspath,padi.subjcode));

%loop over subjects
for ss=1:numel(subjdirs)
    
    %get contrast images
    con_nii=dir(fullfile(padi.statspath,subjdirs(ss).name,'con*.nii'));
    
    %loop over contrasts
    for c_con=1:numel(con_nii)
        
        %make dir
        warning off;mkdir(fullfile(padi.savepath,contrastnames{c_con}));warning on;
        
        %copy file
        copyfile(...
            fullfile(padi.statspath,subjdirs(ss).name,con_nii(c_con).name),...
            fullfile(padi.savepath,contrastnames{c_con},...
            strcat(subjdirs(ss).name,'_',con_nii(c_con).name))...
            );        
        
    end
    
end