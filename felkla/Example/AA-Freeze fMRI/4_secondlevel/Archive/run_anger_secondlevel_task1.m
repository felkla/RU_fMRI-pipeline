clear all; clc;

taskname='task_1';
padi=i_anger_paths(taskname);

% DO ONE SAMPLE ACROSS ALL GROUPS
%------------------------------------------------------------------------------------------------
%move contrasts
%f_anger_movecontrasts_task1

%do the second level stats
%f_anger_dostats_task1

%get contrasts
contrastfolders=dir(fullfile(padi.statspath,'groupstats', 'T_*'));


% MOVE GROUPS
%------------------------------------------------------------------------------------------------

%get IDs
[num,txt,raw] = xlsread('/project/3017061.01/Anger/analysis/GroupID.xlsx') ;
group=txt(2:end,1);
subjID=txt(2:end,3);


%loop over contrasts and move groups to subfolders
for c_con = 1:numel(contrastfolders)
    
     %create dir
    inputfolder=fullfile(padi.statspath,'groupstats',contrastfolders(c_con).name);
    outputfolder1=fullfile(inputfolder,'two_sample_ttest','Patients');
    outputfolder2=fullfile(inputfolder,'two_sample_ttest','Controls');
    if exist(outputfolder1,'dir')
        rmdir(fullfile(inputfolder,'two_sample_ttest'),'s')        
    end
    mkdir(outputfolder1)
    mkdir(outputfolder2)
    
    %loop over subjects
    for c_subj = 1:numel(subjID)
        
        niifile=dir(fullfile(inputfolder,['*' subjID{c_subj} '*']));
        
        if exist(fullfile(inputfolder,niifile.name), 'file') == 2;
            
            if match_str(group(c_subj),'Patient')
                copyfile(...
                    fullfile(inputfolder,niifile.name),...
                    fullfile(outputfolder1,niifile.name)...
                    );
            elseif match_str(group(c_subj),'Control')
                copyfile(...
                    fullfile(inputfolder,niifile.name),...
                    fullfile(outputfolder2,niifile.name)...
                    );
            end
        end
        
    end
    
end

% RUN PAIRED TTESTS
%------------------------------------------------------------------------------------------------

 %loop over contrasts and move groups to subfolders
for c_con = 1:numel(contrastfolders)

    %load the batch
    load f_anger_secondlevel_comparegroups

    %change statsfolder
    outputfolder=fullfile(padi.statspath, 'groupstats',contrastfolders(c_con).name,'two_sample_ttest');
    matlabbatch{1}.spm.stats.factorial_design.dir = {outputfolder};
    
      
    %find subjects nii gr1
    gr1files=cellstr(spm_select('List',fullfile(outputfolder,'Patients'),['^.*\.nii']));
    matlabbatch{1}.spm.stats.factorial_design.des.t2.scans1 = ...
        strcat(fullfile(outputfolder,'Patients'),filesep,gr1files);
    
    %find subjects nii gr2
    gr2files=cellstr(spm_select('List',fullfile(outputfolder,'Controls'),['^.*\.nii']));
    matlabbatch{1}.spm.stats.factorial_design.des.t2.scans2 = ...
        strcat(fullfile(outputfolder,'Controls'),filesep,gr2files);
    
    %run job
    spm_jobman('run',matlabbatch); clear matlabbatch
    
end
    
    