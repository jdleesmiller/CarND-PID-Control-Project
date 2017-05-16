#
# Try the staged CEM results.
# Not great.
#
d <- transform(
  read.csv('data/tune_staged_cem_16.csv'),
  crashed = crashed == 'true'
)
d$sample <- rep(1:(nrow(d)/4), each=4)
nrow(d)

# Four runs per sample; average to get one row.
dAgg <- aggregate(
  cbind(crashed, distance, total_absolute_cte) ~
  sample + kp + ki + kd + min_throttle + max_throttle + mean_steer_delay +
    throttle_steer_threshold, d, mean)
stopifnot(nrow(d) == nrow(dAgg) * 4)
dAgg <- dAgg[order(dAgg$sample),]

# Look only at the last complete generation plus the incomplete one at the end.
dLast <- dAgg[501:nrow(dAgg),]
nrow(dLast)

# Require that we never crashed.
dOK <- subset(dLast, crashed == 0)
nrow(dOK)

# Timid: smallest error among our solutions
head(dOK[order(dOK$total_absolute_cte),])

# Aggressive: fastest laps
head(dOK[order(-dOK$distance),])
