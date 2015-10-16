function [ch_d_h_av_rating] = importnielsen_approach2(filename, channels, UE_target_demo)
%IMPORTFILE Import numeric data from a text file as a matrix.
%   ch_d_h_av_rating = importnielsen_approach2(FILENAME) Reads data from text file FILENAME 
%   a CSV file of the form exported from nielsen
%   data using the queries in the documentation. 
%Inputs:        filename1: is the file containing the average viewership 
%               information for a given demographic for every day and hour.
%               channels: is a cell array of the channels in the schedule
%               UE_target_demo: Is the universe estimate for the target
%               demographic of interest. Needed to compute the ratings.
%Output:        ch_d_h_av_rating: a cell array containing the information
%               about the average rating of each hour-day slot on each
%               channel in the schedule.
%   

%% Initialize variables.
delimiter = ',';
    startRow = 2;
    endRow = inf;

%% Format string for each line of text:
%   column1: text (%s)
%	column2: text (%s)
%   column3: text (%s)
%	column4: text (%f)
% For more information, see the TEXTSCAN documentation.
formatSpec = '%s%s%s%s%[^\n\r]';

%% Open the text file.
fileID = fopen(filename,'r');

%% Read columns of data according to format string.
% This call is based on the structure of the file used to generate this
% code. If an error occurs for a different file, try regenerating the code
% from the Import Tool.
dataArray = textscan(fileID, formatSpec, endRow(1)-startRow(1)+1, 'Delimiter', delimiter, 'HeaderLines', startRow(1)-1, 'ReturnOnError', false);
for block=2:length(startRow)
    frewind(fileID);
    dataArrayBlock = textscan(fileID, formatSpec, endRow(block)-startRow(block)+1, 'Delimiter', delimiter, 'HeaderLines', startRow(block)-1, 'ReturnOnError', false);
    for col=1:length(dataArray)
        dataArray{col} = [dataArray{col};dataArrayBlock{col}];
    end
end

%% Close the text file.
fclose(fileID);
%% Create output variable
dataArray1 = [dataArray{1:end-1}];
%% Post processing to find the time slots missing for each channel.
load('day_labels.mat') 
load('hour_labels.mat')
combos_in_data=strcat(dataArray1(:,3),dataArray1(:,2),dataArray1(:,1));
C=length(channels); %number of channels in the schedule
labels={};
for j=1:C
    num_char=length(channels{j});
    num_space_pad=5-num_char;
    if num_char==5
        CH_id=channels{j};
    elseif num_char==4
        CH_id=strcat(channels{j},{' '});
    elseif num_char==3
        CH_id=strcat(channels{j},{' '},{' '});
    elseif num_char==2
        CH_id=strcat(channels{j},{' '},{' '},{' '});
    elseif num_char==1
        CH_id=strcat(channels{j},{' '},{' '},{' '},{' '});
    end
for i=1:7
    Day=days(i); %pick a day
    for k=1:24
        Hour=hours(k); %pick a label
        label=strcat(Hour,Day,CH_id(1)); %concatenate to see if it showed up
                                      %in the data table.                              
        labels=[labels;label];                              
    end
end
end
%labels=labels(:,1);
[missing_slots,missing_ind]=setdiff(labels,combos_in_data);
%% Add in a zero value viewership for any missing day/hour combos
for zz=1:length(missing_ind)
      dataArray1=[dataArray1; labels{missing_ind(zz),1}(6:10) labels{missing_ind(zz),1}(5) labels{missing_ind(zz),1}(1:4) {'0'}];
end
channel_day_hour_proportion=cell(C*7*24,1);
for xx=1:C*7*24
    channel_day_hour_proportion(xx,1)={str2num(dataArray1{xx,4})/UE_target_demo};
end

%% Create output variable
ch_d_h_av_rating=[dataArray1 channel_day_hour_proportion];

         

end
