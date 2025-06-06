function padi = i_aafreeze_paths(DESIGN, ROUTE)

%string in subject code
padi.subjcode='*sub*';

%path settings
padi.projectpath=fullfile('/project','3023009.03');
if strcmp(DESIGN,'freezing')
    padi.statspath=fullfile(padi.projectpath,'stats','fMRI',DESIGN, ['R' num2str(ROUTE)]);
else
    padi.statspath=fullfile(padi.projectpath,'stats','fMRI',DESIGN);
end
padi.savepath=fullfile(padi.statspath,'groupstats');
padi.maskpath=fullfile(padi.projectpath,'scripts','fMRI','masks');