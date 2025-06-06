function a_anger_RP(subjname,whichtask)

%--------------------------------------------------------------------------
%
% load RP only if no retroicor available for ANGER (alternative to
% a_anger_RETROICORplus)
%
% Reinoud Kaldewaij 2019
%--------------------------------------------------------------------------

% define nr of warm-ups volumes, this determines the number of the first
% scan (and of the rp file).
nrWarmup = 5;

%load paths
padi=i_aafreeze_infofile(subjname);

%get RPars
R = load(fullfile(padi.func,'log',...
    ['rp_',char(subjname),'_task-PAT_acq-MB4_run-',num2str(whichtask),'_bold.txt']));

%save file
savename=fullfile(padi.func,'log',['rp_only_run-',num2str(whichtask),'.mat']);
save(savename,'R')
% save(savename,'RP')