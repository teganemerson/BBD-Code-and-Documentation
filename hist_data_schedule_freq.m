function [frequency_dist, reach]=hist_data_schedule_freq(schedule, weeklongviewership,channels,UE_target_demo)
%hist_data_schedule_freq computes the frequency distribution of a schedule
%given a week of historical data from within the window of time used to
%generate the random schedules for the multiplicative regression model.
%Inputs:        -schedule: a schedule (for now randomly generated)
%               -weeklongviewership: the output of import_nielsen_week.m
%               -reach_threshold: the threshold for defining effective
%               reach.
%               -channels: the cell array of channel labels for the
%               schedule
%               UE_target_demo:nielsen UE for the target demo
%Outputs:       -frequency_dist: the freqeuncy distribution based off the
%               historical data.
%               -effective_reach: the effective reach of the schedule based
%               on the reach threshold defined as an input.
%start and end index for each of the five Nielsen dayparts
load('dayparts.mat')
%nielsen hour labels
load('hour_labels.mat')
%nielsen day labels
load('day_labels.mat')

C=length(channels);

[rows,cols]=find(schedule==1); %identify the spots
sheets=ceil(cols/7); %will be used to identify the channels                              
cols=mod(cols,7); %will be used to determine the day of the week
A=find(cols==0);
cols(A)=7;
L=length(rows); %number of units in schedule
filled_slot_info=cell(L,3);
%^allocate space for the information about the time slots filled
for j=1:L
    filled_slot_info{j,1}=hours{1,rows(j)}; %hour label
    filled_slot_info{j,2}=days{1,cols(j)};  %day label
    num_char=length(channels{sheets(j)});
    num_space_pad=5-num_char;
    %the next few lines zeropad to get the appropriate channel name based
    %on a characteristic of exporting the data from nielsen
    if num_char==5
        filled_slot_info{j,3}=channels{sheets(j)};
    elseif num_char==4
        filled_slot_info{j,3}=strcat(channels{sheets(j)},{' '});
    elseif num_char==3
        filled_slot_info{j,3}=strcat(channels{sheets(j)},{' '},{' '});
    elseif num_char==2
        filled_slot_info{j,3}=strcat(channels{sheets(j)},{' '},{' '},{' '});
    elseif num_char==1
        filled_slot_info{j,3}=strcat(channels{sheets(j)},{' '},{' '},{' '},{' '});
    end
end
%identify the unique people who watched during the week
household_person_combos=strcat(weeklongviewership(:,1),weeklongviewership(:,2));
unique_viewers=unique(household_person_combos);

%allocate space for the number of units each unique viewer saw
person_counts=zeros(length(unique_viewers),1);
%keep track of the weight for each person who saw some number of units
weights=zeros(length(unique_viewers),1);
for n=1:L  
for m=1:length(unique_viewers)
    %find the shows that each unique viewer saw
    person_shows=find(strcmp(household_person_combos,unique_viewers(m))==1);
    
    slot=strcat(filled_slot_info(n,1),filled_slot_info(n,2), filled_slot_info{n,3});
    shows=strcat(weeklongviewership(person_shows,4), weeklongviewership(person_shows,5), weeklongviewership(person_shows,3));
    %check whether or not each time slot appears in the persons show list
    W=intersect(slot,shows);
    [a,b]=size(W);
    
    if a+b>1
        %if the viewer saw the unit add one to their count
        person_counts(m,1)=person_counts(m,1)+1;
        X=find(strcmp(W,shows)==1);
        weight=str2num([weeklongviewership{person_shows(X),6}]);
        weights(m,1)=weight;
    elseif a+b<=1
        %if they didn't see it, continue
        continue
    end  
end
end
%determine the possible number of units a person could have seen. We don't
%count them if they didnt see any of them. 
frequencies=unique(person_counts);
frequencies=frequencies(find(frequencies>0));

%identify the people with each possible frequency and sum up the weights of
%those viewers and divide by the UE to get the percentage.
for k=1:length(frequencies)
    percentages(k)=sum(weights(find(person_counts==frequencies(k))))/UE_target_demo;
end
%defining reach based on 1+ frequencies 
reach=sum(percentages);
%the percentage that saw 0 is 1 minus the sum of people who saw it at least
%once.
frequency_dist=[1-sum(percentages), percentages];

end