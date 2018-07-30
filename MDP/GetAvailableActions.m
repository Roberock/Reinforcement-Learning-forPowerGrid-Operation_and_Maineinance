function [CombinationofActionsinStateS,NavailableActionsState,IdxCombinationofActionsinStateS]=GetAvailableActions(MSS)
%% This function identify the available actions for each parent state 's'
% INPUT
% MSS is the multy state system data structure
% SatesMatrix is the matrix of states Combinations Nstates x Ncomp
%OUTPUT
% CombinationofActionsinStateS= 1 x Nstates cell, each cell contains Na*Ncomp matrix of actions
% NavailableActionsState =  1 x Nstates array of number of actions per state
% IdxCombinationofActionsinStateS =  1 x Nstates array of indices corresponding to action vectors
SatesMatrix=MSS.SatesMatrix;
NavailableActionsState=zeros(1,size(SatesMatrix,1));
[CellofActionsPerComponent,CombinationofActionsinStateS,IdxCombinationofActionsinStateS]=deal(cell(1,MSS.Nstates));
for i=1:MSS.Nstates
    CellofActionsPerComponent{i}=ConstrainActionSpace(SatesMatrix(i,:),MSS);% A Cell of ALLOWED action indices in state i for each component
    CombinationofActionsinStateS{i}=GetAvailableActionTable(CellofActionsPerComponent{i});% combination of actions available for each state
    NavailableActionsState(i)=size(CombinationofActionsinStateS{i},1);
    IdxCombinationofActionsinStateS{i}=find(ismember(MSS.ActionMatrix,CombinationofActionsinStateS{i},'rows'));
end

 
end