function h = bandwidth_cross_validation(r,m,x,H,link,guessing,lapsing,...
                            K,p,ker,maxiter,tol,method)
%
% Cross-validation estimate of the optimal bandwidth for a local polynomial
% estimate of the psychometric function with specified guessing and lapsing
% rates.

%
% INPUT
% 
% r - number of successes at points x
% m - number of trials at points x 
% x - stimulus levels 
% H - search interval
%
% OPTIONAL INPUT
%
% link - name of the link function; default is 'logit'
% guessing - guessing rate; default is 0
% lapsing - lapsing rate; default is 0
% K - power parameter for Weibull and reverse Weibull link; default is 2
% p - degree of the polynomial; default is 1
% ker - kernel function for weights; default is 'normpdf'
% maxiter - maximum number of iterations in Fisher scoring; default is 50
% tol - tolerance level at which to stop Fisher scoring; default is 1e-6
% method - loss function to be used in cross-validation: choose from:
% 'ISEeta', 'ISE', 'deviance'; by default all possible values are
% calculated
%
% OUTPUT
% 
% h - cross-validation bandwidth for the chosen "method"; if no method is
%   specified, then it is three-row vector with entries corresponding to the
%   estimated bandwidths on a p-scale, on an eta-scale and for deviance 

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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%% PROGRAM

%%%% CHECK INPUT PARAMETERS

% First 4 arguments are mandatory
if (nargin<4)
    error('Check input. First 4 arguments are mandatory');
end

%%%%
%%%% DEFAULTS
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

if (nargin<9)
    p = 1;
    disp('degree of the polynomial is 1');
end

if (nargin<10)
    ker = 'normpdf';
    disp('default kernel is ''normpdf''');
end

if (nargin<11)
    maxiter=50;
    disp('default maximum number of iterations is 50');
end

if (nargin<12)
    tol = 1e-6;
    disp('default tolerance is 1e-6');
end

if (nargin<13)
    disp('cross validation bandwidth calculated for the 3 methods');
    method = 'all';
end

%%%% CHECK ROBUSTNESS OF INPUT PARAMETERS
clear data;
data(1).content = x;
data(2).content = r;
data(3).content = m;
checkinput( 'psychometricdata', data );
clear data
checkinput( 'minmaxbandwidth', H );
checkinput( 'linkfunction', link );
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
pn = cell(1,2);
pn{1} = p;
pn{2} = x;
checkinput( 'degreepolynomial', pn );
checkinput( 'kernel', ker );
checkinput( 'maxiter', maxiter );
checkinput( 'tolerance', tol );
checkinput( 'method', method );

% data in column vectors
tmp1(:,1) = r;
r = tmp1;

tmp1(:,1) = m;
m = tmp1;

tmp1(:,1) = x;
x = tmp1;



% initial values for the loops
LH = length(H);
Lx = length(x);

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


%%%% INITIAL VALUES FOR OPTIMISATION
options = optimset('MaxIter', 50); 

%%%%% CROSS-VALIDATION
%%%%% BANDIWDTH

% KZ 22-01-2012 control for Matlab wanrings and repeated warnings
% KZ 28-03-2012 included clean up routine so that the warning settings are
% restored when the function terminates even if by Ctrl+C
s_msg_id = warning('query','all');
cleanUpvar = onCleanup(@()warning(s_msg_id));

warning('off','MATLAB:singularMatrix');
warning('off','modelfree:DeterminantZero');
warning('off','modelfree:IterationsExceeded');
warning('off','MATLAB:nearlySingularMatrix');


if strcmp(method,'ISE'),
    %%% p-scale
    h = fminbnd(@get_ise_p,H(1),H(end),options);
    
elseif strcmp(method,'ISEeta'),
    %%%%% eta scale
    h = fminbnd(@get_ise,H(1),H(end),options);
    
elseif strcmp(method,'deviance'),
    %%%%% DEVINACE
    h = fminbnd(@get_dev,H(1),H(end),options);
    
else
    %%% p-scale
    h(1,:) = fminbnd(@get_ise_p,H(1),H(end),options);
    %%%%% eta scale
    h(2,:) = fminbnd(@get_ise,H(1),H(end),options);
    %%%%% DEVINACE
    h(3,:) = fminbnd(@get_dev,H(1),H(end),options);    
end

% -------------------------------------------------------------------------
	function ise = get_ise_p(h)
		% get ise for this value of h
		% this is a nested function, so it shares variables!
		for i = 1:Lx,
			fest(i,:) = locglmfit(x(i),r([1:(i-1),(i+1):Lx]),...
                m([1:(i-1),(i+1):Lx]),x([1:(i-1),(i+1):Lx]),...
                h,link,guessing,lapsing,K,p,ker,maxiter,tol);
        end
		ise = ISE(r./m, fest); % return MISE for this h
    end
% -------------------------------------------------------------------------
	function ise = get_ise(h)
		% get ise on eta scale on for this value of h
		% this is a nested function, so it shares variables!
		for i = 1:Lx,
			[ftmp,etaest(i,:)] = locglmfit(x(i),r([1:(i-1),(i+1):Lx]),...
                m([1:(i-1),(i+1):Lx]),x([1:(i-1),(i+1):Lx]),...
                h,link,guessing,lapsing,K,p,ker,maxiter,tol);
        end
        fit = (r + .5)./(m + 1);
        fit_eta = linkfun( fit ); 
		
        ise = ISE(fit_eta, etaest); % return MISE for this h

    end
% -------------------------------------------------------------------------
	function D = get_dev(h)
		% get devinace for this value of h
		% this is a nested function, so it shares variables!
		for i = 1:Lx,
			ftmp(i,:) = locglmfit(x(i),r([1:(i-1),(i+1):Lx]),...
                m([1:(i-1),(i+1):Lx]),x([1:(i-1),(i+1):Lx]),...
                h,link,guessing,lapsing,K,p,ker,maxiter,tol);
        end
        D = deviance(r, m, ftmp); % return MISE for this h
	end
% -------------------------------------------------------------------------

end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%% INTERNAL FUNCTIONS %%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%% LOSS FUNCTION

function y = ISE(f1,f2)

y = sum((f1 - f2).^2);
end
