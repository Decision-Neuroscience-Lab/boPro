function b = binomfit_lims(r, m, x, p, link, guessing, lapsing , K)
%
% Maximum likelihood estimates of the parameters of the psychometric
% function based on a binomial generalized linear model with given guessing
% and lapsing rates.
%
%INPUT
%
% r - number of successes at points x
% m - number of trials at points x 
% x - stimulus levels
%
% OPTIONAL INPUT
%
% p - degree of the polynomial; default is 1 
% link - name of the link function; default is 'logit' 
% guessing - guessing rate; default is 0
% lapsing - lapsing rate; default is 0
% K - power parameter for Weibull and reverse Weibull link; default is 2
%
% OUTPUT
%
% b - vector of estimated coefficients for the linear part

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% PROGRAM

%%%% CHECK INPUT PARAMETERS
% First 2 paramaters are mandatory
if (nargin<3)
    error('Check input. First 3 arguments are mandatory');
end

%%%%
%%%% DEFAULTS
if (nargin<4)
    p = 1;
    disp('degree of the polynomial to be fitted on the linear scale is 1');
end

if (nargin<5)
    link = 'logit';
    disp('default link function is ''logit''');
end

if (nargin<6)
    guessing = 0;
    disp('default guessing rate is zero');
end

if (nargin<7)
    lapsing = 0;
    disp('default lapsing rate is zero');
end

if (nargin<8)
    K = 2;
    if strcmp(link, 'weibull')
        disp('default exponent for Weibull link function is 2');
    elseif strcmp(link, 'revweibull')
        disp('default exponent for reverse Weibull link function is 2');
    end
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
checkinput( 'linkfunction', link );
checkinput( 'guessingandlapsing', [ guessing lapsing ] );
if ( strcmp(link, 'weibull') || strcmp(link, 'revweibull'))
    checkinput( 'exponentk', K );
end

%%%%
%%%% INITIALS VALUES

% column vectors
tmp1(:,1) = x;
x = tmp1;

Lx = length(x);

% create matrix with all powers (1 to p) of X (for use in GLMFIT)
X = repmat(x,1,p).^repmat((1:p),Lx,1);

%%%%%%
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


%  fit the GLM model
b = glmfit( X, [r m], 'binomial', 'link', linkfun);