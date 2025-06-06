clear all;clc;
%--------------------------------------------------------------------------
%
%
% extracts signal from all T maps within a single subject GLM
%
%LdV2015
%--------------------------------------------------------------------------

% SETTINGS
%--------------------------------------------------------------------------

%input for signal extraction`
sigextrinput.roinames={...
    'rAmygdala_L.nii',...
    'rAmygdala_R.nii'};

%which task
sigextrinput.statsname='task_2';

%contrast for each indv bin, select which to include
if match_str(sigextrinput.statsname,'task_1')
    sigextrinput.numconimg=[1:12];
elseif match_str(sigextrinput.statsname,'task_2')
    sigextrinput.numconimg=[1:16];
end
nSubj=42;

%path defenition
project=i_anger_paths(sigextrinput.statsname);
project.groupstats=fullfile(project.statspath,'groupstats');
project.subjdirs=dir(fullfile(project.statspath,'sub*'));

sigextrinput.statspath=project.statspath;
mkdir(fullfile(project.statspath,'sig_extract'))

%loop over subjects
for ss=1:numel(project.subjdirs)
    
    %get individual subject data
    [extrdat]=a_anger_firstlevel_sigextr(project.subjdirs(ss).name,sigextrinput);
    
    %devide [roi, then contrast]
    allextrdat(ss,:)=extrdat.dat;
    
end

%collect data
clear alldat
alldat(:,:)=['subjname',extrdat.names];
alldat(2:nSubj+1,1)={project.subjdirs.name}';
alldat(2:nSubj+1,2:size(num2cell(allextrdat),2)+1)=num2cell(allextrdat);


%save files
datestr=getdatestr;%add time stamp (own funcion)
savefilename=fullfile(project.statspath,'sig_extract',[datestr,'_',sigextrinput.statsname,'.csv']);
cell2csv(savefilename,alldat,',');



