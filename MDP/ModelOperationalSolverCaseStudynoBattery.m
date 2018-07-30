function OperationalReward=ModelOperationalSolverCaseStudynoBattery(state)
% the state=[Pgenerators1,Pgenerators2, Load demand1 , Load demand2, Prenewables1,Prenewables2, Links op state 1 and 2]
%% System Data (Structure, Gen Allocation Matrix, Costs, etc)
x=[1 0 0 0 0; 0 1 0 0 0; 0 1 0 0 0; 1 0 0 0 0]; % Generators allocation matrix
D.FDks=[1;1;1;2;3]; % The MSS structure, start nodes
D.FDke=[2;3;4;4;4]; % The MSS structure, end nodes
D.Vnom=4.16; % nominal voltage of the power grid
D.FDX=[0.084557236;0.071993761;0.050734342;0.22605416;0.22605416]; % feeders electrical proprieties
D.FDAmp=[125;135;135;115;115];  % feeders thermal limit in [A]
D.NDn=4; %Number of network nodes
D.FDn=5; %Number of feeders
D.MSn=1; %Number of main generators
D.ts=1;  %Time step
% Operative Costs
D.MSCo=0.1450;% cost of the main generators
D.VGCo=[1e9;1e9;1e9;1e9]; % cost of the virtual generators
D.VGcap=10000; % cost of virtual generators (set high to avoid them to be used unless necessary)
D.PVCo=3.7670e-05;% cost of the photovoltaic generators
D.WCo=0.0390; % cost of the wind generators
D.EVCo=0.0210; % cost of the electric vehicles generators
D.STCo=4.6284e-05; % cost of the storage generators
D.pckg=[50 1  1  50]; %packaging factor for the modularity
D.ENSCo=5; % cost of the ENRGY NOT SUPPLIED
D.PNETuRevenue=4; % MODIFIED 1->4 revenue of the load supplied 
%load('DataNetwork')
%% EVALUATE SYSTEM AT THE GIVEN STATE S
% s_old= the state before action and random transaction
% the state=[Pgenerators, Load demand, Prenewables, Pbattery, Links Degradation]
FDmecst_old = ones(D.FDn,1);
FDmecst_old(1)=state(7); % set op state of line connecting gen 1 to load 1
FDmecst_old(2)=state(8); % set op state of line connecting gen 1 to load 2
LD_old = zeros(D.NDn,1);
LD_old(2:3)=state(3:4); % define the loads
NETPavM_old = [state(1) 0 0 0 0; 
    0 state(5) 0 0 0; 
    0 state(6) 0 0 0; 
    state(2) 0 0 0 0]; % The matrx of available power
%[ENS, NETminCo, PNETu, PDGu, ef] = OPF(x, NETPavM_old, LD_old, FDmecst_old, D)
[ENS,~,PNETu,~,~] = OPF(x, NETPavM_old, LD_old, FDmecst_old, D);% The DC Optimal power flow solver...
%% CALCULATE Reward as +Revenue (electric power supplied)- Production Cost - Renewable production cost- Energy not supplied cost
OperationalReward=sum(PNETu)*D.PNETuRevenue-sum(state(1:2)*D.MSCo)-sum(state(5:6)*D.PVCo)-(ENS*D.ENSCo) ;% The reward is the cost of the energy not supplied in [EURO\MW] * ENS [MW] and the revenue obtained by the load supplied
end