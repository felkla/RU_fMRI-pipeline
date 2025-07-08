% function to obtain the order of conditions that were presented in
% different runs
function cond_order=get_cond_order(prep,i_sub)

ons_names = dir(fullfile(prep.tgt_dir,i_sub,'onsets','*Predator*'));
ons_names = {ons_names.name}';
conds = {'Prediction';'WaitScene';'Outcome';'ITI'};

for i=1:length(ons_names)

    load(fullfile(prep.tgt_dir,i_sub,'onsets',ons_names{i}))

    cond_idx = find(strcmpi(conds, names{1}));
    
    cond_order(i) = cond_idx;
end

end