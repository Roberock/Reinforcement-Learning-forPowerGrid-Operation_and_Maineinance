%% SOLVE BELLMAN OPTIMALITY EQUATION for V
% Initialize our state-value function (Nstates):
%Q =  nan(MSS.Nstates,MSS.Nactions)-inf;
load('Q_MDP.mat')
% Q =  Q(1:MSS.Nstates,1:MSS.Nactions);
gamma=0.9; %discount factor
% some parameters for convergence:
MAX_N_ITERS = 100; iterCnt = 0;  CONV_TOL  = 1e-3; deltaQ= 1e10;
while( (deltaQ > CONV_TOL) && (iterCnt <= MAX_N_ITERS) )
    %deltaV = 0;
    deltaQ = 0;
    for s1=1:MSS.Nstates
        S1=SatesMatrix(s1,:);
        [TransactionProbability_s1_a_s2]=deal(cell(1,NavailableActionsState(s1)));
        [IdxAzione,Cost]=deal(zeros(1,NavailableActionsState(s1)));
        %CombinationofStatiRaggiungibili=cell(1,NavailableActionsState(s1));
        for a=1:NavailableActionsState(s1) % FOR EACH FEASIBLE ACTION IN S
            q = Q(s1,IdxCombinationofActionsinStateS{s1}(a)); 
            if isnan(q)  
                q=0;
            end
            actionVector=CombinationofActionsinStateS{s1}(a,:);
            for c=1:MSS.Ncomponents % FOR EACH COMPONENT
                %MSS.Probabilities{c}(s1,:,actionVector(c));
                ActionCost(c)=Actions.Costs(actionVector(c),c);
                StatiRaggiungibili{c}=find(MSS.Probabilities{c}(S1(c),:,actionVector(c))~=0);
                ProbabilityRaggiungimento{c}=MSS.Probabilities{c}(S1(c),StatiRaggiungibili{c},actionVector(c));
            end
            Cost(a)=sum(ActionCost); % cost of the action to compute the final reward P(s2|a,s1) 
            TransactionProbability_s1_a_s2{a}=prod(GetAvailableActionTable(ProbabilityRaggiungimento),2);
            % find the states that can be reached from action a if taken in s
            CombinationofStatiRaggiungibili=GetAvailableActionTable(StatiRaggiungibili);  
            IdxS2_Action=find(ismember(SatesMatrix,CombinationofStatiRaggiungibili,'rows'));
           
            MaxQs2a2=max(Q(IdxS2_Action,:),[],2); % the maximum among the next states actions values
            %Q(s1,IdxAzione(a))=REWARDS{s1}(a)-Cost(a)+gamma*sum(TransactionProbability_s1_a_s2{a}(~isnan(MaxQs2a2)).*MaxQs2a2(~isnan(MaxQs2a2)) );
            Q(s1,IdxCombinationofActionsinStateS{s1}(a))=REWARDS{s1}(a)-Cost(a)+gamma*sum(TransactionProbability_s1_a_s2{a}(~isnan(MaxQs2a2)).*MaxQs2a2(~isnan(MaxQs2a2)) );
             
            deltaQ = max( [ deltaQ, abs( q-Q(s1,IdxCombinationofActionsinStateS{s1}(a)) ) ] );
        end
        %  V(s1)  = max(Vtemp); % maximise value function among the available actions (optimality policy)
        %  Q(s1,IdxAzione)  = sum(REWARDS{s1}-Cost(a)+max(Qtemp(:,IdxAzione)));
        %  deltaV = max([ deltaV, abs( v-V(s1) ) ] );
        %  deltaQ= max([ deltaQ, abs( q(~isinf(Q(s1,:)))-Q(s1,~isinf(Q(s1,:))) ) ] );
        if mod(s1,1e2)==0
            display(['State Evaluation ' num2str(s1) ', DeltaQ= ' num2str(deltaQ)])
        end
    end
    %V, delta
    iterCnt=iterCnt+1;
    display(['Optimality Iteration ' num2str(iterCnt) ', DeltaV= ' num2str(deltaQ) ])
    save('Q_MDP','Q')
    
end

%% PLOTs

[MaxQ,Policy_MDP]=max(Q,[],2);
LEmeglioAzioni=ActionMatrix(Policy_MDP,:);
 figure(1)
subplot(2,1,1)
hist(LEmeglioAzioni(:,1))
ylabel('Number of states')
xlabel('Actions Gen1')
grid on
subplot(2,1,2)
grid on
hist(LEmeglioAzioni(:,2))
ylabel('Number of states')
xlabel('Actions Gen2')
grid on

% plot the trend of Q(s,a) with the increasing degradation of the generators
Components=[1,2];
SumGenDeg=sum(MSS.SatesMatrix(:,Components),2);
figure(2)
scatter(SumGenDeg,MaxQ);
% plot the trend of Q(s,a) for the loads fixing the state of the generators
Components=[3,4];
SumLoads=sum(MSS.SatesMatrix(:,Components),2);
Components=[5,6];
SumRES=sum(MSS.SatesMatrix(:,Components),2);
Components=[7,8];
SumDegLin=sum(MSS.SatesMatrix(:,Components),2);

GeneratorsDegTarget=2; % AsGoodAsNew both generators
%GeneratorsDegTarget=3; % 1 gen in Deg 1
%GeneratorsDegTarget=4; % 1 gen in Deg 2 or both gen in deg 1
%GeneratorsDegTarget=8; % Both generators failed
% plot maximum expected reward following optimal policy for 
figure(3) %increasing load demand 
scatter(SumRES(SumGenDeg==GeneratorsDegTarget),MaxQ(SumGenDeg==GeneratorsDegTarget));
figure(4) %renewable production and 
scatter(SumLoads(SumGenDeg==GeneratorsDegTarget),MaxQ(SumGenDeg==GeneratorsDegTarget));
figure(5)%line degradation
scatter(SumDegLin(SumGenDeg==GeneratorsDegTarget),MaxQ(SumGenDeg==GeneratorsDegTarget));


figure(6)
subplot(1,2,1)
mesh(Q)
subplot(1,2,2)
contour(Q)

figure(8)
for ac=1:MSS.Nactions
    ecdf(Q(:,ac))
    hold on  
end
grid on
xlabel(['Q(s,a) for a =1,...,' num2str(MSS.Nactions)])
ylabel('ECDF(Q)')