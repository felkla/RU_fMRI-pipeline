%reads out DICOM Files and imports them

% load participant list containing prismaNrs and subject IDs
load '/home/klaassen/projects/telos/data/participantList.mat'

pptIncl = [0,0,0,1,1,1,1,1];
impType = input('Please indicate whether to import EPI or anat files (EPI/anat): ');

for s = 1:numel(participantList.prismaNrs)
    if ~pptIncl(s)
        % skip pilot participants
        continue
    else
        prismanr = participantList.prismaNrs{s};
        [fh,r] = system(['dicq -f PRISMA_' num2str(prismanr)]);
        
        % select correct MR series
        series = splitlines(r);
        h = 1; series2keep = [];
        if strcmp(impType,'EPI')
            % select EPI series
            for i = 1:length(series)
                if ~isempty(strfind(series{i},'ninEPI_bold_v12C'))
                    series2keep(h) = i;
                    h = h+1;
                end
            end
        elseif strcmp(impType,'anat')
            % select anatomical image
            for i = 1:length(series)
                if ~isempty(strfind(series{i},'mprage'))
                    series2keep(h) = i;
                    h = h+1;
                end
            end
        end

        for j=1:length(series2keep)
            a=strfind(series{series2keep(j)},'/common');
            %     b=strfind(series{series2keep(j)},'.0');
            %     b=strfind(series{series2keep(j)},'\n');

            pa=series{series2keep(j)}(a:end);
            %     c=[];
            %     c=strfind(pa,' ');
            %     if ~isempty(c)
            %         pa(c)=[];
            %     end
            %     pa2=cellstr(pa);
            %     filez=dir(fullfile(pa2{1},'MR*'));
            filez=dir(fullfile(pa,'MR*'));

            clear f2nifti
            for i=1:length(filez)
                f2nifti{i,:}=fullfile(filez(i).folder,filez(i).name);
            end

            % Specify the directory path you want to create (quasi-BIDS)
            if contains(participantList.subjNames{s},'pilot')
                if strcmp(impType,'EPI')
                    outputDirectory = fullfile('/projects/crunchie/telos/pilot/data',participantList.subjNames{s},'func',['run' num2str(j)]);
                elseif strcmp(impType,'anat')
                    outputDirectory = fullfile('/projects/crunchie/telos/pilot/data',participantList.subjNames{s},'anat');
                end
            else
                if strcmp(impType,'EPI')
                    outputDirectory = fullfile('/projects/crunchie/telos/data',participantList.subjNames{s},'func',['run' num2str(j)]);
                elseif strcmp(impType,'anat')
                    outputDirectory = fullfile('/projects/crunchie/telos/data',participantList.subjNames{s},'anat');
                end
            end

            % Check if the directory exists
            if ~exist(outputDirectory, 'dir')
                % If it doesn't exist, create it
                mkdir(outputDirectory);
                disp(['Directory created: ' outputDirectory]);
            else
                disp(['Directory already exists: ' outputDirectory]);
            end

            %run the batch
            if strcmp(impType,'EPI')
                fprintf('Converting %s, EPI images, run %i\n',participantList.subjNames{s}, j);
            elseif strcmp(impType,'anat')
                fprintf('Converting %s, anatomical image\n',participantList.subjNames{s});
            end
            matlabbatch=[];
            matlabbatch{1}.spm.util.import.dicom.data = cellstr(f2nifti);
            matlabbatch{1}.spm.util.import.dicom.root = 'flat';
            matlabbatch{1}.spm.util.import.dicom.outdir = {outputDirectory};
            matlabbatch{1}.spm.util.import.dicom.protfilter = '.*';
            matlabbatch{1}.spm.util.import.dicom.convopts.format = 'nii';
            matlabbatch{1}.spm.util.import.dicom.convopts.meta = 0;
            matlabbatch{1}.spm.util.import.dicom.convopts.icedims = 0;
            spm_jobman('run',matlabbatch);
        end
    end
end