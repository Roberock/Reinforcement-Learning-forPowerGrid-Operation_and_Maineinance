%% TRY WITH ONE NET FOR EACH ACTION
clc; clear variables; %close all;
%% LOAD COMPONENTS DATA
DATA_4BusNet
%% Create MultiStateSystem (MSS) Struture using the info on each component
load('MSS_data.mat')
%% R-L Simulation Parameters
maxItr1=1e4; % Number of loops in the Episodic iteration
TimeWindow=25; % Number of time steps in the Episode
gamma=0.9;    % discount factor  in [0,1]
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
[Qs1,Qs2,Qs3]=deal(zeros(1,maxItr1));  % initialize some outputs
%% INITIALIZE ANN
% prepare input output data using random sampling from the state-action
% space and calculating Q
cs=1; csVect=MSS.SatesMatrix(cs,:);% corresponding MSS state vector
Inputs=cell(1,MSS.Nactions); Targets=cell(1,MSS.Nactions);
NsimStart=5000;
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
%  Targets
Discounts=0.9.^(0:1:NsimStart);
for t=1:NsimStart
    Targets{CSACTIONS(t)} = [Targets{CSACTIONS(t)} sum(ISTANTANEOUSREWARDS(t:end).*Discounts(1:end-t))];
end
    for i=1:MSS.Nactions
        NormConstOut(i)=max(abs(Targets{i}))*2;
    end

%%
%NormConstOut=ones(1,MSS.Nactions);
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
  %  NormOUTPUT=0;
  %  NormINPUT=ones(size(MSS.NrandomStatesComp))';
    %     %normilize output
    
          NormOUTPUT=Targets{a}./NormConstOut(a);
          NormINPUT=Inputs{a}./repmat(MSS.NrandomStatesComp',1,size(Inputs{a},2));
    %     % Train the Network
    [net,tr] = train(net,NormINPUT,NormOUTPUT);
    %% set upt parameters fro the incremental training
    net.trainFcn = 'traingd'; %change to traingda
    %     options = trainingOptions('sgdm',...
    %     'LearnRateSchedule','piecewise',...
    %     'LearnRateDropFactor',0.2,...
    %     'LearnRateDropPeriod',5,...
    %     'MaxEpochs',1,...
    %     'MiniBatchSize',64,...
    %     'Plots','training-progress');
    net.trainParam.epochs=1; %fix epoch
    net.trainParam.lr=0.15; %initial learning rate
    net.trainParam.showWindow = false;
    %TRcell{a}=tr;
    NETcell{a}=net;
    
end

%% START Q-learning with ANN
tic
for i=1:maxItr1
    
    %epsilon=0.1;
    %alpha=0.005*(1+ceil(maxItr1/100 ))/(ceil(maxItr1/100)+i);
    epsilon=0.9*(1+ceil(maxItr1/50 ))./(ceil(maxItr1/50)+i);
    
    if  randi(2)<=3
        cs=randi(MSS.Nstates);% Select a random state using uniform law
    else
        cs=find(rand()<TrickECDF,1,'first'); % Select a random state using the ad-hoc degradation proportional pdf
    end
    csVect=MSS.SatesMatrix(cs,:);% corresponding MSS state vector
    % Repeate until Goal state is reached
    %% START EPISODE
    for t=1:TimeWindow %repeat for a time window of TimeWindow
        [csA,Action]=Exploit_or_Explore25Net(NETcell,cs,csVect,MSS,epsilon,NormConstOut); % Action index action in states whilst csA index action in the action set (among all possible action)
        csAVect=MSS.ActionMatrix(csA,:); % The action vector corresponding to csA
        csACost=MSS.ActionsCosts(csA);% The cost of the action
        
        %% ENVIRONMENT MOVE RANDOMLY FROM S(t)-->S(t+1)
        [ns,nsVect]=EnvironmentTrasaction(csVect,csAVect,MSS);
        
        %% REWARDS: when taking action a in current state cs  Reward(cs,csA,ns) is assumed Reward(cs,csA)
        reward_cs_a=MSS.REWARDS{cs}(Action)-csACost;
        
        %% Q-learning
        QforNs=zeros(1,25)-inf;
        for Azioni=MSS.IdxCombinationofActionsinStateS{ns}'
            QforNs(Azioni)=NETcell{Azioni}([nsVect./MSS.NrandomStatesComp]')*NormConstOut(Azioni);
        end
        MaxQnext=max(QforNs);%*OutNormConstant;
        QTargets=reward_cs_a + gamma*MaxQnext;% Temporal Difference
        input = [csVect./MSS.NrandomStatesComp]'; % normalize input
        target = QTargets./NormConstOut(csA); % normalize target
        %% Train the Network Incrementally
        [net,Y,E] = train(NETcell{csA},input,target);  %train
        
        %% Decrease the learning rate of the network that has been trained
               
                if net.trainParam.lr<=1e-4
                    net.trainParam.lr=1e-4;
                else
                     net.trainParam.lr=net.trainParam.lr-1e-5;
                end
        
        NETcell{csA}=net;  %  save net
        cs=ns;  csVect=MSS.SatesMatrix(cs,:);   % Current-state is Next-State
        
    end
    %% SAVE Q to CHECK  CONVERGENCE
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
    if mod(i,100)==0
        display(['QL: Number of Episodes :' num2str(i)]) % DISPLAY THE IGTERATIOSN
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
