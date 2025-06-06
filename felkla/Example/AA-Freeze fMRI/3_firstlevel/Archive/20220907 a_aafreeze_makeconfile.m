function a_aafreeze_makeconfile(SUBJNAME, DESIGN, est_level)

%--------------------------------------------------------------------------
%
% Will make a conditions.mat file which can be used as an input for SPM
%
%LdV2018, adapted by FelKla 2020
% Added an additional 'DESIGN' input to flexibly switch between factorial
% and parametric designs
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
            % unrealistically fast RTs (i.e., below 200 ms, 300 ms uncorrected)
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

        case 'hybrid'
            % This model attempts to model both the 'categorical' choice
            % regressors, as well as modulate those with pmods for money
            % and shocks

            %names
            names{1}='StimShort';
            names{2}='StimApproach';
            names{3}='StimAvoid';
            names{4}='MovShort';
            names{5}='MovPassive';
            names{6}='MovActive';
            names{7}='Money';
            names{8}='Shocks';
            names{9}='Neutral';

            % FIRST, find out which trials to exclude and which to keep

            % make sure to exclude trials with incorrect button-press or
            % unrealistically fast RTs (i.e., below 200 ms)
            row.corr = find(ismember(results{1}.response, [0,97,65]) & (results{1}.rt == 0 | results{1}.rt >= 0.2 | isnan(results{1}.rt)));

            %get row (i.e. trial) numbers for conditions
            row.short = union(find(results{1}.longCSI == 0), find(~ismember(1:62,row.corr))); % add incorrect trials in with short trials
            row.long = intersect(find(results{1}.longCSI == 1), row.corr); % only include long (and correct) trials in analysis

            % also make sure to exclude trials with no HR data available
            % load deltaHR data
            HRpath = fullfile(padi.main, 'scripts', 'HR');
            addpath(HRpath)
            load(fullfile(HRpath, 'DataAll_HR.mat'),'DataAll')

            % NEXT, find all approach/avoid active/passive conditions
            row.approach = find((results{1}.trialtype == 1 & results{1}.selfloc == 3) | (results{1}.trialtype == 2 & results{1}.selfloc ~= 3));
            row.avoid = find((results{1}.trialtype == 1 & results{1}.selfloc ~= 3) | (results{1}.trialtype == 2 & results{1}.selfloc == 3));
            row.passive = find(results{1}.selfloc == 3);
            row.active = find(results{1}.selfloc ~= 3);

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
            onsets{2} = results{1}.timings(intersect(row.long, row.approach),col.StimOnset); %StimApproach
            onsets{3} = results{1}.timings(intersect(row.long, row.avoid),col.StimOnset); %StimAvoid

            onsets{4} = results{1}.timings(row.short,col.MovOnset)+0.1; %MovShort
            onsets{5} = results{1}.timings(intersect(row.long, row.passive),col.MovOnset)+0.1; %MovPassive
            onsets{6} = results{1}.timings(intersect(row.long, row.active),col.MovOnset)+0.1; %MovActive

            onsets{7} = results{1}.timings(row.money, col.OutOnset); %Money
            onsets{8} = results{1}.timings(row.shocks, col.OutOnset); %Shocks
            onsets{9} = results{1}.timings(row.neutral, col.OutOnset); %Neutral

            %correct for starttime
            for i = 1:numel(onsets)
                onsets{i} = onsets{i} - starttime;
            end

            %durations
            % I add 100 ms to all anticipation window durations to correct for first target-movement location
            durations{1} = cfg.cb_mat{1}(row.short,5)+0.1; %StimShort

            durations{2} = cfg.cb_mat{1}(intersect(row.long, row.approach),5)+0.1; %StimApproach
            durations{3} = cfg.cb_mat{1}(intersect(row.long, row.avoid),5)+0.1; %StimAvoid

            [durations{4}, durations{5}, durations{6}] = deal(0); % Stick function
            [durations{7}, durations{8}, durations{9}] = deal(1.5); %outcome is always 1.5s

            % ADD PARAMETRIC MODULATORS
            % select HR trial indices (per subject):
            HRkeeptrials.approach = find(ismember(DataAll.response, [0,97,65]) & ...
                (DataAll.rt == 0 | DataAll.rt >= 0.2 | isnan(DataAll.rt)) & ...
                DataAll.ppnr == subjnr & ...
                DataAll.choice == 2);

            HRkeeptrials.avoid = find(ismember(DataAll.response, [0,97,65]) & ...
                (DataAll.rt == 0 | DataAll.rt >= 0.2 | isnan(DataAll.rt)) & ...
                DataAll.ppnr == subjnr &...
                DataAll.choice == 1);

            % per run:
            %             HRkeeptrials_r = intersect(HRkeeptrials, find(DataAll.run == padi.runnrs(c_run)));
            %
            %             HR_PasAp = find(DataAll.choice == 2 & DataAll.trialtype == 1);
            %             HR_ActAp = find(DataAll.choice == 2 & DataAll.trialtype == 2);
            %             HR_PasAv = find(DataAll.choice == 1 & DataAll.trialtype == 2);
            %             HR_ActAv = find(DataAll.choice == 1 & DataAll.trialtype == 1);

            % create parametric mod. structure and add trial data
            pmod = struct('name', {''}, 'param',{},'poly',{});

            % Approach
            % money
            pmod(2).name{1} = 'Money';
            pmod(2).param{1} = results{1}.rewmagn(intersect(row.long, row.approach));
            pmod(2).poly{1} = 1;
            assert(length(pmod(2).param{1}) == length(onsets{2}));

            % shocks
            pmod(2).name{2} = 'Shocks';
            pmod(2).param{2} = results{1}.shockmagn(intersect(row.long, row.approach));
            pmod(2).poly{2} = 1;
            assert(length(pmod(2).param{2}) == length(onsets{2}));

            % Avoid
            % money
            pmod(3).name{1} = 'Money';
            pmod(3).param{1} = results{1}.rewmagn(intersect(row.long, row.avoid));
            pmod(3).poly{1} = 1;
            assert(length(pmod(3).param{1}) == length(onsets{3}));

            % shocks
            pmod(3).name{2} = 'Shocks';
            pmod(3).param{2} = results{1}.shockmagn(intersect(row.long, row.avoid));
            pmod(3).poly{2} = 1;
            assert(length(pmod(3).param{2}) == length(onsets{3}));

            % demean parametric modulators (wrt subject-level mean per condition)
            meanMoney.approach  = mean(DataAll.money(HRkeeptrials.approach));
            meanMoney.avoid     = mean(DataAll.money(HRkeeptrials.avoid));
            meanShocks.approach = mean(DataAll.shocks(HRkeeptrials.approach));
            meanShocks.avoid    = mean(DataAll.shocks(HRkeeptrials.avoid));

            % approach
            pmod(2).param{1} = pmod(2).param{1} - meanMoney.approach;  % money
            pmod(2).param{2} = pmod(2).param{2} - meanShocks.approach; % shocks

            % avoid
            pmod(3).param{1} = pmod(3).param{1} - meanMoney.avoid;  % money
            pmod(3).param{2} = pmod(3).param{2} - meanShocks.avoid; % shocks

            % Then, add the interactions between money and shocks
            % approach
            %pmod(2).name{3} = 'Money-by-Shocks';
            %pmod(2).param{3} = pmod(2).param{1}.*pmod(2).param{2};
            %pmod(2).poly{3} = 1;
            %
            % avoid
            %pmod(3).name{3} = 'Money-by-Shocks';
            %pmod(3).param{3} = pmod(3).param{1}.*pmod(3).param{2};
            %pmod(3).poly{3} = 1;

            % Finally, set SPM orthogonalization to 0
            orth = cell(1, numel(onsets));
            for c_orth = 1:numel(orth)
                orth{c_orth} = 0; %1 = orthogonalize pmods, 0 = don't orth (see Mumford, Poline, & Poldrack, 2015; PLoS ONE)
            end

        case 'parametric'
            % This model only has single events per phase of the task (stimulus ->
            % movement -> outcome), and parametric modulators of the
            % stimulus and outcome events of money and shocks (and hr)
            
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
            row.short = [row.short, noHRtrials']; % note that 'incorrect' and 'too fast trials' are not in here yet. Maybe still add?

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

            % modulator 3: money modulating reward outcome
            pmod(6).name{1} = 'out_Money';
            pmod(6).param{1} = results{1}.rewmagn(intersect(row.long,row.money));
            pmod(6).poly{1} = 1;
            assert(length(pmod(6).param{1}) == length(onsets{6}));

            % modulator 4: shocks modulating punishment outcome
            pmod(7).name{1} = 'out_Shocks';
            pmod(7).param{1} = results{1}.shockmagn(intersect(row.long,row.shocks));
            pmod(7).poly{1} = 1;
            assert(length(pmod(7).param{1}) == length(onsets{7}));

            % demean parametric modulators
            %compute average deltaHR, money, and shock amounts (per subject)
            meanMoney = mean(DataAll.money(DataAll.ppnr == subjnr & ~isnan(DataAll.deltaHR)));
            meanShocks = mean(DataAll.shocks(DataAll.ppnr == subjnr & ~isnan(DataAll.deltaHR)));

            for c_conds = 1:numel(pmod) %loop over conditions (regressors)

                if ~isempty(pmod(c_conds).name) %skip conditions without pmods

                    for c_pmod = 1:numel(pmod(c_conds).param) %loop over pmods for this condition

                        % Make sure to demean with respect to the subject-average (rather than per run)
                        if contains(pmod(c_conds).name{c_pmod},'deltaHR')

                            % Subtract mean deltaHR from each individual trial
                            pmod(c_conds).param{c_pmod} = pmod(c_conds).param{c_pmod} - meanHR;

                        elseif contains(pmod(c_conds).name{c_pmod},'Money')

                            % Subtract from each individual trial
                            pmod(c_conds).param{c_pmod} = pmod(c_conds).param{c_pmod} - meanMoney;

                        elseif contains(pmod(c_conds).name{c_pmod},'Shocks')

                            % Subtract from each individual trial
                            pmod(c_conds).param{c_pmod} = pmod(c_conds).param{c_pmod} - meanShocks;

                        end
                    end
                end
            end

            %set SPM orthogonalization to 0
            orth = cell(1, numel(onsets));
            for c_orth = 1:numel(orth)
                orth{c_orth} = 0; %1 = orthogonalize pmods, 0 = don't orth (see Mumford, Poline, & Poldrack, 2015; PLoS ONE)
            end

        case {'freezing','freezing_Bsf','freezing_Bmsf','freezing_Btf'}
            % These models are are similar to the 'parametric' model above,
            % but with different pmods. It has 5 pmods for the stimulus
            % event: EVbase, EVdiff_R1, EV_diffR2, EV_diffR3 (and HR).
            % Where EVbase is the trial-by-trial expected value generated
            % by the base model, and EVdiff_R1 to R3 are the difference
            % between the R1, R2, and R3 models and the base model (wrt the
            % EV). So EVdiff_Rx = EVbase - EV_Rx. HR is the raw
            % trial-by-trial heart rate deceleration to attempt to control
            % for basic (task unspecific) HR effects.

            % load deltaHR data
            HRpath = fullfile(padi.main, 'scripts', 'HR');
            addpath(HRpath)
            load(fullfile(HRpath, 'DataAll_HR.mat'),'DataAll')
            if ~isfield(DataAll,'woi') || (DataAll.woi(1) ~= 5 || DataAll.woi(2) ~= 7) % make sure we use the [5 7] dHR window
                DataAll = ComputeDeltaHR([5 7],[],[]);
            end

            % load parametric modulators:
            [freezeDat, freezeDiff, meanFreezeDiff] = deal(cell(1,3));

            % 1) Base model
            baseDat = importfile(fullfile(padi.trialvals,'Base',est_level,['s' num2str(subjnr) '.csv']));

            % 2) Freeze models
            % route 1
            freezeDat{1} = importfile(fullfile(padi.trialvals,'Base_Bsf',est_level,['s' num2str(subjnr) '.csv']));  % raw values
            freezeDiff{1} = baseDat.TrialVals-freezeDat{1}.TrialVals;                                               % difference values

            % route 2
            freezeDat{2} = importfile(fullfile(padi.trialvals,'Base_Bmsf',est_level,['s' num2str(subjnr) '.csv'])); % raw values
            freezeDiff{2} = baseDat.TrialVals-freezeDat{2}.TrialVals;                                               % difference values

            % route 3
            freezeDat{3} = importfile(fullfile(padi.trialvals,'Base_Btf',est_level,['s' num2str(subjnr) '.csv']));  % raw values
            freezeDiff{3} = baseDat.TrialVals-freezeDat{3}.TrialVals;                                               % difference values

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

            % determine which trials (do/don't) have HR (of this ppt/run)
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

            %modulator 1: trial-by-trial values of base model
            pmod(2).name{1} = 'ant_valBase';
            pmod(2).param{1} = baseDat.TrialVals(baseDat.run == padi.runnrs(c_run)); % trial-by-trial values for this RUN
            pmod(2).poly{1} = 1;
            assert(length(pmod(2).param{1}) == length(onsets{2}));

            %modulator 2: trial-by-trial diff of base model and R1 values
            pmodname = 'ant_valR1';
            pmod(2).name{2} = pmodname;
            pmod(2).param{2} = freezeDiff{1}(freezeDat{1}.run == padi.runnrs(c_run)); % trial-by-trial diff values for this RUN
            pmod(2).poly{2} = 1;
            assert(length(pmod(2).param{2}) == length(onsets{2}));

            %modulator 3: trial-by-trial diff of base model R2 values
            pmodname = 'ant_valR2';
            pmod(2).name{3} = pmodname;
            pmod(2).param{3} = freezeDiff{2}(freezeDat{2}.run == padi.runnrs(c_run)); % trial-by-trial diff values for this RUN
            pmod(2).poly{3} = 1;
            assert(length(pmod(2).param{3}) == length(onsets{2}));

            %modulator 4: trial-by-trial diff of base model and R3 values
            pmodname = 'ant_valR3';
            pmod(2).name{4} = pmodname;
            pmod(2).param{4} = freezeDiff{3}(freezeDat{3}.run == padi.runnrs(c_run)); % trial-by-trial diff values for this RUN
            pmod(2).poly{4} = 1;
            assert(length(pmod(2).param{4}) == length(onsets{2}));

            %modulator 5: trial-by-trial raw HR values
%             HRind = find(DataAll.run == padi.runnrs(c_run) & ...
%                 DataAll.ppnr == subjnr & ~isnan(DataAll.deltaHR));
%             assert(all(DataAll.trialnr(HRind)==baseDat.trial(baseDat.run == padi.runnrs(c_run)))); %check that HRtrials and behavioral trials match up
% 
%             pmod(2).name{5} = 'dHR';
%             pmod(2).param{5} = DataAll.deltaHR(HRind); % trial-by-trial raw HR values for this RUN
%             pmod(2).poly{5} = 1;
%             assert(length(pmod(2).param{5}) == length(onsets{2}));

            %demean pmods
            meanBaseParam = mean(baseDat.TrialVals); % compute mean across runs (so for whole subject)
            for i = 1:numel(freezeDiff)
                meanFreezeDiff{i} = mean(freezeDiff{i}); % compute mean across runs (so for whole subject)
            end
%             meanRawHR = mean(DataAll.deltaHR(DataAll.ppnr == subjnr & ~isnan(DataAll.deltaHR)));

            pmod(2).param{1} = pmod(2).param{1} - meanBaseParam;     % subtract mean from trial-values
            pmod(2).param{2} = pmod(2).param{2} - meanFreezeDiff{1}; % subtract mean from trial-diffs
            pmod(2).param{3} = pmod(2).param{3} - meanFreezeDiff{2}; % subtract mean from trial-diffs
            pmod(2).param{4} = pmod(2).param{4} - meanFreezeDiff{3}; % subtract mean from trial-diffs
%             pmod(2).param{5} = pmod(2).param{5} - meanRawHR;         % subtract mean from HR

            %set SPM orthogonalization to 0
            orth = cell(1, numel(onsets));
            for c_orth = 1:numel(orth)
                orth{c_orth} = 0; %1 = orthogonalize pmods, 0 = don't orth (see Mumford, Poline, & Poldrack, 2015; PLoS ONE)
            end

    end

    %do some checks
    for i = 1:numel(onsets)
        %check only the regressors with variable durations
        if numel(durations{i}) > 1
            assert(length(onsets{i}) == length(durations{i}));
        end
    end

    %save file
    if ~exist(fullfile(padi.func,'log'),'dir')
        mkdir(fullfile(padi.func,'log'));
    end
    savename = fullfile(padi.func,'log',['conditions_run-',num2str(padi.runnrs(c_run)),'.mat']);

    if any(strcmp(DESIGN, {'factorial','basic'}))
        save(savename,'names','onsets','durations');
    elseif any(strcmp(DESIGN, {'parametric','hybrid','freezing'}))
        save(savename,'names','onsets','durations','pmod','orth');
    end

end
