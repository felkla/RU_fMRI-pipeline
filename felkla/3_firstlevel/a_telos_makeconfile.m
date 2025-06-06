function a_telos_makeconfile(SUBJNAME, DESIGN)
%--------------------------------------------------------------------------
%
% Will make a conditions.mat file which can be used as an input for SPM
%
% LdV2018, adapted by FelKla 2020
% last edited 12 February 2025 by FelKla
% Added an additional 'DESIGN' input to flexibly switch between designs
%--------------------------------------------------------------------------

%check inputs
if ~exist('SUBJNAME','var')
    SUBJNAME = input('Please input subject name (e.g., "sub-001") :');
end
if ~exist('DESIGN','var')
    DESIGN = input('Please indicate design: "basic" / "predatorGame" :');
end

%get path defs
padi=i_telos_infofile(SUBJNAME);
subjnr = str2double(SUBJNAME(end-2:end));

% GET FILES
%--------------------------------------------------------------------------

%get results file
resultsfile = dir(fullfile(padi.behav,['*',SUBJNAME],'behav','*.csv'));

% READ IN DATA from files
%--------------------------------------------------------------------------
data = importfile(fullfile(resultsfile.folder, resultsfile.name));
assert(numel(data.trialNumber) <= 240, 'Behavioral log file error: Number of trials exceeds 240. Please check for duplicates!')

% GET NAMES, ONSETS, AND DURATIONS for all conditions
%--------------------------------------------------------------------------
% cycle over runs
nRuns = numel(dir(fullfile(padi.func,'run*')));
for c_run = 1:nRuns
    %preallocate variables
    [names, onsets, durations] = deal({});

    %select trials in current run
    row.run = find(data.BlockNumber == c_run);

    %get columns from which to read event timings
    % startDelay onset         = data.TimestampTrialStart
    % Prediction onset         = data.TimestampPredatorWarning
    % Jitter onset             = data.TimestampWaitSceneCall
    % Outcome onset            = data.TimestampOutcome
    % Predator-Torch Collision = data.TimestampTorchPlayerCollision
    % ITI onset                = data.TimestampITICall

    %get start time of the run (i.e., timestamp of first volume)
    row.firsttrial = intersect(row.run, find(data.trialNumber == 1));
    starttime = data.TimestampTrialStart(row.firsttrial); % start of first trial

    switch DESIGN

        case 'basic'
            % This first-level model only models trials as whole events.
            % It's a sanity check for synchronization

            %names
            names{1} = 'Trial';

            %onsets
            onsets{1} = data.TimestampTrialStart(row.run);
            onsets{1} = onsets{1} - starttime; %correct for starttime
            onsets{1} = onsets{1}./1000; % convert to seconds

            %durations
            durations{1} = data.TimestampITICall(row.run)-data.TimestampTrialStart(row.run);
            durations{1} = durations{1}./1000; % convert to seconds

            % make sure to remove trials with NaN
            onsets{1} = onsets{1}(~isnan(onsets{1}));
            durations{1} = durations{1}(~isnan(durations{1}));

        case 'predatorGame'
            % This model has all Predator Game regressors, including the
            % prediction and outcome windows, and electrical shocks/button
            % presses

            %names
            names{1}='startDelay';
            names{2}='prediction';
            names{3}='jitter';
            names{4}='outcomeHit';
            names{5}='outcomeMiss';
            names{6}='buttonPress';
            names{7}='points';
            names{8}='shock';
            names{9}='predictionIncorrect';
            names{10}='outcomeIncorrect';

            % FIRST, find out which trials to exclude and which to keep
            % make sure to exclude trials with no button presses (too late)
            row.corr = find(~isnan(data.RTInitiation));
            row.corr = intersect(row.corr, row.run);
            row.incorr = find(isnan(data.RTInitiation));
            row.incorr = intersect(row.incorr, row.run);

            % get row (i.e. trial) numbers for conditions
            %find all hit/miss trials
            row.hit = find(data.HitMiss == 1);
            row.hit = intersect(row.hit, row.run);
            row.miss = find(data.HitMiss == 0);
            row.miss = intersect(row.miss, row.run);

            %do some checks
            assert(sum([length(row.corr),length(row.incorr)]) == 60,'Error: not all trials are modelled (i.e., the number of trials per block doesn''t add up to 60)');
            assert(sum([length(row.hit),length(row.miss)]) == 60,'Error: not all trials are modelled (i.e., the number of trials per block doesn''t add up to 6)');

            %put in the timings
            onsets{1} = data.TimestampTrialStart(row.run);          %startDelay
            onsets{2} = data.TimestampPredatorWarning(row.corr);    %prediction, correct trials
            onsets{3} = data.TimestampWaitSceneCall(row.run);       %jitter
            onsets{4} = data.TimestampOutcome(intersect(row.hit, row.corr));    %outcome, hits, correct trials
            onsets{5} = data.TimestampOutcome(intersect(row.miss, row.corr));   %outcome, misses, correct trials
            
            onsets{6} = data.TimestampTrialStart(intersect(row.run, row.corr))+data.RTInitiation(intersect(row.run,row.corr)); %buttonPress relative to trial start (i.e., startDelay timestamp)
            onsets{7} = data.TimestampTorchPlayerCollision(row.hit);     %outcome: points
            onsets{8} = data.TimestampPredatorPlayerCollision(row.miss); %outcome: shocks
            
            onsets{9} = data.TimestampPredatorWarning(row.incorr);       %prediction, incorrect trials
            onsets{10} = data.TimestampOutcome(row.incorr);              %outcome, incorrect trials
            
            % remove empty regressors
            emptyRegs = zeros(1,numel(names));
            for r = 1:numel(onsets)
                if isempty(onsets{r})
                    % add regressor to list to remove from names, onsets
                    emptyRegs(r) = 1;
                end
            end
            names = names(~emptyRegs); % remove names
            onsets = onsets(~emptyRegs); % remove onsets

            %correct for starttime and convert to seconds
            for i = 1:numel(onsets)
                onsets{i} = (onsets{i} - starttime)./1000;
            end

            %durations
            durations{1} = 1.5; %startDelay is always 1.5s
            durations{2} = data.PredatorAttackTime(intersect(row.run, row.corr))./1000; %prediction, correct trials (in sec)
            durations{3} = data.WaitJitter(row.run)./1000; %jitter (in sec)
            durations{4} = 2.1; %outcome, hits, correct trials is always 2.1
            durations{5} = 2.1; %outcome, misses, correct trials is always 2.1

            durations{6} = 0; % Stick function for button press
            durations{7} = 0; % Stick function for torchPredatorCollision (points)
            durations{8} = 0; % Stick function for predatorPlayerCollision (shocks)
            if ~isempty(row.incorr)
                durations{9} = data.PredatorAttackTime(intersect(row.run, row.incorr));
                durations{10} = 2.1;
            end

    end

    %do some checks
    for i = 1:numel(onsets)
        %check only the regressors with variable durations
        if exist('durations','var') % FIR models have no durations
            if numel(durations{i}) > 1
                assert(length(onsets{i}) == length(durations{i}));
            end
        end
    end

    %save file
    if ~exist(fullfile(padi.subdata,'behav','log'),'dir')
        mkdir(fullfile(padi.subdata,'behav','log'));
    end
    savename = fullfile(padi.subdata,'behav','log',['conditions-run' num2str(c_run) '.mat']);

    if any(strcmp(DESIGN, {'predatorGame','basic'}))
        save(savename,'names','onsets','durations');
    elseif any(strcmp(DESIGN, {'parametric'}))
        save(savename,'names','onsets','durations','pmod','orth');
    end

end
