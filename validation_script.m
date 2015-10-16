close all
clear all
clc
%%
%UE_target_demo=8760+10330+10250+8580+10370+10420; %%21-23
%UE_target_demo=UE_target_demo*1000;
UE_target_demo=117620+109040;  %21+
UE_target_demo=UE_target_demo*1000;
load('discov_channels.mat')
%%
filename='ch_d_hr_viewing_21_plus.csv';
[ch_d_h_av_rating]=importnielsen_approach2(filename, channels, UE_target_demo);

%I don't know why importnielsen_approach2 will run when you do the
%individual sections, but won't run successfully as a function.....
%%
num_schedules=10000;
[B,log_const,XX_hat,V_star_hat]=multiplicative_regression(ch_d_h_av_rating, channels, num_schedules);
%%
filename1='week_long_viewership_21_plus.csv';
weeklongviewership = import_nielsen_week(filename1);

%%
trials=25;
errors=zeros(trials,1);
reach_threshold=1;
for i=1:trials
chance=rand(24,7,length(channels));
schedule=zeros(24,7,C);
schedule(find(chance>.99))=1;
[frequency_dist,effective_reach]=approach_2_reach_calc(B,schedule,ch_d_h_av_rating,reach_threshold,channels);
[frequency_dist_hist, reach_hist]=hist_data_schedule_freq(schedule, weeklongviewership,channels,UE_target_demo);
errors(i)=reach_hist-effective_reach;
i
end
%%
close all
figure,hold all 
plot(1:10, errors,'b*')
mu=mean(errors);
VAR=std(errors);
plot(1:10,mu*ones(10,1),'r')
plot(1:10, (mu+1.97*VAR)*ones(10,1),'g')
plot(1:10, (mu-1.97*VAR)*ones(10,1),'g')

figure, hold all
plot(0:length(frequency_dist)-1,log(frequency_dist),'b')
plot(0:length(frequency_dist_hist)-1,log(frequency_dist_hist),'r')
