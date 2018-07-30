function [ENS, NETminCo, PNETu, PDGu, ef] = OPF(x, NETPavM, LD, FDmecst, D)
%%	OPF.m: Optimal power flow function considering virtual generators
%
%   Inputs
%       x: allocation matrix for the distributed generators
%       NETPavM: power available in the net
%       LD: loads
%       FDmecst: mechanical states of the feeders
%       D: struct with the needed data for the evaluation of fns
%   Output
%        ENS: Energy Non Supplied
%        NETminCo:  minimum operating cost of the net
%        PNETu: real used power in the net
%        PDGu: real used power of the dgs
%        ef: exitflag of the solver of the OPF
%
%   OPF problem definition
%   
%   min NETco x xNET
%       s.t.
%           Ainq x xnet <= binq
%           Aeq x xnet = beq
%           lb <= x <= up
%
%       xNET: decision vector of the minimization problem. Contains the
%             DGs, the virtual generators and the feeders present in
%             the network. The optimal gives the real power used from the
%             DGs, the load shedding (power virtualy generated to satify
%             the demand) and the power flow in the feeders.
%       binq: containts the max power available for each generator
%             (NETPavM) and the limit of power that is allowed to flow by each feeder
%       beq: is equal to the load in each node
% _________________________________________________________________________
%
%                          DEVELOPED BY 2112 inc.
%__________________________________________________________________________
%%
    
    V0 = D.Vnom;                     % per unit Voltage
    S0 = D.Vnom.^2;                  % per unit Apparent power 
    Z0 = (V0.^2)/S0;                 % per unit Impedance 
    Xpu = D.FDX/Z0;                  % per unit Reactance
    Bpu = (-1./Xpu);                 % per unit Susceptance
    LD0 = LD/S0;                     % per unit Susceptance
    FDPlim = D.FDAmp*D.Vnom;         % feeders power limit
 
    spx = sparse(x);                 % sparse x
    nzn = nnz(spx);                  % number of non-zeros elements in x
    xvg = [x ones(D.NDn,1)];         % adding the virtual generators to x                                 
    spxvg = sparse(xvg);             % sparse xvg
    nznvg = nnz(spxvg);              % number of non-zeros elements in xvg

%   UNTIL THE MOMENT THE COSTS OF THE FEEDERS ARE NOT CONSIDERED

    MSco = D.MSCo(ones(D.NDn,1),:);
    DGco = [D.PVCo(ones(D.NDn,1),:) D.WCo(ones(D.NDn,1),:) D.EVCo(ones(D.NDn,1),:)...
            D.STCo(ones(D.NDn,1),:)].*D.pckg(ones(D.NDn,1),:);     
    MS_DG_VGco = [MSco DGco D.VGCo];
    NETco = [MS_DG_VGco(find(spxvg)); zeros(D.FDn,1)];  % [MS_DG_VGco FDco]
    
    MS_DGAeq = zeros(D.NDn,nznvg);
    [i,~,~] = find(spxvg);
    MS_DGAeq(i+(((1:nznvg)')-1)*D.NDn) = 1;

    FDAeq = zeros(D.NDn,D.FDn);
    FDAeq(D.FDks+(((1:D.FDn)')-1)*D.NDn) = Bpu.*FDmecst;
    FDAeq(D.FDke+(((1:D.FDn)')-1)*D.NDn) = -Bpu.*FDmecst;
    
    Aeq = [MS_DGAeq, FDAeq];
    beq = LD0;
    lb = [zeros(nznvg,1); FDPlim./Bpu]/S0;  
    ub = [NETPavM(find(spx)); ones(D.NDn,1)*D.VGcap; - FDPlim./Bpu]/S0;
    
%  Solver 
Options.Display='off';
Options.Algorithm='dual-simplex';
[xNET, fval, ef] = linprog(NETco', [], [], Aeq, beq, lb, ub, [],Options);

if ef~=1 && ef~=-3
Options.Algorithm='interior-point-legacy';
[xNET, fval, ef] = linprog(NETco', [], [], Aeq, beq, lb, ub, [],Options); 
display(ef)
end
%  outputs
    fdP = xNET(nzn+D.NDn+1:end).*Bpu*S0;
    %Angle=fdP./(Bpu*S0);
    ENS = sum(xNET(1+nzn:nzn+D.NDn))*S0/D.ts;
    NETminCo = fval*S0-ENS*D.VGCo(1);
    PNETu = (xNET(1:nzn))*S0;
    PDGu = sum(xNET(D.MSn+1:nzn+D.MSn-1,1))*S0;
%   nENS = xNET(1+nzn:nzn+D.NDn)*S0;
%   nPnetr = xNET.*[ones(nzn,1);zeros(D.NDn,1);zeros(D.FDn,1)]*S0;
%   fdP =  xNET.*[zeros(nzn,1);zeros(D.NDn,1);ones(D.FDn,1)]*S0;

    
end
