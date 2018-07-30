function [Q_Net,Pi_Net,AddittionalOutputs]=QL_ANN(MSS,maxEpisodes,TimeWindow,NinitialSimulation,hiddenLayerSize,gamma,Epsilon,Alpha,ReductionStep)


%% R-L Simulation Parameters
% maxItr1=1e4; % Number of loops in the Episodic iteration
% TimeWindow=25; % Number of time steps in the Episode
% gamma=0.9;    % discount factor  in [0,1]
% NinitialSimulation=5000;
% hiddenLayerSize=[10 10]
%% trick to obtain more samples in intresting states
Gen12Degs=MSS.SatesMatrix(:,1)+MSS.SatesMatrix(:,2)+MSS.SatesMatrix(:,end)+MSS.SatesMatrix(:,end-1);
TrickECDF= cumsum(Gen12Degs./norm(Gen12Degs,1)); % This will be used to sample more frequently degraded scenarios
%% INTIALIZE
Q=zeros(MSS.Nstates,MSS.Nactions)-inf;
%Q=zeros(MSS.Nstates,MSS.Nactions);
for i=1:MSS.Nstates
    Q(i,MSS.IdxCombinationofActionsinStateS{i})=1e4;  % initialize Q matrix
end
%ET = spalloc(MSS.Nstates,MSS.Nactions,TimeWindow);
[Qs1,Qs2,Qs3]=deal(zeros(1,maxEpisodes));  % initialize some outputs
%% INITIALIZE ANN
% prepare input output data using random sampling from the state-action
% space and calculating Q
cs=1; csVect=MSS.SatesMatrix(cs,:);% corresponding MSS state vector
Inputs=cell(1,MSS.Nactions); Targets=cell(1,MSS.Nactions);

for t=1:NinitialSimulation %repeat for a time window of TimeWindow
    % Possible (randomly selected) Actions index from Current state (csA)
    [csA,Action]=Exploit_or_Explore(Q,cs,MSS.IdxCombinationofActionsinStateS,1);
    CSACTIONS(t)=csA;
    csAVect=MSS.ActionMatrix(csA,:);
    csACost=MSS.ActionsCosts(csA);
    %% ENVIRONMENT MOVE RANDOMLY FROM S(t)-->S(t+1)
    [ns,nsVect]=EnvironmentTrasaction(csVect,csAVect,MSS);
    %% REWARDS: when taking action a in current state cs  Reward(cs,csA,ns) is assumed Reward(cs,csA)
    reward_cs_a=MSS.REWARDS{cs}(Action)-csACost;
    Inputs{csA} = [Inputs{csA} csVect'];
    cs=ns;
    csVect=nsVect;
    ISTANTANEOUSREWARDS(t)=reward_cs_a;
end
%  Targets
Discounts=gamma.^(0:1:NinitialSimulation);
for t=1:NinitialSimulation
    Targets{CSACTIONS(t)} = [Targets{CSACTIONS(t)} sum(ISTANTANEOUSREWARDS(t:end).*Discounts(1:end-t))];
end
% normalization constant
for i=1:MSS.Nactions
    NormConstOut(i)=max(abs(Targets{i}))*2;
end

%%
%NormConstOut=ones(1,MSS.Nactions);
NETcell=cell(1,MSS.Nactions);
for a=1:MSS.Nactions
    % Create a Fitting Network
    %hiddenLayerSize = [10 10];
    net = feedforwardnet(hiddenLayerSize);
    
    % Set up Division of Data for Training, Validation, Testing
    net.divideParam.trainRatio = 70/100;
    net.divideParam.valRatio = 15/100;
    net.divideParam.testRatio = 15/100;
    net.trainFcn = 'trainlm';
    net.layers{1}.transferFcn='logsig';
    net.trainParam.showWindow = false;
    %  NormOUTPUT=0;
    %  NormINPUT=ones(size(MSS.NrandomStatesComp))';
    %     %normilize output
    
    NormOUTPUT=Targets{a}./NormConstOut(a);
    NormINPUT=Inputs{a}./repmat(MSS.NrandomStatesComp',1,size(Inputs{a},2));
    %     % Train the Network
    [net,~] = train(net,NormINPUT,NormOUTPUT);
    %% set upt parameters fro the incremental training
    net.trainFcn = 'traingd'; %change to traingda
    net.trainParam.epochs=1; %fix epoch
    %net.trainParam.lr=0.15; %initial learning rate
    net.trainParam.lr=Alpha(1);
    net.trainParam.showWindow = false;
    %TRcell{a}=tr;
    NETcell{a}=net;
    net.layers{1}.transferFcn='logsig';
    
end

%% START Q-learning with ANN
TrainingCounter=zeros(1,MSS.Nactions); % counts the number of times the network was trained
ReductionAlphaCounter=ones(1,MSS.Nactions); % counts the number of times the network was trained
ReductionEpsilonCounter=1;
CounterUpdating=0; 
epsilon=Epsilon(ReductionEpsilonCounter); % start from the highest greediness factor
for i=1:maxEpisodes
 %sample inital system state
    if  randi(10)<=2
        cs=randi(MSS.Nstates);% Select a random state using uniform law
    else
        cs=find(rand()<TrickECDF,1,'first'); % Select a random state using the ad-hoc degradation proportional pdf
    end
    csVect=MSS.SatesMatrix(cs,:);% corresponding MSS state vector 
    
    %% START EPISODE   % Repeate until Goal state is reached
    for t=1:TimeWindow %repeat for a time window of TimeWindow
       %% Explorative vs exploitative actions
        [csA,Action]=Exploit_or_Explore25Net(NETcell,cs,csVect,MSS,epsilon,NormConstOut); % Action index action in states whilst csA index action in the action set (among all possible action)
        csAVect=MSS.ActionMatrix(csA,:); % The action vector corresponding to csA
        csACost=MSS.ActionsCosts(csA);% The cost of the action
        
        %% ENVIRONMENT MOVE RANDOMLY FROM S(t)-->S(t+1)
        [ns,nsVect]=EnvironmentTrasaction(csVect,csAVect,MSS);
        
        %% REWARDS: when taking action a in current state cs  Reward(cs,csA,ns) is assumed Reward(cs,csA)
        reward_cs_a=MSS.REWARDS{cs}(Action)-csACost;
        
        %% Q-learning
        QforNs=zeros(1,MSS.Nactions)-inf;
        for Azioni=MSS.IdxCombinationofActionsinStateS{ns}'
            QforNs(Azioni)=NETcell{Azioni}([nsVect./MSS.NrandomStatesComp]')*NormConstOut(Azioni);
        end
        MaxQnext=max(QforNs); % calculate maximum obt
        QTargets=reward_cs_a + gamma*MaxQnext;% Temporal Difference
        input = [csVect./MSS.NrandomStatesComp]'; % normalize input
        target = QTargets./NormConstOut(csA); % normalize target
        %% Train the Network Incrementally
        [net,~,~] = train(NETcell{csA},input,target);  %train 
        %% Decrease the learning rate of the network that has been trained
    
        %Chage exploration rate
              CounterUpdating=CounterUpdating+1; % we entered a new updating of Q
        %       SQERROR=(Q(:)- Q_MDP(:)).^2;   RMS(CounterUpdating)=sqrt(mean(SQERROR(~isnan(SQERROR))));
        if mod(CounterUpdating,ReductionStep)==0% Reduce learning rate, the more we learn about something the less the learning rate decreases with the iterations
            ReductionEpsilonCounter=ReductionEpsilonCounter+1; 
            epsilon=Epsilon(ReductionEpsilonCounter);
        end
        
        % Change learning rate
        TrainingCounter(csA)=TrainingCounter(csA)+1;  
        if mod(TrainingCounter(csA),ReductionStep)==0% Reduce learning rate, the more we learn about something the less the learning rate decreases with the iterations
            ReductionAlphaCounter(csA)=ReductionAlphaCounter(csA)+1;
            net.trainParam.lr=Alpha(ReductionAlphaCounter(csA));
        end
        
        NETcell{csA}=net;  %  save net
        cs=ns;  csVect=MSS.SatesMatrix(cs,:);   % Current-state is Next-State
        
    end
    %% SAVE Q to CHECK  CONVERGENCE
    for Azioni=MSS.IdxCombinationofActionsinStateS{1}'
        QSTATE1(Azioni)=NETcell{Azioni}((MSS.SatesMatrix(1,:)./MSS.NrandomStatesComp)').*NormConstOut(Azioni);
    end
    for Azioni=MSS.IdxCombinationofActionsinStateS{4}'
        QSTATE2(Azioni)=NETcell{Azioni}((MSS.SatesMatrix(4,:)./MSS.NrandomStatesComp)').*NormConstOut(Azioni);
    end
    for Azioni=MSS.IdxCombinationofActionsinStateS{end}'
        QSTATE3(Azioni)=NETcell{Azioni}((MSS.SatesMatrix(end,:)./MSS.NrandomStatesComp)').*NormConstOut(Azioni);
    end
    
    Qs1(i)=max(QSTATE1(MSS.IdxCombinationofActionsinStateS{1}));
    Qs2(i)=max(QSTATE2(MSS.IdxCombinationofActionsinStateS{4}));
    Qs3(i)=max(QSTATE3(MSS.IdxCombinationofActionsinStateS{end}));
    
    if mod(i,100)==1 
        display(['QL+ANN EPISODE N-' num2str(i)]) 
        close all
        figure(1)
        plot(Qs1(1:i),'-.b','DisplayName','Qs3');hold on;
        plot(Qs2(1:i),'-.r','DisplayName','Qs1');
        plot(Qs3(1:i),'-.g','DisplayName','Qs2');
        plot(5.7343e+03*ones(size(Qs1(1:i))),'b');
        plot(2.9141e+03*ones(size(Qs1(1:i))),'r');
        plot(-1.7103e+03*ones(size(Qs1(1:i))),'g');
        pause(0.01)
    end
    
end
% a bit of outputs
AddittionalOutputs.Qs1=Qs1;
AddittionalOutputs.Qs2=Qs2;
AddittionalOutputs.Qs3=Qs3;
AddittionalOutputs.NormConstOut=NormConstOut;
AddittionalOutputs.NETcell=NETcell;
% the approximated Q values by the ANN
for a=1:MSS.Nactions
    Q_Net(:,a)=NETcell{a}((MSS.SatesMatrix./repmat(MSS.NrandomStatesComp,MSS.Nstates,1))').*NormConstOut(a);
end
Temp=load('Q_MDP.mat');
Q_Net(isnan(Temp.Q))=NaN;
[~,Pi_Net]=max(Q_Net,[],2); % the optimal policy

end