function h = bandwidth_plugin( r, m, x, link, guessing, lapsing, K, p, ker )
%
% Plug-in estimate of the AMISE optimal bandwidth for a local polynomial
% estimate of the psychometric function.
%
% INPUT
% 
% r - number of successes at points x
% m - number of trials at points x 
% x - stimulus levels 
%
% OPTIONAL INPUT
% 
% link - name of the link function; default is 'logit'
% guessing - guessing rate; default is 0
% lapsing - lapsing rate; default is 0
% K - power parameter for Weibull and reverse Weibull link; default is 2
% p - degree of the polynomial; default is 1
% ker - kernel function for weights; default is 'normpdf'
%
% OUTPUT
% 
% h - plug-in bandwidth (ISE optimal on eta-scale)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%% PROGRAM
%%%% CHECK INPUT PARAMETERS

% First 3 arguments are mandatory
if (nargin<3)
    error('Check input. First 3 arguments are mandatory');
end

%%%%
%%%% DEFAULTS
if (nargin<4)
    link = 'logit';
    disp('default link function is ''logit''');
end

if (nargin<5)
    guessing = 0;
    disp('default guessing rate is zero');
end

if (nargin<6)
    lapsing = 0;
    disp('default lapsing rate is zero');
end

if (nargin<7)
    K = 2;
    if strcmp(link, 'weibull')
        disp('default exponent for Weibull link function is 2');
    elseif strcmp(link, 'revweibull')
        disp('default exponent for reverse Weibull link function is 2');
    end
end

if (nargin<8)
    p = 1;
    disp('degree of the polynomial is 1');
end

if (nargin<9)
    ker = 'normpdf';
    disp('default kernel is ''normpdf''');
end

% Display information only if either Weibull or reverse Weibull link is
% used

%%%% CHECK ROBUSTNESS OF INPUT PARAMETERS
clear data;
data(1).content = x;
data(2).content = r;
data(3).content = m;
checkinput( 'psychometricdata', data );
clear data
pn = cell(1,2);
pn{1} = p;
pn{2} = x;
if length( guessing ) > 1
    error( 'Guessing rate must be a scalar' );
end
if length( lapsing ) > 1
    error( 'Lapsing rate must be a scalar' );
end
checkinput( 'guessingandlapsing', [ guessing lapsing ] );
if ( strcmp(link, 'weibull') || strcmp(link, 'revweibull'))
    checkinput( 'exponentk', K );
end
checkinput( 'degreepolynomial', pn );
if ischar( ker )
    ker = str2func( ker );
end
checkinput( 'kernel', ker );
checkinput( 'linkfunction', link );

%%%% INITIAL VALUES

% data in column vectors
tmp1(:,1) = r;
r = tmp1;

tmp1(:,1) = m;
m = tmp1;

tmp1(:,1) = x;
x = tmp1;

n = length(r);

% p+Dp - degree of polynomial used for parametric fit
if ((n-p)>5), 
    Dp=3; 
elseif ((n-p)==5),
    Dp = 2;
elseif ((n-p)>2),
    Dp=1; 
else
    error(['Not enough data to fit polynomial of degree ',num2str(p)])
end


% support for the kernel
if ( strcmp(func2str(ker),'normpdf')),
    supp = [ -10, 10 ];
else
    supp = [-1, 1 ];
end

%%%%
%%%% PARAMETRIC ESTIMATOR
% parametric estimator of order p + Dp


%%%%
%%% INITIAL
p1 = p + Dp;
lx = length(x);

%%%%
%%%% GLOBAL FIT
X = repmat(x,1,(p1)).^repmat(1:(p1),lx,1);

s_msg_id = warning('query','all');
warning('off','stats:glmfit:IterationLimit');
warning('off','stats:glmfit:BadScaling');
 
if strcmp( link, 'weibull' )
    linkfun = weibull_link_private( K, guessing, lapsing );
    b_lin = glmfit(X, [r m], 'binomial', 'link', linkfun);
elseif strcmp( link, 'revweibull' )
    linkfun = revweibull_link_private( K, guessing, lapsing );
    b_lin = glmfit(X, [r m], 'binomial', 'link', linkfun);
elseif ~strcmp( link, 'logit' )      && ...
   ~strcmp( link, 'probit' )     && ...
   ~strcmp( link, 'loglog' )     && ...
   ~strcmp( link, 'comploglog' ),  

        linkfun = feval(link, guessing, lapsing);
        b_lin = glmfit(X, [r m], 'binomial', 'link', linkfun);
else
    linkfun = feval(strcat( link, '_link_private' ), guessing, lapsing);
    b_lin = glmfit(X, [r m], 'binomial', 'link', linkfun);
end

warning(s_msg_id)

tmp_b_p1 = fliplr(b_lin');

% adjust degenrated values to aviod degenerate results
epsilon = .001;
ind = (r./m>=epsilon) .* (r./m<=1-epsilon);

% coefficients for (p+1)th derivative of parametric estimator
for l=1:p+1,
    tmp_b_p1 = polyder(tmp_b_p1);
end

% calculate the (p+1)th derivative of eta
tmp_eta_p1 = polyval(tmp_b_p1,x) .*ind;

% approximate int(eta^(p+1))^2
int_eta = sum( tmp_eta_p1.^2) * m(1);

%%%% EQUIVALENT KERNEL
tmp = moments(ker,(0:2*p),supp);

% create S matrix (all moments)
S = zeros(p+1,p+1);
for pp = 1:(p+1),
    S(pp,:) = tmp(pp+(0:p));
end

% indicator vector
e_0 = eye(1,p+1);

% vector of powers
ker_eqv = @(x) (e_0/S * repmat(x,p+1,1).^repmat((0:p)',1,length(x)) ) .* ker(x);

%%%% FUNCTIONS OF THE EQUIVALENT KERNEL

% integral of squared equivalent kernel    
k2 = intK2(ker_eqv);

% (p+1)th moment of equivalent kernel 
muK_2 = moments(ker_eqv,p+1,supp)^2;

if (muK_2 < eps),
    muK_2 = eps;
    warning('The estimated value was 0; sample is probably degenerate')
end

%%%%% INTEGRAL OF VARIANCE FUCNTION
if strcmp( link, 'weibull' ) || strcmp( link, 'revweibull' )
    int_sg = quad(@(x) varfun(x,b_lin,linkfun), min(x) - 1, max(x) + 1);
else
    int_sg = quad(@(x) varfun(x,b_lin,linkfun), min(x) - 1, max(x) + 1);
end

% ensure the above integral is positive which might not be the case for
% near degenerate samples; issue warning 
if (int_sg == 0),
    int_sg = eps;
    warning('The estimated value was 0; sample is probably degenerate')
end

%%%%%
%%%%% KERNEL DEPENDANT CONSTANT
C = ( (factorial(p+1).^2 * k2)/(2*(p+1) * muK_2) ).^(1/(2*p+3));

%%%%%
%%%%% BANDWIDTH
h = C * ( int_sg./int_eta ).^(1/(2*p+3));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%% INTERNAL FUNCTIONS %%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%% INTEGARL OF KERNEL SQUARED

function m = intK2(K)

% find approximation of the intergral depending on the type of support
m = quad(@(x) funcK2(x,K),-10,10);


%%%%% KERNEL SQUARED

function y = funcK2(x,K)

y = (feval(K,x)).^2;


%%%%%% MOMENTS OF KERNEL

function m = moments(K,l,supp)

Ll = length(l);
m = zeros(1,Ll);

for s=1:Ll,
    m(s) = quad(@(x) (x.^l(s)) .* K(x),min(supp),max(supp));
end

%%%%%% VARIANCE FUNCTION FOR BINOMAIL DISTRIBUTION

function y = varfun(x,b,link)

% initaila values
p = length(b)-1;
lx= length(x);

% powers of x up to p
X = repmat(x',1,p).^repmat(1:p,lx,1);

% estimated mean
mu = glmval(b, X, link);

% offset
epsilon = .001;
ind = (mu>=epsilon).*(mu<=1-epsilon);

% variance
y = ind./(mu .* (1-mu));


%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% KERNELS

% Epanechnikov
function y = epanechnikov(x)
X = x;
X(abs(X)>1) = 1;
y = 0.75 * (1 - X.^2);

% triangular
function y = triangular(x)
X = x;
X(abs(X)>1) = 1;
y = (1 - abs(X));

% tri-cube
function y = tricube(x)
X = x;
X(abs(X)>1) = 1;
y = ((1 - abs(X).^3).^3);

% bi-square
function y = bisquare(x)
X = x;
X(abs(X)>1) = 1;
y = ((1 - abs(X).^2).^2); 

% uniform
function y = uniform(x)
X = x;
y = (abs(X)<=1)/2;
