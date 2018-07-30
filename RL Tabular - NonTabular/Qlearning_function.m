function [Q,Pi,AdditionalInfo]=Qlearning_function(MSS,maxEpisodes,TimeWindow,QinitialValue,gamma,Epsilon,Alpha,ReductionStep)

%% EXAMPLE INPUTS

% MSS= structure (in future an object) providing info about the system and
% a function outputing rewards

% maxEpisodes=1e4; % Number of loops in the Episodic iteration
% TimeWindow=250; % Number of time steps in the Episode
% gamma=0.9;    % discount factor  in [0,1] 
% ReductionStep=200; % every ReductionStep steps the alpha and epsilon are reduced
% Epsilon=0.9*(1+5e3)./(5e3+(1:1:TimeWindow*maxEpisodes/ReductionStep+1));
% Alpha=0.9*(1+5e3)./(5e3+(1:1:TimeWindow*maxEpisodes/ReductionStep+1));
% [Q,Pi,AdditionalInfo]=Qlearning_function(MSS,maxEpisodes,TimeWindow,gamma,Epsilon,Alpha,ReductionStep)
%% OUTPUT
% Q= state-action value function, a matrix [Ns x Na]
% Pi= the policy derived from Q (i.e. arg max_a Q(s,a) fro each a)
%% INITIALIZE
CounterUpdating=0; % counts the number of updating of Q
ReductionCounter=1; % This counts the number of times the learning rate and the greediness factor are reduced
alpha=Alpha(ReductionCounter); % start from the highest learning rate
epsilon=Epsilon(ReductionCounter); % start from the highest greediness factor
%% This will help exploring more rare scenarios to obtain more samples in intresting states
Gen12Degs=MSS.SatesMatrix(:,1)+MSS.SatesMatrix(:,2)+MSS.SatesMatrix(:,end)+MSS.SatesMatrix(:,end-1);
adHocECDF= cumsum(Gen12Degs./norm(Gen12Degs,1)); % This will be used to sample more frequently degraded scenarios
%% INTIALIZE ELIGIBILITY TRACES ET and ACTION-VALUE-FUNCTION
Q=zeros(MSS.Nstates,MSS.Nactions)-inf; 
for s=1:MSS.Nstates
    Q(s,MSS.IdxCombinationofActionsinStateS{s})=QinitialValue;  % initialize Q matrix with a relativelly high value to stimulate exploration of non-visited states
end
[Qs1,Qs2,Qs3]=deal(zeros(1,maxEpisodes));  % initialize outputs
NEXTSAVE=0;
Pi_save=zeros(MSS.Nstates,maxEpisodes/100);
%DT=zeros(1,maxEpisodes*TimeWindow);ET=ET_start;
%% START SARSA-LAMBDA with Eligibility Traces
tic
for i=1:maxEpisodes
    
        if mod(CounterUpdating,ReductionStep)==0% Reduce learning rate, the more we learn about something the less the learning rate decreases with the iterations
            ReductionCounter=ReductionCounter+1;
            alpha=Alpha(ReductionCounter);
            epsilon=Epsilon(ReductionCounter);
        end
    
    %% initalize state s(t=0)
    cs=find(rand()<adHocECDF,1,'first'); % Select a random state using the ad-hoc distribution (mass prop to sum of deg states)
    if (i>=floor(maxEpisodes*1/3))
        cs=randi(MSS.Nstates);% Select a random state using uniform law
    end
    csVec=MSS.SatesMatrix(cs,:);% corresponding MSS state vector
    % Repeate until Goal state is reached 
    
    
    %% START EPISODE
    for t=1:TimeWindow % repeat for a a predefined TimeWindow for non terminating tasks
        % Possible (randomly selected) Actions index from Current state (csA)
        CounterUpdating=CounterUpdating+1; % we entered a new updating of Q
        %       SQERROR=(Q(:)- Q_MDP(:)).^2;   RMS(CounterUpdating)=sqrt(mean(SQERROR(~isnan(SQERROR))));
    
        [csA,Action]=Exploit_or_Explore(Q,cs,MSS.IdxCombinationofActionsinStateS,epsilon); % Action index action in states whilst csA index action in the action set (among all possible action)
        csAVect=MSS.ActionMatrix(csA,:); % The action vector corresponding to csA
        csACost=MSS.ActionsCosts(csA);% The cost of the action
        
        %% ENVIRONMENT MOVE RANDOMLY FROM S(t)-->S(t+1)
        [ns,~]=EnvironmentTrasaction(csVec,csAVect,MSS);
        
        %% REWARDS: when taking action a in current state cs  Reward(cs,csA,ns) is assumed Reward(cs,csA)
        reward_cs_a=MSS.REWARDS{cs}(Action)-csACost;
        % TD
        deltaTime=reward_cs_a + gamma*max(Q(ns,MSS.IdxCombinationofActionsinStateS{ns})) - Q(cs,csA);
        Q(cs,csA)  = Q(cs,csA) + alpha*deltaTime; 
        % Current-state is Next-State
        cs=ns; %state index
        csVec=MSS.SatesMatrix(cs,:);  %state vector
    end
    %% SAVE Q to CHECK  CONVERGENCE
    Qs1(i)=Q(1,find(Q(1,:)==max(Q(1,:)),1));
    Qs2(i)=Q(4,find(Q(4,:)==max(Q(4,:)),1)); % 1 gen down
    Qs3(i)=Q(end,find(Q(end,:)==max(Q(end,:)),1)); % both gen down and lines too
 
    if mod(i,100)==1
        NEXTSAVE=NEXTSAVE+1;
         [~,Pi_save(:,NEXTSAVE)]=max(Q,[],2);
        display(['EPISODE N-' num2str(i)])
    end
end


[~,Pi]=max(Q,[],2);

AdditionalInfo.Qs1=Qs1;
AdditionalInfo.Qs2=Qs2;
AdditionalInfo.Qs3=Qs3;
AdditionalInfo.Pi_save=Pi_save;

end