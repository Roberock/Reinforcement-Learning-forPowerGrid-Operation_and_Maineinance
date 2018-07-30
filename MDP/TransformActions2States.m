function MSSState=TransformActions2States(OperativeStates,AvailableActions)
ActiveComponents=[1 2 7 8];
MSSState=zeros(size(AvailableActions));
for s=1:size(AvailableActions,1)
    for c=ActiveComponents
    MSSState(s,c)=OperativeStates.Val{c}(AvailableActions(s,c));
    end
end 
end