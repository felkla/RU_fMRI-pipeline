function a_aafreeze_makeconfile(SUBJNAME, DESIGN)

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
            % This first-level model models only trials as whole events
            %names
            names{1} = 'Trial';

            %onsets
            onsets{1} = results{1}.timings(:,col.StimOnset);
            onsets{1} = onsets{1} - starttime; %correct for starttime

            %durations
            durations{1} = (results{1}.timings(:,col.OutOnset)-results{1}.timings(:,col.StimOnset))+cfg.dur.feedback;

        case {'factorial','hybrid'}

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
%             HR part is commented out for now
%             if ~isfield('deltaHR','DataAll')
%                 DataAll = ComputeDeltaHR;
%             end


%             determine which trials (do/don't) have HR
%             (of this ppt/run)
%             noHRind = isnan(DataAll.deltaHR) & ...
%                 DataAll.run == padi.runnrs(c_run) & ...
%                 DataAll.ppnr == subjnr;
% 
%             noHRtrials = DataAll.trialnr(noHRind);
% 
%             remove those noHR trials from the regressors of interest (i.e., all long trials)
%             row.long = setdiff(row.long, noHRtrials);
% 
%             and add them to the short trial selection (so we still model them)
%             row.short = [row.short, noHRtrials']; 

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

            % Add parametric modulators if applicable
            if strcmp(DESIGN,'hybrid')

                % select HR trial indices (per subject):
                HRkeeptrials = find(ismember(DataAll.response, [0,97,65]) & ...
                    (DataAll.rt == 0 | DataAll.rt >= 0.2 | isnan(DataAll.rt)) & ...
                    DataAll.ppnr == subjnr);
                % per run:
%                 HRkeeptrials_r = intersect(HRkeeptrials, find(DataAll.run == padi.runnrs(c_run)));

%                 HR_PasAp = find(DataAll.choice == 2 & DataAll.trialtype == 1);
%                 HR_ActAp = find(DataAll.choice == 2 & DataAll.trialtype == 2);
%                 HR_PasAv = find(DataAll.choice == 1 & DataAll.trialtype == 2);
%                 HR_ActAv = find(DataAll.choice == 1 & DataAll.trialtype == 1);

                % create parametric mod. structure and add trial data
                pmod = struct('name', {''}, 'param',{},'poly',{});

                % PassiveApproach
                % money  
                pmod(2).name{1} = 'ant_Money';
                pmod(2).param{1} = results{1}.rewmagn(intersect(row.long, row.passiveapproach));
                pmod(2).poly{1} = 1;
                assert(length(pmod(2).param{1}) == length(onsets{2}));

                % shocks  
                pmod(2).name{2} = 'ant_Shocks';
                pmod(2).param{2} = results{1}.shockmagn(intersect(row.long, row.passiveapproach));
                pmod(2).poly{2} = 1;
                assert(length(pmod(2).param{2}) == length(onsets{2}));

%                 % deltaHR  
%                 pmod(2).name{3} = 'ant_deltaHR';
%                 pmod(2).param{3} = DataAll.deltaHR(intersect(HRkeeptrials_r, HR_PasAp));
%                 pmod(2).poly{3} = 1;
%                 assert(length(pmod(2).param{3}) == length(onsets{2}));
%                 assert(length(pmod(2).param{3}) == length(pmod(2).param{2}));

                % ActiveApproach
                % money  
                pmod(3).name{1} = 'ant_Money';
                pmod(3).param{1} = results{1}.rewmagn(intersect(row.long, row.activeapproach));
                pmod(3).poly{1} = 1;
                assert(length(pmod(3).param{1}) == length(onsets{3}));

                % shocks  
                pmod(3).name{2} = 'ant_Shocks';
                pmod(3).param{2} = results{1}.shockmagn(intersect(row.long, row.activeapproach));
                pmod(3).poly{2} = 1;
                assert(length(pmod(3).param{2}) == length(onsets{3}));

%                 % deltaHR
%                 pmod(3).name{3} = 'ant_deltaHR';
%                 pmod(3).param{3} = DataAll.deltaHR(intersect(HRkeeptrials_r, HR_ActAp));
%                 pmod(3).poly{3} = 1;
%                 assert(length(pmod(3).param{3}) == length(onsets{3}));
%                 assert(length(pmod(3).param{3}) == length(pmod(3).param{2}));

                % PassiveAvoid
                % money  
                pmod(4).name{1} = 'ant_Money';
                pmod(4).param{1} = results{1}.rewmagn(intersect(row.long,row.passiveavoid));
                pmod(4).poly{1} = 1;
                assert(length(pmod(4).param{1}) == length(onsets{4}));

                % shocks
                pmod(4).name{2} = 'ant_Shocks';
                pmod(4).param{2} = results{1}.shockmagn(intersect(row.long,row.passiveavoid));
                pmod(4).poly{2} = 1;
                assert(length(pmod(4).param{2}) == length(onsets{4}));

%                 % deltaHR
%                 pmod(4).name{3} = 'ant_deltaHR';
%                 pmod(4).param{3} = DataAll.deltaHR(intersect(HRkeeptrials_r, HR_PasAv));
%                 pmod(4).poly{3} = 1;
%                 assert(length(pmod(4).param{3}) == length(onsets{4}));
%                 assert(length(pmod(4).param{3}) == length(pmod(4).param{2}));

                % ActiveAvoid
                % money  
                pmod(5).name{1} = 'ant_Money';
                pmod(5).param{1} = results{1}.rewmagn(intersect(row.long,row.activeavoid));
                pmod(5).poly{1} = 1;
                assert(length(pmod(5).param{1}) == length(onsets{5}));

                % shocks
                pmod(5).name{2} = 'ant_Shocks';
                pmod(5).param{2} = results{1}.shockmagn(intersect(row.long,row.activeavoid));
                pmod(5).poly{2} = 1;
                assert(length(pmod(5).param{2}) == length(onsets{5}));

                % deltaHR
%                 pmod(5).name{3} = 'ant_deltaHR';
%                 pmod(5).param{3} = DataAll.deltaHR(intersect(HRkeeptrials_r, HR_ActAv));
%                 pmod(5).poly{3} = 1;
%                 assert(length(pmod(5).param{3}) == length(onsets{5}));
%                 assert(length(pmod(5).param{3}) == length(pmod(5).param{2}));

                % demean parametric modulators
                % make sure to demean with respect to the subject-average (rather than per run)
                meanMoney = mean(DataAll.money(HRkeeptrials));
                meanShocks = mean(DataAll.shocks(HRkeeptrials));
%                 meanHR = mean(DataAll.deltaHR(HRkeeptrials));

                for c_conds = 1:numel(pmod) %loop over conditions (regressors)

                    if ~isempty(pmod(c_conds).name) %skip conditions without pmods

                        for c_pmod = 1:numel(pmod(c_conds).param) %loop over pmods for this condition

                            % subtract mean money/shock/dHR amount from
                            % each trial
                            if contains(pmod(c_conds).name{c_pmod},'Money')
                                pmod(c_conds).param{c_pmod} = pmod(c_conds).param{c_pmod} - meanMoney;

                            elseif contains(pmod(c_conds).name{c_pmod},'Shocks')
                                pmod(c_conds).param{c_pmod} = pmod(c_conds).param{c_pmod} - meanShocks;

                            elseif contains(pmod(c_conds).name{c_pmod}, 'deltaHR')
                                pmod(c_conds).param{c_pmod} = pmod(c_conds).param{c_pmod} - meanHR;

                            end
                        end
                    end
                end

                %set SPM orthogonalization to 0
                orth = cell(1, numel(onsets));
                for c_orth = 1:numel(orth)
                    orth{c_orth} = 0; %1 = orthogonalize pmods, 0 = don't orth (see Mumford, Poline, & Poldrack, 2015; PLoS ONE)
                end

            end

        case 'parametric'

            % load deltaHR data
            HRpath = fullfile(padi.main, 'scripts', 'HR');
            addpath(HRpath)
            load(fullfile(HRpath, 'DataAll_HR.mat'),'DataAll')
            if ~isfield('deltaHR','DataAll')
                DataAll = ComputeDeltaHR;
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

            %modulator 3: deltaHR modulating anticipation (StimLong)
            pmod(2).name{3} = 'ant_deltaHR';
            pmod(2).param{3} = DataAll.deltaHR(~isnan(DataAll.deltaHR) & ...
                DataAll.run == padi.runnrs(c_run) & ...
                DataAll.ppnr == subjnr);
            % transpose if necessary
            % (make sure all regressors have the same size)
            if size(pmod(2).param{3}) ~= size(pmod(2).param{1})
                pmod(2).param{3} = pmod(2).param{3}';
            end

            pmod(2).poly{3} = 1;
            assert(length(pmod(2).param{3}) == length(onsets{2}));

            % modulator 4: money modulating reward outcome
            pmod(6).name{1} = 'out_Money';
            pmod(6).param{1} = results{1}.rewmagn(intersect(row.long,row.money));
            pmod(6).poly{1} = 1;
            assert(length(pmod(6).param{1}) == length(onsets{6}));

            % modulator 5: shocks modulating punishment outcome
            pmod(7).name{1} = 'out_Shocks';
            pmod(7).param{1} = results{1}.shockmagn(intersect(row.long,row.shocks));
            pmod(7).poly{1} = 1;
            assert(length(pmod(7).param{1}) == length(onsets{7}));

            % demean parametric modulators
            %compute average deltaHR, money, and shock amounts (per subject)
            meanHR = mean(DataAll.deltaHR(DataAll.ppnr == subjnr & ~isnan(DataAll.deltaHR)));
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

            % Finally, add interaction modulators
            % (multiplying the de-meaned main effects)

            % money * shocks (anticipation)
            pmod(2).name{4} = 'ant_MoneyxShocks';
            pmod(2).param{4} = pmod(2).param{1}.*pmod(2).param{2};
            pmod(2).poly{4} = 1;
            assert(length(pmod(2).param{4}) == length(onsets{2}));

            % money * deltaHR (anticipation)
            pmod(2).name{5} = 'ant_MoneyxHR';
            pmod(2).param{5} = pmod(2).param{1}.*pmod(2).param{3};
            pmod(2).poly{5} = 1;
            assert(length(pmod(2).param{5}) == length(onsets{2}));

            % shocks * deltaHR (anticipation)
            pmod(2).name{6} = 'ant_ShocksxHR';
            pmod(2).param{6} = pmod(2).param{2}.*pmod(2).param{3};
            pmod(2).poly{6} = 1;
            assert(length(pmod(2).param{6}) == length(onsets{2}));

            % money * shocks * deltaHR (anticipation)
            pmod(2).name{7} = 'ant_MoneyxShocksxHR';
            pmod(2).param{7} = pmod(2).param{1}.*pmod(2).param{2}.*pmod(2).param{3};
            pmod(2).poly{7} = 1;
            assert(length(pmod(2).param{7}) == length(onsets{2}));

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
    elseif any(strcmp(DESIGN, {'parametric','hybrid'}))
        save(savename,'names','onsets','durations','pmod','orth');
    end

end
