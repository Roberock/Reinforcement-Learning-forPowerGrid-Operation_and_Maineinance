function [ExpectedReward,reward_cs_a]=TestPolicy(Pi,TimeWindow)
%load system data
Temp=load('MSS_data.mat');
MSS=Temp.MSS;
%inital state
cs=1; % Select a random state using the ad-hoc distribution (mass prop to sum of deg states)
csVec=MSS.SatesMatrix(cs,:);
%TimeWindow=1e4;
reward_cs_a=zeros(1,TimeWindow);
ExpectedReward=zeros(1,TimeWindow);
for t=1:TimeWindow % repeat for a a predefined TimeWindow for non terminating tasks
    % Take Actions Accordingly to Policy
    csA=Pi(cs);
    Action=find(MSS.IdxCombinationofActionsinStateS{cs}==csA);
    
    csAVect=MSS.ActionMatrix(csA,:); % The action vector corresponding to csA
    csACost=MSS.ActionsCosts(csA);% The cost of the action
    
    %% ENVIRONMENT MOVE RANDOMLY FROM S(t)-->S(t+1)
    [ns,~]=EnvironmentTrasaction(csVec,csAVect,MSS);
    
    %% REWARDS: when taking action a in current state cs  Reward(cs,csA,ns) is assumed Reward(cs,csA)
    reward_cs_a(t)=MSS.REWARDS{cs}(Action)-csACost; 
    ExpectedReward(t)=mean(reward_cs_a(1:t)); 
    % Current-state is Next-State
    cs=ns; %state index
    csVec=MSS.SatesMatrix(cs,:);  %state vector
end
 
end