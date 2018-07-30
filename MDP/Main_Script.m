clc
clear variables
close all
%% LOAD COMPONENTS DATA
DATA_4BusNet %%% THIS TIME WE TRY WITH LOWER COST OF PM AND CM
%% Build a MDP for MultiStateSystem (MSS) using single components Data
MSS.Ncomponents=8;                           % [2 generators 2 loads 2 renewable sources 2 line cables]
MSS.NrandomStatesComp=[States.N{:}];         % The tot. number of states associated to the 8-d state vector
MSS.NActionsComp=[Actions.N{:}];             % The tot. number of actiojns associated to the 8 components
MSS.Probabilities={Probabilities{1:2} Probabilities{3:6} Probabilities{7:8}}; %
MSS.Nstates=prod(MSS.NrandomStatesComp);     % Total number of states
MSS.Nactions=prod(MSS.NActionsComp);         % Total number of actions
MSS.OperativeStates=OperativeStates;         % Phisical Quantities/Values associated to the operative states
%% BUILD STATE MATRIX, PROBABILITY MATRIX and REWARDS MATRICES
SatesMatrix=fullfact(MSS.NrandomStatesComp);
ActionMatrix=fullfact(MSS.NActionsComp);
%[SatesMatrix,SatesTable]=MakeStatesTable(MSS.NrandomStatesComp); % List of States indices relative to each components
%[ActionMatrix,ActionsTable]=MakeActionsTable(MSS.NActionsComp); % List of Actions indices to be applied to each components
%load('Ptrans_11k_states.mat')
MSS.SatesMatrix=SatesMatrix;
MSS.ActionMatrix=ActionMatrix;
MSS.NonActiveComponents=[3 4 5 6 7 8];
% Get Available Actions in Differet States
[CombinationofActionsinStateS,NavailableActionsState,IdxCombinationofActionsinStateS]=GetAvailableActions(MSS);

%% REWARDS Reward=f(s,a) and not Reward=f(s,a,s')
%% the Reward R(s_start,action,s_end)
% The rewards for this case study is a negative reward determined by the cost of the enrgy not supplied to the power grid
% this reward is gonna be closest to zero when the system adequacy to fulfill electric power needs of the loads is the highest.
% the Reward function is defined as R(s_start,action)=-CostAction(a)+Revenue_NET(s,a)

% where Revenue_NET(s,a) is obtained trough DC OPF solution of the network
% and has different terms: 1) revenue from selling power 2) cost of
% producting power  4) cost of energy not supplied

% This might take a while as it has to to compute ~11000*14 optimizations 
 REWARDS=ComputeStateActionRewards(CombinationofActionsinStateS,MSS); % OP rewards  
 save('REWARDS','REWARDS') 
% load('REWARDS.mat')
%% SOLVE BELLMAN OPTIMALITY EQUATION for Q
% OPTIMAL Q(s,a) acording to bellman eq
Q_BellmanOptimality 
 
%% SOME POST PROCESSING OF THE V 
% plot state/value functions for optimal and suboptimal policy when
% generators are in the same degradation state not failed
for i=1:3
DegradationLogicFind=SatesMatrix(:,1)==i & SatesMatrix(:,2)==i;
scatter(sum(SatesMatrix(DegradationLogicFind,[3:4]),2),V_randompol(DegradationLogicFind),'r.')
hold on
scatter(sum(SatesMatrix(DegradationLogicFind,[3:4]),2),V(DegradationLogicFind),'b+')
end
xlabel('Sum of Load State Indices')
ylabel('State Value Function V')
legend('V_\pi non optimal policy \pi(a|s)', 'V_\pi optimal policy \pi(a|s)*')
grid on
box on
set(gca,'FontSize',24)