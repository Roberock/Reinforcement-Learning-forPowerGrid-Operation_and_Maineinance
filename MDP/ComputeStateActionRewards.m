function  OPrewards=ComputeStateActionRewards(CombinationofActionsinStateS,MSS)
  %% This Funciton caluclate the reward for the power grid system and for each combination of state-action pairs
  % the cost evaluation of the system is otained using a classical
  % DC-optimalpowerflow and by associatin a cost to the Energy-not-supplied
  
  OPrewards=cell(1,MSS.Nstates);
 for s=1:MSS.Nstates
     State_ActionVector=TransformActions2States(MSS.OperativeStates,CombinationofActionsinStateS{s});
      for c=MSS.NonActiveComponents %% 
         State_ActionVector(:,c)=MSS.OperativeStates.Val{c}(MSS.SatesMatrix(s,c));
      end
     OperationalReward=zeros(1,size(State_ActionVector,1));
      parfor r=1:size(State_ActionVector,1)
          OperationalReward(r)=ModelOperationalSolverCaseStudynoBattery(State_ActionVector(r,:));
     end
     OPrewards{s}=OperationalReward; 
     disp(['Evaluate reward for state ' num2str(s) ' and all available actions'])
 end
 
end