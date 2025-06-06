function a_aafreeze_RETROICORplus(SUBJNAME,runnr,padi)

%--------------------------------------------------------------------------
%
% Add RETROICOR as nuisance regressors
%
% Adapted from LdV 2016
%--------------------------------------------------------------------------


%% Load RETROICOR regressors (R) & realignment parameters (RP)
%--------------------------------------------------------------------------

%load RETROICOR file
Rvars = load([padi.hera filesep 'RETROICOR' filesep ['R_',padi.tasks{runnr},'.mat']]);
Rvars = Rvars.R;

%load RPars
RPfile = dir(fullfile(padi.func,'log',...
    ['rp_',char(SUBJNAME),'*',padi.tasks{runnr},'_bold.txt']));
RP = load(fullfile(RPfile.folder, RPfile.name));

%check if size is the same. 
if length(Rvars)-length(RP) ~= 0
    if length(Rvars)-length(RP)==1
        Rvars=Rvars(1:length(RP),:);
    else
        error('check length of RP and RETROICORplus');
    end
end    

%Check if RETROICORplus variables contain NaNs and replace by column mean
if sum(sum(isnan(Rvars))) > 0
    colmeans = nanmean(Rvars);
    for i=1:numel(colmeans)
       ccol = Rvars(:,i);
       ccol(isnan(ccol)) = colmeans(i);
       Rvars(:,i) = ccol;
    end
    disp('Removed NaN(s) from RETROICOR variables')
end

% Remove erronous respiration regressors for subjects 24 and 34
if any(strcmp(SUBJNAME,{'sub-024','sub-034'}))
    Rvars(:,[11:20,23:26]) = [];
end

%combine variables
R = [Rvars RP];

%save file
savename=fullfile(padi.func,'log',['allnuisanceregs_',padi.tasks{runnr},'.mat']);
save(savename,'R')



