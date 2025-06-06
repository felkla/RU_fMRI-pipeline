clear all;
clc;

%--------------------------------------------------------------------------
%
% all analysis steps for project ANGER
%
% all steps that have been applied to the data should be in here so we can
% always go back to the orginal scripts.
%
%LdV2018
%--------------------------------------------------------------------------

%GENERAL SETTINGS

%path defenition
project.mainpath='/project/3017061.01/Anger';
project.datapath=fullfile(project.mainpath,'data');

%add scripts path
addpath(genpath(fullfile(project.mainpath,'scripts','Linda')));
run('/project/3017061.01/Anger/scripts/AAT analysis/paths_AAT_analysis');
addpath('/home/common/matlab/fieldtrip/qsub')

%subject names
%subjname = {'sub-018',    
%    'sub-019', 'sub-020', 'sub-021', 'sub-023', 'sub-024', 'sub-025', 'sub-026', ...
%    'sub-027', 'sub-028', 'sub-029', 'sub-030', 'sub-031', 'sub-032', 'sub-033', 'sub-034', ...
%    'sub-035', 'sub-036', 'sub-037', 'sub-038', 'sub-039', 'sub-040', 'sub-041', 'sub-042', ...
%    'sub-043', 'sub-044', 'sub-045', 'sub-046', 'sub-047'};
subjname={'sub-002','sub-003','sub-004','sub-005','sub-006','sub-007','sub-008','sub-009','sub-010', ...
     'sub-012','sub-013','sub-015','sub-016','sub-017','sub-018', ...   
     'sub-019','sub-020','sub-021','sub-023','sub-024','sub-025', 'sub-026', ...
     'sub-027','sub-028','sub-029','sub-030','sub-031','sub-032', 'sub-033', 'sub-034', ...
     'sub-035','sub-037','sub-039','sub-040','sub-041', 'sub-042', ...
     'sub-043','sub-044','sub-045','sub-046','sub-047'};
% subjname={...
%     'sub-022',...
%     'sub-023','sub-024','sub-025','sub-026','sub-027',...
%     'sub-028','sub-029','sub-030','sub-031','sub-032',...
%     'sub-033','sub-034','sub-035','sub-036','sub-037',...
%     'sub-040','sub-041','sub-042',...
%     'sub-043','sub-045','sub-046','sub-047',...
%     'sub-038','sub-039','sub-040',...
%     };
%which subjects
%subjincl=[2:47];
subjincl = 25:length(subjname);

%whichtasks
do_2dn=0;
do_preproc=0;
do_frt=1;
do_extra_cons=0;



%% 1. DICOM TO NIFTII
if do_2dn==1;
    
    %loop over subjects
    for c_subj=subjincl
        
        %go to seperate folder to dump job files
        cd /project/3017061.01/Anger/scripts/TORQUEJOBS
        
        %submit job to cluster
        strname=[subjname{c_subj} '_anger_d2n'];
        qsubfeval(@a_d2n,...
            subjname{c_subj},...            %input number 1
            'memreq',3000*(1024^2),...
            'timreq',500*60,...
            'batchid',strname,...
            'diary','always')
        
    end%c_subj
    
end%if statement


%% 2. PREPROC
if do_preproc==1;
    
    %loop over subjects
    for c_subj=subjincl
        
        %go to seperate folder to dump job files
        cd /project/3017061.01/Anger/scripts/TORQUEJOBS
        
        %submit job to cluster
        strname=[subjname{c_subj} '_anger_preproc'];
        qsubfeval(@a_anger_preproc,...
            subjname{c_subj},...            %input number 1
            'memreq',3000*(1024^2),...
            'timreq',1000*60,...
            'batchid',strname,...
            'diary','always')
        
    end%c_subj
    
end%if statement

%% 3. FIRST LEVEL
if do_frt==1;
    
    %loop over subjects
    for c_subj=subjincl
        
        %go to seperate folder to dump job files
        cd /project/3017061.01/Anger/scripts/TORQUEJOBS
        
        %submit job to cluster
        strname=[subjname{c_subj} '_anger'];
        qsubfeval(@a_anger_task2_firstlevel,...
            subjname{c_subj},...            %input number 1
            'memreq',3000*(1024^2),...
            'timreq',500*60,...
            'batchid',strname,...
            'diary','always')
        
    end%c_subj
    
end%if statement

%% 4. EXTRA CONS
if do_extra_cons==1
    
    %loop over subjects
    for c_subj=subjincl
        
        %go to seperate folder to dump job files
        cd /project/3017061.01/Anger/scripts/TORQUEJOBS
        
        %submit job to cluster
        strname=[subjname{c_subj} '_anger_extra'];
        qsubfeval(@a_anger_task3_extra_cons,...
            subjname{c_subj},...            %input number 1
            'memreq',3000*(1024^2),...
            'timreq',50*60,...
            'batchid',strname,...
            'diary','always')
        
    end%c_subj
    
end%if statement