trialData <- read.csv("~/Documents/R scripts/trialData(clean).txt")

library(MASS)
fit <- lm(response ~ factor(id) + trial + factor(delay) + factor(reward) + factor(lagReward) + totalvolume,data=trialData)
step <- stepAIC(fit, direction="both")
step$anova

fit <- lm(response ~ factor(id) + factor(delay) + factor(lagReward) - 1,data=trialData)
summary(fit)
# diagnostic plots 
layout(matrix(c(1,2,3,4),2,2)) # optional 4 graphs/page 
plot(fit)

library(lme4) 
m1 <- lmer(accuracy ~ factor(delay)+ factor(lagReward) + totalvolume + factor(reward) + (1 | id), trialData)
m2 <- lmer(response ~ lagReward + delay + reward:delay + (1+reward|id), trialData)
anova(m1,m2)
summary(m1)
plot(m2)

# Fixed effects
library(plm)
library(lmtest)
fixed <- plm(accuracy ~ factor(lagReward) + factor(delay) + totalvolume + factor(reward), data=trialData, index=c("id","trial"), model="within")
summary(fixed)

# Test cross-correlation between individual error terms
pcdtest(fixed, test = c("lm"))
pcdtest(fixed, test = c("cd"))

# Test serial correlation
pbgtest(fixed)

# Test heteroskedasticity
bptest(accuracy ~ factor(lagReward) + factor(delay) + totalvolume + factor(reward) + factor(id), data = trialData, studentize=F)
# Control for heteroskedasticity
coeftest(fixed, vcovHC) # Heteroskedasticity consistent coefficients
coeftest(fixed, vcovHC(fixed, method = "arellano")) # Heteroskedasticity consistent coefficients (Arellano)

# Test against OLS
ols <-lm(accuracy ~ factor(lagReward) + factor(delay) + totalvolume + factor(reward), data=trialData)
pFtest(fixed, ols)

# Test against random effects
random <- plm(accuracy ~ factor(lagReward) + factor(delay) + totalvolume + factor(reward), data=trialData, index=c("id","trial"), model="random")
phtest(fixed, random) # Hausman

# Test fixed time
fixed.time <- plm(accuracy ~ factor(lagReward) + factor(delay) + totalvolume + factor(reward) + factor(trial), data=trialData, index=c("id","trial"), model="random")
pFtest(fixed.time, fixed)
plmtest(fixed, c("time"), type=("bp"))

# Test random against OLS
pool <- plm(accuracy ~ factor(lagReward) + factor(delay) + totalvolume + factor(reward), data=trialData, index=c("id","trial"), model="pooling")
plmtest(pool, type=c("bp"))



