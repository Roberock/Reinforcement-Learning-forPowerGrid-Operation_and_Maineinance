function [Output]=Keep_on_Training_ANN(PreviousTraining_InuputData,MSS,maxEpisodes,TimeWindow,Alpha,Epsilon,gamma)

NETcell=PreviousTraining_InuputData.NETcell;
NormConstOut=PreviousTraining_InuputData.NormConstOut;

%% START Q-learning with ANN
TrainingCounter=zeros(1,MSS.Nactions); % counts the number of times the network was trained
ReductionAlphaCounter=ones(1,MSS.Nactions); % counts the number of times the network was trained
ReductionEpsilonCounter=1;
CounterUpdating=0; 
epsilon=Epsilon(ReductionEpsilonCounter); % start from the highest greediness factor
for i=1:maxEpisodes
 %sample inital system state 
    cs=randi(MSS.Nstates);% Select a random state using uniform law 
    csVect=MSS.SatesMatrix(cs,:);% corresponding MSS state vector 
    
    %% START EPISODE   % Repeate until Goal state is reached
    for t=1:TimeWindow %repeat for a time window of TimeWindow
       %% Explorative vs exploitative actions
        [csA,Action]=Exploit_or_Explore25Net(NETcell,cs,csVect,MSS,epsilon,NormConstOut); % Action index action in states whilst csA index action in the action set (among all possible action)
        csAVect=MSS.ActionMatrix(csA,:); % The action vector corresponding to csA
        csACost=MSS.ActionsCosts(csA);% The cost of the action
        
        %% ENVIRONMENT MOVE RANDOMLY FROM S(t)-->S(t+1)
        [ns,nsVect]=EnvironmentTrasaction(csVect,csAVect,MSS);
        
        %% REWARDS: when taking action a in current state cs  Reward(cs,csA,ns) is assumed Reward(cs,csA)
        reward_cs_a=MSS.REWARDS{cs}(Action)-csACost;
        
        %% Q-learning
        QforNs=zeros(1,MSS.Nactions)-inf;
        for Azioni=MSS.IdxCombinationofActionsinStateS{ns}'
            QforNs(Azioni)=NETcell{Azioni}([nsVect./MSS.NrandomStatesComp]')*NormConstOut(Azioni);
        end
        MaxQnext=max(QforNs); % calculate maximum obt
        QTargets=reward_cs_a + gamma*MaxQnext;% Temporal Difference
        input = [csVect./MSS.NrandomStatesComp]'; % normalize input
        target = QTargets./NormConstOut(csA); % normalize target
        %% Train the Network Incrementally
        [net,~,~] = train(NETcell{csA},input,target);  %train 
        %% Decrease the learning rate of the network that has been trained
    
        %Chage exploration rate
              CounterUpdating=CounterUpdating+1; % we entered a new updating of Q
        %       SQERROR=(Q(:)- Q_MDP(:)).^2;   RMS(CounterUpdating)=sqrt(mean(SQERROR(~isnan(SQERROR))));
        if mod(CounterUpdating,ReductionStep)==0% Reduce learning rate, the more we learn about something the less the learning rate decreases with the iterations
            ReductionEpsilonCounter=ReductionEpsilonCounter+1; 
            epsilon=Epsilon(ReductionEpsilonCounter);
        end
        
        % Change learning rate
        TrainingCounter(csA)=TrainingCounter(csA)+1;  
        if mod(TrainingCounter(csA),ReductionStep)==0% Reduce learning rate, the more we learn about something the less the learning rate decreases with the iterations
            ReductionAlphaCounter(csA)=ReductionAlphaCounter(csA)+1;
            net.trainParam.lr=Alpha(ReductionAlphaCounter(csA));
        end
        
        NETcell{csA}=net;  %  save net
        cs=ns;  csVect=MSS.SatesMatrix(cs,:);   % Current-state is Next-State
        
    end

    if mod(i,100)==1 
        display(['QL+ANN EPISODE N-' num2str(i)])  
    end
    
end
    %% SAVE Q to CHECK  CONVERGENCE
    for Azioni=MSS.IdxCombinationofActionsinStateS{1}'
        QSTATE1(Azioni)=NETcell{Azioni}((MSS.SatesMatrix(1,:)./MSS.NrandomStatesComp)').*NormConstOut(Azioni);
    end
    for Azioni=MSS.IdxCombinationofActionsinStateS{4}'
        QSTATE2(Azioni)=NETcell{Azioni}((MSS.SatesMatrix(4,:)./MSS.NrandomStatesComp)').*NormConstOut(Azioni);
    end
    for Azioni=MSS.IdxCombinationofActionsinStateS{end}'
        QSTATE3(Azioni)=NETcell{Azioni}((MSS.SatesMatrix(end,:)./MSS.NrandomStatesComp)').*NormConstOut(Azioni);
    end
    
    Output.Qs1_final=max(QSTATE1(MSS.IdxCombinationofActionsinStateS{1}));
    Output.Qs2_final=max(QSTATE2(MSS.IdxCombinationofActionsinStateS{4}));
    Output.Qs3_final=max(QSTATE3(MSS.IdxCombinationofActionsinStateS{end}));
    Output.PreviousTraining_InuputData
end