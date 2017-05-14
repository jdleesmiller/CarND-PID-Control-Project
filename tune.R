#
# Try the staged CEM results.
# Not great.
#
d <- read.csv('data/tune_staged_cem_15.csv')
d <- rbind(d, read.csv('data/tune_staged_cem_15b.csv'))
d <- rbind(d, read.csv('data/tune_staged_cem_15c.csv'))
dOK <- subset(d, crashed == 'false')
nrow(dOK)
head(dOK[order(dOK$total_absolute_cte),])
