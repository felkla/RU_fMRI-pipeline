%% fMRI Quality Control Pipeline
% adapted for preprocessed folder structure

clear; close all; clc;

%% Paths & participants
preproDir = 'G:\1_RU5389\3_DERIVED'; % preprocessed data
participants = {'sub-01'};

% Specify runs to include
runsToInclude = [14, 17, 20, 23];

%% Which steps to run
% 1 = tSNR
% 2 = Motion
% 3 = Coverage
% 4 = Global signal outliers
stepsToRun = [1];

%% QC thresholds
FD_thresh   = 0.5;   % mm
GS_zthresh  = 3;     % SD

%% Initialize QC results table
QC_table = table('Size',[length(participants) 7],...
    'VariableTypes',repmat({'double'},1,7),...
    'VariableNames',{'Mean_tSNR','tSNR_std','Mean_FD','Max_FD','Percent_FDoutliers','Coverage','Percent_GSoutliers'});

%% Loop over participants
for p = 1:length(participants)
    sub = participants{p};
    fprintf('Processing participant %s...\n',sub);

    % Initialize QC scalars
    mean_tSNR = NaN; std_tSNR = NaN;
    FD = NaN; maxFD = NaN; percentFDoutliers = NaN;
    coverage = NaN; percentGSoutliers = NaN;

    %% List all functional run folders
    funcFolders = dir(fullfile(preproDir, sub, '*_run-*_bold'));
    funcFolders = funcFolders([funcFolders.isdir]);

    %% Select only the runs specified
    selectedFuncFolders = {};
    for f = 1:length(funcFolders)
        folderName = funcFolders(f).name;
        for r = runsToInclude
            runPattern = sprintf('run-%03d', r);
            if contains(folderName, runPattern)
                selectedFuncFolders{end+1} = fullfile(preproDir, sub, folderName);
            end
        end
    end

    %% Loop over selected run folders
    data4D = [];
    for f = 1:length(selectedFuncFolders)
        funcDir = selectedFuncFolders{f};
        % List NIfTIs
        filesStruct = dir(fullfile(funcDir,'*.nii*'));
        files = fullfile(funcDir,{filesStruct.name});

        % Uncompress .nii.gz if needed
        for i = 1:length(files)
            [~,fname,ext] = fileparts(files{i});
            if strcmp(ext,'.gz')
                gunzip(files{i});
                files{i} = fullfile(funcDir,fname); % update to uncompressed
            end
        end

        % Load NIfTIs
        for i = 1:length(files)
            V = spm_vol(files{i});
            volData = spm_read_vols(V);
            if isempty(data4D)
                data4D = volData;
            else
                data4D = cat(4, data4D, volData);
            end
        end

        % Cleanup temporary .nii if .nii.gz exists
        for i = 1:length(files)
            [~,fname,ext] = fileparts(files{i});
            [~,fname] = fileparts(fname);
            niiFile = fullfile(funcDir,[fname '.nii']);
            gzFile  = fullfile(funcDir,[fname '.nii.gz']);
            if exist(niiFile,'file') && exist(gzFile,'file')
                delete(niiFile);
                fprintf('Deleted temporary file: %s\n', niiFile);
            end
        end
    end

    %% 1. tSNR
    if ismember(1,stepsToRun) && ~isempty(data4D)
        [mean_tSNR, std_tSNR, tSNRmap] = compute_tSNR(data4D);
        outFile = fullfile(preproDir,'QC_results',[sub '_tSNRmap.nii']);
        write_nifti(tSNRmap,V(1),outFile);
    end

    %% 2. Motion
    if ismember(2,stepsToRun)
        rpFile = dir(fullfile(preproDir, sub, 'rp_*.txt'));
        if ~isempty(rpFile)
            rp = load(fullfile(rpFile(1).folder,rpFile(1).name));
            [FD, maxFD, percentFDoutliers] = compute_motion_FD(rp,FD_thresh);
        end
    end

    %% 3. Coverage
    if ismember(3,stepsToRun) && ~isempty(data4D)
        coverage = compute_brain_coverage(mean(data4D,4));
    end

    %% 4. Global signal outliers
    if ismember(4,stepsToRun) && ~isempty(data4D)
        percentGSoutliers = compute_global_signal_outliers(data4D,GS_zthresh);
    end

    %% Ensure scalars
    if ~isscalar(FD), FD = mean(FD); end
    if ~isscalar(maxFD), maxFD = maxFD(1); end
    if ~isscalar(percentFDoutliers), percentFDoutliers = percentFDoutliers(1); end
    if ~isscalar(coverage), coverage = coverage(1); end
    if ~isscalar(percentGSoutliers), percentGSoutliers = percentGSoutliers(1); end

    %% Fill table
    QC_table.Mean_tSNR(p)          = mean_tSNR;
    QC_table.tSNR_std(p)           = std_tSNR;
    QC_table.Mean_FD(p)            = FD;
    QC_table.Max_FD(p)             = maxFD;
    QC_table.Percent_FDoutliers(p) = percentFDoutliers;
    QC_table.Coverage(p)           = coverage;
    QC_table.Percent_GSoutliers(p) = percentGSoutliers;
end

%% Create results folder
resultsDir = fullfile(preproDir,'QC_results');
if ~exist(resultsDir,'dir'), mkdir(resultsDir); end

%% Save QC table with US decimal format
excelFile = fullfile(resultsDir,'QC_summary.xlsx');
oldLocale = java.util.Locale.getDefault;
java.util.Locale.setDefault(java.util.Locale.US);
writetable(QC_table, excelFile);
java.util.Locale.setDefault(oldLocale);

disp(['QC completed. Table saved to ' excelFile]);

% notes/TODOs:
% - unit testing
% - plot realignment parameters
% - tSNR maps
% - test brain coverage and GS outliers scripts
% - implementation: after each step or at the end?
% - voxels outside brain checks
% - move QC to dev branch
