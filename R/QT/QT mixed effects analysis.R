# QT mixed effects analysis
## Bowen J Fung, 2016

### Load data and required packages
trialData <- read.csv("~/Documents/R/QT/trialData.csv")
trialData$censor <- 1 - trialData$censor # In R, 1 is observed, 0 is censored

meData <- trialData[trialData$censor == 1,]
meData <- within(meData, {
  id <- factor(id)
  distribution <- factor(distribution)
  censor <- factor(censor)
  lagDelay <- factor(lagDelay)
  type <- factor(type)
})

# Recode drink to pre- post baseline 
meData[meData$block <= 5, "drink"] <- 1
meData[meData$block > 4 & meData$block < 9, "drink"] <- 2
meData[meData$block >= 9, "drink"] <- 3
meData$drink <- factor(meData$drink)

# Add time variable (totalTrial number)
for (i in unique(meData$id)) {
  meData[meData$id == i,"totalTrial"] <- seq(1,length(meData[meData$id == i,"id"]))
}

### Repeated measures ANOVAs
require(ez)

## Model 1: All factors
# Check design
ezDesign(allFactBalanced,
         x = id, 
         y = drink, 
         col = distribution,
         cell_border_size = 1)

# Remove unbalanced participants
allFactBalanced <- subset(meData, !(id %in% c(6,16,18,30,32,34)))

ezANOVA(data = allFactBalanced, dv = rt, wid = id, 
        between = .(type), 
        within = .(drink,distribution),
        type = 3, detailed = T, return_aov = F)

plt <- ezPlot(data = allFactBalanced,
            x = drink, 
            dv = rt, 
            wid = id,
            split = type,
            between = type,
            within = .(drink,distribution), 
            type = 3,
            x_lab = "Treatment block",
            y_lab = "Mean quitting time",
            split_lab = "Treatment condition",
            levels = list(drink = list(new_names = c("Baseline 1","Treatment","Baseline 2")), 
                          type = list(new_names = c("Caloric","Water")))
)
print(plt)

## Model 2: Distribution as within.full covariate only
# Check design
ezDesign(meDataBalanced,
         x = id, 
         y = drink, 
         col = distribution,
         cell_border_size = 1)
# Remove unbalanced participants
meDataBalanced <- subset(meData, !(id %in% c(32,34)))

mdl <- ezANOVA(data = meDataBalanced, dv = rt, wid = id, 
        between = .(type), 
        within = .(drink),
        within_full = .(distribution, totalTrial), # Include distribution, and time regressor
        type = 3, detailed = T, return_aov = F)
print(mdl)

plt <- ezPlot(data = meDataBalanced,
              x = drink, 
              dv = rt, 
              wid = id,
              split = type,
              between = type,
              within = .(drink), 
              within_full = .(distribution,totalTrial), 
              type = 3,
              x_lab = "Treatment block",
              y_lab = "Mean quitting time",
              split_lab = "Treatment condition",
              levels = list(drink = list(new_names = c("Baseline 1","Treatment","Baseline 2")), 
                            type = list(new_names = c("Caloric","Water")))
)
print(plt)

## Model 3: Separate distributions
# Subset data
uni <- subset(meData, distribution == 1 & !(id %in% c(6,16,18,30,32)))

# Check design
ezDesign(uni,
         x = id, 
         y = drink, 
         col = distribution,
         cell_border_size = 1)

mdl <- ezANOVA(data = uni, dv = rt, wid = id, 
               between = .(type), 
               within = .(drink),
               within_full = .(totalTrial), # Include distribution, and time regressor
               type = 3, detailed = T, return_aov = F)
print(mdl)

plt <- ezPlot(data = uni,
              x = drink, 
              dv = rt, 
              wid = id,
              split = type,
              between = type,
              within = .(drink), 
              type = 3,
              x_lab = "Treatment block",
              y_lab = "Mean quitting time",
              split_lab = "Treatment condition",
              levels = list(drink = list(new_names = c("Baseline 1","Treatment","Baseline 2")), 
                            type = list(new_names = c("Caloric","Water")))
)
print(plt)

# Subset data
pareto <- subset(meData, distribution == 2 & !(id %in% c(6,34)))

# Check design
ezDesign(pareto,
         x = id, 
         y = drink, 
         col = distribution,
         cell_border_size = 1)

mdl <- ezANOVA(data = pareto, dv = rt, wid = id, 
               between = .(type), 
               within = .(drink),
               type = 3, detailed = T, return_aov = F)
print(mdl)

plt <- ezPlot(data = pareto,
              x = drink, 
              dv = rt, 
              wid = id,
              split = type,
              between = type,
              within = .(drink), 
              type = 3,
              x_lab = "Treatment block",
              y_lab = "Mean quitting time",
              split_lab = "Treatment condition",
              levels = list(drink = list(new_names = c("Baseline 1","Treatment","Baseline 2")), 
                            type = list(new_names = c("Caloric","Water")))
)
print(plt)

## Model 4: Separate distributions (treatment only)
# Subset data
uni <- subset(meData, drink == 2 & distribution == 1)

# Check design
ezDesign(uni,
         x = id, 
         y = drink, 
         col = distribution,
         cell_border_size = 1)

mdl <- ezANOVA(data = uni, dv = rt, wid = id, 
               between = .(type), 
               type = 3, detailed = T, return_aov = F)
print(mdl)

plt <- ezPlot(data = uni,
              x = type, 
              dv = rt, 
              wid = id,
              between = type,
              type = 3,
              x_lab = "Treatment condition",
              y_lab = "Mean quitting time",
              levels = list(drink = list(new_names = c("No liquid","Liquid")), 
                            type = list(new_names = c("Caloric","Water")))
)
print(plt)

# Subset data
pareto <- subset(meData, drink == 2 & distribution == 2)

# Check design
ezDesign(pareto,
         x = id, 
         y = drink, 
         col = distribution,
         cell_border_size = 1)

mdl <- ezANOVA(data = pareto, dv = rt, wid = id, 
               between = .(type), 
               within_full = .(totalTrial), # Include distribution, and time regressor
               type = 3, detailed = T, return_aov = F)
print(mdl)

plt <- ezPlot(data = pareto,
              x = type, 
              dv = rt, 
              wid = id,
              between = type,
              type = 3,
              x_lab = "Treatment condition",
              y_lab = "Mean quitting time",
              levels = list(drink = list(new_names = c("No liquid","Liquid")), 
                            type = list(new_names = c("Caloric","Water")))
)
print(plt)

## Model 5: Only treatment
# Subset data
treatment <- subset(meData, block > 4 & block < 9 & !(id %in% c(30,32,34)))

# Check design
ezDesign(treatment,
         x = id, 
         y = drink, 
         col = distribution,
         cell_border_size = 1)

mdl <- ezANOVA(data = treatment, dv = rt, wid = id, 
               between = .(type), 
               within = .(distribution),
               type = 3, detailed = T, return_aov = F)
print(mdl)

plt <- ezPlot(data = treatment,
              x = type, 
              dv = rt, 
              wid = id,
              between = type,
              type = 3,
              x_lab = "Treatment block",
              y_lab = "Mean quitting time",
              split_lab = "Treatment condition",
              levels = list(drink = list(new_names = c("No liquid","Liquid")), 
                            type = list(new_names = c("Caloric","Water")))
)
print(plt)

### Plot and make tables
require(ggplot2)
plt = plt + theme(text = element_text(size=15))
print(plt)

require(xtable)
xtable(mdl$ANOVA)

# Post-hoc tests (simple effects)
d1 <- ezANOVA(data = meDataBalanced[meDataBalanced$type == 1,], 
              dv = rt, wid = id, within = .(drink), 
              within_full = .(distribution,totalTrial), type = 3)

pairwise.t.test(meDataBalanced[meDataBalanced$type == 1,"rt"], 
                meDataBalanced[meDataBalanced$type == 1,"drink"], 
                paired = F, p.adjust.method = "none")

d2 <- ezANOVA(data = meDataBalanced[meDataBalanced$type == 2,], 
              dv = rt, wid = id, within = .(drink), 
              within_full = .(distribution,totalTrial),type = 3)

pairwise.t.test(meDataBalanced[meDataBalanced$type == 2,"rt"], 
                meDataBalanced[meDataBalanced$type == 2,"drink"], 
                paired = F, p.adjust.method = "none")

wilcox.test(rt ~ type, data = subset(meData,distribution == 2), paired = F) # Test differences

pVals <- c(d1$ANOVA$p, d2$ANOVA$p)
holmCorr <- p.adjust(pVals, method = "holm");

### Run panel regression model
require(plm)
require(lmtest)

# Create decaying drink regressor
# for (p in unique(meData$id)) {
#   for (b in unique(meData$block)) {
#     i <- meData$id == p & meData$block == b
#     if (b %in% c(5,6,7,8)) {
#       meData[i,"drinkModel"] <- 1 - (meData$blockTime[i]*0.003) # Or exponential decay ^-0.2
#       # meData[i,"drinkModel"] <- meData$blockTime[i]^-0.2
#     }
#     else {meData[i,"drinkModel"] <- NA
#     }
#   }
# }

control <- subset(meData, type == 1) # Unsure about what "random" constitutes, so split and run each separately as well
treatment <- subset(meData, type == 2)

# Model all
pdata = plm.data(meData,index = c("id","allTrial"))
fixed <- plm(rt ~ drink, data = pdata, model = "within", effects = "individual")
summary(fixed)

# Model control condition
pdata = plm.data(control,index = c("id","totalTrial"))
panelModelControl <- plm(rt ~ drink + distribution, data = pdata, model = "within", effects = "individual")
summary(panelModelControl)

# Model treatment condition
pdata = plm.data(treatment,index = c("id","totalTrial"))
panelModelTreatment <- plm(rt ~ drink + distribution, data = pdata, model = "within", effects = "individual")
summary(panelModelTreatment)

# Model reward rate
pdata = plm.data(treatment,index = c("id","totalTrial"))
panelModelReward <- plm(rt ~ pr, data = pdata, model = "within", effects = "individual")
summary(panelModelReward)

# Diagnostics
bptest(panelModelControl, studentize=F) # Significance implies heteroskedasticity
coeftest(panelModelControl, vcovHC) # Heteroskedasticity consistent coefficients
mean(fixef(panelModelControl)) # Check mean of 'intercept'
sd(fixef(panelModelControl)) / sqrt(length(fixef(panelModelControl))) # Check SEM of 'intercept'

# Save output to text
#library(stargazer)
#cov <- vcovHC(fixed, type = "HC0")
#robust.se <- sqrt(diag(cov))
#stargazer(fixed, fixed, se=list(NULL, robust.se),
#          title="Mixed effects regression results",
#          dep.var.labels="Quit time",
#          covariate.labels=c("Block","Drink"), 
#          single.row=TRUE,no.space=TRUE,omit.stat=c("LL","ser","f"),
#          column.labels=c("default","robust"), align=TRUE, out="Desktop/qtGlucoseUniMixed.tex")