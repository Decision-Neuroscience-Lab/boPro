library(plm)
library(lmtest)
trialData <- read.csv("~/Documents/R/PIP/trialDataJuice(clean).txt")
trialData <- within(trialData, {
  id <- factor(id)
  delay <- factor(delay)
  reward <- factor(reward)
  lagReward <- factor(lagReward)
  lagReward2 <- factor(lagReward2)
  lagReward3 <- factor(lagReward3)
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
          column.labels=c("default","robust"), align=TRUE, out="Desktop/TestStar.tex")

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

