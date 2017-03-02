function link = logit_link( guessing, lapsing )
%
% Logit link in cell form for use with GLMFIT, GLMVAL and other Matlab GLM
% functions. The guessing rate and lapsing rate are fixed; hence link is a
% function of only one variable.
%
% OPTIONAL INPUT
%
% guessing - guessing rate; default is 0
% lapsing - lapsing rate; default is 0
%
% OUTPUT
%
% link - logit link for use in all GLM functions; cell with 3 entries:  
%   	logitFL - link function
%       logitFD - derivative   
%   	logitFI - inverse link
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
link{1} = @(x) logitFL( x, guessing, 1-lapsing );
link{2} = @(x) logitFD( x, guessing, 1-lapsing );
link{3} = @(x) logitFI( x, guessing, 1-lapsing );

% % % % % % % % % % % % % % % % % % 
% % % INTERNAL FUNCTIONS % % % % % 
% % % % % % % % % % % % % % % % % % 
%%%%%%%%%%%
% LOGIT WITH LIMITS

% link
function eta = logitFL(mu,g,l)

mu = max(min(l-eps,mu),g+eps);
eta = log((mu-g)./(l-mu));

% derivative
function eta = logitFD(mu,g,l)

mu = max(min(l-eps,mu),g+eps);
eta = (l-g)./((mu-g).*(l-mu));

% inverse link
function mu = logitFI(eta,g,l)

eta = max(log(eps./(l-g)),eta);
eta = min(log((l-g)./eps),eta);
mu = g + (l-g)./(1+exp(-eta));