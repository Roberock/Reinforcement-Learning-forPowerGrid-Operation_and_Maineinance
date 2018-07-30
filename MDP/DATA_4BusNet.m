%% THE DATA FOR THE Scaled-Down 4 NODES POWER GRID
% THE power Grid has 8 multi state components distributed over 4 nodes:
%idx>  Description
%1&2>  2 controllable and degradable generators in nodes 1 and 4
%3&4>  2 non-controllable Loads in nodes 2 and 3
%5&6>  2 non-controllable renewable energy sources
%7&8>  2 non-controllable degradable links (1-2 and 1-3) 
%% the system components' states 
% Total Combination of states Ns= 4^2* 3^2 *3^2 *3^2=11664 states combinations
% S_{Deg,Gen,i}={ASAN deg_1 deg_2 Failed}_i \forall i=1,2 
% S_{Loads,i}={L_1 L_2 L_3}_i \forall i=1,2 
% S_{Pow,res,i}={Pres_1 Pres_2 Pres_3}_i \forall i=1,2 
% S_{Deg,link,i}={ASAN deg_1 Failed}_i \forall i=1,2 
%% Opeartive States (OP) indices
% OperativeStates.Idx{1}=[1 2 3]; % Generator Power 1 (controllable, but affected by Degradation state)
% OperativeStates.Idx{2}=[1 2 3]; % Generator Power 2 (controllable, but affected by Degradation state)
% OperativeStates.Idx{3}=[1 2 3]; % Load 1  (random)
% OperativeStates.Idx{4}=[1 2 3]; % Load 2  (random)
% OperativeStates.Idx{5}=[1 2 3]; % Renewable 1  (random)
% OperativeStates.Idx{6}=[1 2 3]; % Renewable 2  (random)
% OperativeStates.Idx{7}=[1 2]; % Line G1-L1 (random depend on Deg State)
% OperativeStates.Idx{8}=[1 2]; % Line G1-L1 (random depend on Deg State)
%% OP Values
OperativeStates.Val{1}=[40 50 100 0 0]; % Generator Power 1 [MW] (controllable)
OperativeStates.Val{2}=[60 70 120 0 0]; % Generator Power 2 [MW] (controllable)
%OperativeStates.Idx.C2 % State of Carge 1
OperativeStates.Val{3}=[60 100 140]; % Load 1  [MW] (random loads)
OperativeStates.Val{4}=[20 50 110];  % Load 2  [MW] (random loads)
OperativeStates.Val{5}=[0 20 30]; % Renewable 1  [MW] (random renewable production)
OperativeStates.Val{6}=[0 20 60]; % Renewable 2  [MW] (random renewable production)
OperativeStates.Val{7}=[1 0 0]; % Line G1-L1 (1 operative 0 failed)
OperativeStates.Val{8}=[1 0 0]; % Line G1-L1 (1 operative 0 failed)
%% DEGRADATION (DEG) States indices
DegradationStates.Idx{1}=[1 2 3 4]; % Generator 1
DegradationStates.Idx{2}=[1 2 3 4]; % Generator 1
for i=3:6; DegradationStates.Idx{i}=1; % RES & LOADS for simplicity assume non degradable
end
DegradationStates.Idx{7}=[1 2 3]; % Line G1-L1
DegradationStates.Idx{8}=[1 2 3]; % Line G1-L2
%% the actions on the components  
%% Actions List for Each Component
Actions.Idx{1}=[1 2 3 4 5]; % GEN 1 has 3 OP levels + Corrective and Predictive actions [Pg1 Pg2 Pg3 PM CM]
Actions.Idx{2}=[1 2 3 4 5]; % GEN 2 has 3 OP levels + Corrective and Predictive actions [Pg1 Pg2 Pg3 PM CM]
Actions.Idx{7}=[1 2 3]; % Link G1-L1 Normal Operations, Corrective and Predictive  [NN PM CM]
Actions.Idx{8}=[1 2 3]; % Link G1-L1  Normal Operations, Corrective and Predictive [NN PM CM]
Actions.Names{1}={'go2Pg1' 'go2Pg2' 'go2Pg3' 'PM' 'CM'}; % GEN 1 has 3 OP levels + Corrective and Predictive actions [Pg1 Pg2 Pg3 PM CM]
Actions.Names{2}={'go2Pg1' 'go2Pg2' 'go2Pg3' 'PM' 'CM'}; % GEN 2 has 3 OP levels + Corrective and Predictive actions [Pg1 Pg2 Pg3 PM CM]

Actions.Costs=[0 0 0 0 0 0 0 0; % OP action 1
               0 0 0 0 0 0 0 0; % OP action 2
               0 0 0 0 0 0 0 0; % OP action 3
               10  10  0 0 0 0 15  15 ; % PM action 4
               500  500  0 0 0 0 150  150 ]; % PM action 5 
          
%  NUMBER OF ACTIONS to EACH COMPONENT 
Actions.N{1}=[5];  Actions.N{2}=[5]; 
Actions.N{3}=[1]; Actions.N{4}=[1];  
Actions.N{5}=[1]; Actions.N{6}=[1]; 
Actions.N{7}=[1]; % assumes in this new case study that lines mainteinance is not perfomred by the generators agent
Actions.N{8}=[1]; % assumes in this new case study that lines mainteinance is not perfomred by the generators agent
% NUMBER OF STATES ASSOCIATED to EACH COMPONENT  
States.N{1}=[4];  States.N{2}=[4];  
States.N{3}=[3];  States.N{4}=[3];   
States.N{5}=[3];  States.N{6}=[3];  
States.N{7}=[3]; States.N{8}=[3];  

%% Operational transition Probabilities
% Those defines the dynamic of the system operations, 
%OperativeStates.Idx.C2 % State of Carge 1 
 Probabilities{3}=[0.400000000000000,0.300000000000000,0.300000000000000;0.300000000000000,0.300000000000000,0.400000000000000;0.200000000000000,0.400000000000000,0.400000000000000]; % Load 1  (random)
 Probabilities{4}=[0.400000000000000,0.300000000000000,0.300000000000000;0.300000000000000,0.300000000000000,0.400000000000000;0.200000000000000,0.400000000000000,0.400000000000000]; % Load 2  (random)
 Probabilities{5}=[0.500000000000000,0.100000000000000,0.400000000000000;0.300000000000000,0.300000000000000,0.400000000000000;0.100000000000000,0.400000000000000,0.500000000000000]; % Renewable 1  (random)
 Probabilities{6}=[0.50,0.200000000000000,0.300000000000000;0.400000000000000,0.400000000000000,0.200000000000000;0,0.500000000000000,0.500000000000000]; % Renewable 2  (random)
 Probabilities{7}=[0.90,0.08,0.020;0,0.97,0.03;0.1,0,0.9]; % line  (driven by deg)
 Probabilities{8}=[0.90,0.08,0.020;0,0.97,0.03;0.1,0,0.9]; % line  (driven by deg)
%% DEG Probabilities
% Those are the trasition probabilities of action-controllable components
% each action has a Scomp x Scomp matix of trasition probabilities where Scom is the number of states of the specific component attribute
 Probabilities{1}(:,:,1)=[0.980000000000000,0.0200000000000000,0,0;0,0.950000000000000,0.0500000000000000,0;0,0,0.900000000000000,0.100000000000000;0,0,0,0]; % Generator degradation action 1 (go to Pg1)
 Probabilities{1}(:,:,2)=[0.970000000000000,0.0300000000000000,0,0;0,0.950000000000000,0.0500000000000000,0;0,0,0.900000000000000,0.100000000000000;0,0,0,0]; % Generator degradation action 2 (go to Pg2)
 Probabilities{1}(:,:,3)=[0.950000000000000,0.0400000000000000,0.01,0;0,0.950000000000000,0.0400000000000000,0.01;0,0,0.9700000000000000,0.0300000000000000;0,0,0,0]; % Generator degradation action 3 (go to Pg3)
 Probabilities{1}(:,:,4)=[1,0,0,0; 0.5,0,0.5,0; 0.5,0,0,0.5; 0,0,0,0]; % Generator degradation action 4 (PM)
 Probabilities{1}(:,:,5)=[0,0,0,0; 0,0,0,0; 0,0,0,0; 0.15,0,0,0.85]; % Generator degradation action 5 (CM)
 Probabilities{2} = Probabilities{1}; % Generator
%  Probabilities{7}(:,:,1)=[0.90,0.08,0.020;0,0.97,0.03;0,0,0]; % Line G1-L1 degradation action 1 (notmal operation)
%  Probabilities{7}(:,:,2)=[1,0,0; 0.5,0.5,0;0,0,0]; % Line G1-L1 degradation action 2 (PM)
%  Probabilities{7}(:,:,3)=[0,0,0; 0,0,0; 0.1,0,0.9];  % Line G1-L1 degradation action 3 (CM)
%  Probabilities{8}= Probabilities{7}; % Line G1-L2

           



