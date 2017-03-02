function [b,K] = binom_revweib( r, m, x, p, initK, guessing, lapsing)
%
% Maximum likelihood estimates of the parameters of the reverse Weibull
% model for the psychometric function.
%
%
% INPUT
%
% r - number of successes at points x
% m - number of trials at points x 
% x - stimulus levels
%
% OPTIONAL INPUT
% 
% p - degree of the polynomial; default is 1 
% initK - initial value for K (power parameter in reverse Weibull model);
% default is 2 
% guessing - guessing rate; default is 0
% lapsing - lapsing rate; default is 0
%
% OUTPUT
% 
% b - vector of estimated coefficients for the linear part
% K - estimate of the power parameter in the reverse Weibull model

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % % PROGRAM

%%%% CHECK INPUT PARAMETERS
% First 2 paramaters are mandatory
if (nargin<3)
    error('Check input. First 3 arguments are mandatory');
end

%%%% DEFAULTS
if (nargin<4)
    p = 1;
    disp('degree of the polynomial is 1');
end

if (nargin<5)
    initK = 2;
    disp('initial value for K (power parameter in reverse Weibull model) is 2');
end

if (nargin<6)
    guessing = 0;
    disp('default guessing rate is zero');
end

if (nargin<7)
    lapsing = 0;
    disp('default lapsing rate is zero');
end

%%%% CHECK ROBUSTNESS OF INPUT PARAMETERS
clear data;
data(1).content = x;
data(2).content = r;
data(3).content = m;
checkinput( 'psychometricdata', data );
clear data;
pn = cell(1,2);
pn{1} = p;
pn{2} = x;
checkinput( 'degreepolynomial', pn );
if length( guessing ) > 1
    error( 'Guessing rate must be a scalar' );
end
if length( lapsing ) > 1
    error( 'Lapsing rate must be a scalar' );
end
checkinput( 'guessingandlapsing', [ guessing lapsing ] );
checkinput( 'exponentk', initK );

tmp1(:,1) = x;
x = tmp1;
Lx = length(x);
X = repmat(x,1,p).^repmat((1:p),Lx,1);

% GLM ESTIMATION
s_msg_id = warning('query','all');
warning('off','stats:glmfit:IterationLimit');
warning('off','stats:glmfit:BadScaling');

initK = log(initK);
K = fminsearch(@(K) likfun(K,X,[r m],guessing,lapsing),initK,optimset('MaxFunEvals',5000,...
    'MaxIter',5000,'TolX',1e-3,'TolFun',1e-3));
K = .05+exp(K);

warning(s_msg_id)
%%%%%%%%%
%%% SET LINK
link = revweibull_link( K, guessing, lapsing );

%%%%%%
% GLM
b = glmfit( X, [r m], 'binomial', 'link', link);

% % % % % % % % % % % % % % % % % % 
% % % INTERNAL FUNCTIONS % % % % % 
% % % % % % % % % % % % % % % % % % 


%%%%%%%%%%%%%%%%%% LIKELIHOOD %%%%%%%%%%%%%%%%%%%%%%%%%%%
function res = likfun(K,x,Y,guessing,lapsing)

K = .05+exp(K);

%%% SET LINK
link = revweibull_link( K, guessing, lapsing );

% GLM
b = glmfit(x,Y,'binomial','link',link);

% FITTED PROBABILITIES
fitted = glmval(b,x,link);
fitted( fitted <= guessing ) = guessing + eps;
fitted( fitted >= 1 - lapsing ) = 1 - lapsing - eps;

% LIKELIHOOD
res = -(Y(:,1)' * log(fitted) + (Y(:,2) - Y(:,1))' * log(1 - fitted));

%%%%%%% END LIKELIHOOD %%%%%%%%%%%%%%%%%%%%%%