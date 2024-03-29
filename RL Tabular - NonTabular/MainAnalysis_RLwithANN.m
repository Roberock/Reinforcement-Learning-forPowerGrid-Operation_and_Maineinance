clc
clear variables
close all

%% LOAD REFERENCE OPTIMALITY
Temp=load('Q_MDP.mat');
Qmdp=Temp.Q; % reference optimal solution
[MaxQ_mdp,Pi_mdp]=max(Qmdp,[],2);
 %% Input
Temp=load('MSS_data.mat');
MSS=Temp.MSS;

maxEpisodes=1e4; % Number of loops in the Episodic iteration
TimeWindow=3; % Number of time steps in the Episode
gamma=0.9;    % discount factor  in [0,1] 
ReductionStep=100; % every ReductionStep steps the alpha and epsilon are reduced 
Epsilon=0.9*(1+1e1)./(1e1+(1:1:TimeWindow*maxEpisodes/ReductionStep+1)); 
Alpha=0.2*(1+1e0)./(1e0+(1:1:TimeWindow*maxEpisodes/ReductionStep+1));
hiddenLayerSize=[10 5];
NinitialSimulation=1e4;
%% QL+ANN
[Q_Net,Pi_Net,AddittionalOutputs]=QL_ANN(MSS,maxEpisodes,TimeWindow,NinitialSimulation,hiddenLayerSize,gamma,Epsilon,Alpha,ReductionStep);
ActionsPercent=mean(Pi_mdp==Pi_Net);
 
figure(1)
plot(AddittionalOutputs.Qs1(1:maxEpisodes),'-.b','DisplayName','Qs3');hold on;
plot(AddittionalOutputs.Qs2(1:maxEpisodes),'-.r','DisplayName','Qs1');
plot(AddittionalOutputs.Qs3(1:maxEpisodes),'-.g','DisplayName','Qs2');
plot(5.7343e+03*ones(1,maxEpisodes),'b');
plot(2.9141e+03*ones(1,maxEpisodes),'r');
plot(-1.7103e+03*ones(1,maxEpisodes),'g');


%% Again
Epsilon=ones(size(Epsilon)).*0.001; 
Alpha=ones(size(Alpha)).*0.0001; 
[Output]=Keep_on_Training_ANN(PreviousTraining_InuputData,MSS,maxEpisodes,TimeWindow,Alpha,Epsilon,gamma);