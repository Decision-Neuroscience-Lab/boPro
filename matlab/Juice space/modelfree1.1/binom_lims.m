function [ b, guessing, lapsing ] = binom_lims( r, m, x, gl, link, p, K, initval )
%
% Maximum likelihood estimates of the parameters of the psychometric
% function based on a binomial generalized linear model with automatically
% estimated guessing rate or lapsing rate or both. 
%
% INPUT
%
% r - number of successes at points x
% m - number of trials at points x 
% x - stimulus levels
%
% OPTIONAL INPUT
% 
% gl - indicator, calulate only guessing if 'guessing', only lapsing if
%       'lapsing' and both guessing and lapsing if 'both'; default is
%       'both'
% link - name of the link function; defaul is 'logit'
% p - degree of the polynomial; default is 1 
% K - power parameter for Weibull and reverse Weibull link; default is 2
% initval - initial value for guessing and lapsing; default is [.01 .01] if guessing and
%       lapsing rates are estimated, and .01 if only guessing or only lapsing
%       rate is estimated
%
% OUTPUT
% 
% b - estimated coefficients for the linear part
% guessing - estimated guessing rate
% lapsing - estimated lapsing rate
%
% Created by Ivan Marin-Franch, 20/11/2008

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%% PROGRAM

%%%% CHECK INPUT PARAMETERS

% First 3 paramaters are mandatory
if (nargin<3)
    error('Check input. First 3 arguments are mandatory');
end

%%%%
%%%% DEFAULTS
if ( nargin<4 )
    gl = 'both';
    disp('both guessing and lapsing rates are calculated');
end

if ~strcmp( gl, 'both' )  && ...
   ~strcmp( gl, 'guessing' ) && ...
   ~strcmp( gl, 'lapsing')
    error( 'Wrong value for guessing/lapsing indicator gl' );
end

if (nargin<5)
    link = 'logit';
    disp('default link function is ''logit''');
end

if (nargin<6)
    p = 1;
    disp('degree of the polynomial is 1');
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
    if strcmp( gl, 'both' )
        initval = [.01 .01];
        disp('default initial values for guessing and lapsing rates are 0.01 and 0.01');
    elseif strcmp( gl, 'guessing' )
        initval = .01;
        disp('default initial value for guessing rate is 0.01');
    else
        initval = .01;
        disp('default initial value for lapsing rate is 0.01');
    end
end


%%%% CHECK ROBUSTNESS OF INPUT PARAMETERS
clear data;
data(1).content = x;
data(2).content = r;
data(3).content = m;
checkinput( 'psychometricdata', data );
clear data;
checkinput( 'linkfunction', link );
pn = cell(1,2);
pn{1} = p;
pn{2} = x;
checkinput( 'degreepolynomial', pn );
if ( strcmp(link, 'weibull') || strcmp(link, 'revweibull'))
    checkinput( 'exponentk', K );
end

initval( initval == 0 ) = eps;

% Check initial values for guessing or guessing/lapsing and call internal
% functions binom_gl or binom_g depending on indicator gl
if strcmp( gl, 'both' )
    if ( length(initval) ~= 2), 
        error( 'initval must have two elements if both guessing and lapsing rates are being estimated' )
    end
    checkinput( 'guessingandlapsing', initval );
    [ b, guessing, lapsing ] = binom_gl( r, m, x, link, p, K, initval );

elseif strcmp( gl, 'guessing' )
% Check that initval is a positive scalar
    if length( initval ) > 1 || initval < 0 || initval >= 1
        error( 'Guessing rate must be a scalar between 0 and 1' );
    end
    [ b, guessing ] = binom_g( r, m, x, link, p, K, initval );
    lapsing = 0;

else
 % Check that initval is a positive scalar
    if length( initval ) > 1 || initval < 0 || initval >= 1
        error( 'Lapsing rate must be a scalar between 0 and 1' );
    end
    [ b, lapsing ] = binom_l( r, m, x, link, p, K, initval );
    guessing = 0;
end