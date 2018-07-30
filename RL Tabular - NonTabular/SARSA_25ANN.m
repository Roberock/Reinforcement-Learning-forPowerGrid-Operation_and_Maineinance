%% TRY WITH ONE NET FOR EACH ACTION

clc; clear variables; %close all;
%% LOAD COMPONENTS DATA
DATA_4BusNet
%% Create MultiStateSystem (MSS) Struture using the info on each component
load('MSS_data.mat')
%% REWARDS Reward=f(s,a) and not Reward=f(s,a,s')
%% the Reward R(s_start,action,s_end)
%load('REWARDS.mat')
%% R-L Simulation Parameters
maxItr1=5e4; % Number of loops in the Episodic iteration
TimeWindow=4; % Number of time steps in the Episode
gamma=0.9;    % discount factor  in [0,1]
ReductionStep=300;
%Epsilon=linspace(0.9,0.05,TimeWindow*maxItr1/ReductionStep+1); % greediness factor   in [0,1]
%Alpha=linspace(0.3,0.05,TimeWindow*maxItr1/ReductionStep+1);  %learning Rate   in [0,1]
%CounterUpdating=0;
%% trick to obtain more samples in intresting states
Gen12Degs=MSS.SatesMatrix(:,1)+MSS.SatesMatrix(:,2)+MSS.SatesMatrix(:,end)+MSS.SatesMatrix(:,end-1);
TrickECDF= cumsum(Gen12Degs./norm(Gen12Degs,1)); % This will be used to sample more frequently degraded scenarios
%% INTIALIZE ELIGIBILITY TRACES SARSA(LAMBDA) METHOD
%Q=zeros(MSS.Nstates,MSS.Nactions)-inf;
Q=zeros(MSS.Nstates,MSS.Nactions);
%ET = zeros(MSS.Nstates,MSS.Nactions)-inf;
for i=1:MSS.Nstates
    Q(i,MSS.IdxCombinationofActionsinStateS{i})=1e2;  % initialize Q matrix
end

[G_sum_discounted,Qs1,Qs2,Qs3]=deal(zeros(1,maxItr1));  % initialize some outputs
[Reward_discounted,Reward_not_discounted]=deal(zeros(1,TimeWindow));
%% INITIALIZE ANN
% prepare input output data using random sampling from the state-action
% space and calculating Q
cs=1;epsilon=1;
csVect=MSS.SatesMatrix(cs,:);% corresponding MSS state vector
Inputs=cell(1,MSS.Nactions);
Targets=cell(1,MSS.Nactions);
NsimStart=10000;
for t=1:NsimStart %repeat for a time window of TimeWindow
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

%% Targets
Discounts=0.9.^(0:1:NsimStart);
for t=1:NsimStart
    Targets{CSACTIONS(t)} = [Targets{CSACTIONS(t)} sum(ISTANTANEOUSREWARDS(t:end).*Discounts(1:end-t))];
end
  for i=1:MSS.Nactions
      NormConstOut(i)=max(abs(Targets{i}));
 end
%NormConstOut=ones(1,MSS.Nactions);
%%
alpha=0.01;
for a=1:MSS.Nactions
    % Create a Fitting Network
    hiddenLayerSize = [10 10];
    net = feedforwardnet(hiddenLayerSize);
    
    % Set up Division of Data for Training, Validation, Testing
    net.divideParam.trainRatio = 70/100;
    net.divideParam.valRatio = 15/100;
    net.divideParam.testRatio = 15/100;
    net.trainFcn = 'trainlm';
    net.trainParam.showWindow = false;
    net.trainParam.showCommandLine = false;
    %normilize output
    NormOUTPUT=Targets{a}./NormConstOut(a);
    NormINPUT=Inputs{a}./repmat(MSS.NrandomStatesComp',1,size(Inputs{a},2));
    % Train the Network
    [net,tr] = train(net,NormINPUT,NormOUTPUT);
    net.trainFcn = 'traingd';% Change learning algorithm (gradient des.)
    net.trainParam.showWindow = false;
    net.trainParam.showCommandLine = false;
    net.trainParam.lr=alpha;%learning rte
    
    net.trainParam.epochs=1;% Change epochs
    TRcell{a}=tr;
    NETcell{a}=net;
end


 
%% START SARSA-LAMBDA with Eligibility Traces
CounterUpdating=0; % counts the number of updating of Q
ReductionCounter=1; % This counts the number of times the learning rate and the greediness factor are reduced
%alpha=Alpha(ReductionCounter); % start from the highest learning rate
Epsilon=0.9*(1+5e3)./(5e3+(1:1:TimeWindow*maxItr1/ReductionStep+1));
for i=1:maxItr1
    
     epsilon=0.9*(1+ceil(maxItr1/100 ))./(ceil(maxItr1/100)+i); 
     cs=randi(MSS.Nstates);% Select a random state using uniform law 
     csVect=MSS.SatesMatrix(cs,:);% corresponding MSS state vector
   
    %% START EPISODE
    for t=1:TimeWindow %repeat for a time window of TimeWindow
 
        [csA,Action]=Exploit_or_Explore25Net(NETcell,cs,csVect,MSS,epsilon,NormConstOut); % Action index action in states whilst csA index action in the action set (among all possible action)
        
        csAVect=MSS.ActionMatrix(csA,:); % The action vector corresponding to csA
        csACost=MSS.ActionsCosts(csA);% The cost of the action
        %% ENVIRONMENT MOVE RANDOMLY FROM S(t)-->S(t+1)
        [ns,nsVect]=EnvironmentTrasaction(csVect,csAVect,MSS);
        %% REWARDS: when taking action a in current state cs  Reward(cs,csA,ns) is assumed Reward(cs,csA)
        reward_cs_a=MSS.REWARDS{cs}(Action)-csACost;
        %% Next State Action
        %[nsA,Action]=Exploit_or_Explore(Q,ns,MSS.IdxCombinationofActionsinStateS,epsilon);
        [nsA,Action]=Exploit_or_Explore25Net(NETcell,ns,nsVect,MSS,epsilon,NormConstOut);
        nsAVect=MSS.ActionMatrix(nsA,:); 
        Qnext=NETcell{nsA}([nsVect./MSS.NrandomStatesComp]');%*OutNormConstant; 
        QTargets=reward_cs_a + gamma*Qnext; 
        input = [csVect./MSS.NrandomStatesComp]';
        target = QTargets./NormConstOut(csA);
        
        % Train the Network Incremental
        %[net,Y,E] = adapt(net,inputs,targets);
        [net,Y,E] = train(NETcell{csA},input,target);  %train
%         if  net.trainParam.lr>1e-5
%         net.trainParam.lr=net.trainParam.lr-1e-5;%reduce learning rate
%         end
%         NETcell{csA}=net;
        
        % Current-state is Next-State
        cs=ns;
        csVect=MSS.SatesMatrix(cs,:); 
    end
    %% SAVE Q to CHECK  CONVERGENCE
    G_sum_discounted(i)=sum(Reward_discounted);
    
    for a=MSS.IdxCombinationofActionsinStateS{1}'
        QSTATE1(a)=NETcell{a}(MSS.SatesMatrix(1,:)'./MSS.NrandomStatesComp').*NormConstOut(a);
    end
    for a=MSS.IdxCombinationofActionsinStateS{4}'
        QSTATE2(a)=NETcell{a}(MSS.SatesMatrix(4,:)'./MSS.NrandomStatesComp').*NormConstOut(a);
    end
    for a=MSS.IdxCombinationofActionsinStateS{end}'
        QSTATE3(a)=NETcell{a}(MSS.SatesMatrix(end,:)'./MSS.NrandomStatesComp').*NormConstOut(a);
    end
    
    Qs1(i)=max(QSTATE1(MSS.IdxCombinationofActionsinStateS{1}));
    Qs2(i)=max(QSTATE2(MSS.IdxCombinationofActionsinStateS{4}));
    Qs3(i)=max(QSTATE3(MSS.IdxCombinationofActionsinStateS{end}));
    if mod(i,10)==0
        display(['SARSA: Number of Episodes :' num2str(i)]) % DISPLAY THE IGTERATIOSN
        close all
        figure(10)
        plot(Qs1(1:i),':b','DisplayName','Qs3');hold on;
        plot(Qs2(1:i),':r','DisplayName','Qs1');
        plot(Qs3(1:i),':g','DisplayName','Qs2');
        plot(5.7343e+03*ones(size(Qs1(1:i))),'b');
        plot(2.9141e+03*ones(size(Qs1(1:i))),'r');
        plot(-1.7103e+03*ones(size(Qs1(1:i))),'g');
        pause(0.01)
        
    end
    
end
 