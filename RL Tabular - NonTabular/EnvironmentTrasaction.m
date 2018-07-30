function [ns,nsVect]=EnvironmentTrasaction(csVec,csAVect,MSS)
%% ENVIRONMENT MOVE RANDOMLY FROM S(t)-->S(t+1)
% INPUT:  csVec= curretn stae vector ,csAVect=  current action vector ,MSS= MultyStateSystemStructure
% OUTPUT:  ns= next state index ,nsVect=  next state vector  
%nsVect=zeros(1,MSS.Ncomponents);
for c=1:MSS.Ncomponents % FOR EACH COMPONENT RANDOMIZE A STATE TRANSACTION
    nsVect(c)=find(cumsum(MSS.Probabilities{c}(csVec(c),:,csAVect(c)))>=rand(),1); % next state vector
end
%ns=find(ismember(MSS.SatesMatrix,nsVec,'rows')); % Find the state index corresponding to the next state vector
ns=sub2ind(MSS.NrandomStatesComp, nsVect(1),nsVect(2),nsVect(3),nsVect(4),nsVect(5),nsVect(6),nsVect(7),nsVect(8)); 
end