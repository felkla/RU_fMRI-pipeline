%% script to concatenate FIR time-series data (bins)
% Felix Klaassen January 2023

%% Approach-Avoid-Passive-Active
% find data files
if ispc
    projectpath = 'P:\3023009.03\';
elseif isunix
    projectpath = '/project/3023009.03/';
end
statspath = fullfile(projectpath,'stats','fMRI','FIR','groupstats');
addpath beeswarm-master

% indicate filename of extracted data
extr_names = {'extr_amygdala_LR.mat','extr_ventralStriatum_LR.mat','extr_vmPFC_LR.mat'};
extr_name = extr_names{3}; % change this

% precreate data matrix
data = cell(2,2);
[data{1,1}, data{1,2}, data{2,1}, data{2,2}] = deal([]);
data_names = {'Approach-Passive','Approach-Active';'Avoid-Passive','Avoid-Active'};

contrasts = dir([statspath,filesep,'T_*']);
contrastnames = {}; [contrastnames{1:length(contrasts),1}] = deal(contrasts.name);

for i = 1:length(contrastnames)
    % load data per contrast
    data_temp = load(fullfile(statspath,contrastnames{i},extr_name));

    if contains(contrastnames{i},'Approach')
        r = 1;
    elseif contains(contrastnames{i},'Avoid')
        r = 2;
    end
    if contains(contrastnames{i},'Passive')
        c = 1;
    elseif contains(contrastnames{i},'Active')
        c = 2;
    end

    data{r,c} = [data{r,c}, data_temp.sigextr'];
end

%% Plots
% --- Preparation --- %
time = -1.5:1.5:9;

% baseline correction (per subject)
subMeans = cat(3,mean(cat(3,data{1,1},data{1,2}),3),mean(cat(3,data{2,1},data{2,2}),3));
subMeans = subMeans(:,1,:);
subMeans = mean(subMeans,3); % mean signal per subject of bin1
data_cor = cell(size(data)); % create matrix for baseline corrected data
for ch = 1:2
    for resp = 1:2
        for bin = 1:size(data{ch,resp},2)
            % subtract subject-wise grand-means of bin1 from subject-wise condition-means (per bin)
            data_cor{ch,resp}(:,bin) = data{ch,resp}(:,bin)-subMeans;
        end
    end
end

% baseline correction (per condition)
data_cor = cell(size(data));
baseVals = NaN(58,1);
for ch = 1:2
    for resp = 1:2
        baseVals = data{ch,resp}(:,1); % take values of bin1
        for t = 1:8
            % subtract from all bins (1-8)
            data_cor{ch,resp}(:,t) = data{ch,resp}(:,t)-baseVals;
        end
    end
end

% --- Approach vs. Avoid --- %
% first average over passive vs. active responses
Approach = mean(cat(3,data_cor{1,1},data_cor{1,2}),3);
Avoid = mean(cat(3,data_cor{2,1},data_cor{2,2}),3);

% compute standard error of the mean
if exist('stdErr','var');clearvars stdErr;end
for i = 1:size(Approach,2)
    stdErr.Approach(i) = std(Approach(:,i))/sqrt(size(Approach,1));
    stdErr.Avoid(i) = std(Avoid(:,i))/sqrt(size(Avoid,1));
end

f = figure;
% fill([0,6,6,0],[-0.1,-0.1,0.1,0.1],[0.85,0.85,0.85],'EdgeColor','none');
line([-2,10.5],[0,0],'Color','k'); hold on
line([0,0],[-1,1],'Color','k');

% Individual data points
swarmchart(time(2:end)-0.1, Approach(:,2:end), 16, [0.106,0.619,0.467], 'filled','MarkerFaceAlpha',0.3,'MarkerEdgeAlpha',0.3)
swarmchart(time(2:end)+0.1, Avoid(:,2:end), 16, [0.459,0.439,0.7], 'filled','MarkerFaceAlpha',0.3,'MarkerEdgeAlpha',0.3)

% Averages
% Approach
er1 = errorbar(time-0.1,mean(Approach),stdErr.Approach);
er1.Color = [0.106,0.619,0.467]; er1.LineStyle = 'none'; er1.LineWidth = 1;
plot(time-0.1, mean(Approach),'-o','Color',[0.106,0.619,0.467],'LineWidth',1,'MarkerSize',8,'MarkerEdgeColor',[0.106,0.619,0.467],'MarkerFaceColor',[0.106,0.619,0.467]); % black: 'k'; or green: [0.106,0.619,0.467]
% plot(time, Approach, 'o','Color',[0.106,0.619,0.467, 0.2],'MarkerSize',4,'MarkerEdgeColor',[0.106,0.619,0.467],'MarkerFaceColor',[0.106,0.619,0.467]); % black: 'k'; or green: [0.106,0.619,0.467])
% xlim([-2, 10]); ylim([-0.4, 0.2]);

% Avoid
er2 = errorbar(time+0.1,mean(Avoid),stdErr.Avoid);
er2.Color = [0.459,0.439,0.7]; er2.LineStyle = 'none'; er2.LineWidth = 1;
plot(time+0.1, mean(Avoid),'-o','Color',[0.459,0.439,0.7],'LineWidth',1,'MarkerSize',8,'MarkerEdgeColor',[0.459,0.439,0.7],'MarkerFaceColor',[0.459,0.439,0.7]); % white: [1,1,1,]; or purple: [0.459,0.439,0.7]

% aesthetics
xlim([-2, 10]); %ylim([-0.04, 0.02]);
if strcmp(extr_name, extr_names{1})
    ylim([-0.04, 0.02]);
%     ylim([-0.11 0.05]) 
elseif strcmp(extr_name, extr_names{2})
    ylim([-0.02, 0.03]);
%     ylim([-0.11 0.05]) 
elseif strcmp(extr_name, extr_names{3})
    ylim([-0.02, 0.02]);
%     ylim([-0.11 0.05])
end
set(gca, "XTick",-2:1:10, "YTick", -0.5:0.01:0.5); %legend({'Stimulus screen','','','','','','','Approach','','Avoid'});
title(extr_name(6:end-7)); xlabel('Time (s)'); ylabel('arbitrary units')

saveas(f,['plots' filesep [extr_name(6:end-7) '_choice-cor'] '.pdf']);

% --- Passive vs. Active --- %
% first average over passive vs. active responses
Passive = mean(cat(3,data_cor{1,1},data_cor{2,1}),3);
Active = mean(cat(3,data_cor{1,2},data_cor{2,2}),3);

% compute standard error of the mean
if exist('stdErr','var');clearvars stdErr;end
for i = 1:size(Passive,2)
    stdErr.Passive(i) = std(Passive(:,i))/sqrt(size(Passive,1));
    stdErr.Active(i) = std(Active(:,i))/sqrt(size(Active,1));
end

f = figure;
% fill([0,6,6,0],[-0.1,-0.1,0.1,0.1],[0.85,0.85,0.85],'EdgeColor','none');
line([-2,10.5],[0,0],'Color','k'); hold on
line([0,0],[-1,1],'Color','k');

% Individual data points
swarmchart(time(2:end)-0.1, Passive(:,2:end), 16, [1 1 1], 'filled', 'MarkerEdgeColor', 'k','MarkerFaceAlpha',0.3,'MarkerEdgeAlpha',0.3)
swarmchart(time(2:end)+0.1, Active(:,2:end), 16, [0 0 0], 'filled','MarkerFaceAlpha',0.3,'MarkerEdgeAlpha',0.3)

% Averages
% Passive
er1 = errorbar(time-0.1,mean(Passive),stdErr.Passive);
er1.Color = 'k'; er1.LineStyle = 'none'; er1.LineWidth = 1;
plot(time-0.1, mean(Passive),'--o','Color','k','LineWidth',1,'MarkerSize',8,'MarkerEdgeColor','k','MarkerFaceColor',[1 1 1]); % black

% Active
er2 = errorbar(time+0.1,mean(Active),stdErr.Active);
er2.Color = 'k'; er2.LineStyle = 'none'; er2.LineWidth = 1;
plot(time+0.1, mean(Active),'-o','Color','k','LineWidth',1,'MarkerSize',8,'MarkerEdgeColor','k','MarkerFaceColor','k'); % white

% aesthetics
xlim([-2, 10]); %ylim([-0.04, 0.02]);
if strcmp(extr_name, extr_names{1})
    ylim([-0.04, 0.02]);
%     ylim([-0.11 0.05]) 
elseif strcmp(extr_name, extr_names{2})
    ylim([-0.02, 0.03]);
%     ylim([-0.11 0.05]) 
elseif strcmp(extr_name, extr_names{3})
    ylim([-0.02, 0.02]);
%     ylim([-0.11 0.05])
end

set(gca, "XTick",-2:1:10, "YTick", -0.5:0.01:0.5); %legend({'Stimulus screen','','','','Passive','','Active'});
title(extr_name(6:end-7)); xlabel('Time (s)'); ylabel('arbitrary units')

saveas(f,['plots' filesep [extr_name(6:end-7) '_response-cor'] '.pdf']);

% --- Choice * Response (interaction) --- %
% compute standard error of the mean
stdErr = cell(size(data_cor));
for i = 1:size(data_cor{1,1},2)
    stdErr{1,1}(i) = std(data_cor{1,1}(:,i))/sqrt(size(data_cor{1,1},1)); % Approach-Passive
    stdErr{2,1}(i) = std(data_cor{2,1}(:,i))/sqrt(size(data_cor{2,1},1)); % Avoid-Passive
    stdErr{1,2}(i) = std(data_cor{1,2}(:,i))/sqrt(size(data_cor{1,2},1)); % Approach-Active
    stdErr{2,2}(i) = std(data_cor{2,2}(:,i))/sqrt(size(data_cor{2,2},1)); % Avoid-Active
end

titles = {'Passive','Active'};
figure;
for sp = 1:2
    subplot(1,2,sp);
    fill([0,6,6,0],[-0.1,-0.1,0.1,0.1],[0.85,0.85,0.85],'EdgeColor','none');
    line([-2,10.5],[0,0],'Color','k'); hold on
    line([0,0],[-1,1],'Color','k');
    
    % Approach
    er1 = errorbar(time,mean(data_cor{1,sp}),stdErr{1,sp}); % approach
    er1.Color = [0.106,0.619,0.467]; er1.LineStyle = 'none'; er1.LineWidth = 1;
    plot(time, mean(data_cor{1,sp}),'-o','Color',[0.106,0.619,0.467],'LineWidth',1,'MarkerSize',8,'MarkerEdgeColor',[0.106,0.619,0.467],'MarkerFaceColor',[0.106,0.619,0.467]); % green

    % Avoid
    er2 = errorbar(time,mean(data_cor{2,sp}),stdErr{2,sp}); % avoid
    er2.Color = [0.459,0.439,0.7]; er2.LineStyle = 'none'; er2.LineWidth = 1;
    plot(time, mean(data_cor{2,sp}),'-o','Color',[0.459,0.439,0.7],'LineWidth',1,'MarkerSize',8,'MarkerEdgeColor',[0.459,0.439,0.7],'MarkerFaceColor',[0.459,0.439,0.7]); % purple

    xlim([-2, 10]); ylim([-0.02, 0.02]);
    set(gca, "XTick",-2:1:10, "YTick", -0.05:0.01:0.05); legend({'Stimulus screen','','','','Approach','','Avoid'});
    title(titles{sp}); xlabel('Time (s)'); ylabel('arbitrary units')
end
sgtitle(extr_name(6:end-7));


%% Statistics

% --- Do 3-way repeated measures ANOVA (time * choice * response) --- %
% First, create the data matrix.
% Each ppt and conditions corresponds to a matrix dimension:
% 1 (rows) = participants   (1-58)
% 2 (cols) = time           (1-8)
% 3        = choice         (approach/avoid)
% 4        = response       (passive/active)
bins = 2:5; %only include bin 2 - 5 (last bin is 4.5 - 6 sec. post trial onset)
datamat = NaN(58,numel(bins),2,2); 
for s = 1:58
    for t = 1:numel(bins)
        for ch = 1:2
            for resp = 1:2
                datamat(s,t,ch,resp) = data_cor{ch,resp}(s,t+1);
            end
        end
    end
end

within_factor_names = {'time','choice','response'};

[tbl,rm] = simple_mixed_anova(datamat,[],within_factor_names);
sph = mauchly(rm);
ep = epsilon(rm);

% --- Follow-up paired sample t-tests for significant effects --- %
% time-by-choice - for each time bin test the effect of choice
Approach = mean(cat(3,data_cor{1,1},data_cor{1,2}),3);
Avoid = mean(cat(3,data_cor{2,1},data_cor{2,2}),3);
[h, p, ci, stats] = deal(cell(1,numel(bins)));
for t = 1:numel(bins)
    [h{t},p{t},ci{t},stats{t}] = ttest(Approach(:,t+1), Avoid(:,t+1));
end

% time-by-response - for each time bin test the effect of response
Passive = mean(cat(3,data{1,1},data{2,1}),3);
Active = mean(cat(3,data{1,2},data{2,2}),3);
[h, p, ci, stats] = deal(cell(1,numel(bins)));
for t = 1:numel(bins)
    [h{t},p{t},ci{t},stats{t}] = ttest(Active(:,t+1), Passive(:,t+1));
end
