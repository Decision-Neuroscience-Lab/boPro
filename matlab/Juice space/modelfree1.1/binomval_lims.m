function pfit = binomval_lims( b, xfit, link,guessing, lapsing , K)
%
% Fitted values at points xfit for a binomial generalized linear model with
% coefficients b and given guessing and lapsing rates.
%
% INPUT
%
% xfit - points at which to calculate the estimate 'pfit'
% b - column vector of coefficients (result of BINOFIT_LIMS)
%
% OPTIONAL INPUT
%
% link - name of the link function; default is the canonical link 
%           'logit', but this should be the same as used in binofit_lims        
% guessing - guessing rate; default is 0, but this should be the same as
%           used in binofit_lims
% lapsing - lapsing rate; default is 0, but this should be the same as used
%           in binofit_lims 
% K - power parameter for Weibull and reverse Weibull link; default is 2,
%           but this should be the same as used in binofit_lims
%
% OUTPUT
%
% pfit - vector of fitted values at points xfit

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% PROGRAM

%%%% CHECK INPUT PARAMETERS + INFORM OF DEFAULT VALUES
% First 2 paramaters are mandatory
if (nargin<2)
    error('Coefficients (b) and stimulus levels (xfit) are mandatory');
end

%%%% DEFAULTS
if (nargin<3)
    link = 'logit';
    disp('default link function is ''logit''');
end

if (nargin<4)
    guessing = 0;
    disp('default guessing rate is zero');
end

if (nargin<5)
    lapsing = 0;
    disp('default lapsing rate is zero');
end

if (nargin<6)
    K = 2;
    if strcmp(link, 'weibull')
        disp('default exponent for Weibull link function is 2');
    elseif strcmp(link, 'revweibull')
        disp('default exponent for reverse Weibull link function is 2');
    end
end

%%%% CHECK ROBUSTNESS OF INPUT PARAMETERS
checkinput( 'designpoints', xfit );
checkinput( 'linkfunction', link );
checkinput( 'guessingandlapsing', [ guessing lapsing ] );
if ( strcmp(link, 'weibull') || strcmp(link, 'revweibull'))
    checkinput( 'exponentk', K );
end


%%%%
%%%% INITIALS VALUES

% column vectors
tmp1(:,1) = xfit;
xfit = tmp1;

% initial values
Lxfit = length(xfit);
p = length(b)-1;

% create matrix with all powers (1 to p) of xfit (for use in GLMFIT)
x = repmat(xfit,1,p).^repmat((1:p),Lxfit,1);

%%%%%
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

%%%%% FIT
pfit = glmval(b,x,linkfun );