# Load data (change path if necessary)
x = read.csv("/Users/Bowen/Desktop/TIMEDEC/timedecQualtrics.csv")

# Make sure plot package is installed
list.of.packages = c("corrplot", "psych")
new.packages = list.of.packages[!(list.of.packages %in% installed.packages()[,"Package"])]
if(length(new.packages)){
  install.packages(new.packages)
}

# Load package
lapply(list.of.packages, require, character.only = TRUE)


## IPIP
# Get indices of IPIP items
i = which(colnames(x) == 'IPIP_1'):which(colnames(x) == 'IPIP_50')

# Plot correlation matrix
corrplot(cor(x[,i]),
         tl.cex = 0.5)

# Test reliabilities
print('Alphas for N, E, O, A, C')
for(j in seq(from = 1, to = 41, by = 10)){
  k = i[j:(j + 9)]
  print(alpha(x[,k])$total$std.alpha)
}

## BIS BAS
# Get indices of BISBAS items
i2 = which(colnames(x) == 'BIS_BAS_1'):which(colnames(x) == 'BIS_BAS_24')

# Plot correlation matrix
corrplot(cor(x[,i2]),
         tl.cex = 0.5)

# Test reliabilities
print('Alphas for N, E, O, A, C')
for(j in seq(from = 1, to = 41, by = 10)){
  k = i2[j:(j + 9)]
  print(alpha(x[,k])$total$std.alpha)
}
