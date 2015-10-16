function [frequency_dist,effective_reach]=approach_2_reach_calc(B,schedule,ch_d_h_av_rating,reach_threshold,channels)
%approach_2_reach_calc computes the reach/effective reach of a schedule
%accoring to the coefficients present in B and the characteristics of the
%schedule.
%Inputs:    -B is a vector of the coefficients output from multiplicative
%           regression.m
%           -schedule is the (24)x(7)x(number channels) binary array
%           corresponding to placement of slots.
%           -ch_d_h_av_rating is the channel, day, hour,average rating as
%           computed by the function importnielsen_approach2
%           -reach_threshold is the number of exposures after which we say
%           a person has been reached.
%           -channels is the cell array of channel labels for the schedule
%Outputs:   -schedule reach is the reach as computed from the BBD where the
%           parameters of the BBD are detemined from the schedule and the B
%           vector
%
%
%% compute the characteristics of the schedule
    load('dayparts.mat') %pull in the matrix containing the lower and upper
                         %bounds of each day part.
    load('hour_labels.mat') %load the hour labels as labeled by nielsen
    load('day_labels.mat')  %load the day labels as labeled by nielsen
    [rows,cols]=find(schedule>=1); %Identify the spots where the ads were 
                                   %placed
    sheets=ceil(cols/7); %will be used to identify the channels                              
    cols=mod(cols,7); %will be used to determine the day of the week
    A=find(cols==0);
    cols(A)=7;
    L=length(rows);
    filled_slot_info=cell(L,3);
    %allocate space for the information about the time slots filled
for j=1:L
    filled_slot_info{j,1}=hours{1,rows(j)}; %hour label
    filled_slot_info{j,2}=days{1,cols(j)};  %day label
    %the following bit is identifying the channel label and space padding
    %with the appropriate number of spaces as is necessary because the
    %channel array just has the letters but the nielsen data is exported
    %with space pads to length 5. I know there is a better way to do this.
    num_char=length(channels{sheets(j)});   
    num_space_pad=5-num_char;
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
 %compute the same channel pairs  
 C=length(channels);
 same_channel_pairs=0;   
for s=1:C
    W=sum(sum(schedule(:,:,s))); %counts the number of ads on each of the 
                                 %channels
    %check to see if the number of inserts on the channel is more than two,
    %if it is then you compute the number of possible pairs that happened
    %within that channel. If not, there are no channel pairs. 
    if W<2
        same_channel_pairs=same_channel_pairs;
    elseif W>=2
        same_channel_pairs=same_channel_pairs+nchoosek((W),2);
    end
end
%the proportion of possible ad pairs that happened on the same channel
 X1=same_channel_pairs/nchoosek(L,2);
 
 %compute the proportion of pairs that are placed in the same daypart
 same_day_part_pairs=0;
for k=1:5
        %count the number of insertions within a given day part. 
        day_part_slots=sum(sum(sum(schedule(dayparts(k,1):dayparts(k,2),:,:))));
        %check to see if the number of placesments in the daypart is
        %greater than 2 otherwise there are no within daypart pairs for
        %that daypart
        if day_part_slots<2
            same_day_part_pairs=same_day_part_pairs;
        elseif day_part_slots>=2
        same_day_part_pairs=same_day_part_pairs+nchoosek(day_part_slots,2);
        end
end
%proportion of total pairs that are places in the same daypart.
    X2=same_day_part_pairs/nchoosek(L,2);
    %proportion of same daypart pairs
    
    %NOTE:leaving out X3,X4 for the moment. No same program pairs and no
    %'same-program-type' pairs
    
    %pull the average rating (averaged over time from the nielsen data
    %of each of the filled time slots from ch_d_h_av_rating
    list=[];
    for w=1:L
        %use the day, hour, and channel to pull the average rating 
        hr=find(strcmp(filled_slot_info(w,1),ch_d_h_av_rating(:,3))==1);
        day=find(strcmp(filled_slot_info(w,2),ch_d_h_av_rating(:,2))==1);
        ch=find(strcmp(filled_slot_info{w,3},ch_d_h_av_rating(:,1))==1);
        hr_day=intersect(hr,day);
        hr_day_ch=intersect(hr_day,ch);
        list=[list; ch_d_h_av_rating{hr_day_ch,5}];
    end
    %compute the average rating of the schedule slots
    X5=mean(list);
    %compute the variance of spot ratings
    X6=std(list);    
    %number of slots in the schedule, again, in the form of the paper
    %notation
    X7=L;
    
   %% Compute the V* for the schedule
   %formula for V* given the coefficients determined in multiplicative
   %regression. 
   V_star=exp(B(1))*(1+X1)^(B(2))*(1+X2)^(B(3))*(X5)^(B(4))*(X6)^(B(5))*(X6)^(B(6));
   mu=X5;
   %the equations for the parameters from V* and mu
   %NOTE: I am getting negative alphas and betas because V* is larger than
   %mu*(1-mu)... this makes it infeasible to compute reach..... how to work
   %around this. I wonder if my average rating data is incorrect?
   alpha=abs((mu*V_star)/(mu*(1-mu)-V_star));
   Beta=abs((alpha*(1-mu))/mu);
   %based on the reach threshold we have to identify which frequencies we
   %say count as reach
   frequencies=0:L;
   frequency_dist=zeros(1,L+1);
   for i=1:L+1;
       k=frequencies(i);
       %add the percentage of people exposed to k viewings of the schedule
       %using the closed form of the beta binomial distribution. If we sum
       %the percentages that didnt see the needed frequencies we can
       %subtract that from one to get the reach
       frequency_dist(i)=nchoosek(L,k)*beta(k+alpha,L-k+Beta)/beta(alpha,Beta);
   end
   %reach is sum of frequency distribution values greater than or equal to
   %the threshold
   effective_reach=sum(frequency_dist(1,reach_threshold+1:end));
       

end