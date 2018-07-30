clc
clear variables
close all

%% LOAD REFERENCE OPTIMALITY
Temp=load('Q_MDP.mat');
Qmdp=Temp.Q; % reference optimal solution
[MaxQ_mdp,Pi_mdp]=max(Qmdp,[],2);
%% SOLVE SARSA with eligibility traces for the grid system
Temp=load('MSS_data.mat');
MSS=Temp.MSS;

maxEpisodes=1e5; % Number of loops in the Episodic iteration
TimeWindow=250; % Number of time steps in the Episode
gamma=0.9;    % discount factor  in [0,1]
ACC_ET=1;     % 1 => accumulating elabability traces; 0 => replacing elagability traces
QinitialValue=1e4;

SAVE_Results=1;  % 1 to save simulation results 0 to not save
ReductionStep=100; % every ReductionStep steps the alpha and epsilon are reduced 
Epsilon=0.9*(1+5e3)./(5e3+(1:1:TimeWindow*maxEpisodes/ReductionStep+1)); 
Alpha=0.9*(1+5e3)./(5e3+(1:1:TimeWindow*maxEpisodes/ReductionStep+1));
%% TEST SARSA lambda =[0,0.25,0.5,0.75]
Lambda=[0,0.25,0.5,0.75];
% Epsilon=ones(size(Epsilon));
% Alpha=ones(size(Epsilon)).*0.1;
for i=1:4
lambda=Lambda(i);
[QARSA,PiSARSA,AdditionalInfoARSA]=SARSA_lambda_function(MSS,maxEpisodes,TimeWindow,QinitialValue,gamma,Epsilon,Alpha,lambda,ACC_ET,ReductionStep);
 Save.QARSA{i}=QARSA;
 Save.PiSARSA{i}=PiSARSA;
 Save.AdditionalInfoARSA{i}=AdditionalInfoARSA;
 
figure(1)
hold on
plot(mean(repmat(Pi_mdp,1,size(AdditionalInfoARSA.Pi_save,2))==AdditionalInfoARSA.Pi_save),'r')
xlabel('Episodes*100')
ylabel('% ACTIONS == to MDP Optimal Policy')
end


%% Try Q-learning
[Q_QL,Pi_QL,AdditionalInfo_QL]=Qlearning_function(MSS,maxEpisodes,TimeWindow,QinitialValue,gamma,Epsilon,Alpha,ReductionStep);
PLOT_Q(Q_QL,MSS)
figure
hold on
% plot reference MDP optimality  vs Qlearning result for 3 states
plot(ones(size(AdditionalInfo_QL.Qs1)).*5.7343e+03,':r')
plot(ones(size(AdditionalInfo_QL.Qs1)).*2.9141e+03,':b')
plot(ones(size(AdditionalInfo_QL.Qs1)).*-1.7103e+03,':k')
plot(AdditionalInfo_QL.Qs1,'r')
plot(AdditionalInfo_QL.Qs2,'b')
plot(AdditionalInfo_QL.Qs3,'k')

figure
plot(mean(repmat(Pi_mdp,1,size(AdditionalInfo_QL.Pi_save,2))==AdditionalInfo_QL.Pi_save))


%% TRY Qlearning using MDP policy 
QinitialValue=-1e4;
[Q,Pi,AdditionalInfo]=Qlearning_function_usingPolicy(MSS,maxEpisodes,TimeWindow,QinitialValue,gamma...
                                                        ,Alpha,ReductionStep,Pi_mdp);
                                                    
                                                    
                                                    
subplot(2,1,1)
hold on
plot(ones(size(AdditionalInfo.Qs1)).*5.7343e+03,':r')
plot(ones(size(AdditionalInfo.Qs2)).*2.9141e+03,':b')
plot(ones(size(AdditionalInfo.Qs3)).*-1.7103e+03,':k')
plot(AdditionalInfo.Qs1,'r')
plot(AdditionalInfo.Qs2,'b')
plot(AdditionalInfo.Qs3,'k')
grid on
xlabel('Episodes ')
ylabel('max_a Q(s,a)')
 subplot(2,1,2)
plot(mean(repmat(Pi_mdp,1,size(AdditionalInfo.Pi_save,2))==AdditionalInfo.Pi_save))
 grid on
xlabel('Episodes*100')
ylabel('% ACTIONS == to MDP Optimal Policy')
 
 if SAVE_Results==save('WORKSPACE.mat')
 end