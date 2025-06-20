function [outindex, outcell]=findstrpart(textcell,strpart)

%--------------------------------------------------------------------------
% input:
%   textcell:   - cell array with strings
%   strpart:    - part of a string for which you are looking for
%
% returns:
%   1. index of cell array where part of the string is present
%   2. rows of the cell array containing that
%
%LdeVoogd2013
%--------------------------------------------------------------------------

%use existing function
temp=strfind(textcell,strpart);

%loop over length cellarray for index
a=1;
for i=1:length(temp)
    if ~isempty(cell2mat(temp(i)))
        outindex(a,:)=i;
        a=a+1;
    end
end

%get parts of the cell string based on index
if exist('outindex')
    outcell=textcell(outindex);
else
    outindex=[];
    outcell=[];
end