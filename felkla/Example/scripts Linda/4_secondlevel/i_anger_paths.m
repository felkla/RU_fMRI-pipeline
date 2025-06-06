function padi=i_anger_paths(taskname)


%string in subject code
padi.subjcode='*sub*';

%path settings
padi.projectpath=fullfile('/project','3017061.01','Anger');
padi.statspath=fullfile(padi.projectpath,'analysis','fMRI',taskname);
padi.savepath=fullfile(padi.statspath,'groupstats');



% 
% %path settings
% homepath='F:';
% projectpath=fullfile(homepath,'projects','FCWML_fMRI');
% datapath=fullfile(projectpath,'data');
% statspath=fullfile(projectpath,'stats','fMRI','Day1','groupstats');
% nbackpaths={'T_neg_nback','T_pos_nback'};
% new_nbackpaths={'neg_nback_nbackgrouponly','pos_nback_nbackgrouponly'};
% groupcontrastfolders={'gr1','gr2'};