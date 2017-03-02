function link = comploglog_link( guessing, lapsing )
%
% Complementary log-log link in cell form for use with GLMFIT, GLMVAL and
% other Matlab GLM functions. The guessing rate and lapsing rate are fixed;
% hence link is a function of only one variable.
%
% OPTIONAL INPUT
%
% guessing - guessing rate; default is 0
% lapsing - lapsing rate; default is 0
%
% OUTPUT
%
% link - complementary log-log link for use in all GLM functions; cell with 3 entries:  
%   	comploglogFL - link function
%       comploglogFD - derivative   
%   	comploglogFI - inverse link
%
% Created by Ivan Marin-Franch, 20/03/2009

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% PROGRAM
if ( nargin < 1 ), 
    guessing = 0; 
end

if ( nargin < 2 ),
    lapsing = 0;
end

checkinput( 'guessingandlapsing', [ guessing, lapsing ] );

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% SET LINK
link = cell(3,1);
link{1} = @(x) comploglogFL( x, guessing, 1-lapsing );
link{2} = @(x) comploglogFD( x, guessing, 1-lapsing );
link{3} = @(x) comploglogFI( x, guessing, 1-lapsing );

% % % % % % % % % % % % % % % % % % 
% % % INTERNAL FUNCTIONS % % % % % 
% % % % % % % % % % % % % % % % % % 
%%%%%%%%%%%%%%%%%%%%%%%%%%%
% COMPLEMENTARY LOGLOG WITH LIMITS
% link
function eta = comploglogFL(mu,g,l)

mu = max(min(l-eps,mu),g+eps);
eta = log(-log((l-mu)./(l-g)));

% derivative
function eta = comploglogFD(mu,g,l)

mu = max(min(l-eps,mu),g+eps);
eta = -1./((l-mu).*log((l-mu)./(l-g)));

% inverse link
function mu = comploglogFI(eta,g,l)

eta = max(log(-log(1-eps./(l-g))),eta);
eta = min(log(-log(eps./(l-g))),eta);
mu = g + (l-g) * (- expm1(-exp(eta)));