function a_aafreeze_RP(subjname,runnr,padi)

%--------------------------------------------------------------------------
%
% load RP only if no retroicor available for AA-FREEZE (alternative to
% a_aafreeze_RETROICORplus)
%
% Reinoud Kaldewaij 2019
% Felix Klaassen 2021
%--------------------------------------------------------------------------

%get RPars
R = load(fullfile(padi.func,'log',...
    ['rp_',char(subjname),'_task-PAT_run-',num2str(padi.runnrs(runnr)),'_bold.txt']));

%save file
savename=fullfile(padi.func,'log',['rp_only_run-',num2str(padi.runnrs(runnr)),'.mat']);
save(savename,'R')