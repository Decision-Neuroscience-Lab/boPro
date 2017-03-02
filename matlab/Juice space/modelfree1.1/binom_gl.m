function [b, guessing, lapsing] = binom_gl(r,m,x,link,p,K,initval)
%
% THIS IS AN INTERNAL FUNCTION: USE BINOM_LIMS FOR BEST RESULTS
%
% Maximum likelihood estimates of the parameters of the psychometric function
% with guessing and lapsing rates. The estimated parameters for the
% linear part are in vector 'b 'and the estimated rates are in 'guessing' and 'lapsing'.    
%
% INPUT
%
% r - number of successes at points x
% m - number of trials at points x 
% x - stimulus levels
% link - name of the link function
% p - degree of the polynomial
% K - power parameter for Weibull and reverse Weibull link
% initval - initial values for guessing and lapsing 
%
% OUTPUT
% 
% b - vector of estimated coefficients for the linear part
% guessing - estimated guessing rate
% lapsing - estimated lapsing rate

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%% PROGRAM

tmp1(:,1) = x;
x = tmp1;
Lx = length(x);
X = repmat(x,1,p).^repmat((1:p),Lx,1);

initval = log(initval./(1-initval));

% GLM ESTIMATION
gl = fminsearch(@(gl) likfun(gl,X,r,m,link,K),initval,optimset('MaxFunEvals',...
    5000,'MaxIter',5000,'Tolx',1e-3,'TolFun',1e-3));

gl = 1./(1+exp(-gl));
guessing = gl(1);
lapsing = gl(2);

% assign link function
switch link
case'logit' 
% LOGISTIC
    linkfun = logit_link_private( guessing, lapsing );
case'probit' 
% PROBIT
    linkfun = probit_link_private( guessing, lapsing );
case'loglog'
% LOG-LOG
    linkfun = loglog_link_private( guessing, lapsing );
case'comploglog' 
% COMPLEMENTARY LOG-LOG
    linkfun = comploglog_link_private( guessing, lapsing );
case 'revweibull'
% REVERSE WEIBULL WITH EXPONENT K
    linkfun = revweibull_link_private( K, guessing, lapsing );
case 'weibull'
% WEIBULL WITH EXPONENT K
    linkfun = weibull_link_private( K, guessing, lapsing );
otherwise
% USER DEFINED FUNCTION    
    linkfun = feval( link, guessing, lapsing );
end

% GLM
b = glmfit(X,[r,m],'binomial','link',linkfun);


    
% % % % % % % % % % % % % % % % % % 
% % % INTERNAL FUNCTIONS % % % % % 
% % % % % % % % % % % % % % % % % % 

%%%%%%%%%%%%%%%%%% LIKELIHOOD %%%%%%%%%%%%%%%%%%%%%%%%%%%

function res = likfun(gl,X,r,m,link,K)

gl = 1./(1+exp(-gl));

guessing = min(gl(1),1-gl(2));
lapsing = min(gl(2),1-gl(1));

switch link
case'logit' 
% LOGISTIC
    linkfun = logit_link_private( guessing, lapsing );
case'probit' 
% PROBIT
    linkfun = probit_link_private( guessing, lapsing );
case'loglog'
% LOG-LOG
    linkfun = loglog_link_private( guessing, lapsing );
case'comploglog' 
% COMPLEMENTARY LOG-LOG
    linkfun = comploglog_link_private( guessing, lapsing );
case 'revweibull'
% REVERSE WEIBULL WITH EXPONENT K
    linkfun = revweibull_link_private( K, guessing, lapsing );
case 'weibull'
% WEIBULL WITH EXPONENT K
    linkfun = weibull_link_private( K, guessing, lapsing );
otherwise
% USER DEFINED FUNCTION    
    linkfun = feval( link, guessing, lapsing );
end

% GLM
b = glmfit(X,[r,m],'binomial','link',linkfun);

% FITTED PROBABILITIES
fitted = glmval(b,X,linkfun);
fitted( fitted <= guessing ) = guessing + eps;
fitted( fitted >= 1 - lapsing ) = (1 - lapsing) - eps;

% LIKELIHOOD
res = -(r' * log(fitted) + (m - r)' * log(1 - fitted));

%%%%%%% END LIKELIHOOD %%%%%%%%%%%%%%%%%%%%%%