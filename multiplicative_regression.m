function [B,log_const,XX_hat,V_star_hat]=multiplicative_regression(ch_d_h_av_rating, channels, num_schedules);
%multiplicative regression performs the multiplicative regression to get
%out the coefficients needed to compute V* for a new schedule and
%consequently it's frequeny distribution. Takes in a the output of 
%importnielson_approach2.m plus channel labels and the number of random
%schedules to be generated.
%
%Inputs:       ch_d_h_av_rating: the cell array containing the average
%               ratings from the desired demographic for each channel, day,
%               hour in the schedule. 
%               num_schedules: number of random schedules you build the
%               model off of.
%               channels: The channel IDs for each schedule. Cell array of
%               strings.
%Outputs:       B: the vector containing the regression coefficients from
%               the model proposed by Rust. 
%               log_const: the log of the scaling factor.
%               XX_hat: The measured statistics for each of the different
%               schedules
%               V_star_hat: Estimated values of V* used for the regression.
%



%start and end index for each of the five Nielsen dayparts
load('dayparts.mat')
%nielsen hour labels
load('hour_labels.mat')
%nielsen day labels
load('day_labels.mat')

C=length(channels);

XX=[];
VV_star=[];
M=num_schedules;
for i=1:M
    
    chance=rand(24,7,C);%create a random array the size of a schedule
    [rows,cols]=find(chance>0.99); %pick the slots where we will put an ad. 
                                %above .98 will give us a (hopefully)
                                %sparse schedule.
    schedule=zeros(24,7,C);
    schedule(find(chance>.99))=1;
    sheets=ceil(cols/7); %will be used to identify the channels                              
    cols=mod(cols,7); %will be used to determine the day of the week
    A=find(cols==0);
    cols(A)=7;
    L=length(rows); %number of units in the schedule
    filled_slot_info=cell(L,3);
    %^allocate space for the information about the time slots filled
for j=1:L
    filled_slot_info{j,1}=hours{1,rows(j)}; %hour label
    filled_slot_info{j,2}=days{1,cols(j)};  %day label
    num_char=length(channels{sheets(j)});
    num_space_pad=5-num_char;
    %this part is gross because when the nielsen data is exported it space
    %pads the channel name to length 5
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
   
 same_channel_pairs=0;   
for s=1:C
    W=sum(sum(schedule(:,:,s))); 
    %^counts the number of units in a sheet (a single channel)
    
    %the lines below compute the number of same channel pairs. There are
    %less than two units on a channel then there are no unit pairs for that
    %channel
    if W<2
        same_channel_pairs=same_channel_pairs;
    elseif W>=2
    same_channel_pairs=same_channel_pairs+nchoosek((W),2);
    end
end
    X1=same_channel_pairs/nchoosek(L,2);
    same_day_part_pairs=0;
    %^proportion of same channel pairs
    
for k=1:5
    day_part_slots=sum(sum(sum(schedule(dayparts(k,1):dayparts(k,2),:,:))));
    %^computes the number of units in each daypart based on the daypart
    %splits predefiined by me in the vector 'daypart.mat'
        
    %the lines below compute the number of same channel pairs. There are
    %less than two units on a channel then there are no unit pairs for that
    %channel
    if day_part_slots<2
       same_day_part_pairs=same_day_part_pairs;
    elseif day_part_slots>=2
       same_day_part_pairs=same_day_part_pairs+nchoosek(day_part_slots,2);
    end
end
    X2=same_day_part_pairs/nchoosek(L,2);
    %^proportion of same daypart pairs
    
    %NOTE:leaving out X3,X4 for the moment. No same program pairs and no
    %'same-program-type' pairs
    
    %the following section generates a list of the ratings of the units
    %Will be used to compute X5 and X6
    list=[];
    for w=1:L
        %pull the hour, day, and channel of each unit and reference the
        %ch-d-hr average rating information to retrieve the rating of the
        %unit
        hr=find(strcmp(filled_slot_info(w,1),ch_d_h_av_rating(:,3))==1);
        day=find(strcmp(filled_slot_info(w,2),ch_d_h_av_rating(:,2))==1);
        ch=find(strcmp(filled_slot_info{w,3},ch_d_h_av_rating(:,1))==1);
        hr_day=intersect(hr,day);
        hr_day_ch=intersect(hr_day,ch);
        list=[list; ch_d_h_av_rating{hr_day_ch,5}];
    end
      
    X5=mean(list);
    %^average rating of a spot in the schedule
    X6=std(list);    
    %^variance of the ratings of spots in the schedule
    X7=L;
    %^number of spots in the schedule
    
    XX=[XX;1+X1,1+X2,X5,X6,X7]; 
    V_star=X5*(1-X5); %from the paper we can approximate V* by mu(1-mu) when mu is small
    VV_star=[VV_star; V_star];
end
XX_hat=XX;
V_star_hat=VV_star;
XX=[ones(1,M);log(XX)']';
%^XX is the matrix of all of the different input values for the multivariate 
%regression equations for the corresponding duplication value in Y_values
VV_star=log(VV_star);

B=inv(XX'*XX)*XX'*VV_star;
%^computes the least squares solution to the linear regression problem
log_const=B(1);
B(1)=exp(B(1));

end