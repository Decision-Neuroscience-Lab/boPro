function checkinput(type, data)
%
% THIS IS AN INTERNAL FUNCTION
%
% This function checks robustness of input parameters for all
% functions in 'modelfree' package.
%
%INPUT
%
% type - type of checking
% data - input data to be checked
%
% Created by Ivan Marin-Franch, 13/11/2008

switch type
    case 'designpoints'
        checkdesignpoints( data );
    case 'psychometricdata'
        checkpsychometricdata( data(1).content, data(2).content, data(3).content );
    case 'degreepolynomial'
        checkdegreepolynomial( data );
    case 'linkfunction'
        checklinkfunction( data );
    case 'guessingandlapsing'
        checkguessingandlapsing( data );
    case 'bootstrapreplications'
        checkbootstrapreplications( data );
    case 'exponentk'
        checkexponentk( data );
    case 'minmaxbandwidth'
        checkminmaxbandwidth( data );
    case 'bandwidth'
        checkbandwidth( data );
    case 'kernel'
        checkkernel( data );
    case 'maxiter'
        checkmaxiter( data );
    case 'tolerance'
        checktolerance( data );
    case 'method'
        checkmethod( data );
end

end

function checkdesignpoints( x )

[ rx, cx ] = size( x );
if cx ~= 1
    error('Stimulus levels should be a column vector');
end

end



function checkpsychometricdata( x, k, m )

% Check format of x and y
[ rx, cx ] = size( x );
[ rk, ck ] = size( k );
[ rm, cm ] = size( m );

if rx ~= rk || rx ~= rm
    error( 'The number of stimulus levels, successes and trials must be the same' );
end

if rx < 2 || rk < 2 || rm < 2
    error( 'Minimum number of points is 2' );
end

if cx ~= 1
    error( 'Vector of stimulus levels should be a column vector' );
end

if ck ~= 1
    error( 'Vector of number of successes should be a column vector' );
end

if cm ~= 1
    error( 'Vector of number of trials should be a column vector' );
end

if any( k < 0 ) || any( round( k ) ~= k )
    error( 'Number of successes must be a non-negative integer' );
end

if any( m <= 0 ) || any( round( m ) ~= m )
    error( 'Number of trials must be a positive integer' );
end

if any( k > m )
    error( 'Number of successes cannot be larger than number of trials' );
end

end

function checkdegreepolynomial( pn )

n = length( pn{2} );
p = pn{1};

if ~( strcmp( class(p), 'double' ) )
   error( 'Degree of polynomial must be a positive scalar' );
end
if p <= 0 || round( p ) ~= p || length( p ) > 1
    error( 'Degree of polynomial must be a positive integer' );
elseif p >= n,
    error( 'Degree of polynomial must be less than number of observations' )
end

end

function checklinkfunction( LINK )

if ~ischar(LINK )
    error('Argument link must be a character with name of a link function')
end

if ~strcmp( LINK, 'logit' )      && ...
   ~strcmp( LINK, 'probit' )     && ...
   ~strcmp( LINK, 'loglog' )     && ...
   ~strcmp( LINK, 'comploglog' ) && ...
   ~strcmp( LINK, 'weibull' )    && ...
   ~strcmp( LINK, 'revweibull' ),

    tmp = feval(LINK,0,0);
    if ( iscell(tmp) && length(tmp) == 3),
            if ~(isa( tmp{1}, 'function_handle') && ...
                    isa( tmp{2}, 'function_handle') && ...
                    isa( tmp{3}, 'function_handle') ),
                error( '%s is not an allowed link function', char( LINK ) );
            end
    else
        error( '%s is not an allowed link function', char( LINK ) );
    end
end

end

function checkguessingandlapsing( gl )

if any( gl < 0 ) || any( gl >= 1 )
    error( 'Guessing and lapsing rates must be greater or equal 0 and less than  1' );
end
if sum( gl ) >= 1,
    error( 'Guessing cannot be greater than or equal to 1-lapsing' );
end

end

function checkbootstrapreplications( N )

if ~( strcmp( class(N), 'double' ) )
    error( 'Number of bootstrap replications has to be an integer greater than 2 ' );
elseif N <= 1 || round( N ) ~= N || length( N ) > 1
    error( 'Number of bootstrap replications has to be and integer greater than 2 ' );
end

end

function checkexponentk( k )

if ~( strcmp( class(k), 'double' ) )
    error( 'Exponent for Weibull or reverse Weibull link function must be a positive scalar' );
end

if ( length( k ) > 1 || k <= 0 )
    error( 'Exponent for Weibull or reverse Weibull link function must be a positive scalar' );
end

end

function checkminmaxbandwidth( H )

[ rH cH ] = size( H );

if rH ~= 1 || cH ~= 2
    error( 'H has be a row vector with two values defining the search interval' );
end
if H(1) >= H(2)
    error( 'Lower limit of the search interval must be less than the upper limit' );
end

if H(1) <= 0
    error( 'Lower limit of the search interval must be positive' );
end

end

function checkbandwidth( h )

if ~( strcmp( class(h), 'double' ) )
    error( 'Bandwidth must be a positive scalar' );
end

if length( h ) > 1 || h <= 0
    error( 'Bandwidth must be a positive scalar' );
end

end

function checkkernel( ker )

if isa( ker, 'function_handle') 
    ker = func2str( ker );
elseif ~ischar( ker )
    error('Argument ker must be a character with name of a kernel')
end

if ~strcmp( ker, 'normpdf' )      && ...
   ~strcmp( ker, 'epanechnikov' ) && ...
   ~strcmp( ker, 'triangular' )   && ...
   ~strcmp( ker, 'tricube' )      && ...
   ~strcmp( ker, 'bisquare' )     && ...
   ~strcmp( ker, 'uniform' )
    error( '"%s" is not an allowed kernel', ker );
end

end
    
function checkmaxiter( maxiter )

if ~( strcmp( class(maxiter), 'double' ) )
    error( 'Maximum number of iterations must be a positive integer' );
end

if length( maxiter ) > 1
    error( 'Maximum number of iterations must be a positive integer' );
elseif maxiter <= 0 || round( maxiter ) ~= maxiter 
    error( 'Maximum number of iterations must be a positive integer' );
end

end

function checktolerance( tol )

if ~( strcmp( class(tol), 'double' ) )
    error( 'Tolerance level must be a positive scalar' );
end

if ( length( tol ) > 1 || tol <= 0 )
    error( 'Tolerance level must be a positive scalar' );
end

end

function checkmethod( method )

[ rm cm ] = size( method );

if rm > 1
    error( 'Choose only one method or ''all'' to calculate bandwidth' );
end

if ~strcmp( method, 'ISE' )        && ...
   ~strcmp( method, 'ISEeta' )     && ...
   ~strcmp( method, 'deviance' ) && ...
   ~strcmp( method, 'all' )
    error( '"%s" is a wrong loss function', method );
end

end