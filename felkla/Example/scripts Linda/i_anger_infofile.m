function padi=i_anger_infofile(subjname)

%paths
padi.main=fullfile(...
    '/project','3017061.01');
padi.rawdata=fullfile(padi.main,'raw');
padi.data=fullfile(padi.main,'Anger','work_data');
padi.func=fullfile(padi.data,char(subjname),'func');
padi.struc=fullfile(padi.data,char(subjname),'struc');
padi.anat=fullfile(padi.struc,'T1_1');

padi.tasks={'task_1','task_2','task_3'};

padi.log=fullfile(padi.data,char(subjname),'log');
padi.meanEPI=fullfile(padi.struc,'meanEPI');
padi.stats=fullfile(padi.main,'Anger','analysis');

padi.templates=fullfile(padi.main,'Anger','templates');

