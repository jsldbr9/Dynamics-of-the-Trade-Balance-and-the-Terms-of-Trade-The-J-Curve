function [ys,params,check] = J_CURVE_steadystate(ys,exo,M_,options_)

% function [ys,check] = *model*_steadystate(ys,exo)
% computes the steady state for the associated *model*.mod file using a numerical solver
%
% Inputs:
%   - ys        [vector] vector of initial values for the steady state of the endogenous variables
%   - exo       [vector] vector of values for the exogenous variables
%
% Output:
%   - ys        [vector] vector of steady state values for the the endogenous variables
%   - check     [scalar] set to 0 if steady state computation worked and to
%                        1 of not (allows to impose restriction on parameters)

check = 0; % set the indicator vaiable (=1 means that the steady state is not found)




%-------------------------------------------------------------------------
% Upload initial values of structural parameters
%-------------------------------------------------------------------------
NumberOfParameters = M_.param_nbr;
for ii = 1:NumberOfParameters
  paramname = M_.param_names{ii,:};
  eval([ paramname ' = M_.params(' int2str(ii) ');']);
end




%-------------------------------------------------------------------------
% Set up the problem (try to use closed-form solutions as much as possible)
%-------------------------------------------------------------------------

q_H = 1;
q_F = 1;
A = 1;
A_H = 1;
A_F = 1;
sdf_H = betta;
sdf_F = betta;

% Symmetric equilibrium
Eqs = @(x)...
[...

% (1) Labor market
%((1-muu)/muu)*(c/(1-n)) = qa_H * (1-theta)*exp(A)  * (k/n)^theta
((1-muu)/muu)*(x(1)/(1-x(2))) - x(7) * (1-theta)*exp(A)  * (x(3)/x(2))^theta

% (2) Capital market
%1 = betta  * ( 1 - delta + qa_H * theta*exp(A) * (k/n)^(theta-1) );
1 - betta  * ( 1 - delta + x(7) * theta*exp(A) * (x(3)/x(2))^(theta-1) );

% (3) Aggregate good resourse constraints
%y = delta*k  + c;
x(4) - delta*x(3)  - x(1);

% (4) Home and foreign goods resourse constraints
%exp(A)*k^(theta)*n^(1-theta) = a_H + a_F;
exp(A)*x(3)^(theta)*x(2)^(1-theta) - x(6) - x(5);

% (5) Domestic good demand
%a_H = omega*(qa_H)^(-sigm) * y_H;
x(6) - omega*x(7)^(-sigm) * x(4);

% (6) Exports demand
%a_F = (1-omega)*(qa_F)^(-sigm) * y_F;
x(5) - (1-omega)*x(7)^(-sigm) * x(4);

% (7) Aggregate price index
%omega*(qb_F)^(1-sigm) + (1-omega)*(qa_F)^(1-sigm) = 1;
omega*(x(7))^(1-sigm) + (1-omega)*(x(7))^(1-sigm) - 1;


...
];




%-------------------------------------------------------------------------
% Run the solver and save the result
%-------------------------------------------------------------------------

% Initial guesses
x0 = load('steady_st_init_values');

% Fsolve options
tol      = 1e-10;
Iter     = 100000;
FunEvals = 100000;
options  = optimset('Display', 'on', 'MaxFunEvals', FunEvals, 'MaxIter', Iter, 'TolFun', tol, 'TolX', tol);

% Run fsolve
[ss,fval,exitflag] = fsolve(Eqs, x0.ss, options);

% Exitflag indicates the reason fsolve stopped;  exitflag < 1 means that the solution was not found
if exitflag <1
    check=1;
    return;
end

% Save the solution
save('steady_st_init_values.mat','ss');




%-------------------------------------------------------------------------
% Assign output to model variables
%-------------------------------------------------------------------------

ss = real(ss);

c_H = ss(1)
c_F = c_H;
n_H = ss(2)
n_F = n_H;
l_H = 1-n_H;
l_F = l_H;
k_H = ss(3)
k_F = k_H;
y_H = ss(4)
y_F = y_H;

a_F  = ss(5)
a_H  = ss(6)
b_F  = a_H;
b_H  = a_F;

qa_H = ss(7)
qa_F = qa_H
qb_F = qa_H
qb_H = qa_H
tot  = qb_H/qa_H

nx_H = ( a_F - b_H*(qb_H/qa_H) )/y_H;
nx_F = ( b_H - a_F*(qa_F/qb_F) )/y_F;

I_H = delta*k_H;
I_F = I_H;

w_H = qa_H*(1-theta)*exp(A_H) * (k_H/n_H)^theta;
w_F = w_H;

R_k_H = qa_H*theta*exp(A_H) * (k_H/n_H)^(theta-1);
R_k_F = R_k_H;

f_H = exp(A)*k_H^(theta)*n_H^(1-theta);
f_F = f_H;

MU_c_H = muu*(c_H^B1)*(l_H^B2)
MU_c_F = MU_c_H;


log_y_H = log(y_H);
log_y_F = log(y_F);
log_c_H = log(c_H);
log_c_F = log(c_F);
log_I_H = log(I_H);
log_I_F = log(I_F);
log_k_H = log(k_H);
log_k_F = log(k_F);
log_n_H = log(n_H);
log_n_F = log(n_F);
log_A_H = log(A_H);
log_A_F = log(A_F);


%-------------------------------------------------------------------------
% Save the structural parameters (the calibrated ones will be updated)
%-------------------------------------------------------------------------

for iter = 1:length(M_.params) % update parameters set in the file
  eval([ 'params(' num2str(iter) ',1) = ' M_.param_names{iter,:} ';' ]);
end




%-------------------------------------------------------------------------
% Save the calibrated steady state
%-------------------------------------------------------------------------

% constructs the output vestor ys
NumberOfEndogenousVariables = M_.orig_endo_nbr; % auxiliary variables are set automatically

steady_st_valuses = zeros(1,NumberOfEndogenousVariables);

for ii = 1:NumberOfEndogenousVariables
    varname = M_.endo_names{ii,:};
  eval(['ys(' int2str(ii) ') = ' varname ';']);
  eval([ 'steady_st_values(' num2str(ii) ') = ' varname ';']);
end

save('steady_st_values.mat','steady_st_values');