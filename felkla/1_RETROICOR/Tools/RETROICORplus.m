%--------------------------------------------------------------------------
%RETROICOR_setup_subject
%EJH 2011-15

%--------------------------------------------------------------------------


function [R]=RETROICORplus(matFilename,RETROICORbegremscans,RETROICORendremscans)

if ~nargin
    [matfile, matpath, irr] = uigetfile( ...
       {'*.mat','HeRa MAT files (*.mat)'}, ...
        'Pick a MAT file created by HeRa');
    matFilename = fullfile(matpath,matfile);
    
    RETROICORbegremscans = inputdlg('Number of scans to remove at beginning','',1);
    RETROICORbegremscans = str2num(RETROICORbegremscans{1});

    RETROICORendremscans = inputdlg('Number of scans to remove at end','',1);
    RETROICORendremscans = str2num(RETROICORendremscans{1});

end

%--------------------------------------------------------------------------

%Load hera processed pulse data
heradata = load(matFilename);
%--------------------------------------------------------------------------

%Set Fourier order
fOrder = 5;

%Get sample rate
SR = heradata.matfile.settings.samplerate;

%Run rejection interpolation
heradata.matfile = ...
    RETROICORplus_interpolate_hera_reject(heradata.matfile,SR);

%Get all scan triggers and cut out the right ones (setting above)
if size(heradata.matfile.markerlocs,2)>1
    scanTriggers = heradata.matfile.markerlocs';
else
    scanTriggers = heradata.matfile.markerlocs;
end

%Check if this is a continuous run
if sum(abs(diff(scanTriggers)-mean(diff(scanTriggers)))>2) >0 %TR is never more than 2 ms off mean
    error('This appears not to be a continuous recording')
end

%Add one scan trigger at the end to enable retroicor for last scan
scanTriggers = [scanTriggers;...
    round(scanTriggers(end)+mean(diff(scanTriggers)))];

%Run RETROICOR to create regressors
[CPR,RPR,NR]=RETROICORplus_calc(...
    scanTriggers,...                    %Scan trigger indices
    heradata.matfile.prepeaklocs,...    %Heart beat peak indices
    heradata.matfile.rawpulsedata,...   %Pulse data
    heradata.matfile.rawrespdata,...    %Respiration data
    SR,...                              %sample rate
    fOrder);                            %Fourier order

%Save the result
R = [CPR,RPR,NR];
R = R(RETROICORbegremscans+1:end-RETROICORendremscans,:);
% path = ['/home/memory/anovdhei/VRFC/data/'];
% outfile = fullfile(path,['addregressors.mat']);
% save(outfile,'R');




