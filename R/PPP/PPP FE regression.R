# PPP panel regression
## Bowen J Fung, 2016

library(plm)
library(lmtest)
#trialData <- read.csv("~/Documents/R/PPP/trialDataPPP.txt")
#trialData <- subset(trialData, flag == 0) # Subset to clean (physiological?) data (this will remove participants 10,23,28,34,49)

trialData <- read.csv("~/Documents/R/PPP/trialDataAll.txt") # Contains all clean experiments

"trialData <- subset(trialData, id %in% c(5,8,12,18,25,34,35,36,39,45,51)) # Remove participants who occasionally consume diet soft drink
trialData <- subset(trialData, id %in% c(8,18,25,34,35,36,45)) # Remove participants who regularly consume diet soft drink
"

# Add indicator variables for calories and sweetness
trialData$caloric <- factor(ifelse(trialData$type %in% c(1,5), 1, 0))
trialData$sweet <- factor(ifelse(trialData$type %in% c(1,4), 1, 0))

# Subset to main task phase
trialData <- subset(trialData, session == 2)

### type: (1 = juice, 2 = money, 3 = water, 4 = aspartame, 5 = glucose)

trialData <- within(trialData, {
  id <- factor(id)
  type <- factor(type)
  delay <- factor(delay)
  reward <- factor(reward, levels = c("none", "small", "medium", "large"), ordered = F)
  lagReward <- factor(lagReward, levels = c("none", "small", "medium", "large"), ordered = F)
  lagDelay <- factor(lagDelay)
})
attach(trialData)

Y <- cbind(response)
X <- cbind(delay, reward, lagReward, totalvolume)
pdata = plm.data(trialData,index = c("id","trial"))
pdata2 = pdata.frame(trialData,index = c("id","trial"), drop.index = TRUE, row.names = TRUE)

# Descriptive summaries
summary(Y)
summary(X)

# Pooled OLS estimator
pooling <- plm(Y ~ delay + reward + lagReward + totalvolume + lagResponse, data = pdata, model = "pooling")
summary(pooling)

# Between estimator
between <- plm(Y ~ delay + reward + lagReward + totalvolume + lagResponse, data = pdata, model = "between")
summary(between)

# First differences estimator
firstdiff <- plm(Y ~ delay + reward + lagReward + totalvolume + lagResponse, data = pdata, model = "fd")
summary(firstdiff)

# Fixed effects (within) estimator
fixed <- plm(Y ~ delay + reward + lagReward + totalvolume + lagDelay + lagResponse, data = pdata, model = "within")
fixed <- plm(response ~ delay + lagReward*sweet*caloric*type + lagDelay + lagResponse, data = pdata, model = "within")

summary(fixed)
coeftest(fixed, vcovHC) # Heteroskedasticity consistent coefficients
mean(fixef(fixed)) # Check mean of 'intercept'
sd(fixef(fixed)) / sqrt(length(fixef(fixed))) # Check SEM of 'intercept'

# Random effects estimator
random <- plm(Y ~ delay + reward + lagReward + totalvolume + lagDelay, data = pdata, model = "random")
summary(random)

# LM test for random vs OLS
plmtest(pooling) # Significance advises random effects

# LM test for fixed vs OLS
pFtest(fixed, pooling) # Significance advises fixed effects

# Hausman test for random vs fixed effects
phtest(random, fixed) # Significance advises fixed effects

## Other diagnostics
# Test cross-correlation between individual error terms
pcdtest(fixed, test = c("lm"))
pcdtest(fixed, test = c("cd"))

# Test serial correlation
pbgtest(fixed)

# Test heteroskedasticity
bptest(fixed, studentize=F) # Significance implies heteroskedasticity
# Control for heteroskedasticity
coeftest(fixed, vcovHC) # Heteroskedasticity consistent coefficients
coeftest(fixed, vcovHC(fixed, method = "arellano")) # Heteroskedasticity consistent coefficients (Arellano)

# Test fixed time
fixed.time <- plm(Y ~ X + factor(trial), data = pdata, model = "random")
pFtest(fixed.time, fixed)
plmtest(fixed, c("time"), type=("bp"))

# Save output to text
library(stargazer)
stargazer(random,type="text",out="Desktop//LaTex DocsrandomTable.txt")
stargazer(fixed,type="text",out="Desktop/LaTex Docs/fixedTable.txt")

cov <- vcovHC(fixed, type = "HC0")
robust.se <- sqrt(diag(cov))
stargazer(fixed, fixed, se=list(NULL, robust.se),
          title="Fixed effects regression results",
          dep.var.labels="Response",
          covariate.labels=c("Delay (6 seconds)","Delay (8 seconds)","Delay (10 seconds)",
                             "Anticipated reward (small)","Anticipated reward (medium)",
                             "Anticipated reward (large)","Previous reward (small)",
                             "Previous reward (medium)","Previous reward (large)","Total volume",
                             "Previous delay (6 seconds)", "Previous delay (8 seconds)", 
                             "Previous delay (10 seconds)","Previous response"), 
          single.row=TRUE,no.space=TRUE,omit.stat=c("LL","ser","f"),
          column.labels=c("default","robust"), align=TRUE, out="Desktop/Malto.tex")

# Random subset power analysis
repeats <- 100
numTrials2Remove <- 32
require(data.table)
pVals <- array()
for (reps in seq(repeats)) {
  rmv <- names(trialData)[c(1,9)] # Drop some vars for cleanliness
  DT <- data.table(trialData[,!(names(trialData) %in% rmv)]) # Convert to data.table
  
  for (p in unique(trialData$id)) {
    DT <- DT[-sample(which(DT$id == p), numTrials2Remove)] # Drop n randomly sampled trials for each participant
  }
  
  # Analyse remaining dataset (use your own analysis)
  pdata = plm.data(data.frame(DT),index = c("id","trial"))
  fixed <- plm(response ~ delay + reward + lagReward + totalvolume + lagDelay + lagResponse, data = pdata, model = "within")
  temp <- coeftest(fixed, vcovHC)
  
  pVals <- rbind(pVals,temp[7:9,4]) # Concatenate p values into array
}

# Plot histogram of p values
require(ggplot2)
require(reshape2)
d <- melt(pVals)
ggplot(d,aes(x = value)) + 
  facet_wrap(~Var2, scales = "free_x") + 
  geom_histogram()

# All data model using lme4
require(nlme)
require(lme4)
require(lmerTest)
# Relevel type
trialData$type <- factor(trialData$type, levels = c(2,3,4,5,1))
trialData$presence <- factor(ifelse(trialData$lagReward == "none", 0, 1))
trialData$presence2 <- factor(ifelse(trialData$reward == "none", 0, 1))

m0 <- lmer(response ~ delay + lagDelay + lagResponse + reward + lagReward + totalvolume + (1|id), data = trialData) # Original model
m0 <- lmer(response ~ delay + lagReward*sweet*caloric + lagDelay + lagResponse + (1|type/id), data = trialData) # Caloric/sweet model

summary(m0)
plot(m0)

# Try with lme
m1 <- lme(response ~ delay + presence*sweet*caloric, random = ~1|type/id, 
          method = "ML", data = trialData, na.action = "na.omit") # Caloric/sweet model
summary(m1)
plot(m1)
qqnorm(m1, ~ranef(., level=2))
plot( m1, resid(., type = "p") ~ fitted(.) | delay,
      id = 0.05, adj = -0.3 )
m1.1 <- update( m1, weights = varIdent(form = ~ 1 | delay) )
summary(m1.1)

write.csv(round(summary(m1.1)$coefficients, digits = 3), 
          "/Users/Bowen/Documents/PhD/manuscripts/POP/submissions/JEP/resubmission/lme.csv")

# Build model from bottom


anova(m1,m2,m3,m4)

# require(robustlmm)
#  m2 <- rlmer(response ~ delay + lagReward*sweet*caloric + (1|id), 
#             data = trialData, method = "DASvar")
#  m2 <- rlmer(response ~ delay + lagDelay + lagResponse + reward + lagReward + totalvolume + (1|id), 
#              data = trialData, method = "DASvar")

# Robust SE
require("sandwich")
require("lmtest")
model$newse<-vcovHC(m1)
coeftest(model,model$newse)

# Diagnose collinearity
vif.mer <- function (fit) {
  ## adapted from rms::vif
  v <- vcov(fit)
  nam <- names(fixef(fit))
  ## exclude intercepts
  ns <- sum(1 * (nam == "Intercept" | nam == "(Intercept)"))
  if (ns > 0) {
    v <- v[-(1:ns), -(1:ns), drop = FALSE]
    nam <- nam[-(1:ns)]
  }
  d <- diag(v)^0.5
  v <- diag(solve(v/(d %o% d)))
  names(v) <- nam
  v
}

kappa.mer <- function (fit,
                       scale = TRUE, center = FALSE,
                       add.intercept = TRUE,
                       exact = FALSE) {
  X <- fit@pp$X
  nam <- names(fixef(fit))
  ## exclude intercepts
  nrp <- sum(1 * (nam == "(Intercept)"))
  if (nrp > 0) {
    X <- X[, -(1:nrp), drop = FALSE]
    nam <- nam[-(1:nrp)]
  }
  if (add.intercept) {
    X <- cbind(rep(1), scale(X, scale = scale, center = center))
    kappa(X, exact = exact)
  } else {
    kappa(scale(X, scale = scale, center = scale), exact = exact)
  }
}

require(pwr)
pwr.f2.test(u = 14, v = 3702, f2 = 0.005, sig.level = 0.05) # For juice experiment, using partial eta-squared
pwr.f2.test(u = 22, v = 16763, f2 = 0.005, sig.level = 0.05) # For juice experiment, using partial eta-squared
