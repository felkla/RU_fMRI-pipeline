function a_aafreeze_makeconfile(SUBJNAME, DESIGN, ROUTE, est_level)

%--------------------------------------------------------------------------
%
% Will make a conditions.mat file which can be used as an input for SPM
%
%LdV2018, adapted by FelKla 2020
% Added an additional 'DESIGN' input to flexibly switch between designs
%--------------------------------------------------------------------------

%get path defs
padi=i_aafreeze_infofile(SUBJNAME);

if strcmp(SUBJNAME,'sub-00x')
    subjnr = 0;
else
    subjnr = str2double(SUBJNAME(end-2:end));
end

% number of runs this ppt has
if any(strcmp(SUBJNAME,padi.tworuns))
    nRun = 2;
else
    nRun = 3;
end

for c_run = 1:nRun

    % GET FILES
    %--------------------------------------------------------------------------

    %get results file
    resultsfile = dir(fullfile(padi.behav,['run',num2str(padi.runnrs(c_run))],'*results.mat'));
    %name
    filename.results = fullfile(padi.behav,['run',num2str(padi.runnrs(c_run))],resultsfile.name);

    %get cfg file
    configfile=dir(fullfile(padi.behav,['run',num2str(padi.runnrs(c_run))],'*cfg.mat'));
    %name
    filename.cfg=fullfile(padi.behav,['run',num2str(padi.runnrs(c_run))],configfile.name);

    % READ IN DATA from files
    %--------------------------------------------------------------------------
    load(filename.results);
    load(filename.cfg);

    % GET NAMES, ONSETS, AND DURATIONS for all conditions
    %--------------------------------------------------------------------------
    struct('names',{''},'onsets',{},'durations',{});

    %onsets
    %get start time of the run (i.e., timestamp of first volume)
    starttime = cfg.scanner.FirstTR.onset; % SHOULD BE WARM-UP OR FIRSTTRIG

    %get column numbers from which to read event timings
    col.StimOnset = 3;
    col.MovOnset = 4;
    col.OutOnset = 12;

    switch DESIGN

        case 'basic'
            % This first-level model only models trials as whole events.
            % It's a sanity check for synchronization
            %names
            names{1} = 'Trial';

            %onsets
            onsets{1} = results{1}.timings(:,col.StimOnset);
            onsets{1} = onsets{1} - starttime; %correct for starttime

            %durations
            durations{1} = (results{1}.timings(:,col.OutOnset)-results{1}.timings(:,col.StimOnset))+cfg.dur.feedback;

        case 'factorial'
            % This model has only 'categorical' regressors, estimating the
            % effect of passive/active approach/avoid on BOLD

            %names
            names{1}='StimShort';
            names{2}='StimPassiveApproach';
            names{3}='StimActiveApproach';
            names{4}='StimPassiveAvoid';
            names{5}='StimActiveAvoid';
            names{6}='MovShort';
            names{7}='MovPassive';
            names{8}='MovActive';
            names{9}='Money';
            names{10}='Shocks';
            names{11}='Neutral';

            % FIRST, find out which trials to exclude and which to keep

            % make sure to exclude trials with incorrect button-press or
            % unrealistically fast RTs (i.e., below 200 ms, 300 ms uncorrected for timing error)
            row.corr = find(ismember(results{1}.response, [0,97,65]) & (results{1}.rt == 0 | results{1}.rt >= 0.3 | isnan(results{1}.rt)));

            %get row (i.e. trial) numbers for conditions
            row.short = union(find(results{1}.longCSI == 0), find(~ismember(1:62,row.corr))); % add incorrect trials in with short trials
            row.long = intersect(find(results{1}.longCSI == 1), row.corr); % only include long (and correct) trials in analysis

            % NEXT, find all approach/avoid active/passive conditions
            row.approach = find((results{1}.trialtype == 1 & results{1}.selfloc == 3) | (results{1}.trialtype == 2 & results{1}.selfloc ~= 3));
            row.avoid = find((results{1}.trialtype == 1 & results{1}.selfloc ~= 3) | (results{1}.trialtype == 2 & results{1}.selfloc == 3));
            row.passive = find(results{1}.selfloc == 3);
            row.active = find(results{1}.selfloc ~= 3);

            row.passiveapproach = intersect(row.passive, row.approach);
            row.activeapproach = intersect(row.active, row.approach);
            row.passiveavoid = intersect(row.passive, row.avoid);
            row.activeavoid = intersect(row.active, row.avoid);

            % add outcomes (money/shock/nothing)
            row.shocks = find(results{1}.outcome == 1 & results{1}.payout == 1);
            row.money = find(results{1}.outcome == 2 & results{1}.payout == 1);
            row.neutral = find(results{1}.outcome == 3);

            %do some checks
            assert(sum([length(row.short),length(row.long)]) == 62,'Error: not all trials are modelled (i.e., the number of trials doesn''t add up to 62)');
            assert(sum([length(row.shocks),length(row.money),length(row.neutral)]) == 62,'Error: not all trials are modelled (i.e., the number of trials doesn''t add up to 62)');

            %put in the timings
            % I add 100 ms to all movement window onsets, because the first
            % location of the target 'movement' is the same as the target
            % location during the anticipation, and so the onset of the
            % movement is only visible for the participant 100 ms later
            % (2nd location)
            onsets{1} = results{1}.timings(row.short,col.StimOnset); %StimShort
            onsets{2} = results{1}.timings(intersect(row.long, row.passiveapproach),col.StimOnset); %StimPassiveApproach
            onsets{3} = results{1}.timings(intersect(row.long, row.activeapproach),col.StimOnset); %StimActiveApproach
            onsets{4} = results{1}.timings(intersect(row.long, row.passiveavoid),col.StimOnset); %StimPassiveAvoid
            onsets{5} = results{1}.timings(intersect(row.long, row.activeavoid),col.StimOnset); %StimActiveAvoid

            onsets{6} = results{1}.timings(row.short,col.MovOnset)+0.1; %MovShort
            onsets{7} = results{1}.timings(intersect(row.long, row.passive),col.MovOnset)+0.1; %MovPassive
            onsets{8} = results{1}.timings(intersect(row.long, row.active),col.MovOnset)+0.1; %MovActive

            onsets{9} = results{1}.timings(row.money, col.OutOnset); %Money
            onsets{10} = results{1}.timings(row.shocks, col.OutOnset); %Shocks
            onsets{11} = results{1}.timings(row.neutral, col.OutOnset); %Neutral

            %correct for starttime
            for i = 1:numel(onsets)
                onsets{i} = onsets{i} - starttime;
            end

            %durations
            % I add 100 ms to all anticipation window durations to correct for first target-movement location
            durations{1} = cfg.cb_mat{1}(row.short,5)+0.1; %StimShort

            durations{2} = cfg.cb_mat{1}(intersect(row.long, row.passiveapproach),5)+0.1; %StimPassiveApproach
            durations{3} = cfg.cb_mat{1}(intersect(row.long, row.activeapproach),5)+0.1; %StimActiveApproach
            durations{4} = cfg.cb_mat{1}(intersect(row.long, row.passiveavoid),5)+0.1; %StimPassiveAvoid
            durations{5} = cfg.cb_mat{1}(intersect(row.long, row.activeavoid),5)+0.1; %StimActiveAvoid

            [durations{6}, durations{7}, durations{8}] = deal(0); % Stick function
            [durations{9}, durations{10}, durations{11}] = deal(1.5); %outcome is always 1.5s

        case 'parametric'
            % This model only has single events per phase of the task (stimulus ->
            % movement -> outcome), and parametric modulators of the
            % stimulus events of money, shocks, and their interaction
            
            % load deltaHR data
            HRpath = fullfile(padi.main, 'scripts', 'HR');
            addpath(HRpath)
            load(fullfile(HRpath, 'DataAll_HR.mat'),'DataAll')
            if ~isfield('deltaHR','DataAll')
                DataAll = ComputeDeltaHR([5 7],[],[]);
            end

            %names
            names{1}='StimShort';
            names{2}='Stim';
            names{3}='MovActive';
            names{4}='MovPassive';
            names{5}='OutShort';
            names{6}='Out_Money';
            names{7}='Out_Shocks';
            names{8}='Out_Neutral';

            %get row (i.e. trial) numbers for trial types
            row.short = find(results{1}.longCSI == 0);
            row.long = find(results{1}.longCSI == 1);
            row.passive = find(results{1}.selfloc == 3);
            row.active = find(results{1}.selfloc ~= 3);

            % determine which trials (do/don't) have HR
            % (of this ppt/run)
            noHRind = isnan(DataAll.deltaHR) & ...
                DataAll.run == padi.runnrs(c_run) & ...
                DataAll.ppnr == subjnr;

            noHRtrials = DataAll.trialnr(noHRind);

            % remove those noHR trials from the regressors of interest (i.e., all long trials)
            row.long = setdiff(row.long, noHRtrials);

            % and add them to the short trial selection (so we still model them)
            row.short = [row.short, noHRtrials']; 

            % determine which trials had shock/money/neutral outcomes
            row.shocks = find(results{1}.outcome == 1 & results{1}.payout == 1);
            row.money = find(results{1}.outcome == 2 & results{1}.payout == 1);
            row.neutral = find(results{1}.outcome == 3);

            %do some checks
            assert(sum([length(row.short),length(row.long)]) == 62);
            assert(sum([length(row.shocks),length(row.money),length(row.neutral)]) == 62);

            %put in the timings
            onsets{1} = results{1}.timings(row.short,col.StimOnset); %StimShort
            onsets{2} = results{1}.timings(row.long,col.StimOnset); %Stim (long)

            onsets{3} = results{1}.timings(row.passive,col.MovOnset) + 0.1; %MovPassive
            onsets{4} = results{1}.timings(row.active,col.MovOnset) + 0.1; %MovActive

            onsets{5} = results{1}.timings(row.short, col.OutOnset); %OutShort
            onsets{6} = results{1}.timings(intersect(row.long, row.money), col.OutOnset); %Out_Money
            onsets{7} = results{1}.timings(intersect(row.long, row.shocks), col.OutOnset); %Out_Shocks
            onsets{8} = results{1}.timings(intersect(row.long, row.neutral), col.OutOnset); %Out_Neutral

            %correct for starttime
            for i = 1:numel(onsets)
                onsets{i} = onsets{i} - starttime;
            end

            %durations
            durations{1} = cfg.cb_mat{1}(row.short,5) + 0.1; %StimShort
            durations{2} = cfg.cb_mat{1}(row.long,5) + 0.1; %Stim (long)

            [durations{3}, durations{4}] = deal(0); %movement is always a stick function

            [durations{5}, durations{6}, durations{7}, durations{8}] = deal(1.5); %outcome is always 1.5s

            %define parametric modulators
            pmod = struct('name', {''}, 'param',{},'poly',{});

            %modulator 1: money modulating anticipation (StimLong)
            pmod(2).name{1} = 'ant_Money';
            pmod(2).param{1} = results{1}.rewmagn(row.long);
            pmod(2).poly{1} = 1;
            assert(length(pmod(2).param{1}) == length(onsets{2}));

            %modulator 2: shocks modulating anticipation (StimLong)
            pmod(2).name{2} = 'ant_Shocks';
            pmod(2).param{2} = results{1}.shockmagn(row.long);
            pmod(2).poly{2} = 1;
            assert(length(pmod(2).param{2}) == length(onsets{2}));

            % modulator 3: money-by-shocks interaction. Defined further
            % below

            % demean parametric modulators
            %compute average deltaHR, money, and shock amounts (per subject)
            meanMoney = mean(DataAll.money(DataAll.ppnr == subjnr & ~isnan(DataAll.deltaHR)));
            meanShocks = mean(DataAll.shocks(DataAll.ppnr == subjnr & ~isnan(DataAll.deltaHR)));

            for c_conds = 1:numel(pmod) %loop over conditions (regressors)

                if ~isempty(pmod(c_conds).name) %skip conditions without pmods

                    for c_pmod = 1:numel(pmod(c_conds).param) %loop over pmods for this condition

                        % Make sure to demean with respect to the subject-average (rather than per run)
                        if contains(pmod(c_conds).name{c_pmod},'Money')

                            % Subtract from each individual trial
                            pmod(c_conds).param{c_pmod} = pmod(c_conds).param{c_pmod} - meanMoney;

                        elseif contains(pmod(c_conds).name{c_pmod},'Shocks')

                            % Subtract from each individual trial
                            pmod(c_conds).param{c_pmod} = pmod(c_conds).param{c_pmod} - meanShocks;

                        end
                    end
                end
            end

            %Extra modulator: money-by-shocks interaction modulating anticipation (StimLong)
            pmod(2).name{3} = 'ant_Money-by-Shocks';
            pmod(2).param{3} = pmod(2).param{1}.*pmod(2).param{2};
            pmod(2).poly{3} = 1;
            assert(length(pmod(2).param{3}) == length(onsets{2}));

            %set SPM orthogonalization to 0
            orth = cell(1, numel(onsets));
            for c_orth = 1:numel(orth)
                orth{c_orth} = 0; %1 = orthogonalize pmods, 0 = don't orth (see Mumford, Poline, & Poldrack, 2015; PLoS ONE)
            end

        case 'freezing'
            % These models are are similar to the 'parametric' model above,
            % but with different pmods. It has 5 pmods for the stimulus
            % event: EVbase, EVdiff_R1, EV_diffR2, EV_diffR3.
            % Where EVbase is the trial-by-trial expected value generated
            % by the base model, and EVdiff_R1 to R3 are the difference
            % between the R1, R2, and R3 models and the base model (wrt the
            % EV). So EVdiff_Rx = EVbase - EV_Rx. 

            % load deltaHR data
            HRpath = fullfile(padi.main, 'scripts', 'HR');
            addpath(HRpath)
            load(fullfile(HRpath, 'DataAll_HR.mat'),'DataAll')
            if ~isfield(DataAll,'woi') || (DataAll.woi(1) ~= 5 || DataAll.woi(2) ~= 7) % make sure we use the [5 7] dHR window
                DataAll = ComputeDeltaHR([5 7],[],[]);
            end

            % load parametric modulators:
%             [freezeDat, freezeDiff, meanFreezeDiff] = deal(cell(1,1));

            % 1) Base model
            baseDat = importfile(fullfile(padi.trialvals,'Base',est_level,['s' num2str(subjnr) '.csv']));

            % 2) Freeze models
            if ROUTE == 1
                % route 1
                freezeDat = importfile(fullfile(padi.trialvals,'Base_Bsf',est_level,['s' num2str(subjnr) '.csv']));  % raw values

            elseif ROUTE == 2
                % route 2
                freezeDat = importfile(fullfile(padi.trialvals,'Base_Bmsf',est_level,['s' num2str(subjnr) '.csv'])); % raw values

            elseif ROUTE == 3
                % route 3
                freezeDat = importfile(fullfile(padi.trialvals,'Base_Btf',est_level,['s' num2str(subjnr) '.csv']));  % raw values

            end
            
            % split all regressors in two conditions: with negative and positive difference values
            baseVals = cell(1,2);   % 1 = negative diff. vals, 2 = positive diff. vals
            freezeDiff = cell(1,2); % 1 = negative diff. vals, 2 = positive diff. vals

            freezeDiffs = baseDat.TrialVals-freezeDat.TrialVals;                                               
            freezeDiff{1} = freezeDiffs(freezeDiffs < 0); % only negative diff. values
            freezeDiff{2} = freezeDiffs(freezeDiffs > 0); % only positive diff. values
            baseVals{1} = baseDat.TrialVals(freezeDiffs < 0); % base vals of negative diff. trials
            baseVals{2} = baseDat.TrialVals(freezeDiffs > 0); % base vals of positive diff. trials

            assert(size(freezeDiff{1},1)+size(freezeDiff{2},1) == size(freezeDiffs,1)); % check sizes

            %names
            names{1}='StimShort';
            names{2}='StimNeg'; % modulated by negative diffs
            names{3}='StimPos'; % modulated by positive diffs
            names{4}='MovActive';
            names{5}='MovPassive';
            names{6}='OutShort';
            names{7}='Out_Money';
            names{8}='Out_Shocks';
            names{9}='Out_Neutral';

            %get row (i.e. trial) numbers for trial types
            row.short = find(results{1}.longCSI == 0);
            row.long = find(results{1}.longCSI == 1);
            row.passive = find(results{1}.selfloc == 3);
            row.active = find(results{1}.selfloc ~= 3);

            % determine which trials (do/don't) have HR (of this ppt/run)
            noHRind = isnan(DataAll.deltaHR) & ...
                DataAll.run == padi.runnrs(c_run) & ...
                DataAll.ppnr == subjnr;

            noHRtrials = DataAll.trialnr(noHRind);

            % remove those noHR trials from the regressors of interest (i.e., all long trials)
            row.long = setdiff(row.long, noHRtrials);

            % and add them to the short trial selection (so we still model them)
            row.short = [row.short, noHRtrials'];

            % find which trials have negative vs. positive difference
            % scores
            row.neg = freezeDat.trial(freezeDiffs < 0 & freezeDat.ppnr == subjnr & freezeDat.run == padi.runnrs(c_run));
            row.pos = freezeDat.trial(freezeDiffs > 0 & freezeDat.ppnr == subjnr & freezeDat.run == padi.runnrs(c_run));

            assert(all(sort([row.neg; row.pos])==row.long')); % check they're the same trials
            
            % determine which trials had shock/money/neutral outcomes
            row.shocks = find(results{1}.outcome == 1 & results{1}.payout == 1);
            row.money = find(results{1}.outcome == 2 & results{1}.payout == 1);
            row.neutral = find(results{1}.outcome == 3);

            %do some checks
            assert(sum([length(row.short),length(row.long)]) == 62);
            assert(sum([length(row.shocks),length(row.money),length(row.neutral)]) == 62);

            %put in the timings
            onsets{1} = results{1}.timings(row.short,col.StimOnset); %StimShort
            onsets{2} = results{1}.timings(intersect(row.long,row.neg),col.StimOnset); %Stim (long); negative
            onsets{3} = results{1}.timings(intersect(row.long,row.pos),col.StimOnset); %Stim (long); positive

            onsets{4} = results{1}.timings(row.passive,col.MovOnset) + 0.1; %MovPassive
            onsets{5} = results{1}.timings(row.active,col.MovOnset) + 0.1; %MovActive

            onsets{6} = results{1}.timings(row.short, col.OutOnset); %OutShort
            onsets{7} = results{1}.timings(intersect(row.long, row.money), col.OutOnset); %Out_Money
            onsets{8} = results{1}.timings(intersect(row.long, row.shocks), col.OutOnset); %Out_Shocks
            onsets{9} = results{1}.timings(intersect(row.long, row.neutral), col.OutOnset); %Out_Neutral

            %correct for starttime
            for i = 1:numel(onsets)
                onsets{i} = onsets{i} - starttime;
            end

            %durations
            durations{1} = cfg.cb_mat{1}(row.short,5) + 0.1; %StimShort
            durations{2} = cfg.cb_mat{1}(intersect(row.long,row.neg),5) + 0.1; %Stim (long); negative
            durations{3} = cfg.cb_mat{1}(intersect(row.long,row.pos),5) + 0.1; %Stim (long); positive

            [durations{4}, durations{5}] = deal(0); %movement is always a stick function

            [durations{6}, durations{7}, durations{8}, durations{9}] = deal(1.5); %outcome is always 1.5s

            %define parametric modulators
            pmod = struct('name', {''}, 'param',{},'poly',{});

            %modulator 1: trial-by-trial values of base model (negative diff. trials)
            pmod(2).name{1} = 'ant_valBase-neg';
            pmod(2).param{1} = baseDat.TrialVals(baseDat.run == padi.runnrs(c_run) & freezeDiffs < 0); % trial-by-trial values for this RUN
            pmod(2).poly{1} = 1;
            assert(length(pmod(2).param{1}) == length(onsets{2}));

            %modulator 2: trial-by-trial values of base model (positive diff. trials)
            pmod(3).name{1} = 'ant_valBase-pos';
            pmod(3).param{1} = baseDat.TrialVals(baseDat.run == padi.runnrs(c_run) & freezeDiffs > 0); % trial-by-trial values for this RUN
            pmod(3).poly{1} = 1;
            assert(length(pmod(3).param{1}) == length(onsets{3}));

            if ROUTE == 1
                %modulator 3: trial-by-trial diff between base model and R1 values (negative diff trials)
                pmodname = 'ant_valR1-neg';
                pmod(2).name{2} = pmodname;

                %modulator 4: trial-by-trial diff between base model and R1 values (positive diff trials)
                pmodname = 'ant_valR1-pos';
                pmod(3).name{2} = pmodname;

            elseif ROUTE == 2
                %modulator 3: trial-by-trial diff between base model and R2 values (negative diff trials)
                pmodname = 'ant_valR2-neg';
                pmod(2).name{2} = pmodname;

                %modulator 4: trial-by-trial diff between base model and R2 values (positive diff trials)
                pmodname = 'ant_valR2-pos';
                pmod(3).name{2} = pmodname;

            elseif ROUTE == 3
                %modulator 3: trial-by-trial diff between base model and R3 values (negative diff trials)
                pmodname = 'ant_valR3-neg';
                pmod(2).name{2} = pmodname;

                %modulator 4: trial-by-trial diff between base model and R3 values (positive diff trials)
                pmodname = 'ant_valR3-pos';
                pmod(3).name{2} = pmodname;

            end
            
            % negative trial diffs
            pmod(2).param{2} = freezeDiffs(freezeDat.run == padi.runnrs(c_run) & freezeDiffs < 0); % trial-by-trial diff values for this RUN
            pmod(2).poly{2} = 1;
            assert(length(pmod(2).param{2}) == length(onsets{2}));

            % positive trial diffs
            pmod(3).param{2} = freezeDiffs(freezeDat.run == padi.runnrs(c_run) & freezeDiffs > 0); % trial-by-trial diff values for this RUN
            pmod(3).poly{2} = 1;
            assert(length(pmod(3).param{2}) == length(onsets{3}));

            %demean pmods
            % mean base vals (neg and pos)
            meanBaseParam(1) = mean(baseDat.TrialVals(freezeDiffs < 0)); % compute mean across runs (so for whole subject)
            meanBaseParam(2) = mean(baseDat.TrialVals(freezeDiffs > 0)); % compute mean across runs (so for whole subject)

            % mean diff vals (neg and pos)
            meanFreezeDiff(1) = mean(freezeDiffs(freezeDiffs < 0)); % compute mean across runs (so for whole subject)
            meanFreezeDiff(2) = mean(freezeDiffs(freezeDiffs > 0)); % compute mean across runs (so for whole subject)

            % negative diff trials
            pmod(2).param{1} = pmod(2).param{1} - meanBaseParam(1);  % subtract mean from trial-values
            pmod(2).param{2} = pmod(2).param{2} - meanFreezeDiff(1); % subtract mean from trial-diffs

            % positive diff trials
            pmod(3).param{1} = pmod(3).param{1} - meanBaseParam(2);  % subtract mean from trial-values
            pmod(3).param{2} = pmod(3).param{2} - meanFreezeDiff(2); % subtract mean from trial-diffs

            %set SPM orthogonalization to 0
            orth = cell(1, numel(onsets));
            for c_orth = 1:numel(orth)
                orth{c_orth} = 0; %1 = orthogonalize pmods, 0 = don't orth (see Mumford, Poline, & Poldrack, 2015; PLoS ONE)
            end

        case 'FIR'
            % This model estimates BOLD activity without assuming a HRF. It
            % enables investigation of the time course of the BOLD signal
            % over time (e.g., during the anticipation window), separately
            % for different conditions

            % This model has only 'categorical' regressors, estimating the
            % effect of passive/active approach/avoid on BOLD

            %names
            names{1}='Short';
            names{2}='PassiveApproach';
            names{3}='ActiveApproach';
            names{4}='PassiveAvoid';
            names{5}='ActiveAvoid';

            % FIRST, find out which trials to exclude and which to keep:

            % make sure to exclude trials with incorrect button-press or
            % unrealistically fast RTs (i.e., below 200 ms, 300 ms uncorrected for timing error)
            row.corr = find(ismember(results{1}.response, [0,97,65]) & (results{1}.rt == 0 | results{1}.rt >= 0.3 | isnan(results{1}.rt)));

            %get row (i.e. trial) numbers for conditions
            row.short = union(find(results{1}.longCSI == 0), find(~ismember(1:62,row.corr))); % add incorrect trials in with short trials
            row.long = intersect(find(results{1}.longCSI == 1), row.corr); % only include long (and correct) trials in analysis

            % NEXT, find all approach/avoid active/passive conditions
            row.approach = find((results{1}.trialtype == 1 & results{1}.selfloc == 3) | (results{1}.trialtype == 2 & results{1}.selfloc ~= 3));
            row.avoid = find((results{1}.trialtype == 1 & results{1}.selfloc ~= 3) | (results{1}.trialtype == 2 & results{1}.selfloc == 3));
            row.passive = find(results{1}.selfloc == 3);
            row.active = find(results{1}.selfloc ~= 3);

            row.passiveapproach = intersect(row.passive, row.approach);
            row.activeapproach = intersect(row.active, row.approach);
            row.passiveavoid = intersect(row.passive, row.avoid);
            row.activeavoid = intersect(row.active, row.avoid);

            %do some checks
            assert(sum([length(row.short),length(row.long)]) == 62,'Error: not all trials are modelled (i.e., the number of trials doesn''t add up to 62)');

            %put in the timings
            onsets{1} = results{1}.timings(row.short,col.StimOnset); %Short
            onsets{2} = results{1}.timings(intersect(row.long, row.passiveapproach),col.StimOnset); %PassiveApproach
            onsets{3} = results{1}.timings(intersect(row.long, row.activeapproach),col.StimOnset); %ActiveApproach
            onsets{4} = results{1}.timings(intersect(row.long, row.passiveavoid),col.StimOnset); %PassiveAvoid
            onsets{5} = results{1}.timings(intersect(row.long, row.activeavoid),col.StimOnset); %ActiveAvoid

            % durations
            [durations{1}, durations{2}, durations{3}, durations{4}, durations{5}] = deal(0); % like a stick function

            %correct for starttime
            for i = 1:numel(onsets)
                onsets{i} = onsets{i} - starttime;
                onsets{i} = onsets{i} - 1.5; % subtract 1 TR (1500 ms)
            end

    end

    %do some checks
    for i = 1:numel(onsets)
        %check only the regressors with variable durations
        if exist('durations','var') % the FIR model has no durations
            if numel(durations{i}) > 1
                assert(length(onsets{i}) == length(durations{i}));
            end
        end
    end

    %save file
    if ~exist(fullfile(padi.func,'log'),'dir')
        mkdir(fullfile(padi.func,'log'));
    end
    savename = fullfile(padi.func,'log',['conditions_run-',num2str(padi.runnrs(c_run)),'.mat']);

    if any(strcmp(DESIGN, {'factorial','basic','FIR'}))
        save(savename,'names','onsets','durations');
    elseif any(strcmp(DESIGN, {'parametric','hybrid','freezing'}))
        save(savename,'names','onsets','durations','pmod','orth');
    end

end
