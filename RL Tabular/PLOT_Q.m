function PLOT_Q(Q,MSS)


[MaxQ,Policy_MDP]=max(Q,[],2);
LEmeglioAzioni=MSS.ActionMatrix(Policy_MDP,:);
 figure 
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
figure 
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
figure  %increasing load demand 
scatter(SumRES(SumGenDeg==GeneratorsDegTarget),MaxQ(SumGenDeg==GeneratorsDegTarget));
figure  %renewable production and 
scatter(SumLoads(SumGenDeg==GeneratorsDegTarget),MaxQ(SumGenDeg==GeneratorsDegTarget));
figure %line degradation
scatter(SumDegLin(SumGenDeg==GeneratorsDegTarget),MaxQ(SumGenDeg==GeneratorsDegTarget));


figure 
subplot(1,2,1)
mesh(Q)
subplot(1,2,2)
contour(Q)

figure 
for ac=1:MSS.Nactions
    ecdf(Q(~isnan(Q(:,ac))&~isinf(Q(:,ac)),ac))
    hold on  
end
grid on
xlabel(['Q(s,a) for a =1,...,' num2str(MSS.Nactions)])
ylabel('ECDF(Q)')
end