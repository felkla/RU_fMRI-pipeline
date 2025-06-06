function a_anger_task2_makeconfile(SUBJNAME,whichtask)

%--------------------------------------------------------------------------
%
% Will make a conditions.mat file which can be used as an input for SPM
%
%LdV2018
%--------------------------------------------------------------------------

%settings
str_trig=6;                     %first trigger
taskname='task_2';

%get path defs
padi=i_anger_infofile(SUBJNAME);


% GET LOG FILE
%--------------------------------------------------------------------------

%get logfile
logfile=dir(fullfile(padi.log,'preslog','*knutson*.log'));

%name
filename=fullfile(padi.log,'preslog',logfile.name);

%deliminator
delim='_';% multiple possible eg (',;:')
stringparts={...
    'Picture_rew_cue_',...
    'Picture_rew_tar_',...
    'Picture_rew_mis_',...
    'Picture_rew_hit_',...
    'Picture_nrw_cue_',...
    'Picture_nrw_tar_',...
    'Picture_nrw_mis_',...
    'Picture_nrw_hit_',...
    'Pulse_10_'};%will sort logfile


% GET SORTED OUTPUT
%--------------------------------------------------------------------------
[presoutput] = i_anger_getpresoutpout(filename,stringparts,whichtask);


% REMOVE STRING PARTS
%--------------------------------------------------------------------------
for sp=1:numel(stringparts);    
    presoutput_clean{sp}=regexprep(presoutput{sp},stringparts{sp},'');  
end

% ORDER DATA
%--------------------------------------------------------------------------

%get onsets
sp=[1,3,4,5,7,8];
for ss=sp
    stimonset{ss}=str2num(char(presoutput_clean{ss}));
end
    
%remove dur target
sp=[2,6];
for ss=sp
    for tt=1:length(presoutput_clean{ss})
        temp(tt,:)=cell2mat(textscan(char(presoutput_clean{ss}(tt)),...
            '%d %d', 'delimiter',delim));
    end
    stimonset{ss}=double(temp(:,2));
end

%get startime
trigtimes=str2num(char(presoutput_clean{9}));
trigtimes=trigtimes(trigtimes>0);%remove negative values
starttime=trigtimes(str_trig);

%subtract starttime
for i = 1:numel(stimonset)
    stimonset{i}=stimonset{i}-starttime;
end

% MAKE CONDITIONS.MAT FILE
%--------------------------------------------------------------------------
struct('names',{''},'onsets',{},'durations',{});

%names
names{1}='rew_cue'; 
names{2}='rew_tar'; 
names{3}='rew_mis'; 
names{4}='rew_hit';
names{5}='nrw_cue';
names{6}='nrw_tar'; 
names{7}='nrw_mis';
names{8}='nrw_hit'; 

%onsets [devide by 10000 to convert to seconds]
for i = 1:numel(stimonset)
    onsets{i}=double(stimonset{i}/10000);
    durations{i}=[zeros(length(onsets{i}),1)];
end

%save file
warning off
mkdir(fullfile(padi.func,taskname,'log'));
warning on
savename=fullfile(padi.func,taskname,'log','conditions.mat');
save(savename,'names','onsets','durations');

