function a_anger_task1_makeconfile(SUBJNAME)

%--------------------------------------------------------------------------
%
% Will make a conditions.mat file which can be used as an input for SPM
%
%LdV2018
%--------------------------------------------------------------------------

%settings
str_trig=6;                     %first trigger
taskname='task_1';
whichtask=1;

%get path defs
padi=i_anger_infofile(SUBJNAME);


% GET LOG FILE
%--------------------------------------------------------------------------

%get logfile
logfile=dir(fullfile(padi.log,'preslog','*DFET.log'));

%name
filename=fullfile(padi.log,'preslog',logfile.name);

%deliminator
delim='_';% multiple possible eg (',;:')
stringparts={'Picture_pic','Pulse_10_'};%will sort logfile


% GET SORTED OUTPUT
%--------------------------------------------------------------------------
[presoutput] = i_anger_getpresoutpout(filename,stringparts,whichtask);

%each block contains 50 faces presented 4 times in flow thus 200 pictures
%per block, take each 200th one to get the first [CHECK IF TRUE!]
presoutput{1}=presoutput{1}(1:200:3600);

% REMOVE STRING PARTS
%--------------------------------------------------------------------------
for sp=1:numel(stringparts);    
    presoutput_clean{sp}=regexprep(presoutput{sp},stringparts{sp},''); 
    presoutput_clean{sp}=regexprep(presoutput_clean{sp},'red_dot_','');  
end

% ORDER DATA
%--------------------------------------------------------------------------

%first loop over pictures to get category code [so '0' does not get lost]
for tt=1:length(presoutput_clean{1})
    temp=char(presoutput_clean{1}(tt));
    stimcodes(tt)=str2num(temp(3));
end

%then get onsets
for tt=1:length(presoutput_clean{1})
    stimonsets(tt,:)=cell2mat(textscan(char(presoutput_clean{1}(tt)),...
        '%d %d %d', 'delimiter',delim));
end
stimonsets=stimonsets(:,3);

%get startime
trigtimes=str2num(char(presoutput_clean{2}));
trigtimes=trigtimes(trigtimes>0);%remove negative values
starttime=trigtimes(str_trig);

%subtract starttime
stimonsets=stimonsets-starttime;

% MAKE CONDITIONS.MAT FILE
%--------------------------------------------------------------------------
struct('names',{''},'onsets',{},'durations',{});

%names
names{1}='anger'; %code [0]
names{2}='happy'; %code [1]
names{3}='fear'; %code [2]

%onsets [devide by 10000 to convert to seconds]
onsets{1}=double(stimonsets(stimcodes==0)/10000)';
onsets{2}=double(stimonsets(stimcodes==1)/10000)';
onsets{3}=double(stimonsets(stimcodes==2)/10000)';

%durations [23 sec per block]
durations{1}=[ones(1,length(onsets{1}))*23];
durations{2}=[ones(1,length(onsets{2}))*23];
durations{3}=[ones(1,length(onsets{3}))*23];


%save file
warning off
mkdir(fullfile(padi.func,taskname,'log'));
warning on
savename=fullfile(padi.func,taskname,'log','conditions.mat');
save(savename,'names','onsets','durations');

