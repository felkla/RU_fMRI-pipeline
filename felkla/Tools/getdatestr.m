function datestr=getdatestr()

%
%returns year - month - day in a string: 20131003
%
%lddevoogd2013

%get date/time ect
allstr=clock;

%check day
if size(num2str(allstr(3)),2)==1 ;   
    daystr=[num2str(0),num2str(allstr(3))];
else
    daystr=num2str(allstr(3));
end

%check month
if size(num2str(allstr(2)),2)==1 ;   
    monthstr=[num2str(0),num2str(allstr(2))];
else
    monthstr=num2str(allstr(2));
end

%make string
datestr=strcat([num2str(allstr(1)), ...
    monthstr,...
    daystr]);
