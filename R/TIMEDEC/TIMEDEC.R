# TIMEDEC
## Bowen J Fung, 2015

# Repeated measures for feedback manipulation
feedMan <- read.csv("~/Documents/R/TIMEDEC/feedbackMan.csv")
# Subset to only ECG data
feedMan <- subset(feedMan, id < 121)
require(PMCMR)
h <- kruskal.test(k-k2 ~ as.factor(condition), data = feedMan)
posthoc.kruskal.nemenyi.test(k-k2 ~ as.factor(condition), data = feedMan, g = as.factor(condition), method="Tukey") # Find mean ranks in MATLAB
pairwise.wilcox.test((feedMan$k-feedMan$k2), g = as.factor(feedMan$condition), p.adj="none", exact=T)

# Test if 'overestimate' < 'underestimate' for increase (more negative) in k
s <- wilcox.test(feedMan$k[feedMan$condition == 2]-feedMan$k2[feedMan$condition == 2], 
                 feedMan$k[feedMan$condition == 3]-feedMan$k2[feedMan$condition == 3])

# Test if 'control' < 'underestimate' for increase (more negative) in k
wilcox.test(feedMan$k[feedMan$condition == 4]-feedMan$k2[feedMan$condition == 4], 
            feedMan$k[feedMan$condition == 3]-feedMan$k2[feedMan$condition == 3])

# Test if 'control' > 'overestimate' for increase (more negative) in k
wilcox.test(feedMan$k[feedMan$condition == 4]-feedMan$k2[feedMan$condition == 4], 
            feedMan$k[feedMan$condition == 2]-feedMan$k2[feedMan$condition == 2])


# Correlations and multiple comparison corrections
data <- read.table("~/Documents/R/TIMEDEC/data.csv")

edr <- read.csv("/Users/Bowen/Documents/R/TIMEDEC/timedecKubios.csv")
names(edr)[1] <- "id"
edr <- edr[,c("id","edr")]
data <- merge(data,edr,by = "id", all.x = T, all.y = F)

# Physiological censoring
data$meanHR[data$meanHR == 0] <- NA
data$sdnn[data$sdnn == 0] = NA
data$sdnni[data$sdnni == 0] = NA
data$meanHR[data$meanHR > 140] = NA
data$sdnn[data$sdnn < 20] = NA
data$sdnni[data$sdnni < 20] = NA
data$hfpowfft[data$hfpowfft > 4000] = NA
data$lfpowfft[data$lfpowfft > 4000] = NA

data <- subset(data, filter == 1 & id < 121) # Subset to clean data
attach(data)
require(Hmisc)
require(corrgram)
require(ggplot2)
require(xtable)
require(ppcor)
source("/Users/Bowen/Documents/R/misc functions/corrstars.R")
source("/Users/Bowen/Documents/R/misc functions/xtable.decimal.R")

# DR and HR
vars <- c("meanDiff","cvReproduction","stevens1","stevens2","meanHR","sdnn","hfpowfft","lfpowfft")
temp <- data[vars]
corrgram(temp,order=TRUE,lower.panel = panel.ellipse, upper.panel = panel.pts, cor.method = "spearman")
corr <- rcorr(as.matrix(temp), type = "spearman")

fdrCorr <- apply(corr$P, 2, p.adjust, method = "holm") # Methods are bonferroni, holm, hochberg, hommel, BH, or BY

corrstars(as.matrix(temp), type = "spearman", method = "none")
xtable(corrstars(as.matrix(temp)))

# Control for respiration (by including heart rate)
require(ppcor)
vars <- c("stevens2","hfpowfft","meanHR")
temp <- data[vars]
temp <- temp[complete.cases(temp),]
pcor(temp, method = "spearman")
spcor(temp, method = "spearman")
# Control for respiration (by including peak HF)
vars <- c("stevens2","hfpowfft","hfpeakfft")
temp <- data[vars]
temp <- temp[complete.cases(temp),]
pcor(temp, method = "spearman")
spcor(temp, method = "spearman")
# Control for respiration (by including edr)
vars <- c("stevens2","hfpowfft","edr")
temp <- data[vars]
temp <- temp[complete.cases(temp),]
pcor(temp, method = "spearman")
spcor(temp, method = "spearman")

# Plots
ggplot(data, aes(x = stevens1, y = lfpowfft)) + geom_point(aes(color = stevens1)) + geom_smooth(method = "lm", se = TRUE)

write.table(round(corr$r, digits = 2), file = "~/Documents/R/TIMEDEC/DRHRcorrR.csv")
write.table(round(corr$P, digits = 3), file = "~/Documents/R/TIMEDEC/DRHRcorrP.csv")
write.table(round(fdrCorr,digits = 3), file = "~/Documents/R/TIMEDEC/DRHRcorrFDR.csv")

# TD and HR
vars <- c("bayesLogK","meanHR","sdnn","hfpowfft","lfpowfft")
temp2 <- data[vars]
corrgram(temp2,order=TRUE,lower.panel=panel.ellipse,cor.method = "spearman")
corr <- rcorr(as.matrix(temp2), type = "spearman")
fdrCorr <- apply(corr$P, 1, p.adjust, method = "BH") # Methods are bonferroni, holm, hochberg, hommel, BH, or BY

corrstars(as.matrix(temp2), type = "spearman", method = "none")
xtable(corrstars(as.matrix(temp2)))

write.table(round(corr$r, digits = 2), file = "~/Documents/R/TIMEDEC/TDHRcorrR.csv")
write.table(round(corr$P, digits = 3), file = "~/Documents/R/TIMEDEC/TDHRcorrP.csv")
write.table(round(fdrCorr,digits = 3), file = "~/Documents/R/TIMEDEC/TDHRcorrFDR.csv")

# Questionnaire and HR
vars <- c("meanHR","sdnn","sdnni","hfpowfft","lfpowfft","ipipN","ipipE","ipipO","ipipA","ipipC","BIS","BASdrive","BASfun","BASreward","zaubAUC")
temp3 <- data[vars]
corrgram(temp3,order=TRUE,lower.panel=panel.ellipse,cor.method = "spearman")
corr <- rcorr(as.matrix(temp3), type = "spearman")
fdrCorr <- apply(corr$P, 1, p.adjust, method = "BH") # Methods are bonferroni, holm, hochberg, hommel, BH, or BY

corrstars(as.matrix(temp3), type = "spearman", method = "none")
xtable.decimal(corrstars(as.matrix(temp3), type = "spearman", method = "none"))

write.table(round(corr$r, digits = 2), file = "~/Documents/R/TIMEDEC/QHRcorrR.csv")
write.table(round(corr$P, digits = 3), file = "~/Documents/R/TIMEDEC/QHRcorrP.csv")
write.table(round(fdrCorr,digits = 3), file = "~/Documents/R/TIMEDEC/QHRcorrFDR.csv")

# TD and AUC
vars <- c("k3","meanHR","zaubAUC")
temp4 <- data[vars]
corrgram(temp4,order=TRUE,lower.panel=panel.ellipse,cor.method = "spearman")
corr <- rcorr(as.matrix(temp4), type = "spearman")
fdrCorr <- apply(corr$P, 1, p.adjust, method = "BH") # Methods are bonferroni, holm, hochberg, hommel, BH, or BY

corrstars(as.matrix(temp4), type = "spearman", method = "none")
xtable(corrstars(as.matrix(temp4)))

# Questionnaire, TD, DR
vars <- c("k3","meanDiff","cvReproduction","stevens1","stevens2") #"bayesLogK","magEffect","zaubAUC")
temp5 <- data[vars]
corrgram(temp5,order=TRUE,lower.panel=panel.ellipse,cor.method = "spearman")
corr <- rcorr(as.matrix(temp5), type = "spearman")
fdrCorr <- apply(corr$P, 1, p.adjust, method = "BH") # Methods are bonferroni, holm, hochberg, hommel, BH, or BY

corrstars(as.matrix(temp5), type = "spearman", method = "none")
xtable.decimal(corrstars(as.matrix(temp5), type = "spearman", method = "none"))


## Correlation between carry-over effects and HR data
coefs <- read.csv("~/Documents/R/TIMEDEC/COcoefs.csv")
coefs <- subset(coefs,id %in% data$id) # Subset to clean data
data <- cbind(data,coefs)

vars <- c("sample","meanHR","sdnn","hfpowfft","lfpowfft")
temp6 <- data[vars]
corrgram(temp6,order=TRUE,lower.panel=panel.ellipse,cor.method = "spearman")
corr <- rcorr(as.matrix(temp6), type = "spearman")
fdrCorr <- apply(corr$P, 1, p.adjust, method = "BH") # Methods are bonferroni, holm, hochberg, hommel, BH, or BY

corrstars(as.matrix(temp6), type = "spearman", method = "none")
xtable.decimal(corrstars(as.matrix(temp6), type = "spearman", method = "none"))


# Partial correlations (control for respiration)
vars <- c("k3","stevens1","stevens2","meanDiff","meanHR","stevens1","stevens2","sdnn","hfpowfft","lfpowfft")
temp <- data[vars]
temp <- temp[complete.cases(temp),]
x <- temp$stevens2
y <- temp$hfpowfft
z <- temp$meanHR
pcor.test(x, y, z, method = "spearman")
spcor.test(x, y, z, method = "spearman")

detach(data)

# Check physiological data between feedback conditions
require(PMCMR)
kruskal.test(data$meanHR~ as.factor(condition), data = data)
kruskal.test(data$sdnn~ as.factor(condition), data = data)
kruskal.test(data$hfpowfft~ as.factor(condition), data = data)
kruskal.test(data$lfpowfft~ as.factor(condition), data = data)

posthoc.kruskal.nemenyi.test(data$meanHR ~ as.factor(condition), data = data, g = as.factor(condition), method="Tukey") # Find mean ranks in MATLAB
posthoc.kruskal.nemenyi.test(data$sdnn ~ as.factor(condition), data = data, g = as.factor(condition), method="Tukey") # Find mean ranks in MATLAB
posthoc.kruskal.nemenyi.test(data$hfpowfft ~ as.factor(condition), data = data, g = as.factor(condition), method="Tukey") # Find mean ranks in MATLAB
posthoc.kruskal.nemenyi.test(data$lfpowfft ~ as.factor(condition), data = data, g = as.factor(condition), method="Tukey") # Find mean ranks in MATLAB

pairwise.wilcox.test(data$meanHR, data$condition, p.adjust.method = "none", na.rm = T)
wilcox.test(data[condition == 3,"meanHR"], data[condition == 4,"meanHR"], p.adjust.method = "none", na.rm = T)
pairwise.wilcox.test(data$sdnn, data$condition, p.adjust.method = "none", na.rm = T)
pairwise.wilcox.test(data$hfpowfft, data$condition, p.adjust.method = "none", na.rm = T)
pairwise.wilcox.test(data$lfpowfft, data$condition, p.adjust.method = "none", na.rm = T)
wilcox.test(data[condition == 2,"lfpowfft"], data[condition == 3,"lfpowfft"], p.adjust.method = "none", na.rm = T)

# Control for feedback conditions
## Partial correlations
vars <- c("stevens1","lfpowfft","condition")
temp <- data[vars]
temp <- temp[complete.cases(temp),]
x <- temp$stevens1
y <- temp$lfpowfft
z <- temp$condition
pcor.test(x, y, z, method = "spearman")
rcorr(x,y, type = "spearman")

## Quantile regression
require("quantreg")
qs = 1:9/10
# Mean HR and discount rate
fit1 <- rq(k3 ~ meanHR, data = data, tau = qs)
summary(fit1, se = "nid")
plot(fit1)
fit2 <- rq(k3 ~ meanHR + as.factor(condition), data = data, tau = qs)
summary(fit2, se = "nid")
plot(fit2)
# HF and exponent
fit1 <- rq(stevens2 ~ hfpowfft, data = data, tau = 0.5)
summary(fit1, se = "nid")
fit2 <- rq(stevens2 ~ hfpowfft + as.factor(condition), data = data, tau = 0.5)
summary(fit2, se = "nid")
# LF and exponent
fit1 <- rq(stevens2 ~ lfpowfft, data = data, tau = 0.5)
summary(fit1, se = "nid")
fit2 <- rq(stevens2 ~ lfpowfft + as.factor(condition), data = data, tau = 0.5)
summary(fit2, se = "nid")
# LF and scale
fit1 <- rq(stevens1 ~ lfpowfft, data = data, tau = 0.6)
summary(fit1, se = "nid")
fit2 <- rq(stevens1 ~ lfpowfft + as.factor(condition), data = data, tau = 0.6)
summary(fit2, se = "nid")

# Figures
## Duration reproduction
timeSeries <- read.csv("~/Documents/R/TIMEDEC/timeSeries.csv", header = T)
intervals <- read.csv("~/Documents/R/TIMEDEC/intervals.csv", header = T)

kruskal.test(meanReproduction ~ as.factor(sampleInterval), data = intervals)
kruskal.test(meanDiff ~ as.factor(sampleInterval), data = intervals)

kruskal.test(stdReproduction ~ as.factor(sampleInterval), data = intervals)
kruskal.test(cvReproduction ~ as.factor(sampleInterval), data = intervals)

require("quantreg")
qs = 1:9/10
fit1 <- rq(diff ~ sample, data = timeSeries, tau = qs)
summary(fit1, se = "nid")
plot(fit1)
fit2 <- rq(k3 ~ meanHR + as.factor(condition), data = data, tau = qs)
summary(fit2, se = "nid")
plot(fit2)

attach(timeSeries)
require(ggplot2)
require(ggExtra)
plot_center = ggplot(timeSeries, aes(x=sample,y=reproduction)) + geom_point(aes(colour = factor(sample))) + stat_smooth(method = "lm", formula = y ~ poly(x,2), size = 1)
ggMarginal(plot_center, type="density", margins = "y")

## Regression
summary(lm(stevens2 ~ hfpowfft + lfpowfft, data = data))

# Grossman and Kollai (1993) suggestion (PNS activity only indexed by HF-HRV if HR taken into account)
summary(lm(stevens2 ~ hfpowfft, data = data))
summary(lm(stevens2 ~ hfpowfft+ meanHR, data = data))

# Effect sizes for some tests
cohensD(stevens2-1)
t.test(stevens2-1)
