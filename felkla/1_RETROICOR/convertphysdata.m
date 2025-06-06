function [] = convertphysdata(SUBJNR, padi)
%% Description
% Convert BrainVision physiological data (.eeg format) to Autonomate-compatible formats
% INPUTS
%   - SUBJNR:   number of the subject to convert
%   - SUBJNAME: corresponding name in format 'sub-00x'
%   - padi:     structure containing paths

%% Input
if SUBJNR < 10 || SUBJNR == 'x'
    SUBJNAME = ['sub-00' num2str(SUBJNR)];
elseif SUBJNR < 100
    SUBJNAME = ['sub-0' num2str(SUBJNR)];
else
    SUBJNAME = ['sub-' num2str(SUBJNR)];
end

%% Prep
% Add brainampconverter and fieldtrip to path
if ispc
    addpath H:\common/matlab/fieldtrip
elseif isunix
    addpath /home/common/matlab/fieldtrip
end

ft_defaults
addpath(fullfile(padi.main,'brainampconverter'));

curpath = pwd;

%% Select data
datadir = fullfile(padi.rawdata,SUBJNAME,'ses-mri01','phys');
filedir = dir([datadir, filesep,'*.eeg']);
filename = filedir.name(1:length(filedir.name));

cd(datadir)

%% Do conversion
fprintf('Converting physiological data of subject %i...\n', SUBJNR);
brainampconverter(filename);

cd(curpath)

fprintf('Done!\n');

end

