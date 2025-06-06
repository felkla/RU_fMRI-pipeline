% create onset files for BIDS data -

% Function for writing the onsets files for one subject - the following is
% an example of how onset files are set up to fit the needs of SPM
%
%%% Format must be : file with 3 variables - names, onset, duration

% Example for file with 3 condtions (2 task, 1 baseline)

% names = cell(1,3);
% onsets = cell(1,3);
% durations = cell(1,3);
%
% names{1} = 'add';
% onsets{1} = [166.7742 172.6876 177.7342 184.1456 201.53 209.7 215.9406 225.6018 320.6838 327.4248 332.6936 337.2923];
% durations{1} = [2.3868 3.0553 2.4931 2.4683 2.3368 3.5722 3.0435 3.5707 2.68 3.1327 2.2381 2.3958];
%
% names{2} = 'sub';
% onsets{2} = [69.1668 74.833 92.3837 98.9326 104.372 111.3265 128.8686 136.7567 141.3543 244.29 250.9498 255.3798 260.4096 280.6257 288.6493 296.5246 302.4964];
% durations{2} = [2.5271 2.9987 2.3419 3.0142 1.9604 1.8954 2.7807 2.227 3.3609 1.9426 2.2744 2.4641 2.8919 2.6118 3.0432 3.2123 3.4519];
%
% names{3} = 'fix';
% onsets{3} = [8.2313];
% durations{3} = [24.0826];
%
% Inputs:
% cfg - cfg structure obtained from config_subjects_objdraw
% i_sub - index of the current subject

function create_onset_files(cfg, i_sub)

% setup some variables

func_dir = fullfile(cfg.ds_root,i_sub,'func');
evt_files = dir(fullfile(func_dir,'*events.tsv'));
evt_fnames = {evt_files.name}';

% if the folder already exists then empty it first
if exist(fullfile(cfg.tgt_dir,i_sub, 'onsets'))
    files = dir(fullfile(cfg.tgt_dir,i_sub, 'onsets'));
    for k = 1:length(files)
        delete([fullfile(cfg.tgt_dir,i_sub, 'onsets') '/' files(k).name]);
    end
    rmdir(fullfile(cfg.tgt_dir,i_sub, 'onsets'));
    mkdir(fullfile(cfg.tgt_dir,i_sub, 'onsets'));
end

for this_run = 1:length(evt_fnames)
    
    % load evts file 
    evts = tdfread(fullfile(func_dir,evt_fnames{this_run}));
    
    ons_names = unique(cellstr(evts.trial_type));
    
    % exlude catches
    ons_names(find(strcmpi(ons_names,'Catch')))= [];
    
    onsets = cell(1,length(ons_names));
    names = ons_names; 
    durations = cell(1,length(ons_names)); 
    
    for ons = 1:length(ons_names)
        
        this_ons = ons_names{ons}; 
        
        onsets{ons} = evts.onset(find(strcmpi(cellstr(evts.trial_type),this_ons)));
        
        durations{ons} = evts.duration(find(strcmpi(cellstr(evts.trial_type),this_ons)));
    end 
    
    % if folder does not exist then create it
    if ~exist(fullfile(cfg.tgt_dir,i_sub, 'onsets'))
        mkdir(fullfile(cfg.tgt_dir,i_sub, 'onsets'));
    end
    
    save(fullfile(cfg.tgt_dir,i_sub, 'onsets',[evt_fnames{this_run}(1:end-4),'.mat']), 'names', 'onsets', 'durations');
    
end
end