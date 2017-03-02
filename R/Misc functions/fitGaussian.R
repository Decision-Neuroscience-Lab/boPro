# fit gaussian distribution
# mle example from http://www.r-bloggers.com/fitting-a-model-by-maximum-likelihood/

library(stats4)

set.seed(1001) # set seed of random process to ensure consistent results
N <- 100 # set number of observations
x <- rnorm(N, mean = 5, sd = 3) # get data as draws from gaussian

# below is our objective function; this is what we will try to optimise
LL <- function (mu, sigma){
  temp <- suppressWarnings(dnorm(x,mu,sigma))
  return(-sum(log(temp)))
}

# get the fit
mle.fit <- mle(LL, start = list(mu = 5, sigma = 3))

# interrogate the fit
mle.fit@min
mle.fit@coef