function a_anger_RP(subjname,whichtask)

%--------------------------------------------------------------------------
%
% load RP only if no retroicor available for ANGER (alternative to
% a_anger_RETROICORplus)
%
% Reinoud Kaldewaij 2019
%--------------------------------------------------------------------------

%load paths
padi=i_anger_infofile(subjname);

%get RPars
RP=load(fullfile(padi.func,padi.tasks{whichtask},'log',...
    ['rp_',char(subjname),'_0001.txt']));

%remove first 5
R=RP(6:end,:);

%save file
savename=fullfile(padi.func,padi.tasks{whichtask},'log','rp_only.mat');
save(savename,'R')