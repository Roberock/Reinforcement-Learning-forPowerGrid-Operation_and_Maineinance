function [AvailableActionsMatrix]=GetAvailableActionTable(CellofActionsPerComponent)
%% This Function create a list of states combinations given the discretization list of states allowed for each component
% e.g a list of 4 components first 2 have 3 states, last 2 have 10 and 12  states, respectivelly
% NumberofSatesPerComponent=[4 4 10 12]; SatesTable=MakeStatesTable(NumberofSatesPerComponent)
 
Ncomponents=length(CellofActionsPerComponent);
StatesofComponent1=CellofActionsPerComponent{1};
AvailableActionsMatrix=StatesofComponent1';
ColumnNames=cell(1,Ncomponents);
ColumnNames{1}={'C_1'};

for i=2:Ncomponents
    ColumnNames{i}=['C_' num2str(i)];
    StatesofComponenti=CellofActionsPerComponent{i};
    SizeTableTemp=size(AvailableActionsMatrix,1);
    AvailableActionsMatrix=repmat(AvailableActionsMatrix,length(CellofActionsPerComponent{i}),1) ;
    Add2TabComponenti=[];
    for s=StatesofComponenti
        Add2TabComponenti=[Add2TabComponenti;repmat(s,SizeTableTemp,1)];
    end
    AvailableActionsMatrix=[AvailableActionsMatrix Add2TabComponenti];
end

end