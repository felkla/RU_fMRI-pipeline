function padi = i_aafreeze_infofile(subjname)

if ~exist('subjname','var')
    subjnr = input('Please input subject number: ');
    if subjnr < 10
        subjname = ['sub-00' num2str(subjnr)];
    elseif subjnr < 100
        subjname = ['sub-0' num2str(subjnr)];
    else
        subjname = ['sub-' num2str(subjnr)];
    end
end

% my paths
if ispc
    padi.main = fullfile(...
        'P:','3023009.03');
elseif isunix
    padi.main = fullfile(...
        '/project','3023009.03');
end
padi.rawdata = fullfile(padi.main,'raw');
padi.data = fullfile(padi.main,'data');
padi.func = fullfile(padi.data,char(subjname),'ses-mri01','func');
padi.anat = fullfile(padi.data,char(subjname),'ses-mri01','anat');
padi.fmap = fullfile(padi.data,char(subjname),'ses-mri01','fmap'); 
padi.phys = fullfile(padi.rawdata,char(subjname),'ses-mri01','phys');
padi.hera = fullfile(padi.data,char(subjname),'hr'); % heart rate
padi.scr = fullfile(padi.data,char(subjname),'scr'); % skin conductance
padi.trialvals = fullfile(padi.main,'scripts','Behavior','Computational modelling','TrialValues','Choice','HR');

% output paths
padi.behav = fullfile(padi.rawdata,char(subjname),'ses-mri01','beh');
padi.meanEPI = fullfile(padi.anat,'meanEPI');
padi.stats = fullfile(padi.main,'stats','fMRI');

padi.templates = fullfile(padi.main,'scripts','fMRI','templates');

% Some subjects have incomplete data or missing data in certain runs
padi.incompl_subs = [19,29];
padi.tworuns = {'sub-004','sub-018','sub-019','sub-040','sub-044','sub-047','sub-049','sub-052','sub-061'};

if any(strcmp(subjname,{'sub-004','sub-018','sub-019','sub-044','sub-052','sub-061'}))
    padi.tasks = {'run-1','run-2'};
    padi.runnrs = [1,2];
    
elseif any(strcmp(subjname,{'sub-047','sub-049'}))
    padi.tasks = {'run-1','run-3'};
    padi.runnrs = [1,3];
    
elseif any(strcmp(subjname,{'sub-040'}))
    padi.tasks = {'run-2','run-3'};
    padi.runnrs = [2,3];
    
else
    padi.tasks={'run-1','run-2','run-3'};
    padi.runnrs = [1,2,3];
end

% no RETROICOR for these ppts
padi.noHR = {'sub-003','sub-011','sub-024'}; 


