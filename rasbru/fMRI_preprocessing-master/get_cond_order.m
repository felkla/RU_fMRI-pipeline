% function to obtain the order of conditions that were presented in
% different runs for the objdraw experiment
function cond_order=get_cond_order(prep,i_sub)

ons_names = dir(fullfile(prep.tgt_dir,i_sub,'onsets','*task-main*'));
ons_names = {ons_names.name}';
conds = {'Photo', 'Drawing', 'Sketch'};

for i=1:length(ons_names)
    
    load(fullfile(prep.tgt_dir,i_sub,'onsets',ons_names{i}))
    
    cond_idx = find(strcmpi(conds,names{1}(1:end-2)));
    
    cond_order(i) = cond_idx;
end 
    
end 