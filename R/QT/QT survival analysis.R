# QT surival analysis
## Bowen J Fung, 2016

### Load data and required packages
trialData <- read.csv("~/Documents/R/QT/trialData.csv")
trialData$censor <- 1 - trialData$censor # In R, 1 is observed, 0 is censored

# Recode type (so results are interpreted from satiety perspective)
names(trialData)[20] <- "Treatment"
trialData[trialData$Treatment == 1, "Treatment"] <- "Caloric"
trialData[trialData$Treatment == 2, "Treatment"] <- "Water"
#trialData[trialData$Treatment == 2, "Treatment"] <- 0

trialData <- within(trialData, {
  id <- factor(id)
  distribution <- factor(distribution)
  Treatment <- factor(Treatment, levels = c("Water","Caloric"))
})

# Remove participants
trialData <- subset(trialData,!(id %in% c(32,34)))

# Add allBlock (block number for each distribution)
trialData$allBlock <- trialData$block
trialData[trialData$distribution == 2,"allBlock"] <- trialData[trialData$distribution == 2,"allBlock"]/2
trialData[trialData$distribution == 1,"allBlock"] <- (trialData[trialData$distribution == 1,"allBlock"]+1)/2

### Drop baseline blocks and split by distribution
allData <- subset(trialData, block > 2) # All data excluding practice
rrData <- subset(trialData, block <= 4 | block >= 9) # Non-drink trials (for reward rate comparison)
drinkData <- subset(trialData, block > 4 & block < 9) # Drink trials (both dists)
uniData <- subset(trialData, block > 4 & block < 9 & distribution == 1)
paretoData <- subset(trialData, block > 4 & block < 9 & distribution == 2)

## To test drink consumption within groups
waterData <- subset(trialData, distribution == 2 & Treatment == "Water")# & block > 2)
caloricData <- subset(trialData, distribution == 2 & Treatment == "Caloric")# & block > 2)

## Choose which distribution to run analysis on
detach(uniData)
attach(paretoData)

## Transform to survivor function
require(survival)
qts = Surv(rt,censor)
est1 = survfit(qts ~ 1)
str(est1) # Summary returned as a list
plot(est1, main = "Kaplan-Meier estimate with 95% confidence bounds", xlab="Time (secs)", ylab = "Survival function")

### Plot treatment
source("/Users/Bowen/Documents/R/misc functions/ggsurvplot.R")
stype <- survfit(qts ~ Treatment)
names(stype$strata) <- c("Caloric","Water")
plt <- ggsurvplot(stype, conf.int = T, events = F, zeroy = F, xlab = "Time (secs)", col = c("tan1","steelblue2"), linetype = F)
plt + theme(legend.title=element_blank(), 
            legend.position = c(0.8,0.8), text = element_text(size=18),
            axis.title.y=element_text(margin=margin(0,20,0,0)),
            legend.key.size = unit(1.5, 'lines'),
            plot.margin = unit(c(1,1,1,1), "cm")) + 
  scale_x_continuous(limits=c(0, 12), expand = c(0, 0), breaks=seq(0, 12, 4)) + 
  scale_y_continuous(limits=c(0,1), expand = c(0, 0), breaks=seq(0,1,0.2)) # Change lims

### Plot timing environment
source("/Users/Bowen/Documents/R/misc functions/ggsurvplot.R")
stype <- survfit(qts ~ distribution)
names(stype$strata) <- c("Uniform","Heavy-tailed")
plt <- ggsurvplot(stype, conf.int = T, events = F, zeroy = F, xlab = "Time (secs)", col = c("lightpink1","darkolivegreen2"), linetype = F)
plt + theme(legend.title=element_blank(), 
            legend.position = c(0.7,0.8), 
            text = element_text(size=18),
            axis.title.y=element_text(margin=margin(0,20,0,0)),
            legend.key.size = unit(1.5, 'lines'),
            plot.margin = unit(c(1,1,1,1), "cm")) + scale_x_continuous(limits=c(0, 12), expand = c(0, 0)) + scale_y_continuous(limits=c(0,1), expand = c(0, 0)) # Change lims

### Plot delay distributions 
distributions <- read.csv("~/Documents/R/QT/distributions.csv", header = F)
library(tidyr)
library(ggplot2)

xx <- seq(0,15,0.01)
m <- matrix(data=cbind(distributions[1,], distributions[2,], distributions[3,]), ncol=3)
colnames(m) <- c("xx", 'uniform', 'pareto')
df <- as.data.frame(m)

plot(df$xx, df$uniform, type = "l", lwd = 3, col = "darkolivegreen2", ylab = "Probability", xlab = "Time (secs)", 
     ylim = c(0,0.2), xlim = c(0,25), yaxs = "i", xaxs="i",
     cex.lab = 1.5, cex.axis = 1.3)
lines(df$xx, df$pareto, type = "l", lwd = 3, col = "lightpink1")
legend(12,0.18, c("Uniform", "Heavy-tailed"), 
       lty=c(1,1), lwd=c(2.5,2.5), col=c("darkolivegreen2","lightpink1"), box.lty=0, cex = 1.3)

### Means with CI
print(survfit(qts ~ Treatment), print.rmean=TRUE)

### Test for differences
survdiff(qts ~ Treatment, rho = 0)
# Second arguement (rho) is 0 for log-rank, 1 for Peto&Peto modification of the Gehan-Wilcoxon test

# Analyse effect of drink (i.e. drinking vs not drinking)
temp <- trialData[trialData$distribution == 1,]
qts = Surv(temp$rt,temp$censor)
est1 = survfit(qts ~ temp$drink)
plot(est1, main = "Kaplan-Meier estimate for drink vs not", xlab="Time (secs)", ylab = "Survival function")
survdiff(qts ~ temp$drink, rho = 0)

### Cox proportional hazards model (use cluster() for approximate jackknife variance)
qts = Surv(rt, censor)
fit1 <- coxph(qts ~ Treatment + distribution + drink + cluster(id), method="breslow") # Methods are 'efron','breslow', or 'exact'
summary(fit1)
fit1$loglik

cox.zph(fit1) # Check proportional hazards assumption

## Accelerated failure time model
fit2 <- survreg(qts ~ Treatment, dist="weibull") # ("weibull", "exponential", "gaussian", "logistic", "lognormal", or "loglogistic")
summary(fit2)
fit2$loglik

## Cox mixed effects model
require(coxme)
require(gtools)
fit3 <- coxme(qts ~ Treatment + (1 |as.factor(id)))
summary(fit3)
fixef(fit3)
int <- ranef(fit3)$as.factor.id

# Inspect individual effects
cond <- c(rep(0,length(unique(id))))
cond[unique(id) <= 25] <- 1
cond[unique(id) > 25] <- 2

int <- int[sort(names(int))]

indEffects <- data.frame(unique(id), cond, int)
names(indEffects) <- c("id","cond","effect")

ggplot(indEffects[!(indEffects$id %in% c()),], aes(x = effect, fill = as.factor(cond))) + #y = ..density..
  geom_histogram(alpha = .9, binwidth = 0.6, position="identity")

indEffects[outlier(indEffects[!(indEffects$id %in% c()),"effect"], logical = T),"id"]

var.test(effect ~ cond, data = indEffects) # Test for equality of variances (use Welch's for unequal variances)
t.test(effect ~ cond, data = indEffects, paired = F, var.equal = F) # Change var.equal for Student's
wilcox.test(effect ~ cond, data = indEffects, paired = F, var.equal = F)

## Frailty analysis
require(frailtypack)

ezDesign(waterData, allBlock, drink, distribution)

waterData <- subset(trialData, Treatment == "Water" & block > 2 & distribution == 2)
caloricData <- subset(trialData, Treatment == "Caloric" & block > 2)

fitFrail <- frailtyPenal(Surv(rt,censor) ~ cluster(id) + distribution*Treatment, 
                         data = drinkData, 
                         Frailty = T, 
                         n.knots = 7, 
                         kappa = 5000,
                         cross.validation = T,
                         RandDist = "LogN")
fitFrail
summary(fitFrail, level = 0.95)
uniplot(fitFrail, type.plot = "survival", conf.bands = TRUE)

## Frailty analysis using H-likel
require(frailtyHL)
frailtyHL(Surv(rt,censor) ~ Treatment + (1|id), 
          data = paretoData,
          varfixed = F, varinit = 0.1, 
          Maxiter = 200, convergence = 10^-6,
          mord = 0, dord = 1,
          RandDist = "Normal")

## Generalized estimating equations (GEE for AFT)
# !!!WARNING, TAKES 10+ MINUTES!!! #
require(aftgee)
fitGee <- aftgee(qts ~ Treatment, data = paretoData, id = id)
summary(fitGee)

# Zero-inflated negative binomial mixed-effects
### This has two processes, the first is governed by a binary distribution which generates "zeros" (censored events),
### the second is then governed by either a Poisson or negative binomial distribution to generate the other times.
require(glmmADMB)

# Recode censored events as zeros
zeroData <- trialData
zeroData$id <- factor(zeroData$id)
# Subset for analysis
zeroData <- subset(zeroData, distribution == 1)
actualPZ <- sum(zeroData$censor == 0) / dim(zeroData)[1] # Provide actual proportion of quit choices
start <- list(fixed = 0, pz = actualPZ, log_alpha = 1, RE_sd = 0.25, RE_cor = 0.0001, u = 0)
zeroData$rt[zeroData$censor == 0] <- 0
zeroData$rt <- round(zeroData$rt*100)

# Run zero-inflated model
z1 <- glmmadmb(rt ~ Treatment + (1|id), data = zeroData, zeroInflation = T, family = "poisson") # or "nbinom"/"nbinom1"
summary(z1)
logLik(z1)
AIC(z1)
int <- ranef(z1)

# Inspect individual intercepts
cond <- c(rep(0,length(unique(id))))
cond[unique(id) < 25] <- 1
cond[unique(id) >= 25] <- 2

indEffects <- data.frame(unique(id), cond, int)
names(indEffects) <- c("id","cond","effect")

ggplot(indEffects[!(indEffects$id %in% c()),], aes(x = effect, fill = as.factor(cond))) + #y = ..density..
  geom_histogram(alpha = .7, binwidth = 1, position="identity")

indEffects[outlier(indEffects[!(indEffects$id %in% c()),"effect"], logical = T),"id"]

var.test(effect ~ cond, data = indEffects) # Test for equality of variances (use Welch's for unequal variances)
t.test(effect ~ cond, data = indEffects, paired = F, var.equal = F) # Change var.equal for Student's
ks.test(indEffects[indEffects$cond == 1,"effect"],indEffects[indEffects$cond == 2,"effect"])

# Run hurdle model
## First fit non-zero counts
z2 <- glmmadmb(rt ~ Treatment + (1|id), data = subset(zeroData, distribution == 1 & rt > 0), zeroInflation = T, family = "truncnbinom1")
summary(z2)
int <- ranef(z2)

# Then fit to binary
zeroData$q <- as.numeric(zeroData$rt > 0)
binFit <- glmmadmb(q ~ Treatment + (1|id), data = subset(zeroData, distribution == 1), zeroInflation = T, family = "binomial") # Add or leave "type"
summary(binFit)
int <- ranef(binFit)

# Multi-state Markov model
require(msm)

# Rearrange data by delay time
msmData <- uniData
for (i in unique(msmData$id)) {
  temp <- msmData[msmData$id == i,]
  newOrder <- temp[order(temp$delay),]
  msmData[msmData$id == i,] <- newOrder
}

initTransitions <- rbind(c(0,0.25), c(0,0.25))
crudeinits.msm(censor+1 ~ delay, id, data = msmData, qmatrix = initTransitions)
msmFit <- msm(censor+1 ~ delay, subject = id, data = msmData, qmatrix = initTransitions)

# Joint models
require(JM)
