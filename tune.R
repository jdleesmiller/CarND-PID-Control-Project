#
# Try the staged CEM results.
# Not great.
#
d <- transform(
  read.csv('data/tune_staged_cem_16.csv'),
  crashed = crashed == 'true'
)
nrow(d)
dAgg <- aggregate(
  cbind(crashed, distance, total_absolute_cte) ~
  kp + ki + kd + min_throttle + max_throttle + mean_steer_delay +
    throttle_steer_threshold, d, mean)
stopifnot(nrow(d) == nrow(dAgg) * 4)
dOK <- subset(dAgg, crashed == 0)
nrow(dOK)

# Timid:
head(dOK[order(dOK$total_absolute_cte),])

# Aggressive:
head(dOK[order(-dOK$distance),])
