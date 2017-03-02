function [pfit,etafit,warncount,H] = locglmfit_sparse_private(xfit,r,m,x,h,link,...
    guessing,lapsing,K,p,ker,maxiter,tol)
%
% THIS IS AN INTERNAL FUNCTION: USE LOCGLMFIT FOR BEST RESULTS
%
% Local polynomial estimator for the psychometric function and eta function
% (psychometric function transformed by link) for binomial data; also
% returns the hat matrix H. This function is used for large data sets, i.e.
% more than 15 observations.
%
% INPUT
%
% xfit - points at which to calculate the estimate pfit
% r - number of successes at points x
% m - number of trials at points x 
% x - stimulus levels
% h - bandwidth(s) 
% link - name of the link function
% guessing - guessing rate
% lapsing - lapsing rate
% K - power parameter for Weibull and reverse Weibull link
% p - degree of the polynomial 
% ker - kernel function for weights 
% maxiter - maximum number of iterations in Fisher scoring
% tol - tolerance level at which to stop Fisher scoring
%
% OUTPUT
%
% pfit - value of the local polynomial estimate at points x
% etafit - estimate of eta (link of pfit)
% H - hat matrix

%%%%
% KZ 11-Mar-12
% changed so that in every call to locglmfit the warnings about zero determinant and exceeded number of 
% iterations are displayed only once; that is:
% added a variable warncount which is [0 0] if there are no warnings, 
% first entry =1, if there was a warning about determinant being close to zero, too small bandwidth,
% second entry =1, if the number of iterations was exceeded; 
% NOTE that now warncount is the third argument returned by this function
%
% KZ 22-03-12
% included a try-catch statement to avoid problem cause by singularity; the
% function returns zeros and NA instead of crashing; this happens if the
% bandwidth used is too small for matlab to be able to handel the matrix
% inverse in a normal way
%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% PROGRAM

%%%% INITAILS VALUES

% link
if ( strcmp( link, 'weibull' ) || strcmp( link, 'revweibull' ) )
    
     LINK = feval( strcat( link, '_link_private' ), K, guessing, lapsing );

elseif ~strcmp( link, 'logit' )      && ...
   ~strcmp( link, 'probit' )     && ...
   ~strcmp( link, 'loglog' )     && ...
   ~strcmp( link, 'comploglog' ),
        
    LINK = feval(link,guessing,lapsing);
else
     LINK = feval( strcat( link, '_link_private' ), guessing, lapsing );
end
linkfun = LINK{1};
derinv  = LINK{2};
linkinv = LINK{3};

n = length(r);
nx = length(xfit);

% data into column vectors
tmp1(:,1) = r;
r = tmp1;

tmp1(:,1) = m;
m = tmp1;

tmp1(:,1) = x;
x = tmp1;

tmp2(1,:) = xfit;
xfit = tmp2;

%%%%  MATRICES FOR CALCULATION

% vector of differences xfit-x
diffx = reshape( repmat(xfit,n,1)-repmat(x,1,nx), n*nx,1);

% calculate weights given by the kernel ker and bandwidth h
kerx = zeros( nx * length( x ), 1 );

if length( h ) == 1
     kerx = feval(ker,diffx,0,h);
else
    h_mat = reshape( repmat(h',n,1), n*nx,1);
    kerx = feval(ker,diffx,0,h_mat);
end

% form a matrix of 1,x,x^2,...,x^p
tmpX0 = repmat(diffx,1,p+1).^repmat(0:p,n*nx,1);

% reshape to appropraite form for creating sparse X0
tmpX0 = reshape(tmpX0,n,(p+1)*nx);
for l = 1:(p+1),
    tmpX01(:,l:(p+1):(p+1)*nx) = tmpX0(:,(l-1)*nx+(1:nx));
end
tmpX01 = reshape(tmpX01,n*nx*(p+1),1);

% create sparse X0
ind_row = reshape(repmat(reshape(1:(n*nx),n,nx),p+1,1),n*nx*(p+1),1);
ind_col = reshape(repmat(1:(nx*(p+1)),n,1),n*nx*(p+1),1);
X0 = sparse(ind_row,ind_col,tmpX01);

% intial values for the algorithm
mu0 = (r + .5)./(m + 1);

eta0 = linkfun(mu0);
Z0 = repmat(eta0,nx,1);
eta_mu = feval(derinv,mu0);

% binomial weights for the algorithm
ind = 1:nx*n;

W = sparse(ind,ind,repmat(1 ./(eta_mu.*sqrt(mu0 .* (1 - mu0)./ m)),nx,1));

% kernel weights
KerX = sqrt(sparse(ind,ind,kerx(:,1)));

% combined binomial and kernel weights
WK = W .* KerX;

% raw means in a matrix form
KM = repmat( r./m , nx , 1 );

% linear estimator
X = WK * X0;
Y = WK * Z0; 

% check that bandwidth is not too small for the data  
DetXX = det( X'*X);

% 6-Jan-12
% Change 'error' to 'warning'.
% KZ 11-03-12
% add warning identifier
warncount = zeros(1,2);
if( abs(DetXX) < 1e-14),
    warncount(1) = 1; %warning('modelfree:DeterminantZero','Determinant close to 0: bandwidth is too small')
end

% KZ 22-03-12
% catch errors caused by singularity
Errcaught = 0;
try 
    beta = mldivide((X'*X),(X'*Y));
catch Err
    Errcaught = 1;
    beta = -50 * ones(nx*(p+1),1);
    if nargout == 4,
        H = matrix(NA,nx,nr);
    end
    
end
    
if ~Errcaught,
    
% inital values for stopping the loop
iternum = 0;
etadiff = tol+1;
etafit = (X0 * beta);
mu_raw = repmat(mu0,nx,1);
M = repmat(m,nx,1);
score = 1;

% offset value (ensure no limiting values appear in the algorithm)
epsilon = 1/(20*max(m));

%%%%%
%%%%% FISHER SCORING

while ((iternum<maxiter)&&(etadiff>tol)&&(score)),

    % obtain values from previous loop
    mu_old = mu_raw;
    eta_old = etafit;
    
    % new mean
    mu = linkinv(etafit);
    mu_raw = mu;
    
    % offset
    mu(mu>=1-lapsing-epsilon) = 1-lapsing-epsilon;
    mu(mu<=guessing+epsilon) = guessing+epsilon;
    
    % derivatived d eta / d mu
    eta_mu = derinv(mu);

    % z scores
    z = etafit + (KM - mu) .* eta_mu;
    
    % new weights
    WK = sparse(ind,ind,(1./(eta_mu.*sqrt(mu .* (1 - mu)./M)))) .* KerX;

    % linear estimator
    X = WK * X0;
    Y = WK * z;
    
    % new estimate of beta
    beta = (X'*X)\(X'*Y); %    beta = inv(X'*X)*(X'*Y);
    
    % beta0 (i.e. value of eta function)
    eta1 = beta(1:(p+1):end);

    % new estiate of eta and its derivatives
    etafit = (X0 * beta);
    
    % increase iteration count and adjust stopping values
    iternum = iternum + 1;
    mudiff = max(max(abs(mu_old-mu_raw)));
    etadiff = max(max(abs(eta_old-etafit)));
    score = ~((mudiff<tol)&(max(abs(eta1))>50));
end

% KZ 11-03-12
% add warning identifier
% warning about exceeding iteration max
if (maxiter==iternum),
    warncount(2) = 1; %warning('modelfree:IterationsExceeded','iteration limit reached')
end


% Hat matrix
if nargout == 4,
    tmpH = (X'* X)\(X' * WK);
    tmpH = tmpH(1:(p+1):end,:);
    H = zeros(nx,n);
    for i = 1:nx,
        H(i,:) = tmpH(i,(1:n)+(i-1)*n);
    end
end

end % if ~Err.caught

% retrive beta0 and remove v. large and v. small values
etafit = beta(1:(p+1):end);

% find estimate of PF
pfit = feval(linkinv,etafit);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% KERNELS

function y = epanechnikov(x,m,s)
X = x/s;
X(abs(X)>1) = 1;
y = 0.75 * (1 - X.^2)/s;

function y = triangular(x,m,s)
X = x/s;
X(abs(X)>1) = 1;
y = (1 - abs(X))/s;

function y = tricube(x,m,s)

X = x/s;
X(abs(X)>1) = 1;
y = ((1 - abs(X).^3).^3)/s;

function y = bisquare(x,m,s)

X = x/s;
X(abs(X)>1) = 1;
y = ((1 - abs(X).^2).^2)/s;

% uniform
function y = uniform(x,m,s)
X = x/s;
y = (abs(X)<=1)/2;