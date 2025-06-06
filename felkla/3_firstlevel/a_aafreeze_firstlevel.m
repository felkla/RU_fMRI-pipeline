function a_aafreeze_firstlevel(SUBJNAME,DESIGN, ROUTE, takeHR, est_level)

%--------------------------------------------------------------------------
%
% perform first level model estimation for aa-freeze
%
%LdV 2016, adapted by FelKla 2020
%--------------------------------------------------------------------------

%get subjname
if ~exist('SUBJNAME','var')
    subjnr = input('Please input subject number: ');
    if subjnr < 10 || subjnr == 'x'
        SUBJNAME = ['sub-00' num2str(subjnr)];
    elseif subjnr < 100
        SUBJNAME = ['sub-0' num2str(subjnr)];
    else
        SUBJNAME = ['sub-' num2str(subjnr)];
    end
end

%get info which model to run
if ~exist('DESIGN','var')
    DESIGN = input('Please input design type (''basic'', ''factorial'', ''parametric'', ''freezing'', or ''FIR''): ');
end
if strcmp(DESIGN,'freezing') 
    if ~exist('ROUTE','var')
        ROUTE = input('Please indicate which route: 1, 2, or 3: ');
    end
    if ~exist('est_level','var')
        est_level = input('Please input whether model-based estimates are on group-level or subject-level (''group'' or ''sub'') :');
    end
else
    ROUTE = [];
    est_level = '';
end

%use HR as nuisance regressor?
if ~exist('takeHR','var')
    takeHR = input('Take HR along as nuisance regressor? (no=0, yes=1): ');
    if takeHR ~= 0 && takeHR ~= 1
        error('HR input must be 0 or 1');
    end
end

%load paths
padi = i_aafreeze_infofile(SUBJNAME);

%run conditions
a_aafreeze_makeconfile(SUBJNAME, DESIGN, ROUTE, est_level);

%run retroicorspm
for c_run = 1:numel(padi.tasks)
    if takeHR
        a_aafreeze_RETROICORplus(SUBJNAME,c_run,padi);
    elseif ~takeHR
        a_aafreeze_RP(SUBJNAME,c_run,padi)
    end
end

% PARAMETERS
%--------------------------------------------------------------------------

%stats output
if strcmp(DESIGN,'freezing')
    statspath = fullfile(padi.stats,DESIGN,['R' num2str(ROUTE)],char(SUBJNAME));
else
    statspath = fullfile(padi.stats,DESIGN,char(SUBJNAME));
end
if exist(statspath,'dir'); rmdir(statspath,'s'); end %remove when exists
mkdir(statspath);

% RUN FIRST LEVEL
%--------------------------------------------------------------------------
%load spm batch
if strcmp(DESIGN,'basic')
    load f_aafreeze_firstlevel_basic.mat
    
elseif strcmp(DESIGN,'factorial')
    if any(strcmp(SUBJNAME,padi.tworuns))
        load f_aafreeze_firstlevel_tworuns.mat
    else
        load f_aafreeze_firstlevel.mat
    end

elseif strcmp(DESIGN,'hybrid')
    if any(strcmp(SUBJNAME,padi.tworuns))
        load f_aafreeze_firstlevel_hybrid_tworuns.mat
    else
        load f_aafreeze_firstlevel_hybrid.mat
    end

elseif strcmp(DESIGN,'parametric')
    if any(strcmp(SUBJNAME,padi.tworuns))
        load f_aafreeze_firstlevel_pmod_tworuns.mat
    else
        load f_aafreeze_firstlevel_pmod.mat
    end   
    
elseif strcmp(DESIGN,'freezing')
    if any(strcmp(SUBJNAME,padi.tworuns))
        load f_aafreeze_firstlevel_freezing_tworuns.mat
    else
        load f_aafreeze_firstlevel_freezing.mat
    end

elseif strcmp(DESIGN,'FIR')
    if any(strcmp(SUBJNAME,padi.tworuns))
        load f_aafreeze_firstlevel_FIR_tworuns.mat
    else
        load f_aafreeze_firstlevel_FIR.mat
    end
end

%some pp do not have HR
for c_run = 1:numel(padi.tasks)
    if takeHR==0
        matlabbatch{1}.spm.stats.fmri_spec.sess(c_run).multi_reg = cellstr(fullfile(padi.func,'log',['rp_only_run-',num2str(padi.runnrs(c_run)),'.mat']));
    else
        matlabbatch{1}.spm.stats.fmri_spec.sess(c_run).multi_reg = cellstr(fullfile(padi.func,'log',['allnuisanceregs_run-',num2str(padi.runnrs(c_run)),'.mat']));
    end
end

%replace subject name
matlabbatch = struct_string_replace(matlabbatch,'sub-001',char(SUBJNAME));

% replace correct run nrs for ppts with only 2 runs
if any(strcmp(SUBJNAME, padi.tworuns))
    for i = 1:numel(matlabbatch{1}.spm.stats.fmri_spec.sess)
        matlabbatch{1}.spm.stats.fmri_spec.sess(i) = struct_string_replace(matlabbatch{1}.spm.stats.fmri_spec.sess(i),['run-' num2str(i)],padi.tasks{i});
    end
end

% add RETROICOR F-contrast if applicable/possible
if takeHR && ~strcmp(DESIGN,'FIR')
    matlabbatch{3}.spm.stats.con.consess{end+1}.fcon.name = 'HR';
    
    % determine the amount of zero-padding necessary for the contrast
    % (i.e., the number of regressors *preceding* the RETROICOR)
    if strcmp(DESIGN, 'factorial')
        padding = zeros(10,11);
        
    elseif strcmp(DESIGN, 'hybrid')
        padding = zeros(10,13);
    
    elseif strcmp(DESIGN, 'parametric')
        padding = zeros(10,13);
        
    elseif any(strcmp(DESIGN,{'freezing'}))
        padding = zeros(10,13); % was 10

    end
    
    % F-contrast (for the first 10 cardiac-phase regressors)
    HRweights = eye(10);
    
    % add to batch
    matlabbatch{3}.spm.stats.con.consess{end}.fcon.weights = [padding HRweights];
    matlabbatch{3}.spm.stats.con.consess{end}.fcon.sessrep = 'replsc';
    matlabbatch{3}.spm.stats.con.delete = 0;
end

%change outputdir
matlabbatch{1}.spm.stats.fmri_spec.dir = {statspath};

%run job
spm_jobman('run',matlabbatch);
