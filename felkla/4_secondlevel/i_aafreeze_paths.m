function padi = i_aafreeze_paths(DESIGN)

%string in subject code
padi.subjcode='*sub*';

%path settings
padi.projectpath=fullfile('/project','3023009.03');
padi.statspath=fullfile(padi.projectpath,'stats','fMRI',DESIGN);
padi.savepath=fullfile(padi.statspath,'groupstats');
padi.maskpath=fullfile(padi.projectpath,'scripts','fMRI','masks');