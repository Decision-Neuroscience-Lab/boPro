function [pfit,etafit,H] = locglmfit(xfit,r,m,x,h,link,guessing,lapsing,...
    K,p,ker,maxiter,tol)
%
% Local polynomial estimator for the psychometric function and eta function
% (psychometric function transformed by link) for binomial data; also
% returns the hat matrix H. Actual calculations are done in
% locglmfit_private or locglmfit_sparse_private depending on the size of
% the data set. Here, the data are split into several parts to speed up the
% calculations.
%
%INPUT
%
% xfit - points at which to calculate the estimate pfit
% r - number of successes at points x
% m - number of trials at points x 
% x - stimulus levels 
% h - bandwidth(s)
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
%
% OUTPUT
%
% pfit - value of the local polynomial estimate at points xfit
% etafit - estimate of eta (link of pfit)
% H - hat matrix

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%% PROGRAM

%%%%
% KZ 11-Mar-12
% changed so that in every call to locglmfit the warnings about zero determinant and exceeded number of 
% iterations are displayed only once; that is:
% added a variable Warn which is [0 0] is there are no warnings from private functions, 
% if the first entry is positive, then a warning about too small bandwidth is displayed,
% if the second entry is positive, then a warning about exceeded number of iterations is displayed; 
% changed the private functions acordingly, so that they return the required
% information
%%%%%

%%%%%
% KZ 28-Mar-12
% included a clean up function which restores warning settings to their
% original state
%%%%%


%%%% CHECK INPUT PARAMETERS
% First 5 arguments are mandatory
if (nargin<5)
    error('Check input. First 5 arguments are mandatory');
end

%%%%
%%%% DEFAULTS
if (nargin<6)
    link = 'logit';
    disp('default link function is ''logit''');
end

if (nargin<7)
    guessing = 0;
    disp('default guessing rate is zero');
end

if (nargin<8)
    lapsing = 0;
    disp('default lapsing rate is zero');
end

if (nargin<9)
    K = 2;
    if strcmp(link, 'weibull')
        disp('default exponent for Weibull link function is 2');
    elseif strcmp(link, 'revweibull')
        disp('default exponent for reverse Weibull link function is 2');
    end
end

if (nargin<10)
    p = 1;
    disp('degree of the polynomial is 1');
end

if (nargin<11)
    ker = 'normpdf';
    disp('default kernel is ''normpdf''');
end

if (nargin<12)
    maxiter = 500;
    disp('default maximum number of iterations is 50');
end

if (nargin<13)
    tol = 1e-6;
    disp('default tolerance is 1e-6');
end

%%%% CHECK ROBUSTNESS OF INPUT PARAMETERS
[ rxfit, cxfit ] = size( xfit );
if cxfit ~= 1
    error('Vector xfit should be a column vector');
end
clear data;
data(1).content = x;
data(2).content = r;
data(3).content = m;
checkinput( 'psychometricdata', data );
clear data
[ rh, ch ] = size( h );
if ch ~= 1
    error('Vector of bandwidths should be column vector');
end
if ~( length( h ) == 1 || rh == rxfit )
    error( 'Bandwidth h must be either a scalar or a vector with the same number of elements as xfit' );
end
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

%%%%%
%%%%% INITIAL VALUES

% KZ 28-03-2012 included clean up routine so that the warning settings are
% restored when the function terminates even if by Ctrl+C
s_msg_id = warning('query','all');
cleanUpvar = onCleanup(@()warning(s_msg_id));

warning('off','MATLAB:singularMatrix');
warning('off','MATLAB:nearlySingularMatrix');


Warn1 = 0;

split = 20;

Lxfit = length(xfit);
Lx = length(x);

if (Lx > 15),
    % big data
    fun_estim = 'locglmfit_sparse_private';
else
    % small data
    fun_estim = 'locglmfit_private';
end

%%%% SPLIT AND EVALUATION
if length( h ) == 1
    % with Hat matrix
    if nargout == 3,

        if (Lxfit<=split),

            % small x
            [pfit,etafit,Warn,H] = feval(fun_estim,xfit,r,m,x,h,link,guessing,lapsing,...
                K,p,ker,maxiter,tol);
            Warn1 = Warn1 + Warn;
        else
            % large x
            % number of parts into which the fitting is divided
            fLx = floor(Lxfit/split);

            % initialise output
            pfit = [];
            etafit = [];
            H = [];   

                for i = 0:(fLx-1),
                    
                    % part of the fit
                    [pfit1,etafit1,Warn,H1] = feval(fun_estim,xfit(i*split + (1:split)),r,m,...
                        x,h,link,guessing,lapsing,K,p,ker,maxiter,tol);
                    Warn1 = Warn1 + Warn;
                    % put the fits together
                    pfit = [pfit;pfit1];
                    etafit = [etafit;etafit1];
                    H = [H;H1];   
                end
                %final part of the fit
                if ((split*fLx)<Lxfit),
                   
                    [pfit1,etafit1,Warn,H1] = feval(fun_estim,xfit((1+split*fLx):Lxfit),r,m,...
                        x,h,link,guessing,lapsing,K,p,ker,maxiter,tol);
                    Warn1 = Warn1 + Warn;
                    % put the fits together
                    pfit = [pfit;pfit1];
                    etafit = [etafit;etafit1];
                    H = [H;H1];   
                end
                
        end

    else % no Hat matrix

        if (Lxfit<=split),

            % small x
            [pfit,etafit,Warn] = feval(fun_estim,xfit,r,m,x,h,link,guessing,lapsing,...
                K,p,ker,maxiter,tol);
            Warn1 = Warn1 + Warn;
        else
            % large x
            % number of parts into which the fitting is divided
            fLx = floor(Lxfit/split);

            % initialise output
            pfit = [];
            etafit = [];

            for i = 0:(fLx-1),
                % part of the fit
                [pfit1,etafit1,Warn] = feval(fun_estim,xfit(i*split + (1:split)),r,m,x,h,...
                    link,guessing,lapsing,K,p,ker,maxiter,tol);
                Warn1 = Warn1 + Warn;
                % put the fits together
                pfit = [pfit;pfit1];
                etafit = [etafit;etafit1];
            end
            %final part of the fit
            if ((split*fLx)<Lxfit),
                [pfit1,etafit1,Warn] = feval(fun_estim,xfit((1+split*fLx):Lxfit),r,m,x,h,...
                    link,guessing,lapsing,K,p,ker,maxiter,tol);
                Warn1 = Warn1 + Warn;
                % put the fits together
                pfit = [pfit;pfit1];
                etafit = [etafit;etafit1];
            end

        end
    
    end % if nargout == 3
else % if length( h ) == 1
    % with Hat matrix
    if nargout == 3,

        if (Lxfit<=split),

            % small x
            [pfit,etafit,Warn,H] = feval(fun_estim,xfit,r,m,x,h,link,guessing,lapsing,...
                K,p,ker,maxiter,tol);
            Warn1 = Warn1 + Warn;
        else
            % large x
            % number of parts into which the fitting is divided
            fLx = floor(Lxfit/split);

            % initialise output
            pfit = [];
            etafit = [];
            H = [];   

                for i = 0:(fLx-1),
                 % part of the fit
                    [pfit1,etafit1,Warn,H1] = feval(fun_estim,xfit(i*split + (1:split)),r,m,x,...
                         h(i*split + (1:split)),link,guessing,lapsing,K,p,ker,maxiter,tol);
                    Warn1 = Warn1 + Warn;
                     % put the fits together
                    pfit = [pfit;pfit1];
                    etafit = [etafit;etafit1];
                    H = [H;H1];   
                end
                %final part of the fit
                if ((split*fLx)<Lxfit),
                    [pfit1,etafit1,Warn,H1] = feval(fun_estim,xfit((1+split*fLx):Lxfit),r,m,x,...
                        h((1+split*fLx):Lxfit),link,guessing,lapsing,K,p,ker,maxiter,tol);
                    Warn1 = Warn1 + Warn;
                    % put the fits together
                    pfit = [pfit;pfit1];
                    etafit = [etafit;etafit1];
                    H = [H;H1];   
                end
        end
    else % no Hat matrix
        if (Lxfit<=split),

            % small x
            [pfit,etafit,Warn] = feval(fun_estim,xfit,r,m,x,h,link,guessing,lapsing,...
                K,p,ker,maxiter,tol);
            Warn1 = Warn1 + Warn;
        else
            % large x

            % number of parts into which the fitting is divided
            fLx = floor(Lxfit/split);

            % initialise output
            pfit = [];
            etafit = [];

            for i = 0:(fLx-1),
                % part of the fit
                [pfit1,etafit1,Warn] = feval(fun_estim,xfit(i*split + (1:split)),r,m,x,h(i*split + (1:split)),...
                    link,guessing,lapsing,K,p,ker,maxiter,tol);
                Warn1 = Warn1 + Warn;
                % put the fits together
                pfit = [pfit;pfit1];
                etafit = [etafit;etafit1];
            end
            %final part of the fit
            if ((split*fLx)<Lxfit),
                [pfit1,etafit1,Warn] = feval(fun_estim,xfit((1+split*fLx):Lxfit),r,m,x,h((1+split*fLx):Lxfit),...
                    link,guessing,lapsing,K,p,ker,maxiter,tol);
                Warn1 = Warn1 + Warn;    
                % put the fits together
                pfit = [pfit;pfit1];
                etafit = [etafit;etafit1];
            end

        end
    
    end % if nargout == 3
end % if length( h ) == 1

% KZ 11-03-12
% warn user once if there were any warnings generated in the private
% functions
               if (Warn1(1) > 0),
                    warning('modelfree:DeterminantZero','Determinant close to 0: bandwidth is too small')
                end
                if (Warn1(2) > 0),
                    warning('modelfree:IterationsExceeded','iteration limit reached')
                end