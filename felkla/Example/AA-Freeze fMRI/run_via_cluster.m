clear all; clc;

%--------------------------------------------------------------------------
% All analysis steps for project AA-freeze
%
% all steps that have been applied to the data should be in here so we can
% always go back to the orginal scripts.
%
%LdV2018, adapted by FelKla 2022
%--------------------------------------------------------------------------

%% TIMER
% set a timer to wait for X minutes before starting this batch
t_min = input('Wait x minutes before submitting next job: ');
t_tot = 60*t_min;
fprintf('Waiting %i minutes before submitting next job...\n',t_min);
starttime = tic;
t_elapsed = 0;

while t_elapsed < t_tot
    % wait
    t_elapsed = toc(starttime);
end

%% GENERAL SETTINGS

%path definition
project.mainpath='/project/3023009.03';
project.datapath=fullfile(project.mainpath,'data');
project.analysispath = fullfile(project.mainpath,'scripts','fMRI');

%add paths
addpath(fullfile(project.mainpath,'scripts'));
addpath(fullfile(project.datapath));
addpath(project.analysispath);
addpath('/home/common/matlab/fieldtrip/qsub')

%create folder to dump torque output
torquedir = [project.mainpath,'/scripts/TORQUEJOBS'];
if exist(torquedir, 'dir')
    rmdir(torquedir,'s');
end
mkdir(torquedir);

%subject names
% all included subs:
% {'sub-00x','sub-001','sub-002','sub-004','sub-005','sub-006','sub-007','sub-008','sub-009','sub-010',...
%     'sub-012','sub-014','sub-015','sub-016','sub-017','sub-018','sub-020',...
%     'sub-021','sub-022','sub-023','sub-024','sub-025','sub-026','sub-027','sub-028','sub-030',...
%     'sub-031','sub-032','sub-033','sub-034','sub-036','sub-037','sub-038','sub-039','sub-040',...
%     'sub-041','sub-042','sub-043','sub-044','sub-045','sub-046','sub-047','sub-048','sub-049',...
%     'sub-051','sub-052','sub-053','sub-055','sub-056','sub-057','sub-058','sub-059','sub-060',...
%     'sub-061','sub-062','sub-063','sub-065','sub-066'};

subjname = {'sub-001','sub-002','sub-004','sub-005','sub-006','sub-007','sub-008','sub-009','sub-010',...
    'sub-012','sub-014','sub-015','sub-016','sub-017','sub-018','sub-020',...
    'sub-021','sub-022','sub-023','sub-024','sub-025','sub-026','sub-027','sub-028','sub-030',...
    'sub-031','sub-032','sub-033','sub-034','sub-036','sub-037','sub-038','sub-039','sub-040',...
    'sub-041','sub-042','sub-043','sub-044','sub-045','sub-046','sub-047','sub-048','sub-049',...
    'sub-051','sub-052','sub-053','sub-055','sub-056','sub-057','sub-058','sub-059','sub-060',...
    'sub-061','sub-062','sub-063','sub-065','sub-066'};

% which subjects
subjincl = 1:length(subjname);

%whichtasks
do_preproc = false;
do_frt = true;
do_extra_cons = false;

%factorial or parametric design?
DESIGN = {'basic','factorial','parametric','freezing','FIR'};
DESIGN = DESIGN{5};

% Include RETROICOR regressors? (1=yes, 0=no)
noHRppts = {'sub-003','sub-011'}; % no RETROICOR for these ppts
takeHR = ones(1,length(subjname));
takeHR(ismember(subjname,noHRppts)) = 0;

% for freeze models, indicate the route to be modelled
ROUTES = [1,2,3];
ROUTE = 3;
if strcmp(DESIGN, 'freezing')
    ROUTE = ROUTES(ROUTE);
else 
    ROUTE = [];
end

% for freeze models, are the trialvals generated on sub or group-level?
est_levels = {'sub','group',''};
est_level = est_levels{2};

%% 1. PREPROC
if do_preproc
    
    %loop over subjects
    for c_subj = subjincl
        
        %go to seperate folder to dump job files
        cd(torquedir);
        
        %submit job to cluster
        strname=[subjname{c_subj} '_aafreeze_preproc'];
        qsubfeval(@run_preproc,...
            subjname{c_subj},...            %input number 1
            'memreq',(1024^3)*14,... 
            'timreq', (60*60)*5,...
            'batchid',strname,...
            'diary','always')
        
    end%c_subj
    
    cd(project.mainpath)
    
end%if statement


%% 2. FIRST LEVEL
if do_frt
    
    %loop over subjects
    for c_subj = subjincl
        
        %go to seperate folder to dump job files
        cd(torquedir);
        
        %submit job to cluster
        strname=[subjname{c_subj} '_aafreeze_firstlevel'];
        qsubfeval(@run_firstlevel,...       %function
            subjname{c_subj},...            %input number 1
            DESIGN,...                      %input number 2
            ROUTE,...                       %input number 3
            takeHR(c_subj),...              %input number 4
            est_level,...                   %input number 5
            'memreq',(1024^3)*12,...        %in bytes
            'timreq',(60*60)*1,...
            'batchid',strname,...
            'diary','always',...
            'options', sprintf('-w %s', '/project/3023009.03/scripts/TORQUEJOBS'))
        
    end%c_subj
    
    cd(project.mainpath)
    
end%if statement

%% 3. EXTRA CONS
if do_extra_cons
    
    %loop over subjects
    for c_subj=subjincl
        
        %go to seperate folder to dump job files
        cd(torquedir);
        
        %submit job to cluster
        strname=[subjname{c_subj} '_anger_extra'];
        qsubfeval(@a_anger_task3_extra_cons,...
            subjname{c_subj},...            %input number 1
            'memreq',3000*(1024^2),...
            'timreq',50*60,...
            'batchid',strname,...
            'diary','always')
        
    end%c_subj
    
    cd(project.mainpath)
    
end%if statement