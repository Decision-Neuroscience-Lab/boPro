# TIMEDEC task phase analysis
## Bowen J Fung, 2016

# Read behavioural data
data <- read.table("/Users/Bowen/Documents/R/TIMEDEC/data.csv")
data <- data[,-c(75:91)] # Drop old Kubios analysis
data <- subset(data, filter == 1 & id < 121) # Subset to ECG cohort

# Read ECG data
filePath <- "/Users/Bowen/Documents/R/TIMEDEC/Kubios2016"
files <- dir(filePath)

phaseData <- data.frame()
for (i in files){
  temp <- read.csv(paste(filePath,"/", i, sep = ""), header = TRUE)
  
  temp$Sample <- as.integer(regmatches(i, gregexpr("[0-9]+", i))[[1]][1])
  temp$phase <- as.integer(regmatches(i, gregexpr("[0-9]+", i))[[1]][2])
  phaseData <- rbind(phaseData,temp)
}
names(phaseData)[1] <- "id"

# Merge files
data <- merge(data, phaseData,
      by = "id", all = T)

# Clean physiologically improbably data
data$meanhr[data$meanhr == 0] <- NA
data$sdnn[data$sdnn == 0] = NA
data$sdnni[data$sdnni == 0] = NA
data$meanHR[data$meanHR > 140] = NA
data$sdnn[data$sdnn < 20] = NA
data$sdnni[data$sdnni < 20] = NA
data$hfpowfft[data$hfpowfft > 4000] = NA
data$lfpowfft[data$lfpowfft > 4000] = NA
data$sdnn[data$sdnn < 20] = NA
data$sdnni[data$sdnni < 20] = NA

source("/Users/Bowen/Documents/R/misc functions/corrstars.R")
require(Hmisc)

consolidateDuplicates <- function(data) {
  library(data.table)
  data <- as.data.table(sapply(data, as.numeric ))
  # Get mean of dups
  data <- data[,lapply(.SD, mean, na.rm = T),by = id]
  return(data)
}

conserveLastPhase <- function(data) {
  data <- data[order(data$id, -data$phase),]
  data <- data[!duplicated(data$id),]
}

attach(data)

# Behavioural
vars <- c("id","meanDiff","cvReproduction","stevens1","stevens2",
          "bayesLogK","k","k2","k3","zaubAUC",
          "meanHR","meanhr","rmssd","lfpeakfft","hfpeakfft","hfpowfft","lfpowfft","lfpowprfft","hfpowprfft","totpowfft","lfhffft","edr")
temp <- data[phase %in% c(1),vars]
#temp <- consolidateDuplicates(temp)
corr <- rcorr(as.matrix(temp), type = "spearman")
corrstars(as.matrix(temp), type = "spearman", method = "none")

corrstars(as.matrix(temp), type = "spearman", method = "BH")

# Control for respiration (by including heart rate)
require(ppcor)
vars <- c("stevens2","hfpowfft","meanHR")
temp <- data[vars]
temp <- temp[complete.cases(temp),]
pcor(temp, method = "spearman")
spcor(temp, method = "spearman")

## Correlation between carry-over effects and HR data
coefs <- read.csv("~/Documents/R/TIMEDEC/COcoefs.csv")
coefs <- subset(coefs,id %in% data$id) # Subset to clean data
data <- merge(data,coefs,by = "id", all.x = T, all.y  = F)

vars <- c("sample","meanHR","sdnn","hfpowfft","lfpowfft")
temp6 <- data[vars]
corrgram(temp6,order=TRUE,lower.panel=panel.ellipse,cor.method = "spearman")
corr <- rcorr(as.matrix(temp6), type = "spearman")
fdrCorr <- apply(corr$P, 1, p.adjust, method = "BH") # Methods are bonferroni, holm, hochberg, hommel, BH, or BY

corrstars(as.matrix(temp6), type = "spearman", method = "none")
xtable.decimal(corrstars(as.matrix(temp6), type = "spearman", method = "none"))


# Partial correlations (control for respiration)
vars <- c("k3","stevens1","stevens2","meanDiff","meanHR","stevens1","stevens2","rmssd","hfpowfft","lfpowfft")
temp <- data[vars]
temp <- temp[complete.cases(temp),]
x <- temp$stevens2
y <- temp$hfpowfft
z <- temp$meanHR
pcor.test(x, y, z, method = "spearman")
spcor.test(x, y, z, method = "spearman")

# Merged table with all variables
vars <- c("bayesLogK","meanDiff","cvReproduction","stevens1","stevens2","meanHR","rmssd","hfpowfft","lfpowfft")
temp2 <- data[vars]
corrgram(temp2,order=TRUE,lower.panel=panel.ellipse,cor.method = "spearman")
corr <- rcorr(as.matrix(temp2), type = "spearman")
fdrCorr <- apply(corr$P, 1, p.adjust, method = "BH") # Methods are bonferroni, holm, hochberg, hommel, BH, or BY

corrstars(as.matrix(temp2), type = "spearman", method = "none")
xtable(corrstars(as.matrix(temp2)))

detach(data)

# Check physiological data between feedback conditions
require(PMCMR)
kruskal.test(data$meanHR~ as.factor(condition), data = data)
kruskal.test(data$rmssd~ as.factor(condition), data = data)
kruskal.test(data$hfpowfft~ as.factor(condition), data = data)
kruskal.test(data$lfpowfft~ as.factor(condition), data = data)

posthoc.kruskal.nemenyi.test(data$meanHR ~ as.factor(condition), data = data, g = as.factor(condition), method="Tukey") # Find mean ranks in MATLAB
posthoc.kruskal.nemenyi.test(data$rmssd ~ as.factor(condition), data = data, g = as.factor(condition), method="Tukey") # Find mean ranks in MATLAB
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
