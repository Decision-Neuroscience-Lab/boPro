# PIP legacy analyses
## Bowen Fung, 2014


ezPlot(x = reward, data = trialData, dv = response, wid = id, within_full = .(delay,reward), within = .(delay,reward))
ezDesign(data = pip, x = mean, y = delay, row = session, col = delay)

aov <- aov(response ~ delay + lagReward + Error(id/(delay + lagReward)), data = trialData)
summary(aov)
coefficients(aov)

data_delay1 <- trialData[trialData$delay=="4",]
summary(aov(response ~ reward, data_delay1))
data_delay2 <- trialData[trialData$delay=="6",]
summary(aov(response ~ reward, data_delay2))
data_delay3 <- trialData[trialData$delay=="8",]
summary(aov(response ~ reward, data_delay3))
data_delay4 <- trialData[trialData$delay=="10",]
summary(aov(response ~ reward, data_delay4))

data_reward1 <- trialData[trialData$reward=="0",]
summary(aov(response ~ delay, data_reward1))
data_reward2 <- trialData[trialData$reward=="0.5",]
summary(aov(response ~ delay, data_reward2))
data_reward3 <- trialData[trialData$reward=="1.2",]
summary(aov(response ~ delay, data_reward3))
data_reward4 <- trialData[trialData$reward=="2.3",]
summary(aov(response ~ delay, data_reward4))

# For CV
load("~/Documents/R/Misc functions/makeRM.Rdata")
cv = read.csv("~/Documents/R/PIP/cvJuice.txt")
cvrm = make.rm(constant = "id",repeated = c("cv1","cv2","cv3","cv4"), data = cv)
cvaov <- aov(repdat~contrasts+Error(cons.col),cvrm)
cvaov2 <- aov(repdat~contrasts,cvrm)
summary(cvaov)
require(lsr)
etaSquared(cvaov2, type = 2, anova = T)

# Create models for each variable plus combinations and compare fits
# Variable list (Delay is constant) = reward, lagReward, totalVolume, lagDelay, lagResponse 
library(lme4)
m1 <- lmer(response ~ delay + (1|id), trialData, REML = FALSE, verbose = 1)
m2 <- update(m1, response ~ delay + lagResponse + (1|id))
m3 <- update(m1, response ~ delay + lagResponse + lagDelay (1|id))
m4 <- update(m1, response ~ delay + lagResponse + lagDelay + lagReward + (1|id))
m5 <- update(m1, response ~ delay + lagResponse + lagDelay + lagReward + reward + (1|id))
m6 <- update(m1, response ~ delay + lagResponse + lagDelay + lagReward + reward + totalvolume + (1|id))


anova(m1,m2,m4,m5,m6)

# Let's try to do osme post-hoc comparisons
library(nlme)

lme_velocity = lme(response ~ delay + lagReward, data = trialData, random = ~1|id)
anova(lme_velocity)
summary(lme_velocity)

options(contrasts=c("contr.sum","contr.poly"))

# Mult comp
require(multcomp)
summary(glht(lme_velocity, linfct=mcp(lagReward = "Tukey")))
summary(glht(lme_velocity, linfct=mcp(lagReward = "Tukey")), test = adjusted(type = "none"))
summary(glht(lme_velocity, linfct=mcp(lagReward = "Tukey")), test = adjusted(type = "b"))

# Diagnostics
plot(ranef(lme_velocity))
res_lme=residuals(lme_velocity)
plot(res_lme)
qqnorm(res_lme)
qqline(res_lme)
plot(lme_velocity)

library(MASS)
m0 <- lm(response ~ delay + lagDelay + reward + lagReward + lagResponse + totalvolume, trialData)
step = stepAIC(m0, direction = "both")
step$anova

library(lattice)
dotplot(ranef(m1, condVar = TRUE))


# For others
load("~/Documents/R scripts/makeRM.Rdata")
lagVar = read.csv("~/Documents/MATLAB/PIPW/data/RMlagRewardVar.txt")
lagVarJuice = subset(lagVar, type == 1)
rm = make.rm(constant = "id",repeated = c("D1R1","D1R2","D1R3","D1R4","D2R1","D2R2","D2R3","D2R4","D3R1","D3R2","D3R3","D3R4","D4R1","D4R2","D4R3","D4R4"), data = lagVarJuice)
summary(aov(repdat~contrasts+Error(cons.col),rm))

library(ez)
rm = ezANOVA(data = lagVarJuice, dv = response, wid = id, within_full = .(delay,reward), within = .(delay,reward))
rm = ezANOVA(data = trialData, dv = response, wid = id, within_full = .(delay), within = .(delay))
rm


# One more mult comp
require(afex)
m1 <- aov_ez(id = "id", dv = "response", data = trialData, within = c("delay","lagReward"), return = "Anova", fun.aggregate = mean, type = 3)
summary(m1)
require(phia)
testInteractions(m1[["lm"]], pairwise = "delay", idata = m1[["idata"]], adjustment = "none")

