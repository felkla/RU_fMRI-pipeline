function padi = i_telos_infofile(subjname)

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
padi.main = fullfile('/home','klaassen','projects','telos'); %parent directory of project
padi.rawdata = fullfile(padi.main,'Raw');
padi.data = fullfile('/projects','crunchie','telos','data'); %BIDS folder
padi.subdata = fullfile(padi.data,char(subjname));
padi.func = fullfile(padi.subdata,'func');
padi.anat = fullfile(padi.subdata,'anat');
padi.fmap = fullfile(padi.subdata,'fmap'); 
padi.phys = fullfile(padi.rawdata,char(subjname),'ses-mri01','phys');
padi.hera = fullfile(padi.subdata,'hr'); % heart rate
padi.scr = fullfile(padi.subdata,'scr'); % skin conductance
padi.trialvals = fullfile(padi.main,'Scripts','Behavior','Computational modelling','TrialValues'); % use later for model-derived variables CPP/RU

% output paths
padi.behav = fullfile(padi.data);
padi.meanEPI = fullfile(padi.anat,'meanEPI');
padi.stats = fullfile(padi.main,'output','stats');

padi.templates = fullfile(padi.main,'templates');

% no RETROICOR for these ppts
padi.noHR = {}; 


