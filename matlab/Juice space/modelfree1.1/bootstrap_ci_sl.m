function [ci,sl0] = bootstrap_ci_sl(TH,r,m,x,N,h0,alpha,X,link,guessing,lapsing,...
                        K,p,ker,maxiter,tol)
%
% Bootstrap estimate of a confidence interval at a significance level alpha
% for the estimated slope for the local polynomial estimate of the
% psychometric function with given guessing and lapsing rates. The
% confidence interval is based on bootstrap percentiles.
%
% See Efron & Tibshirani's "An introduction to the bootstrap", 1993
%
% INPUT
%
% TH - required threshold level
% r - number of successes at points x
% m - number of trials at points x 
% x - stimulus levels 
% N - number of bootstrap replications; N should be at least 1000 for 
%   reliable results  
% h0 - bandwidth
%
% OPTIONAL INPUT
%
% alpha - significance level of the confidence interval; default is 0.05
% X - set of values at which estimates of the psychometric function for the
%       slope estimation are to be obtained; if not given, 1000 equally spaced 
%       points from mininmum to maximum of 'x' are used 
% link - name of the link function; default is 'logit'
% guessing - guessing rate; default is 0
% lapsing - lapsing rate; default is 0
% K - power parameter for Weibull and reverse Weibull link; default is 2
% p - degree of the polynomial; default is 1
% ker - kernel function for weights; default is 'normpdf'
% maxiter - maximum number of iterations in Fisher scoring; default is 50
% tol - tolerance level at which to stop Fisher scoring; default is 1e-6
%
% OUTPUT
% 
% ci - confidence interval based on bootstrap percentiles
% sl0 - slope estimate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%
% KZ 22-Jan-12
% included warning control so that warnings about small bandwidth, exceeded 
% number of iterations and singularity problems are not printed while this
% function is running
%
% KZ 28-Mar-12
% included a clean up function which restores warning settings to their
% original state
%%%%%

%%%%% PROGRAM
% First 6 arguments are mandatory
if (nargin<6)
    error('Check input. First 6 arguments are mandatory');
end

%%%%
%%%% DEFAULTS
if (nargin<7)
    alpha = 0.05;
    disp('default signigicant level is 0.05');
end

if (nargin<8)
    X = linspace(min(x),max(x),1000)';
elseif (isempty(X)),
    X = linspace(min(x),max(x),1000)';
end

if (nargin<9)
    link = 'logit';
    disp('default link function is ''logit''');
end

if (nargin<10)
    guessing = 0;
    disp('default guessing rate is zero');
end

if (nargin<11)
    lapsing = 0;
    disp('default lapsing rate is zero');
end

if (nargin<12)
    K = 2;
    if strcmp(link, 'weibull')
        disp('default exponent for Weibull link function is 2');
    elseif strcmp(link, 'revweibull')
        disp('default exponent for reverse Weibull link function is 2');
    end
end

if (nargin<13)
    p = 1;
    disp('degree of the polynomial to be fitted on the linear scale is 1');
end

if (nargin<14)
    ker = 'normpdf';
    disp('default kernel is ''normpdf''');
end

if (nargin<15)
    maxiter=50;
    disp('default maximum number of iterations is 50');
end

if (nargin<16)
    tol = 1e-6;
    disp('default tolerance is 1e-6');
end

%%%% CHECK ROBUSTNESS OF INPUT PARAMETERS
if ~( strcmp( class(TH), 'double' ) )
    error( 'Threshold level should be a scalar' );
end
clear data;
data(1).content = x;
data(2).content = r;
data(3).content = m;
checkinput( 'psychometricdata', data );
clear data;
checkinput('bootstrapreplications',N);

[rX, cX] = size( X );
if cX > 1
    error('X (values where to estimate the PF) has to be column vector');
end
if rX < 2
    error('At least 2 values needed for vector X');
end

if ( (min( x) > min(X)) || (max(x) < max(X))  ) ,
        error('Supplied values of X are outside the range of stimulus levels x');
end

checkinput( 'bandwidth', h0 );
if length(alpha)>1,
    error('Significance level must be scalar')
elseif alpha <= 0 || alpha > 0.5
    error('Significance level must be between 0 and 0.5');
end
checkinput( 'linkfunction', link );
if length( guessing ) > 1
    error( 'Guessing rate must be scalar' );
end
if length( lapsing ) > 1
    error( 'Lapsing rate must be scalar' );
end
checkinput( 'guessingandlapsing', [ guessing lapsing ] );

if TH <= guessing 
    error( 'Threshold level should be greater than guessing rate');
elseif TH >= 1-lapsing
    error( 'Threshold level should be smaller than 1- lapsing rate');
end

pn = cell(1,2);
pn{1} = p;
pn{2} = x;
checkinput( 'degreepolynomial', pn );
if ( strcmp(link, 'weibull') || strcmp(link, 'revweibull'))
    checkinput( 'exponentk', K );
end
checkinput( 'kernel', ker );
checkinput( 'maxiter', maxiter );
checkinput( 'tolerance', tol );

if N < 1000,
    warning('modelfree:smallN', 'number of bootstrap samples should be greater than 1000 \n otherwise the results might be unreliable' );
end

%%%%% INITIAL VALUES
% data in column vectors
tmp1(:,1) = r;
r = tmp1;

tmp1(:,1) = m;
m = tmp1;

tmp1(:,1) = x;
x = tmp1;

% KZ 22-01-2012 control for Matlab wanrings and repeated warnings
% KZ 28-03-2012 included clean up routine so that the warning settings are
% restored when the function terminates even if by Ctrl+C
s_msg_id = warning('query','all');
cleanUpvar = onCleanup(@()warning(s_msg_id));

warning('off','MATLAB:singularMatrix');
warning('off','modelfree:DeterminantZero');
warning('off','modelfree:IterationsExceeded');
warning('off','MATLAB:nearlySingularMatrix');


%%%% INITIAL ESTIMATE
% initial estimates with bandiwdth h0
f = locglmfit(x,r,m,x,h0,link,guessing,lapsing,K,p,ker,...
    maxiter,tol);

% dense version for estimation of the threshold
F = locglmfit(X,r,m,x,h0,link,guessing,lapsing,K,p,ker,maxiter,tol);

%%%%%%%%%
%%%% THERESHOLD ESTIMATE
[th0,sl0] = threshold_slope(F,X,TH);

%%%%%%%%%
%%%% BOOTSTRAP SAMPLING
% re-sampling
M = repmat(m,1,N);
samp = binornd(M,repmat(f,1,N));

% exclude "degenerate samples" if min(M)>1
if (min(M)>1),
    for i = 1:N,
        ok(i) = (length(unique(samp(:,i)))>3);
    end

    while (min(ok)==0),
        Lok = sum(ok==0);
        samp(:,ok==0) = binornd(repmat(m,1,Lok),repmat(f,1,Lok));
        findok = find(ok==0);
        for i = findok,
            ok(i) = (length(unique(samp(:,i)))>3);
        end
    end
end

%%% INITIATE VARABLE IN WHICH DATA ARE STORED
th_boot = zeros(1,N);
sl_boot = zeros(1,N);

%%%%%%%%%%%%%%%%%%%%%
%%%%%%% BOOTSTRAP ESTIMATES OF THE THRESHOLD
for i = 1:N,

    ftmp = locglmfit(X,samp(:,i),m,x,h0,link,guessing,lapsing,...
                K,p,ker,maxiter,tol);

    [th_boot(i),sl_boot(i)] = threshold_slope(ftmp,X,TH);
    
end

ci(1) = prctile( sl_boot, 100 * ( alpha / 2 ) );
ci(2) = prctile( sl_boot, 100 * ( 1 - alpha / 2 ) );

end