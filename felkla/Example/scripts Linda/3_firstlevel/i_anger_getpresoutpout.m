function [presoutput] = i_anger_getpresoutpout(filename,stringparts,whichtask)

%--------------------------------------------------------------------------
%
% Sorts presentation output
% -----------------------------------------------
%
% logfile:      presentation log file [file.log]
% stringparts:  cell array of string parts, presoutput has same size
%
%lddevoogd2014
%--------------------------------------------------------------------------


% LOAD LOG FILE
%--------------------------------------------------------------------------
%open logfile
fileID = fopen(filename);

%remove the first 5 lines within the texfile (are headerlines)
for removelines = 1:5;
    tline = fgetl(fileID);
end

%devide input into columns based on delimiter which is a tab ('\t')
if whichtask == 1
    outputfile = textscan(fileID, '%d %d %s %s %s %s %s','delimiter','\t');
elseif whichtask == 2
    outputfile = textscan(fileID, '%s %s %s %s %s %s %s %s %s','delimiter','\t');
end
fclose(fileID);

%combine crucial variables together and convert into string
respvar=strcat(outputfile{1,3},'_',outputfile{1,4},'_',outputfile{1,5});
    

% SORT OUTPUT
%--------------------------------------------------------------------------
for ss=1:numel(stringparts)
    
    [xx presoutput{ss}]=findstrpart(respvar,stringparts{ss});%own function
    
end
