function a_anger_RETROICORplus(subjname,whichtask)

%--------------------------------------------------------------------------
%
% perform RETROICOR for ANGER
%
%LdV 2016
%--------------------------------------------------------------------------

% PARAMETERS
%--------------------------------------------------------------------------

%load paths
padi=i_anger_infofile(subjname);

%get hera files
matFilenames=dir(fullfile(padi.log,'brainamp','*fMRI*hera.mat'));

%check if there are 3 files
%if numel(matFilenames)~=3; error('check number of files');end;

if numel(matFilenames)~=3; 
    for i = 1:length(matFilenames)
        if strfind(matFilenames(i).name,['run_',num2str(whichtask)]) > 0
            matFilenamepath = fullfile(padi.log,'brainamp',matFilenames(i).name);
        end    
    end
end;

% PERFORM RETROICOR
%--------------------------------------------------------------------------

%get file
if numel(matFilenames)==3; 
    matFilenamepath=fullfile(padi.log,'brainamp',matFilenames(whichtask).name);
end

%run [file,nscans removed beginning,nscans removed end]
Rvars = RETROICORplus(matFilenamepath,5,0);

%get RPars
RP=load(fullfile(padi.func,padi.tasks{whichtask},'log',...
    ['rp_',char(subjname),'_0001.txt']));

%remove first 5
RP=RP(6:end,:);

%fix subject 14 task1
if strcmp(subjname,'sub-014')==1 && whichtask==1
	Rvars=Rvars(1:end-6,:);
end

%check if size is the same. When scanner is stopped manually then it
%could occure 1 trigger is send out more than there are actual images
if length(Rvars)-length(RP) ~= 0
    if length(Rvars)-length(RP)==1;
        Rvars=Rvars(1:length(RP),:);
    else
        error('check length of RP and RETROICORplus');
    end
end    



%Check if RETROICORplus variables contain NaNs and replace by column mean
if sum(sum(isnan(Rvars)))>0
    colmeans = nanmean(Rvars);
    for i=1:numel(colmeans)
       ccol = Rvars(:,i);
       ccol(isnan(ccol))=colmeans(i);
       Rvars(:,i)=ccol;
    end
    disp('Removed NaN(s) from RETROICOR variables')
end
 
%combine variables
R=[Rvars RP];

%save file
savename=fullfile(padi.func,padi.tasks{whichtask},'log','allnuisanceregs.mat');
save(savename,'R')



