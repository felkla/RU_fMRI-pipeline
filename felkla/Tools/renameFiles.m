function renameFiles(path, extension)
% Renames all files in a folder [path], with possible filter for files with
% a certain [extension].

% Check variables
assert(ischar(extension), 'Variable ''extension'' must be a character string')

% Get all text files in the current folder
if exist('extension', 'var')
    files = dir([path filesep '*.' extension]);
else
    files = dir(path);
end

% Loop through each file 
for id = 2:length(files)
    % Get the file name 
    [~, f,ext] = fileparts(files(id).name);
    rename = strcat(f(1:11),'AA_PILOT2',f(27:end),ext) ; 
    movefile(files(id).name, rename); 
end