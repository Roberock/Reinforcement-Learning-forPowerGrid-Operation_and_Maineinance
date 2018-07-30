function CellofActionsPerComponent=ConstrainActionSpace(StateVector,MSS)
%% AVAILABLE ACTIONS CONSTRAINTS
% This function is constraining the action space associated to each
% component
CellofActionsPerComponent=cell(1,8);
for i=1:MSS.Ncomponents; CellofActionsPerComponent{i}=1; end
%% CONSTRAINTS ON actions on component 1 THE GENERATOR 1
if StateVector(1)==4 %GENERATOR IN THE LAST DEGRADATION STATE
    CellofActionsPerComponent{1}=5; % Only CORRECTIVE MAINTEINANCE ALLOWED
elseif StateVector(1)==3 %GENERATOR IN THE SECOND LAST DEGRADATION STATE
    CellofActionsPerComponent{1}=[1 4];  %  PREVENTIVE MAINTEINANCE ALLOWED BUT GENERATION CONSTRAINED TO LOW
elseif StateVector(1)==2 %GENERATOR IN THE SECOND LAST DEGRADATION STATE
    CellofActionsPerComponent{1}=[1 2 3 4];
elseif StateVector(1)==1  %GENERATOR As good as New AGAN 
    CellofActionsPerComponent{1}=[1 2 3 4];
end  
%% CONSTRAINTS ON actions on component 2
if StateVector(2)==4 %GENERATOR IN THE LAST DEGRADATION STATE
    CellofActionsPerComponent{2}=5; % Only CORRECTIVE MAINTEINANCE ALLOWED
elseif StateVector(2)==3 %GENERATOR IN THE SECOND LAST DEGRADATION STATE
    CellofActionsPerComponent{2}=[1 4];  % PREVENTIVE MAINTEINANCEor GENERATION CONSTRAINED TO LOW Production (action 1)
elseif StateVector(2)==2 %GENERATOR IN THE SECOND LAST DEGRADATION STATE
    CellofActionsPerComponent{2}=[1 2 3 4];
elseif StateVector(2)==1  %GENERATOR As good as New AGAN 
    CellofActionsPerComponent{2}=[1 2 3 4];
end

end